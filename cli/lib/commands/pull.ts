import chalk from "chalk";
import yoctoSpinner from "yocto-spinner";
import { dockerCompose, checkDocker } from "../utils/docker";
import path from "node:path";

interface PullOptions {
  instance?: string;
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

  try {
    projectName = await getProjectNameFromOptions(options.instance);

    // Determine the source path based on the project name
    const match = projectName.match(/^thezoo-cli-instance-(.+?)-v/);
    if (match) {
      const instanceId = match[1];
      zooSourcePath = path.join(paths.runtime, instanceId, "zoo");
    } else {
      // Running from dev environment
      zooSourcePath = process.cwd();
    }
  } catch (error) {
    console.error(chalk.red(`❌ ${(error as Error).message}`));
    console.log(chalk.gray('Run "thezoo start" first to create an instance'));
    process.exit(1);
  }

  const spinner = yoctoSpinner({ text: "Pulling images..." }).start();

  try {
    // Pull all services including all profiles
    spinner.text = "Pulling all services...";
    await dockerCompose("--profile '*' pull --quiet", {
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
