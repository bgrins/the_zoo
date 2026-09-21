import { existsSync } from "node:fs";
import path from "node:path";
import chalk from "chalk";
import { instanceProjectName } from "../utils/config";
import {
  type DockerComposeOptions,
  dockerCompose,
  getComposeServices,
  getRunningInstances,
  requireDocker,
} from "../utils/docker";
import { CliError, errorMessage } from "../utils/errors";
import {
  getDefaultInstanceId,
  getZooPackagePath,
  instanceExists,
  instanceServices,
  isCliProject,
  parseProjectName,
  prepareInstance,
  projectComposeOptions,
  withHeavyApps,
} from "../utils/instance";
import { readEnvFile } from "../utils/network-env";
import { startSpinner } from "../utils/output";
import { findInstanceProjects, findRunningProject } from "../utils/project";

interface PullOptions {
  instance?: string;
}

/**
 * How to run compose for the images to pull: the running project --instance names (or the
 * only one), unless another CLI version started it with that version's images, else the
 * instance as its next start under this version would run it
 */
async function pullTarget(
  instance: string | undefined,
): Promise<{ composeOptions: DockerComposeOptions; withHeavy: boolean }> {
  const running = await getRunningInstances();
  const runningMatch = instance
    ? findInstanceProjects(running, instance).length > 0
    : running.length > 0;
  let instanceId = instance ?? getDefaultInstanceId();
  if (runningMatch) {
    const projectName = await findRunningProject(instance);
    const parsed = parseProjectName(projectName);
    if (!parsed || projectName === instanceProjectName(parsed.instanceId)) {
      const composeOptions = await projectComposeOptions(projectName);
      const envFile = [composeOptions.envFile ?? []].flat()[0];
      const env = (envFile && (await readEnvFile(envFile))) || {};
      // The dev environment (not a CLI instance) has every profile's services
      return { composeOptions, withHeavy: !isCliProject(projectName) || withHeavyApps(env) };
    }
    instanceId = parsed.instanceId;
  }

  if (!(await instanceExists(instanceId))) {
    throw new CliError(
      instance
        ? `Instance "${instanceId}" does not exist`
        : "No Zoo instance is running or created",
      { hint: 'Run "the_zoo start" first to create an instance' },
    );
  }
  const info = await prepareInstance({ instanceId, dryRun: true });
  const composeFile = path.join(info.packagePath, "docker-compose.yaml");
  return {
    composeOptions: {
      // A production instance gets its copy of the sources at its next start
      cwd: existsSync(composeFile) ? info.packagePath : getZooPackagePath(),
      projectName: info.projectName,
      env: info.env,
    },
    withHeavy: withHeavyApps(info.env),
  };
}

/**
 * Pull Zoo container images
 */
export async function pull(options: PullOptions): Promise<void> {
  console.log(chalk.blue("📦 Pulling Zoo container images..."));

  await requireDocker();

  let target: Awaited<ReturnType<typeof pullTarget>>;
  try {
    target = await pullTarget(options.instance);
  } catch (error) {
    if (error instanceof CliError) {
      throw error;
    }
    throw new CliError(errorMessage(error));
  }
  const composeOptions = { ...target.composeOptions, showCommand: false };
  const { used, heavyLeftOut } = instanceServices(
    await getComposeServices(composeOptions),
    target.withHeavy,
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
