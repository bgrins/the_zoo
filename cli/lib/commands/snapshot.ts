import fs from "node:fs/promises";
import chalk from "chalk";
import packageJson from "../../package.json" with { type: "json" };
import { execCommand, runHelper } from "../utils/docker";
import { CliError } from "../utils/errors";
import { getInstanceEnvFile } from "../utils/instance";
import { applyEnvUpdates, parseEnvContent, readEnvContent } from "../utils/network-env";
import { startSpinnerHoldingSignals } from "../utils/output";
import {
  composeProject,
  DATABASES,
  findService,
  getPostgres,
  getProjectContainers,
  planReset,
  type ProjectContainer,
  runReset,
} from "../utils/stateful";
import { resolveProject } from "./reset";

interface InstanceOptions {
  instance?: string;
}

// `snapshot restore golden` goes back to the state built into the images
const GOLDEN = "golden";

interface Manifest {
  name: string;
  createdAt: string;
  cliVersion: string;
  // How each stateful service's archive was made: "saved" from its files, "copied" from the
  // snapshot its files still match, or "golden" (none: it restores the golden state)
  services: Record<string, { image: string; digests: string[]; archive: string }>;
}

function validateName(name: string, { allowGolden = false } = {}): void {
  if (!/^[A-Za-z0-9][A-Za-z0-9_.-]*$/.test(name)) {
    throw new CliError(`Invalid snapshot name: "${name}"`, {
      hint: "Use letters, digits, '.', '_' and '-'",
    });
  }
  if (name === GOLDEN && !allowGolden) {
    throw new CliError(`"${GOLDEN}" names the state built into the images`);
  }
}

// Archives a service's zoo.snapshot directory, as a path from /, into /zoo-out/NAME. A service
// that follows a database (core/follow-restore.sh) is archived only when its files match that
// database's current restore. Otherwise it would refill them on its next start, so the snapshot
// gets what it would refill them with: the restored snapshot's archive, or none for golden.
const SAVE_SCRIPT = `set -e
name=$1 service=$2 dir=$3 database=$4
out=/zoo-out/$name
mkdir -p "$out"
if [ -n "$database" ]; then
  record=/zoo-state/$database
  generation=$(sed -n 's/^generation=//p' "$record" 2>/dev/null || true)
  if [ -z "$generation" ] || [ "$(cat "$dir/.zoo-restore" 2>/dev/null || true)" != "$generation" ]; then
    source=$(sed -n 's/^source=//p' "$record" 2>/dev/null || true)
    previous=/zoo-snapshots/\${source#snapshot:}/$service.tar
    if [ "\${source#snapshot:}" != "$source" ] && [ -f "$previous" ]; then
      cp "$previous" "$out/"
      echo copied
    else
      echo golden
    fi
    exit 0
  fi
  # Left by an earlier save (restartWriters); a restore must not carry it
  rm -f "$dir/.zoo-keep"
fi
tar -C / -cf "$out/$service.tar" "\${dir#/}"
echo saved`;

async function getContext(options: InstanceOptions) {
  const projectName = await resolveProject(options.instance);
  const containers = await getProjectContainers(projectName);
  const postgres = getPostgres(containers, projectName);
  return { projectName, containers, postgres, volume: postgres.volumes["/zoo-snapshots"] };
}

async function readManifest(postgres: ProjectContainer, name: string): Promise<Manifest> {
  try {
    return JSON.parse(
      await runHelper(postgres.image, 'cat "/zoo-snapshots/$1/manifest.json"', [name], {
        volumes: { [postgres.volumes["/zoo-snapshots"]]: "/zoo-snapshots:ro" },
      }),
    );
  } catch {
    throw new CliError(`No snapshot named "${name}"`, { hint: 'Run "the_zoo snapshot list"' });
  }
}

async function imageDigests(images: string[]): Promise<Record<string, string[]>> {
  const { stdout } = await execCommand("docker", ["image", "inspect", ...new Set(images)]);
  const inspected: { Id: string; RepoDigests: string[] | null }[] = JSON.parse(stdout);
  return Object.fromEntries(inspected.map((image) => [image.Id, image.RepoDigests ?? []]));
}

// The running services that write to the databases or their files, stopped while they are
// archived
function writers(containers: ProjectContainer[]): string[] {
  return containers
    .filter((c) => c.running && (c.labels["zoo.db"] || c.labels["zoo.snapshot"]))
    .map((c) => c.service)
    .sort();
}

