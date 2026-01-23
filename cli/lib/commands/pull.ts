import chalk from "chalk";
import { existsSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import yoctoSpinner from "yocto-spinner";
import { dockerCompose, checkDocker } from "../utils/docker";

interface PullOptions {
  instance?: string;
}

/**
 * Try to find the Zoo repo root by walking up from this source file location.
 */
function findZooRepoRoot(): string | null {
  const explicit = process.env.ZOO_REPO_ROOT || process.env.ZOO_ROOT || process.env.THE_ZOO_ROOT;
  if (explicit && existsSync(path.join(explicit, "docker-compose.yaml"))) {
    return explicit;
  }

  const here = path.dirname(fileURLToPath(import.meta.url));
  let cur = here;
  for (let i = 0; i < 8; i++) {
    const candidate = path.join(cur, "docker-compose.yaml");
    if (existsSync(candidate)) return cur;
    const parent = path.dirname(cur);
    if (parent === cur) break;
    cur = parent;
  }
  return null;
}

/**
 * Pull Zoo container images
 */
export async function pull(options: PullOptions): Promise<void> {
  console.log(chalk.blue("📦 Pulling Zoo container images..."));

  // Check Docker first
  const dockerRunning = await checkDocker();
  if (!dockerRunning) {
    console.error(chalk.red("❌ Docker is not running. Please start Docker first."));
    process.exit(1);
  }

  // Import here to avoid circular dependency
  const { getProjectName: getProjectNameFromOptions } = await import("../utils/project");
  const { paths } = await import("../utils/config");

  let projectName: string;
  let zooSourcePath: string;

  const repoRoot = findZooRepoRoot();

  // In dev mode (ZOO_DEV=1), always prefer the real repo root
  if (process.env.ZOO_DEV === "1" && repoRoot) {
    zooSourcePath = repoRoot;
    projectName = "the_zoo"; // Default project name for dev
  } else {
    try {
      projectName = await getProjectNameFromOptions(options.instance);

      // Determine the source path based on the project name
      const match = projectName.match(/^thezoo-cli-instance-(.+?)-v/);
      if (match) {
        const instanceId = match[1];
        const instancePath = path.join(paths.runtime, instanceId, "zoo");
        if (existsSync(instancePath)) {
          zooSourcePath = instancePath;
        } else if (repoRoot) {
          zooSourcePath = repoRoot;
        } else {
          zooSourcePath = process.cwd();
        }
      } else {
        // Running from dev environment
        zooSourcePath = repoRoot || process.cwd();
      }
    } catch (error) {
      // No running instance - use repo root for pulling
      if (repoRoot) {
        zooSourcePath = repoRoot;
        projectName = "the_zoo";
      } else {
        console.error(chalk.red(`❌ ${(error as Error).message}`));
        console.log(chalk.gray('Run "thezoo start" first to create an instance'));
        process.exit(1);
      }
    }
  }

  const spinner = yoctoSpinner({ text: "Pulling images..." }).start();

  try {
    // Pull default services
    spinner.text = "Pulling default services...";
    await dockerCompose("pull --quiet", {
      cwd: zooSourcePath,
      projectName,
      showCommand: false,
    });

    // Pull on-demand services
    spinner.text = "Pulling on-demand services...";
    await dockerCompose("--profile on-demand pull --quiet", {
      cwd: zooSourcePath,
      projectName,
      showCommand: false,
    });

    spinner.success("All images pulled successfully");
    console.log(chalk.green("✓ Zoo container images are ready"));
  } catch (error) {
    spinner.error("Failed to pull images");
    console.error(chalk.red((error as Error).message));
    process.exit(1);
  }
}
