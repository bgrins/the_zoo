import chalk from "chalk";
import { requireDocker } from "../utils/docker";
import { findRunningProject } from "../utils/project";
import {
  DATABASES,
  type DatabaseState,
  getPostgres,
  getProjectContainers,
  isUncleanKeep,
  planReset,
  readRestoreRecords,
  runReset,
} from "../utils/stateful";

interface InstanceOptions {
  instance?: string;
}

/**
 * The running project an --instance value names, else this checkout's own (in development)
 * or the only running one
 */
export async function resolveProject(instance?: string): Promise<string> {
  await requireDocker();
  return findRunningProject(instance, { preferCheckout: true });
}

export async function reset(app: string | undefined, options: InstanceOptions): Promise<void> {
  const projectName = await resolveProject(options.instance);
  const containers = await getProjectContainers(projectName);
  await runReset(projectName, containers, planReset(containers, app));
}

function describe(state: DatabaseState): string[] {
  const source = state.source?.replace(/^snapshot:/, "snapshot ") ?? "unknown";
  const lines = [
    state.restoredAt
      ? `${source}, restored ${state.restoredAt} in ${state.restoreSeconds?.toFixed(2)}s`
      : "never restored",
  ];
  if (state.baseline && !state.skippedRestore && state.source !== `snapshot:${state.baseline}`) {
    lines.push(chalk.yellow(`baseline ${state.baseline} has no snapshot for it`));
  }
  if (state.skippedRestore) {
    const line = `start at ${state.startedAt} kept the data: ${state.skippedRestore}`;
    lines.push(
      isUncleanKeep(state) ? chalk.yellow(`⚠ ${line}; "the_zoo reset" restores it`) : line,
    );
  }
  return lines;
}

export async function state(options: InstanceOptions & { json?: boolean }): Promise<void> {
  const projectName = await resolveProject(options.instance);
  const records = await readRestoreRecords(
    getPostgres(await getProjectContainers(projectName), projectName),
  );

  if (options.json) {
    console.log(JSON.stringify({ project: projectName, databases: records }, null, 2));
    return;
  }
  for (const database of DATABASES) {
    const record = records[database];
    const [first, ...rest] = record ? describe(record) : ["no restore recorded"];
    console.log(`${database.padEnd(9)}${first}`);
    for (const line of rest) {
      console.log(`${"".padEnd(9)}${line}`);
    }
  }
}
