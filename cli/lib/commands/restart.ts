import { getRunningInstances } from "../utils/docker";
import { CliError } from "../utils/errors";
import {
  checkStart,
  getDefaultInstanceId,
  instanceExists,
  parseInstanceSettings,
  parseWaitTimeout,
} from "../utils/instance";
import { findInstanceProjects } from "../utils/project";
import { start } from "./start";
import { stop } from "./stop";

interface RestartOptions {
  port?: string;
  setEnv?: string[];
  instance?: string;
  withHeavy?: boolean;
  wait?: boolean;
  waitTimeout?: string;
}

export async function restart(options: RestartOptions): Promise<void> {
  const instanceId = options.instance ?? getDefaultInstanceId();
  if (options.instance && !(await instanceExists(instanceId))) {
    throw new CliError(`Instance "${instanceId}" does not exist.`);
  }
  // Settings start would reject must not leave the instance stopped
  const envVars = parseInstanceSettings(options);
  parseWaitTimeout(options);
  const running = findInstanceProjects(await getRunningInstances(), instanceId);
  await checkStart(instanceId, { envVars, command: "restart" });

  // Stop the instance even if another CLI version started it; it would hold the
  // proxy port and subnet the new start needs
  for (const projectName of running) {
    await stop({ instance: projectName, quiet: true });
  }
  await start({ ...options, quiet: true, otherVersionsStopped: true });
}
