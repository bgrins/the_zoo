import chalk from "chalk";
import { dockerCompose, checkDocker } from "../utils/docker";
import { CliError, errorMessage } from "../utils/errors";
import { getInstanceEnvFile, getInstanceSourcePath } from "../utils/instance";
import { startSpinner } from "../utils/output";
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
    throw new CliError("Docker is not running. Please start Docker first.");
  }

  let projectName: string;

  try {
    projectName = await getProjectName(options.instance);
  } catch (error) {
    throw new CliError(errorMessage(error), {
      hint: 'Run "the_zoo start" first to create an instance',
    });
  }

  const spinner = startSpinner("Pulling images...");

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
    throw new CliError(errorMessage(error));
  }
}
