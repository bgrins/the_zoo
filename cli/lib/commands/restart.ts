import { getProjectName } from "../utils/config";
import { getRunningInstances } from "../utils/docker";
import { CliError } from "../utils/errors";
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
    throw new CliError(`Instance "${instanceId}" does not exist.`);
  }

  const runningProjects = await getRunningInstances();
  if (runningProjects.includes(getProjectName(instanceId))) {
    await stop({ instance: instanceId, quiet: true });
  }
  await start({ ...options, quiet: true });
}