// Leaves a one-shot marker core/follow-restore.sh consumes: at the follower's next start its
// files stay as saved, as its database's data does, instead of being refilled
const KEEP_FILES_SCRIPT = ': > "$1/.zoo-keep"';

/**
 * Start the services a save stopped. The databases it stopped keep the data they had instead
 * of restoring their baseline, and so do the files of the services that follow them.
 */
async function restartWriters(projectName: string, stopped: string[]): Promise<void> {
  if (stopped.length === 0) {
    return;
  }
  const containers = await getProjectContainers(projectName);
  const kept = DATABASES.filter(
    (database) =>
      stopped.includes(database) && findService(containers, database)?.running === false,
  );
  const postgres = findService(containers, "postgres");
  if (kept.length > 0 && postgres) {
    await runHelper(postgres.image, 'for db in "$@"; do : > "/zoo-state/$db.keep"; done', kept, {
      volumes: { [postgres.volumes["/zoo-state"]]: "/zoo-state" },
    });
  }
  for (const follower of containers) {
    const dir = follower.labels["zoo.snapshot"];
    if (dir && kept.includes(follower.labels["zoo.db"] ?? "")) {
      await runHelper(follower.image, KEEP_FILES_SCRIPT, [dir], { volumesFrom: follower.id });
    }
  }
  await composeProject(projectName, [
    "--profile",
    "*",
    "up",
    "-d",
    "--no-deps",
    "--no-recreate",
    "--wait",
    ...stopped,
  ]);
}

export async function snapshotSave(name: string, options: InstanceOptions): Promise<void> {
  validateName(name);
  const { projectName, containers, postgres, volume } = await getContext(options);
  const existing = await listSnapshots(postgres);
  if (existing.some((snapshot) => snapshot.name === name)) {
    throw new CliError(`Snapshot "${name}" already exists`, {
      hint: `Remove it first with "the_zoo snapshot rm ${name}"`,
    });
  }

  const stateful = containers.filter((c) => c.labels["zoo.snapshot"]);
  const stopped = writers(containers);
  const removePartial = () =>
    runHelper(postgres.image, 'rm -rf "/zoo-out/$1"', [name], {
      volumes: { [volume]: "/zoo-out" },
    });
  const { spinner, ...signals } = startSpinnerHoldingSignals(
    `Saving snapshot ${name}...`,
    "snapshot save",
  );
  try {
    // What an earlier save cut short left
    await removePartial();
    if (stopped.length > 0) {
      await composeProject(projectName, ["stop", ...stopped]);
    }
    signals.check();
    const digests = await imageDigests(stateful.map((c) => c.image));
    const manifest: Manifest = {
      name,
      createdAt: new Date().toISOString(),
      cliVersion: packageJson.version,
      services: {},
    };
    for (const container of stateful) {
      signals.check();
      spinner.text = `Saving snapshot ${name}: ${container.service}...`;
      const archive = await runHelper(
        container.image,
        SAVE_SCRIPT,
        [
          name,
          container.service,
          container.labels["zoo.snapshot"],
          container.labels["zoo.db"] ?? "",
        ],
        { volumesFrom: container.id, volumes: { [volume]: "/zoo-out" } },
      );
      manifest.services[container.service] = {
        image: container.image,
        digests: digests[container.image] ?? [],
        archive: archive.trim(),
      };
    }
    signals.check();
    await runHelper(
      postgres.image,
      'printf "%s\\n" "$2" > "/zoo-out/$1/manifest.json"',
      [name, JSON.stringify(manifest, null, 2)],
      { volumes: { [volume]: "/zoo-out" } },
    );
  } catch (error) {
    spinner.error(`Failed to save snapshot ${name}`);
    await removePartial().catch(() => {});
    // A child process the signal ended fails too
    throw signals.interruption() ?? error;
  } finally {
    try {
      await restartWriters(projectName, stopped);
    } finally {
      signals.release();
    }
  }
  spinner.success(`Saved snapshot ${name}`);
}

