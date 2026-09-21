import { X509Certificate } from "node:crypto";
import { readFileSync, statfsSync } from "node:fs";
import os from "node:os";
import chalk from "chalk";
import packageJson from "../../package.json" with { type: "json" };
import { instanceProjectName } from "../utils/config";
import {
  type ComposeService,
  describeDockerError,
  dockerProbe,
  getComposeServices,
  TimeoutError,
} from "../utils/docker";
import { CliError, errorMessage } from "../utils/errors";
import {
  caCertPath,
  DEFAULT_PROXY_PORT,
  getDefaultInstanceId,
  getZooPackagePath,
  listInstanceDirs,
  parsePort,
} from "../utils/instance";
import {
  allocateNetwork,
  type DockerNetwork,
  findSubnetConflicts,
  getDockerNetworks,
  savedIpBase,
  subnetsOutsideProject,
} from "../utils/network-env";
import { checkProxyPort } from "../utils/proxy-port";
import { compareVersions, parseVersion } from "../utils/version";

// The packaged compose file's healthchecks set start_interval, which needs Compose 2.20.2
// and Docker Engine 25.0 (API 1.44): older engines make `up` fail. The CLI's compose commands
// and flags all work with Compose 2.20.2 (`start --wait`, for one, only exists in v5).
const MIN_COMPOSE_VERSION = "2.20.2";
const MIN_ENGINE_VERSION = "25.0.0";
// A cold start downloads ~15 GB of images, ~35 GB with the heavy apps
const MIN_FREE_DISK_BYTES = 20e9;

type Level = "ok" | "warn" | "fail" | "skip";

interface Check {
  level: Level;
  detail: string;
  hint?: string;
}

interface DockerInfo {
  ServerVersion?: string;
  OperatingSystem?: string;
  NCPU?: number;
  MemTotal?: number;
  ServerErrors?: string[];
}

const SYMBOLS: Record<Level, string> = {
  ok: chalk.green("✓"),
  warn: chalk.yellow("!"),
  fail: chalk.red("✗"),
  skip: chalk.gray("-"),
};

const SKIPPED: Check = { level: "skip", detail: "skipped, Docker is not running" };

function formatBytes(bytes: number): string {
  return `${(bytes / 1e9).toFixed(1)} GB`;
}

/**
 * Bytes of a compose mem_limit: `docker compose config` gives bytes, a compose file "512m"
 */
function parseMemLimit(limit: string | number): number {
  const match = String(limit)
    .trim()
    .match(/^(\d+(?:\.\d+)?)\s*([bkmg]?)b?$/i);
  if (!match) {
    return 0;
  }
  const unit = { "": 1, b: 1, k: 1024, m: 1024 ** 2, g: 1024 ** 3 }[match[2].toLowerCase()] ?? 1;
  return Number(match[1]) * unit;
}

function checkVersion(label: string, version: string, minimum: string, hint: string): Check {
  const parsed = parseVersion(version.replace(/^v/, ""));
  const required = parseVersion(minimum);
  if (!parsed || !required) {
    return { level: "warn", detail: `unrecognized version "${version}"; needs ${minimum}+` };
  }
  // Compare releases only: Docker Desktop ships builds like 2.29.2-desktop.1
  if (compareVersions({ ...parsed, prerelease: [] }, required) < 0) {
    return { level: "fail", detail: `${version}; ${label} needs ${minimum}+`, hint };
  }
  return { level: "ok", detail: version };
}

async function checkDaemon(): Promise<{ check: Check; info: DockerInfo | null }> {
  try {
    const { stdout } = await dockerProbe(["info", "--format", "{{json .}}"]);
    const info: DockerInfo = JSON.parse(stdout);
    if (info.ServerErrors?.length) {
      throw new Error(info.ServerErrors.join("; "));
    }
    return {
      check: { level: "ok", detail: `${info.OperatingSystem ?? "running"}, ${info.NCPU} CPUs` },
      info,
    };
  } catch (error) {
    if (error instanceof TimeoutError) {
      const detail = `not responding: ${error.message}`;
      return { check: { level: "fail", detail, hint: "Restart Docker" }, info: null };
    }
    const { detail, hint } = describeDockerError(error);
    return { check: { level: "fail", detail, hint }, info: null };
  }
}

