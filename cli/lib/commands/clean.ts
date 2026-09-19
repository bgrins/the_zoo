import fs from "node:fs/promises";
import path from "node:path";
import chalk from "chalk";
import { confirm } from "@inquirer/prompts";
import { checkDocker, execCommand } from "../utils/docker";
import { paths, sanitizeInstanceId } from "../utils/config";
import { CliError, errorMessage } from "../utils/errors";
import { parseProjectName } from "../utils/instance";
import { getOutputCapture, startSpinner } from "../utils/output";

interface CleanOptions {
  force?: boolean;
  instance?: string;
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
    const { stdout } = await execCommand("docker", [
      ...listing,
      "--filter",
      `label=${PROJECT_LABEL}`,
      "--format",
      `{{.Label "${PROJECT_LABEL}"}}`,
    ]);
    for (const project of stdout.split("\n")) {
      if (parseProjectName(project.trim())) {
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
    const { stdout } = await execCommand("docker", [...listing, "-q", "--filter", filter]);
    return stdout.split("\n").filter(Boolean);
  };

  const containers = await ids(["ps", "-a"]);
  if (containers.length > 0) {
    await execCommand("docker", ["rm", "-f", ...containers]);
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

/**
 * Ask before deleting. Inside the MCP server nobody can answer, so force is required.
 */
async function confirmRemoval(): Promise<boolean> {
  if (getOutputCapture()) {
    throw new CliError("Refusing to remove resources without confirmation; pass force: true");
  }
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
  const dockerRunning = await checkDocker();
  const projects = dockerRunning
    ? (await listCliProjects()).filter(
        (p) => parseProjectName(p)?.instanceId === sanitizeInstanceId(instanceId),
      )
    : [];

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

/**
 * Clean up all Zoo resources from Docker
 */
export async function clean(options: CleanOptions): Promise<void> {
  // If a specific instance is requested, clean only that
  if (options.instance) {
    return cleanInstance(options.instance, options);
  }

  console.log(chalk.blue("🧹 Cleaning up The Zoo CLI instances..."));

  // Check Docker
  const dockerRunning = await checkDocker();
  if (!dockerRunning) {
    throw new CliError("Docker is not running");
  }

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