export async function snapshotRestore(name: string, options: InstanceOptions): Promise<void> {
  validateName(name, { allowGolden: true });
  const { projectName, containers, postgres } = await getContext(options);
  const envFile = getInstanceEnvFile(projectName);
  if (!envFile) {
    throw new CliError(
      `${projectName} is not a CLI instance, so it has no .env to set its baseline in`,
      {
        hint: `Set ZOO_BASELINE=${name === GOLDEN ? "" : name} in the env file it runs with, then recreate postgres and mysql`,
      },
    );
  }

  if (name !== GOLDEN) {
    const manifest = await readManifest(postgres, name);
    const changed = Object.entries(manifest.services)
      .filter(([service, { image }]) => findService(containers, service)?.image !== image)
      .map(([service]) => service);
    if (changed.length > 0) {
      throw new CliError(
        `Snapshot "${name}" was saved with other images of ${changed.join(", ")}`,
        {
          hint: "Restore it with the images it was saved with, or save a new snapshot",
        },
      );
    }
  }

  const content = (await readEnvContent(envFile)) ?? "";
  await fs.writeFile(
    envFile,
    applyEnvUpdates(
      content,
      { ZOO_BASELINE: name === GOLDEN ? "" : name },
      "# Set by the_zoo snapshot restore",
    ),
  );
  // Only postgres and mysql read ZOO_BASELINE; the services that follow them restore from
  // whatever they restored
  await runReset(projectName, containers, planReset(containers));
  console.log(chalk.green(`✓ Baseline: ${name}`));
}

interface SnapshotListing {
  name: string;
  sizeKb: number;
  manifest: Manifest;
}

// One line per snapshot: name, size in KB and manifest, tab-separated
const LIST_SCRIPT = `cd /zoo-snapshots
for dir in */; do
  [ -f "$dir/manifest.json" ] || continue
  printf '%s\\t%s\\t' "\${dir%/}" "$(du -sk "$dir" | cut -f1)"
  tr -d '\\n' < "$dir/manifest.json"
  echo
done`;

async function listSnapshots(postgres: ProjectContainer): Promise<SnapshotListing[]> {
  const output = await runHelper(postgres.image, LIST_SCRIPT, [], {
    volumes: { [postgres.volumes["/zoo-snapshots"]]: "/zoo-snapshots:ro" },
  });
  return output
    .split("\n")
    .filter(Boolean)
    .map((line) => {
      const [name, size, manifest] = line.split("\t");
      return { name, sizeKb: Number(size), manifest: JSON.parse(manifest) };
    });
}

async function activeBaseline(projectName: string, postgres: ProjectContainer): Promise<string> {
  const envFile = getInstanceEnvFile(projectName);
  const content = envFile ? await readEnvContent(envFile) : null;
  return (content && parseEnvContent(content).ZOO_BASELINE) || postgres.env.ZOO_BASELINE || "";
}

// du's KiB, in MB below a GB
function formatSize(kb: number): string {
  const mb = kb / 1024;
  return mb < 1024 ? `${Math.round(mb)} MB` : `${(mb / 1024).toFixed(1)} GB`;
}

export async function snapshotList(options: InstanceOptions): Promise<void> {
  const { projectName, postgres } = await getContext(options);
  const snapshots = await listSnapshots(postgres);
  const active = await activeBaseline(projectName, postgres);
  if (snapshots.length === 0) {
    console.log("No snapshots");
    return;
  }
  const width = Math.max(...snapshots.map((s) => s.name.length));
  for (const snapshot of snapshots) {
    const size = formatSize(snapshot.sizeKb);
    const marker = snapshot.name === active ? chalk.green("  (baseline)") : "";
    console.log(`${snapshot.name.padEnd(width)}  ${snapshot.manifest.createdAt}  ${size}${marker}`);
  }
}

export async function snapshotRemove(name: string, options: InstanceOptions): Promise<void> {
  validateName(name);
  const { projectName, postgres, volume } = await getContext(options);
  if ((await activeBaseline(projectName, postgres)) === name) {
    throw new CliError(`Snapshot "${name}" is the baseline`, {
      hint: `Run "the_zoo snapshot restore ${GOLDEN}" (or another snapshot) first`,
    });
  }
  if (!(await listSnapshots(postgres)).some((snapshot) => snapshot.name === name)) {
    throw new CliError(`No snapshot named "${name}"`, { hint: 'Run "the_zoo snapshot list"' });
  }
  await runHelper(postgres.image, 'rm -rf "/zoo-out/$1"', [name], {
    volumes: { [volume]: "/zoo-out" },
  });
  console.log(chalk.green(`✓ Removed snapshot ${name}`));
}
