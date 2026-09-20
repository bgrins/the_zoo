import fs from "node:fs/promises";
import path from "node:path";
import chalk from "chalk";
import confirm from "@inquirer/confirm";
import packageJson from "../../package.json" with { type: "json" };
import {
  dockerProbe,
  dockerProblem,
  execCommand,
  getRunningInstances,
  requireDocker,
} from "../utils/docker";
import { paths, sanitizeInstanceId } from "../utils/config";
import { CliError, errorMessage } from "../utils/errors";
import { isCliProject, isDevMode, locateInstance, parseProjectName } from "../utils/instance";
import { startSpinner } from "../utils/output";
import { compareVersions, parseVersion } from "../utils/version";

interface CleanOptions {
  force?: boolean;
  instance?: string;
  oldVersions?: boolean;
}

const PROJECT_LABEL = "com.docker.compose.project";

/**
 * Find CLI instance projects that still own containers, networks or volumes.
 * Docker label filters only match exact values, so list the label and filter here.
 */
async function listCliProjects(): Promise<string[]> {
  const listings = [
    ["ps", "-a"],
    ["network", "ls"],
    ["volume", "ls"],
  ];
  const projects = new Set<string>();
  for (const listing of listings) {
    const { stdout } = await dockerProbe([
      ...listing,
      "--filter",
      `label=${PROJECT_LABEL}`,
      "--format",
      `{{.Label "${PROJECT_LABEL}"}}`,
    ]);
    for (const project of stdout.split("\n")) {
      if (isCliProject(project.trim())) {
        projects.add(project.trim());
      }
    }
  }
  return [...projects].sort();
}

/**
 * Remove every container, network, volume and dangling image of a compose project
 */
async function removeProjectResources(projectName: string): Promise<void> {
  const filter = `label=${PROJECT_LABEL}=${projectName}`;
  const ids = async (listing: string[]) => {
    const { stdout } = await dockerProbe([...listing, "-q", "--filter", filter]);
    return stdout.split("\n").filter(Boolean);
  };

  // -v also removes the containers' anonymous volumes (the database data dirs), which carry no
  // project label for the volume cleanup below to find
  const containers = await ids(["ps", "-a"]);
  if (containers.length > 0) {
    await execCommand("docker", ["rm", "-f", "-v", ...containers]);
  }
  const networks = await ids(["network", "ls"]);
  if (networks.length > 0) {
    await execCommand("docker", ["network", "rm", ...networks]);
  }
  const volumes = await ids(["volume", "ls"]);
  if (volumes.length > 0) {
    await execCommand("docker", ["volume", "rm", ...volumes]);
  }
  await execCommand("docker", ["image", "prune", "-f", "--filter", filter]);
}

/**
 * Directories holding a CLI instance's files, across CLI versions
 */
async function findInstanceDirs(instanceId: string): Promise<string[]> {
  const candidates = [path.join(paths.runtime, instanceId)];
  const versions = await fs.readdir(paths.instances).catch(() => []);
  for (const version of versions) {
    candidates.push(path.join(paths.instances, version, instanceId));
  }

  const dirs: string[] = [];
  for (const dir of candidates) {
    const stat = await fs.stat(dir).catch(() => null);
    if (stat?.isDirectory()) {
      dirs.push(dir);
    }
  }
  return dirs;
}

async function confirmRemoval(): Promise<boolean> {
  const confirmed = await confirm({
    message: "Do you want to continue?",
    default: false,
  });
  if (!confirmed) {
    console.log("Operation cancelled");
  }
  return confirmed;
}

/**
 * Clean up a specific instance: its Docker resources and its files
 */
async function cleanInstance(instanceId: string, options: CleanOptions): Promise<void> {
  if (!/^[\w-]+$/.test(instanceId)) {
    throw new CliError(`Invalid instance ID: "${instanceId}"`);
  }

  const dirs = await findInstanceDirs(instanceId);
  const problem = await dockerProblem();
  if (problem) {
    console.log(chalk.yellow(`${problem.message}, so its resources stay; removing files only`));
  }
  const projects = problem
    ? []
    : (await listCliProjects()).filter(
        (p) =>
          sanitizeInstanceId(parseProjectName(p)?.instanceId ?? "") ===
          sanitizeInstanceId(instanceId),
      );

  if (dirs.length === 0 && projects.length === 0) {
    throw new CliError(`Instance "${instanceId}" does not exist.`);
  }

  if (!options.force) {
    console.log(chalk.yellow(`\nThis will remove instance "${instanceId}":`));
    for (const project of projects) {
      console.log(`  - Docker project ${project} (containers, networks, volumes)`);
    }
    for (const dir of dirs) {
      console.log(`  - ${dir}`);
    }

    if (!(await confirmRemoval())) {
      return;
    }
  }

  const spinner = startSpinner(`Removing instance ${instanceId}...`);

  try {
    for (const project of projects) {
      spinner.text = `Removing Docker resources for ${project}...`;
      await removeProjectResources(project);
    }
    for (const dir of dirs) {
      await fs.rm(dir, { recursive: true, force: true });
    }
    spinner.success(`Instance ${instanceId} removed`);
    console.log(chalk.green(`\n✓ Instance "${instanceId}" has been cleaned up`));
  } catch (error) {
    spinner.error("Failed to clean up instance");
    throw new CliError(errorMessage(error));
  }
}