async function checkCompose(): Promise<Check> {
  try {
    const { stdout } = await dockerProbe(["compose", "version", "--short"]);
    return checkVersion(
      "the Zoo",
      stdout.trim(),
      MIN_COMPOSE_VERSION,
      "Update Docker Compose (Docker Desktop includes it)",
    );
  } catch (error) {
    return {
      level: "fail",
      detail: `not available: ${errorMessage(error).trim()}`,
      hint: "Install the Docker Compose plugin",
    };
  }
}

/**
 * Free space where Docker keeps images and volumes, as a container sees it. Docker
 * Desktop's VM disk is a sparse file on the host that grows until the host disk is full,
 * so there the host's free space limits it too.
 */
async function checkDisk(image: string | undefined, dockerDesktop: boolean): Promise<Check> {
  let reclaimable = "";
  try {
    const { stdout } = await dockerProbe(["system", "df", "--format", "{{json .}}"], { scale: 4 });
    const types: Record<string, string> = {
      Images: "images",
      "Local Volumes": "volumes",
      "Build Cache": "build cache",
    };
    reclaimable = stdout
      .split("\n")
      .filter(Boolean)
      .map((line) => JSON.parse(line) as { Type: string; Reclaimable: string })
      .filter((usage) => usage.Type in types)
      .map((usage) => `${types[usage.Type]} ${usage.Reclaimable.replace(/\s*\(.*\)$/, "")}`)
      .join(", ");
  } catch (error) {
    if (error instanceof TimeoutError) {
      return { level: "warn", detail: `unknown: ${error.message}` };
    }
  }
  const reclaimableDetail = reclaimable ? `; reclaimable: ${reclaimable}` : "";

  if (!image) {
    return { level: "warn", detail: `free space unknown${reclaimableDetail}` };
  }
  let available: number;
  try {
    // The image is one the Zoo needs anyway, so pulling it costs nothing extra
    const { stdout } = await dockerProbe(
      ["run", "--rm", "--network", "none", "--entrypoint", "df", image, "-Pk", "/"],
      { scale: 8 },
    );
    available = Number(stdout.trim().split("\n").pop()?.split(/\s+/)[3]) * 1024;
    if (!Number.isFinite(available)) {
      throw new Error(`unexpected df output: ${stdout.trim()}`);
    }
  } catch (error) {
    return {
      level: "warn",
      detail: `free space unknown (${errorMessage(error).trim()})${reclaimableDetail}`,
    };
  }

  let limit = "";
  if (dockerDesktop) {
    const host = statfsSync(os.homedir());
    const hostAvailable = host.bavail * host.bsize;
    if (hostAvailable < available) {
      available = hostAvailable;
      limit = " (on the host, which holds Docker Desktop's disk image)";
    }
  }
  const detail = `${formatBytes(available)} free${limit}${reclaimableDetail}`;
  if (available < MIN_FREE_DISK_BYTES) {
    return {
      level: "warn",
      detail,
      hint:
        "A cold start downloads ~15 GB of images (~35 GB with --with-heavy). " +
        "docker image prune, docker volume prune and docker builder prune free space",
    };
  }
  return { level: "ok", detail };
}

function checkMemory(info: DockerInfo, services: Record<string, ComposeService>): Check {
  const core = Object.values(services).filter((service) => !service.profiles?.length);
  const limits = core.reduce((sum, service) => sum + parseMemLimit(service.mem_limit ?? 0), 0);
  const total = info.MemTotal ?? 0;
  const detail = `${formatBytes(total)} for Docker; the core services' mem_limits total ${formatBytes(limits)}`;
  if (total < limits) {
    return {
      level: "warn",
      detail,
      hint: "Give Docker more memory (Docker Desktop: Settings > Resources)",
    };
  }
  return { level: "ok", detail };
}

async function checkSubnets(networks: DockerNetwork[], currentVersion: string): Promise<Check> {
  const problems: Check[] = [];
  for (const instance of listInstanceDirs()) {
    if (instance.version && instance.version !== currentVersion) {
      continue;
    }
    const project = instance.env.COMPOSE_PROJECT_NAME ?? instanceProjectName(instance.instanceId);
    const conflicts = findSubnetConflicts(instance.env, subnetsOutsideProject(networks, project));
    if (conflicts.length === 0) {
      continue;
    }
    const ipBase = savedIpBase(instance.env);
    problems.push(
      ipBase && conflicts.includes(instance.env.ZOO_SUBNET)
        ? {
            level: "fail",
            detail: `${conflicts.join(", ")} of instance "${instance.instanceId}" (from --ip-base ${ipBase}) overlaps another Docker network`,
            hint: `Remove it with "the_zoo clean --instance ${instance.instanceId}" and create one with another --ip-base`,
          }
        : {
            level: "warn",
            detail: `${conflicts.join(", ")} of instance "${instance.instanceId}" overlaps another Docker network; start moves it`,
          },
    );
  }

  const allSubnets = subnetsOutsideProject(networks, "");
  try {
    // With usedSubnets given, it asks Docker nothing
    await allocateNetwork("thezoo-doctor", { usedSubnets: allSubnets });
  } catch (error) {
    problems.push({
      level: "fail",
      detail: errorMessage(error),
      hint: error instanceof CliError ? error.hint : undefined,
    });
  }

  return (
    problems.find((problem) => problem.level === "fail") ??
    problems[0] ?? { level: "ok", detail: `no conflicts with ${networks.length} Docker networks` }
  );
}

