import { dockerCompose, execCommand, runHelper } from "./docker";
import { CliError } from "./errors";
import { projectComposeOptions } from "./instance";
import { startSpinner } from "./output";

// Services label their state for reset and snapshots in docker-compose.yaml:
// zoo.db names the database the service keeps its state in, and zoo.snapshot the directory
// `snapshot save` archives. core/follow-restore.sh keeps a follower's files in step.
export const DATABASES = ["postgres", "mysql"];

export interface ProjectContainer {
  id: string;
  service: string;
  image: string;
  running: boolean;
  startedAt: string;
  labels: Record<string, string>;
  env: Record<string, string>;
  // Volume name by mount destination
  volumes: Record<string, string>;
}

interface InspectedContainer {
  Id: string;
  Image: string;
  State: { Running: boolean; StartedAt?: string };
  Config: { Labels: Record<string, string> | null; Env: string[] | null };
  Mounts: { Type: string; Name?: string; Destination: string }[];
}

/**
 * Every container of a compose project, stopped ones included
 */
export async function getProjectContainers(projectName: string): Promise<ProjectContainer[]> {
  const { stdout } = await execCommand("docker", [
    "ps",
    "-a",
    "-q",
    "--filter",
    `label=com.docker.compose.project=${projectName}`,
    "--filter",
    "label=com.docker.compose.oneoff=False",
  ]);
  const ids = stdout.split("\n").filter(Boolean);
  if (ids.length === 0) {
    return [];
  }
  const inspected: InspectedContainer[] = JSON.parse(
    (await execCommand("docker", ["inspect", ...ids])).stdout,
  );
  return inspected.map((container) => {
    const labels = container.Config.Labels ?? {};
    return {
      id: container.Id,
      service: labels["com.docker.compose.service"] ?? "",
      image: container.Image,
      running: container.State.Running,
      startedAt: container.State.StartedAt ?? "",
      labels,
      env: Object.fromEntries(
        (container.Config.Env ?? []).map((entry) => {
          const index = entry.indexOf("=");
          return [entry.slice(0, index), entry.slice(index + 1)];
        }),
      ),
      volumes: Object.fromEntries(
        container.Mounts.filter((mount) => mount.Type === "volume" && mount.Name).map((mount) => [
          mount.Destination,
          mount.Name as string,
        ]),
      ),
    };
  });
}

export function findService(
  containers: ProjectContainer[],
  service: string,
): ProjectContainer | undefined {
  return containers.find((container) => container.service === service);
}

/**
 * The postgres container, which lends its image and volumes to the helper containers that
 * read the restore records and snapshots
 */
export function getPostgres(containers: ProjectContainer[], projectName: string): ProjectContainer {
  const postgres = findService(containers, "postgres");
  if (!postgres?.volumes["/zoo-state"] || !postgres.volumes["/zoo-snapshots"]) {
    throw new CliError(`Project ${projectName} has no postgres container with restore records`, {
      hint: "Its images or docker-compose.yaml predate them; recreate it with this version",
    });
  }
  return postgres;
}

/**
 * Run docker compose for a running project from the directory and env files it runs from
 */
