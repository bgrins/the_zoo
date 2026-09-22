import chalk from "chalk";
import { requireDocker } from "../utils/docker";
import { baselineError, getInstanceEnvFile, locateInstance } from "../utils/instance";
import { readEnvFile } from "../utils/network-env";
import { findRunningProject } from "../utils/project";
import { baselineProblem } from "../utils/snapshot-manifest";
import {
  DATABASES,
  type DatabaseState,
  getPostgres,
  getProjectConfig,
  getProjectContainers,
  isUncleanKeep,
  planReset,
  type ProjectContainer,
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

/**
 * Refuse, as its start would, the ZOO_BASELINE of a CLI instance the databases would restore
 * wrongly: one it has no snapshot for, or one saved with other images than compose recreates
 * them from
 */
async function checkBaseline(projectName: string, containers: ProjectContainer[]): Promise<void> {
  const location = locateInstance(projectName);
  const envFile = getInstanceEnvFile(projectName);
  const baseline = envFile && (await readEnvFile(envFile))?.ZOO_BASELINE;
  if (!location || !baseline) {
    return;
  }
  const postgres = getPostgres(containers, projectName);
  const volume = postgres.volumes["/zoo-snapshots"];
  const config = await getProjectConfig(projectName);
  const problem = await baselineProblem(config, postgres.image, volume, baseline);
  if (problem) {
    const { instanceId } = location;
    throw baselineError(problem, { instanceId, baseline, volume, command: "restart" });
  }
}

export async function reset(app: string | undefined, options: InstanceOptions): Promise<void> {
  const projectName = await resolveProject(options.instance);
  const containers = await getProjectContainers(projectName);
  const plan = planReset(containers, app);
  if (plan.databases.length > 0) {
    await checkBaseline(projectName, containers);
  }
  await runReset(projectName, containers, plan);
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
