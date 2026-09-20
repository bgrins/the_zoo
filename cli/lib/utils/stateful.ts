import { dockerCompose, execCommand } from "./docker";
import { CliError } from "./errors";
import { getInstanceEnvFile, getInstanceSourcePath } from "./instance";
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
  labels: Record<string, string>;
  env: Record<string, string>;
  // Volume name by mount destination
  volumes: Record<string, string>;
}

interface InspectedContainer {
  Id: string;
  Image: string;
  State: { Running: boolean };
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
 * Run a shell script in a throwaway container of `image` with `volumes` (name to path)
 * mounted, as root and without a network. Returns its stdout.
 */
export async function runHelper(
  image: string,
  script: string,
  args: string[] = [],
  options: { volumes?: Record<string, string>; volumesFrom?: string } = {},
): Promise<string> {
  const mounts = Object.entries(options.volumes ?? {}).flatMap(([name, target]) => [
    "-v",
    `${name}:${target}`,
  ]);
  const volumesFrom = options.volumesFrom ? ["--volumes-from", options.volumesFrom] : [];
  const { stdout } = await execCommand("docker", [
    "run",
    "--rm",
    "--network",
    "none",
    "--user",
    "0",
    ...volumesFrom,
    ...mounts,
    "--entrypoint",
    "sh",
    image,
    "-c",
    script,
    "sh",
    ...args,
  ]);
  return stdout;
}

/**
 * Run docker compose for a running project from the directory and env file it runs from
 */
export function composeProject(projectName: string, args: string[]): Promise<void> {
  return dockerCompose(args, {
    cwd: getInstanceSourcePath(projectName),
    envFile: getInstanceEnvFile(projectName),
    projectName,
    showCommand: false,
    progress: "quiet",
  });
}

export interface ResetPlan {
  databases: string[];
  // Running services that keep state in those databases, stopped while they are restored
  services: string[];
}

/**
 * What resetting `app` (or everything) takes. Restoring a database resets all of it, so every
 * running service that keeps state there restarts with it; a stopped one catches up when it
 * next starts. Null for an app with no database, which a restart alone resets.
 */
export function planReset(containers: ProjectContainer[], app?: string): ResetPlan | null {
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
    if (!database) {
      return null;
    }
    databases = [database];
  }
  const services = containers
    .filter((c) => c.running && databases.includes(c.labels["zoo.db"]))
    .map((c) => c.service)
    .sort();
  return { databases, services };
}

/**
 * Stop the services, restore the databases (recreating them, so they pick up a changed
 * ZOO_BASELINE, when `recreate` is set) and start the services again
 */
export async function runReset(
  projectName: string,
  plan: ResetPlan,
  options: { recreate?: boolean } = {},
): Promise<void> {
  const started = Date.now();
  const spinner = startSpinner(`Restoring ${plan.databases.join(" and ")}...`);
  try {
    await composeProject(projectName, ["stop", ...plan.services, ...plan.databases]);
    if (options.recreate) {
      await composeProject(projectName, [
        "up",
        "-d",
        "--no-deps",
        "--force-recreate",
        "--wait",
        ...plan.databases,
      ]);
    }
    await composeProject(projectName, ["start", "--wait", ...plan.databases, ...plan.services]);
  } catch (error) {
    spinner.error("Reset failed");
    throw error;
  }
  const restarted = plan.services.length > 0 ? `; restarted ${plan.services.join(", ")}` : "";
  spinner.success(
    `Restored ${plan.databases.join(" and ")} in ${((Date.now() - started) / 1000).toFixed(1)}s${restarted}`,
  );
}
