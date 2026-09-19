import chalk from "chalk";
import { getProjectName } from "../utils/config";
import { getRunningInstances } from "../utils/docker";
import { getDefaultInstanceId, instanceExists } from "../utils/instance";
import { start } from "./start";
import { stop } from "./stop";

interface RestartOptions {
  port?: string;
  setEnv?: string[];
  instance?: string;
}

export async function restart(options: RestartOptions): Promise<void> {
  const instanceId = options.instance ?? getDefaultInstanceId();
  if (options.instance && !(await instanceExists(instanceId))) {
    console.error(chalk.red(`Instance "${instanceId}" does not exist.`));
    process.exit(1);
  }

  const runningProjects = await getRunningInstances();
  if (runningProjects.includes(getProjectName(instanceId))) {
    await stop({ instance: instanceId, quiet: true });
  }
  await start({ ...options, quiet: true });
}
