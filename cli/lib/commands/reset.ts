import chalk from "chalk";
import { checkDocker } from "../utils/docker";
import { CliError } from "../utils/errors";
import { getProjectName } from "../utils/project";
import {
  composeProject,
  DATABASES,
  findService,
  getPostgres,
  getProjectContainers,
  planReset,
  runHelper,
  runReset,
} from "../utils/stateful";

interface InstanceOptions {
  instance?: string;
}

/**
 * The running project an --instance value names, or the only running one
 */
export async function resolveProject(instance?: string): Promise<string> {
  if (!(await checkDocker())) {
    throw new CliError("Docker is not running. Please start Docker first.");
  }
  return getProjectName(instance);
}

export async function reset(app: string | undefined, options: InstanceOptions): Promise<void> {
  const projectName = await resolveProject(options.instance);
  const containers = await getProjectContainers(projectName);
  const plan = planReset(containers, app);
  if (plan) {
    await runReset(projectName, plan);
    return;
  }
  // An app without a database resets by starting again
  const service = app as string;
  if (!findService(containers, service)?.running) {
    console.log(`${service} is not running; it starts from its baseline`);
    return;
  }
  await composeProject(projectName, ["restart", service]);
  console.log(chalk.green(`✓ Restarted ${service}`));
}

export interface DatabaseState {
  source: string | null;
  baseline: string | null;
  restoredAt: string | null;
  restoreSeconds: number | null;
  startedAt: string | null;
  // Why the last start kept the data instead of restoring it: an unclean shutdown, or the
  // restart after `snapshot save`
  skippedRestore: string | null;
  generation: string | null;
}

/**
 * Parse the restore records the database entrypoints write to /zoo-state, as printed by
 * `grep -H . /zoo-state/<database>...`
 */
export function parseRestoreRecords(output: string): Record<string, DatabaseState> {
  const fields: Record<string, Record<string, string>> = {};
  for (const line of output.split("\n")) {
    const match = line.match(/^\/zoo-state\/([\w-]+):([a-z_]+)=(.*)$/);
    if (match) {
      fields[match[1]] ??= {};
      fields[match[1]][match[2]] = match[3];
    }
  }
  return Object.fromEntries(
    Object.entries(fields).map(([database, record]) => {
      const value = (key: string) => record[key] || null;
      const seconds = value("restore_seconds");
      return [
        database,
        {
          source: value("source"),
          baseline: value("baseline"),
          restoredAt: value("restored_at"),
          restoreSeconds: seconds === null ? null : Number(seconds),
          startedAt: value("started_at"),
          skippedRestore: value("kept"),
          generation: value("generation"),
        },
      ];
    }),
  );
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
    lines.push(state.skippedRestore.startsWith("unclean") ? chalk.yellow(line) : line);
  }
  return lines;
}

export async function state(options: InstanceOptions & { json?: boolean }): Promise<void> {
  const projectName = await resolveProject(options.instance);
  const postgres = getPostgres(await getProjectContainers(projectName), projectName);
  const records = parseRestoreRecords(
    await runHelper(
      postgres.image,
      'cd /zoo-state && for db in "$@"; do [ ! -f "$db" ] || grep -H . "/zoo-state/$db"; done',
      DATABASES,
      { volumes: { [postgres.volumes["/zoo-state"]]: "/zoo-state:ro" } },
    ),
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
