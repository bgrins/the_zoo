import chalk from "chalk";
import { dockerCompose, getComposeServices, requireDocker } from "../utils/docker";
import { CliError, errorMessage } from "../utils/errors";
import {
  getInstanceEnvFile,
  getInstanceSourcePath,
  instanceServices,
  isCliProject,
  withHeavyApps,
} from "../utils/instance";
import { readEnvFile } from "../utils/network-env";
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

  await requireDocker();

  let projectName: string;

  try {
    projectName = await getProjectName(options.instance);
  } catch (error) {
    if (error instanceof CliError) {
      throw error;
    }
    throw new CliError(errorMessage(error), {
      hint: 'Run "the_zoo start" first to create an instance',
    });
  }

  const envFile = getInstanceEnvFile(projectName);
  const composeOptions = {
    cwd: getInstanceSourcePath(projectName),
    projectName,
    envFile,
    showCommand: false,
  };
  // The dev environment (not a CLI instance) has every profile's services
  const instanceEnv = (envFile && (await readEnvFile(envFile))) || {};
  const withHeavy = !isCliProject(projectName) || withHeavyApps(instanceEnv);
  const { used, heavyLeftOut } = instanceServices(
    await getComposeServices(composeOptions),
    withHeavy,
  );

  const spinner = startSpinner("Pulling images...");

  try {
    await dockerCompose(["--profile", "*", "pull", "--quiet", ...used], composeOptions);

    spinner.success("All images pulled successfully");
    if (heavyLeftOut.length > 0) {
      console.log(
        chalk.gray(`Not pulled, as the instance doesn't use them: ${heavyLeftOut.join(", ")}`),
      );
    }
    console.log(chalk.green("✓ Zoo container images are ready"));
  } catch (error) {
    spinner.error("Failed to pull images");
    throw new CliError(errorMessage(error));
  }
}