function checkCaCert(): Check {
  let certPath: string;
  try {
    certPath = caCertPath(getZooPackagePath());
    const cert = new X509Certificate(readFileSync(certPath));
    const validTo = new Date(cert.validTo);
    if (validTo.getTime() < Date.now()) {
      return { level: "fail", detail: `${certPath} expired on ${cert.validTo}` };
    }
    return {
      level: "ok",
      detail: `${certPath} (valid until ${validTo.toISOString().slice(0, 10)})`,
    };
  } catch (error) {
    return { level: "fail", detail: errorMessage(error) };
  }
}

/**
 * A check's result, or a failure with the error it threw
 */
async function attempt(check: () => Check | Promise<Check>): Promise<Check> {
  try {
    return await check();
  } catch (error) {
    return {
      level: "fail",
      detail: errorMessage(error),
      hint: error instanceof CliError ? error.hint : undefined,
    };
  }
}

/**
 * Check what the Zoo needs from Docker and the host, and exit non-zero on any failure
 */
export async function doctor(options: { port?: string }): Promise<void> {
  if (options.port !== undefined) {
    parsePort(options.port, "--port");
  }
  let failures = 0;
  const report = (name: string, check: Check) => {
    if (check.level === "fail") {
      failures++;
    }
    console.log(`${SYMBOLS[check.level]} ${name.padEnd(16)} ${check.detail}`);
    if (check.hint) {
      console.log(chalk.gray(`  ${"".padEnd(16)} ${check.hint}`));
    }
  };

  const { check: daemon, info } = await checkDaemon();
  report("Docker daemon", daemon);
  report("Docker Compose", await checkCompose());
  report(
    "Docker Engine",
    info
      ? checkVersion(
          "the Zoo",
          info.ServerVersion ?? "",
          MIN_ENGINE_VERSION,
          "Update Docker (Docker Desktop, or Docker Engine from Docker's own packages)",
        )
      : SKIPPED,
  );

  // Client-side, so it works without the daemon
  let services: Record<string, ComposeService> | null = null;
  let servicesError = "";
  try {
    services = await getComposeServices({
      cwd: getZooPackagePath(),
      projectName: instanceProjectName(getDefaultInstanceId()),
    });
  } catch (error) {
    servicesError = errorMessage(error);
  }
  const noServices: Check = {
    level: "warn",
    detail: `unknown, could not read the compose file: ${servicesError}`,
  };

  report(
    "Disk",
    info
      ? await attempt(() =>
          checkDisk(
            services?.redis?.image,
            info.OperatingSystem?.includes("Docker Desktop") ?? false,
          ),
        )
      : SKIPPED,
  );
  report("Memory", info ? (services ? checkMemory(info, services) : noServices) : SKIPPED);

  const saved = listInstanceDirs().find(
    (instance) =>
      instance.instanceId === getDefaultInstanceId() &&
      (!instance.version || instance.version === `v${packageJson.version}`),
  )?.env;
  const port = options.port ?? saved?.ZOO_PROXY_PORT ?? DEFAULT_PROXY_PORT;
  const bind = saved?.ZOO_PROXY_BIND || "127.0.0.1";
  const ownProject = instanceProjectName(getDefaultInstanceId());
  report(
    `Proxy port ${port}`,
    await attempt(() => checkProxyPort(port, bind, info !== null, [ownProject])),
  );

  report(
    "Subnets",
    info
      ? await attempt(async () =>
          checkSubnets(await getDockerNetworks(), `v${packageJson.version}`),
        )
      : SKIPPED,
  );
  report("CA certificate", checkCaCert());

  if (failures > 0) {
    throw new CliError(`${failures} ${failures === 1 ? "check" : "checks"} failed`);
  }
}