export async function composeProject(projectName: string, args: string[]): Promise<void> {
  return dockerCompose(args, {
    ...(await projectComposeOptions(projectName)),
    showCommand: false,
    progress: "quiet",
  });
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

export async function readRestoreRecords(
  postgres: ProjectContainer,
): Promise<Record<string, DatabaseState>> {
  return parseRestoreRecords(
    await runHelper(
      postgres.image,
      'cd /zoo-state && for db in "$@"; do [ ! -f "$db" ] || grep -H . "/zoo-state/$db"; done',
      DATABASES,
      { volumes: { [postgres.volumes["/zoo-state"]]: "/zoo-state:ro" } },
    ),
  );
}

export const isUncleanKeep = (state: DatabaseState) =>
  state.skippedRestore?.startsWith("unclean") ?? false;

/**
 * One line for each running database that kept its data at its start after an unclean
 * shutdown, instead of restoring its baseline. A record older than the container's start
 * belongs to an earlier start.
 */
export async function keptDataWarnings(projectName: string): Promise<string[]> {
  const containers = await getProjectContainers(projectName);
  const postgres = findService(containers, "postgres");
  if (!postgres?.volumes["/zoo-state"]) {
    return [];
  }
  const records = await readRestoreRecords(postgres);
  return DATABASES.flatMap((database) => {
    const state = records[database];
    const container = findService(containers, database);
    const seconds = (time: string) => time.slice(0, 19);
    if (
      !state ||
      !isUncleanKeep(state) ||
      !container?.running ||
      seconds(state.startedAt ?? "") < seconds(container.startedAt)
    ) {
      return [];
    }
    return [`${database} kept its data at ${state.startedAt}, after an ${state.skippedRestore}`];
  });
}

export interface ResetPlan {
  databases: string[];
  // Running services that keep state in those databases, stopped while they are restored
  stop: string[];
  // The services recreated after the databases are restored, so that none keeps what its
  // container holds: the running ones are started again, the others only created
  running: string[];
  stopped: string[];
}

/**
 * What resetting `app` (or everything) takes. Restoring a database resets all of it, so every
 * service that keeps state there is recreated with it. A full reset also recreates every app
 * and restores both databases; an app reset recreates the app and restores its database.
 */
export function planReset(containers: ProjectContainer[], app?: string): ResetPlan {
  let databases = DATABASES;
  if (app) {
    const container = findService(containers, app);
    if (!container) {
      throw new CliError(`No service "${app}" in this instance`, {
        hint: `Services: ${containers
          .map((c) => c.service)
          .sort()
          .join(", ")}`,
      });
    }
    const database = DATABASES.includes(app) ? app : container.labels["zoo.db"];
    databases = database ? [database] : [];
  }
  const usesRestored = (c: ProjectContainer) => databases.includes(c.labels["zoo.db"] ?? "");
  const recreated = containers.filter((c) => {
    if (DATABASES.includes(c.service)) {
      return false;
    }
    return usesRestored(c) || (app ? c.service === app : c.labels["zoo.core"] !== "true");
  });
  const services = (keep: (c: ProjectContainer) => boolean) =>
    recreated
      .filter(keep)
      .map((c) => c.service)
      .sort();
  return {
    databases,
    stop: services((c) => c.running && usesRestored(c)),
    running: services((c) => c.running),
    stopped: services((c) => !c.running),
  };
}

// Run with a database container's volumes while it is stopped. Without its data and a
// snapshot-save .keep file, its entrypoint restores the baseline even after an unclean stop.
const CLEAR_SCRIPT = 'rm -f "/zoo-state/$1.keep"; [ -z "$2" ] || find "$2" -mindepth 1 -delete';

/**
 * Restore the databases to the baseline (their ZOO_BASELINE snapshot, or the golden state)
 * and recreate the services in the plan
 */
export async function runReset(
  projectName: string,
  containers: ProjectContainer[],
  plan: ResetPlan,
): Promise<void> {
  const started = Date.now();
  const { databases, running, stopped } = plan;
  const spinner = startSpinner(
    databases.length > 0
      ? `Restoring ${databases.join(" and ")}...`
      : `Recreating ${[...running, ...stopped].join(", ")}...`,
  );
  try {
    if (databases.length > 0) {
      await composeProject(projectName, ["stop", ...plan.stop, ...databases]);
      for (const database of databases) {
        const container = findService(containers, database);
        if (container) {
          await runHelper(
            container.image,
            CLEAR_SCRIPT,
            [database, container.labels["zoo.snapshot"] ?? ""],
            { volumesFrom: container.id },
          );
        }
      }
      await composeProject(projectName, [
        "up",
        "-d",
        "--no-deps",
        "--force-recreate",
        "--wait",
        ...databases,
      ]);
    }
    if (running.length > 0) {
      spinner.text = `Recreating ${running.join(", ")}...`;
      await composeProject(projectName, [
        "--profile",
        "*",
        "up",
        "-d",
        "--no-deps",
        "--force-recreate",
        "--wait",
        ...running,
      ]);
    }
    if (stopped.length > 0) {
      await composeProject(projectName, [
        "--profile",
        "*",
        "up",
        "--no-start",
        "--no-deps",
        "--force-recreate",
        ...stopped,
      ]);
    }
    // The services outside the profiles, which the zoo needs running. A core service a reset
    // cut short left stopped is among the stopped ones recreated above, but not started.
    await composeProject(projectName, ["up", "-d", "--no-deps", "--no-recreate", "--wait"]);
  } catch (error) {
    spinner.error("Reset failed");
    throw error;
  }
  const seconds = ((Date.now() - started) / 1000).toFixed(1);
  const recreated = [...running, ...stopped].sort();
  spinner.success(
    databases.length > 0
      ? `Restored ${databases.join(" and ")} in ${seconds}s${recreated.length > 0 ? `; recreated ${recreated.join(", ")}` : ""}`
      : `Recreated ${recreated.join(", ")} in ${seconds}s`,
  );
}
