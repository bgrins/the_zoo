import chalk from "chalk";
import yoctoSpinner from "yocto-spinner";
import { dockerCompose, checkDocker } from "../utils/docker";
import { getInstanceEnvFile, getInstanceSourcePath } from "../utils/instance";
import { getProjectName } from "../utils/project";

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

  let projectName: string;

  try {
    projectName = await getProjectName(options.instance);
  } catch (error) {
    console.error(chalk.red(`❌ ${(error as Error).message}`));
    console.log(chalk.gray('Run "the_zoo start" first to create an instance'));
    process.exit(1);
  }

  const spinner = yoctoSpinner({ text: "Pulling images..." }).start();

  try {
    // Pull all services including all profiles
    spinner.text = "Pulling all services...";
    await dockerCompose(["--profile", "*", "pull", "--quiet"], {
      cwd: getInstanceSourcePath(projectName),
      projectName,
      envFile: getInstanceEnvFile(projectName),
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