const IMAGE_REPOSITORY = "ghcr.io/bgrins/the_zoo/";

function isOlderVersion(version: string | undefined): boolean {
  const parsed = version ? parseVersion(version) : null;
  const current = parseVersion(packageJson.version);
  return parsed !== null && current !== null && compareVersions(parsed, current) < 0;
}

/**
 * Remove what older CLI versions left behind: their instance directories, Docker resources
 * and images. Running instances, and the images running containers use, stay.
 */
async function cleanOldVersions(options: CleanOptions): Promise<void> {
  console.log(chalk.blue("🧹 Cleaning up older CLI versions..."));
  await requireDocker();

  const running = await getRunningInstances({ onlyCliInstances: true });
  const runningDirs = new Set(running.map((project) => locateInstance(project)?.dir));

  const dirs: string[] = [];
  const kept: string[] = [];
  const versionDirs = isDevMode()
    ? []
    : (await fs.readdir(paths.instances).catch(() => [])).filter(isOlderVersion);
  for (const version of versionDirs) {
    const versionDir = path.join(paths.instances, version);
    for (const instanceId of await fs.readdir(versionDir).catch(() => [])) {
      const dir = path.join(versionDir, instanceId);
      (runningDirs.has(dir) ? kept : dirs).push(dir);
    }
  }

  const projects = (await listCliProjects()).filter(
    (project) => !running.includes(project) && isOlderVersion(parseProjectName(project)?.version),
  );

  const lines = async (args: string[]) => (await dockerProbe(args)).stdout.split("\n");
  const inUse = new Set(await lines(["ps", "--format", "{{.Image}}"]));
  const tagged = new Set(await lines(["image", "ls", "--format", "{{.Repository}}:{{.Tag}}"]));
  const images = [...tagged].filter(
    (image) =>
      image.startsWith(IMAGE_REPOSITORY) &&
      isOlderVersion(image.slice(image.lastIndexOf(":") + 1)) &&
      !inUse.has(image),
  );

  for (const dir of kept) {
    console.log(chalk.gray(`Keeping ${dir}, which is running`));
  }
  if (dirs.length === 0 && projects.length === 0 && images.length === 0) {
    console.log(chalk.yellow("Nothing from older CLI versions to remove"));
    return;
  }

  if (!options.force) {
    console.log(chalk.yellow("\nThis will remove:"));
    for (const dir of dirs) {
      console.log(`  - ${dir}`);
    }
    for (const project of projects) {
      console.log(`  - Docker project ${project} (containers, networks, volumes)`);
    }
    for (const image of images) {
      console.log(`  - image ${image}`);
    }
    if (!(await confirmRemoval())) {
      return;
    }
  }

  const spinner = startSpinner("Removing older CLI versions...");
  const failures: string[] = [];
  try {
    for (const project of projects) {
      spinner.text = `Removing Docker resources for ${project}...`;
      await removeProjectResources(project);
    }
    for (const dir of dirs) {
      await fs.rm(dir, { recursive: true, force: true });
    }
    for (const version of versionDirs) {
      // Only once nothing in it is left
      await fs.rmdir(path.join(paths.instances, version)).catch(() => {});
    }
  } catch (error) {
    spinner.error("Failed to clean up");
    throw new CliError(errorMessage(error));
  }
  for (const image of images) {
    spinner.text = `Removing ${image}...`;
    // An image a stopped container still uses can't be removed; the others still can
    await execCommand("docker", ["image", "rm", image]).catch((error) =>
      failures.push(`${image}: ${errorMessage(error).trim()}`),
    );
  }

  if (failures.length > 0) {
    spinner.error(`Could not remove ${failures.length} of ${images.length} images`);
    throw new CliError(failures.join("\n"));
  }
  spinner.success("Older CLI versions removed");
}

/**
 * Clean up all Zoo resources from Docker
 */
export async function clean(options: CleanOptions): Promise<void> {
  if (options.instance && options.oldVersions) {
    throw new CliError("Pass either --instance or --old-versions");
  }
  // If a specific instance is requested, clean only that
  if (options.instance) {
    return cleanInstance(options.instance, options);
  }
  if (options.oldVersions) {
    return cleanOldVersions(options);
  }

  console.log(chalk.blue("🧹 Cleaning up The Zoo CLI instances..."));

  await requireDocker();

  const projects = await listCliProjects();
  if (projects.length === 0) {
    console.log(chalk.yellow("No Zoo CLI instance resources found"));
    return;
  }

  if (!options.force) {
    console.log(chalk.yellow("\nThe following Zoo CLI instances have Docker resources:"));
    projects.forEach((p) => console.log(`  - ${p}`));
    console.log(
      chalk.yellow(
        "\nThis command will stop and remove ALL Zoo CLI containers, networks, and volumes.",
      ),
    );

    if (!(await confirmRemoval())) {
      return;
    }
  }

  const spinner = startSpinner("Cleaning up Docker resources...");

  try {
    for (const project of projects) {
      spinner.text = `Removing Docker resources for ${project}...`;
      await removeProjectResources(project);
    }

    spinner.success("Docker resources cleaned");

    console.log(chalk.green("\n✓ The Zoo CLI instances have been cleaned up"));
  } catch (error) {
    spinner.error("Failed to clean up");
    throw new CliError(errorMessage(error));
  }
}
