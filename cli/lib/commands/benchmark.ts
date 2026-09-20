import { mkdir, writeFile } from "node:fs/promises";
import { platform, cpus, totalmem } from "node:os";
import { join } from "node:path";
import confirm from "@inquirer/confirm";
import chalk from "chalk";
import { loadSites, onDemandServiceSites, type Site } from "../../../scripts/lib/sites";
import {
  type DockerComposeOptions,
  dockerCompose,
  execCommand,
  execShellCommand,
  externalVolumeName,
  getComposeConfig,
  getRunningInstances,
} from "../utils/docker";
import { instanceProjectName } from "../utils/config";
import { CliError } from "../utils/errors";
import {
  getDefaultInstanceId,
  getProxyPort,
  getZooPackagePath,
  instanceExists,
  isCliProject,
  isDevMode,
  parsePort,
  parseProjectName,
  prepareInstance,
  projectComposeOptions,
  startServices,
} from "../utils/instance";
import { checkoutProject, findInstanceProjects, listProjects } from "../utils/project";

interface BenchmarkOptions {
  sitesOnly?: boolean;
  sites?: string;
  output?: string;
  port?: string;
  instance?: string;
  force?: boolean;
}

interface SiteResult {
  cold_start_ms: number | null;
  warm_response_ms: number | null;
  memory_mib: number | null;
}

interface BenchmarkResults {
  timestamp: string;
  version: string;
  proxy_port: number;
  system: {
    os: string;
    cpu: string;
    memory_gb: number;
    docker_version: string;
  };
  cold_start_seconds?: number;
  restart_seconds?: number;
  sites: Record<string, SiteResult>;
  core_services: Record<string, { memory_mib: number | null }>;
}

async function getDockerVersion(): Promise<string> {
  try {
    const { stdout } = await execCommand("docker", ["--version"]);
    return stdout.trim();
  } catch {
    return "unknown";
  }
}

async function getCpuInfo(): Promise<string> {
  if (platform() === "darwin") {
    try {
      const { stdout } = await execCommand("sysctl", ["-n", "machdep.cpu.brand_string"]);
      return stdout.trim();
    } catch {
      // Apple Silicon doesn't have this
      return "Apple Silicon";
    }
  } else {
    try {
      // Use shell for pipe command
      const { stdout } = await execShellCommand(
        "grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2",
      );
      return stdout.trim();
    } catch {
      return cpus()[0]?.model || "unknown";
    }
  }
}

async function collectSystemInfo(): Promise<BenchmarkResults["system"]> {
  let osInfo: string;
  if (platform() === "darwin") {
    try {
      const { stdout } = await execCommand("sw_vers", ["-productVersion"]);
      osInfo = `macOS ${stdout.trim()}`;
    } catch {
      osInfo = "macOS";
    }
  } else {
    try {
      // Use shell for pipe command
      const { stdout } = await execShellCommand(
        "cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2",
      );
      osInfo = stdout.trim().replace(/"/g, "");
    } catch {
      osInfo = "Linux";
    }
  }

  return {
    os: osInfo,
    cpu: await getCpuInfo(),
    memory_gb: Math.round(totalmem() / 1024 / 1024 / 1024),
    docker_version: await getDockerVersion(),
  };
}

async function measureRequest(
  site: string,
  proxyPort: number,
): Promise<{ statusCode: number; timeMs: number }> {
  const url = `https://${site}/`;

  try {
    const { stdout } = await execCommand("curl", [
      "-s",
      "-o",
      "/dev/null",
      "-w",
      "%{http_code} %{time_total}",
      "--proxy",
      `http://localhost:${proxyPort}`,
      "-k",
      "--connect-timeout",
      "120",
      "--max-time",
      "120",
      url,
    ]);

    const [statusCode, timeTotal] = stdout.trim().split(" ");
    return {
      statusCode: parseInt(statusCode, 10),
      timeMs: Math.round(parseFloat(timeTotal) * 1000),
    };
  } catch {
    return { statusCode: 0, timeMs: 0 };
  }
}

async function findServiceContainer(projectName: string, service: string): Promise<string | null> {
  try {
    const { stdout } = await execCommand("docker", [
      "ps",
      "--filter",
      `label=com.docker.compose.project=${projectName}`,
      "--filter",
      `label=com.docker.compose.service=${service}`,
      "--format",
      "{{.Names}}",
    ]);
    return stdout.trim().split("\n")[0] || null;
  } catch {
    return null;
  }
}

async function getContainerMemoryMib(container: string): Promise<number | null> {
  try {
    const { stdout } = await execCommand("docker", [
      "stats",
      "--no-stream",
      "--format",
      "{{.MemUsage}}",
      container,
    ]);

    const memStr = stdout.trim().split(" ")[0]; // e.g., "156.4MiB"
    if (!memStr) return null;

    const value = parseFloat(memStr.replace(/[^0-9.]/g, ""));
    const unit = memStr.replace(/[0-9.]/g, "");

    switch (unit) {
      case "GiB":
        return Math.round(value * 1024);
      case "MiB":
        return Math.round(value);
      case "KiB":
        return Math.round(value / 1024);
      default:
        return Math.round(value);
    }
  } catch {
    return null;
  }
}

async function getCoreContainers(projectName: string): Promise<string[]> {
  try {
    const { stdout } = await execCommand("docker", [
      "ps",
      "--filter",
      "label=zoo.core=true",
      "--filter",
      `label=com.docker.compose.project=${projectName}`,
      "--format",
      "{{.Names}}",
    ]);
    return stdout.trim().split("\n").filter(Boolean).sort();
  } catch {
    return [];
  }
}

async function waitForProxy(proxyPort: number, timeoutSeconds: number = 120): Promise<boolean> {
  const startTime = Date.now();
  const timeoutMs = timeoutSeconds * 1000;

  while (Date.now() - startTime < timeoutMs) {
    try {
      const { statusCode } = await measureRequest("home.zoo", proxyPort);
      if (statusCode >= 200 && statusCode < 400) {
        return true;
      }
    } catch {
      // Keep trying
    }
    await new Promise((resolve) => setTimeout(resolve, 500));
  }

  return false;
}

/**
 * Stop a project, as `the_zoo stop` does a CLI instance. Another project (the dev environment,
 * a worktree) keeps its volumes, which it may not be able to recreate.
 */
async function stopZoo(projectName: string): Promise<void> {
  console.log(chalk.gray(`  Stopping project: ${projectName}`));

  const volumes = isCliProject(projectName) ? ["-v"] : [];
  await dockerCompose(["--profile", "*", "down", ...volumes, "-t", "0", "--remove-orphans"], {
    ...(await projectComposeOptions(projectName)),
    showCommand: false,
    progress: "quiet",
  });
}

/**
 * Start a project and return the proxy port it listens on. A CLI instance project
 * must belong to this CLI version.
 */
async function startZoo(projectName: string, port?: string): Promise<number> {
  const parsed = parseProjectName(projectName);
  if (parsed) {
    const info = await prepareInstance({ instanceId: parsed.instanceId, port });
    await startServices(info, { quiet: true });
    return parseInt(info.env.ZOO_PROXY_PORT, 10);
  }

  // The development environment, started like `npm run start:quick`
  console.log(chalk.gray("  Starting Zoo (dev mode)..."));
  const composeOpts: DockerComposeOptions = {
    cwd: getZooPackagePath(),
    projectName,
    showCommand: false,
    progress: "quiet",
    env: port ? { ZOO_PROXY_PORT: port } : {},
  };
  const volume = externalVolumeName(await getComposeConfig(composeOpts), "zoo_snapshots");
  if (volume) {
    await execCommand("docker", ["volume", "create", volume]);
  }

  // Start core services first so they get their fixed IPs
  await dockerCompose(["up", "-d"], composeOpts);

  // Then create the on-demand containers without starting them
  await dockerCompose(["--profile", "*", "up", "-d", "--no-start"], composeOpts);

  return parseInt(port ?? (await getProxyPort(projectName)), 10);
}

/**
 * Whether the user agrees to stopping a running project, which timing startup does
 */
async function confirmStop(projectName: string, force?: boolean): Promise<boolean> {
  if (force) {
    return true;
  }
  const hint = "Pass --force to stop it without asking, or --sites-only to benchmark it as it runs";
  if (!process.stdin.isTTY) {
    throw new CliError(`Benchmarking startup stops ${projectName}, which is running`, { hint });
  }
  return confirm({
    message: `Benchmarking startup stops ${projectName} twice. Continue?`,
    default: false,
  });
}

export async function benchmark(options: BenchmarkOptions): Promise<void> {
  const isDev = isDevMode();
  const sitesOnly = options.sitesOnly ?? false;
  if (options.port !== undefined) {
    parsePort(options.port, "--port");
  }

  // One site per on-demand app container
  const allSites = onDemandServiceSites(loadSites(getZooPackagePath()));
  let sitesToBenchmark: Site[] = allSites;
  if (options.sites) {
    const requestedSites = options.sites.split(",").map((s) => s.trim());
    sitesToBenchmark = allSites.filter((site) =>
      requestedSites.some((req) => site.domain.includes(req)),
    );
    if (sitesToBenchmark.length === 0) {
      throw new CliError(`No sites matched: ${options.sites}`, {
        hint: `Available sites: ${allSites.map((site) => site.domain).join(", ")}`,
      });
    }
  }

  // Find the project to benchmark: the requested instance (running or not), else the only
  // running one, else the one `start` would create (this checkout's in development)
  const runningInstances = await getRunningInstances();
  let projectName: string;
  if (options.instance) {
    const running = findInstanceProjects(runningInstances, options.instance)[0];
    if (!running && !(await instanceExists(options.instance))) {
      throw new CliError(`Instance "${options.instance}" does not exist.`);
    }
    projectName = running ?? instanceProjectName(options.instance);
  } else if (runningInstances.length > 1) {
    throw new CliError("Several Zoo projects are running", {
      hint: `Pass --instance with one of them:\n${listProjects(runningInstances)}`,
    });
  } else {
    projectName =
      runningInstances[0] ??
      (isDev ? await checkoutProject() : instanceProjectName(getDefaultInstanceId()));
  }
  const isRunning = runningInstances.includes(projectName);

  // Timing restarts stops the project and starts the instance with this CLI version,
  // which for a project from another version would be a different project
  const parsed = parseProjectName(projectName);
  const currentProject = parsed ? instanceProjectName(parsed.instanceId) : projectName;
  if (!sitesOnly && currentProject !== projectName) {
    throw new CliError(
      `${projectName} was started by another CLI version (${parsed?.version}); benchmarking startup would replace it with ${currentProject}`,
      {
        hint: `Stop it with "the_zoo stop --instance ${projectName}" first, or pass --sites-only to benchmark it as it runs`,
      },
    );
  }

  if (!sitesOnly && isRunning && !(await confirmStop(projectName, options.force))) {
    console.log("Benchmark cancelled");
    return;
  }

  let proxyPort = parseInt(options.port ?? (await getProxyPort(projectName)), 10);

  // Determine output directory
  const now = new Date();
  const pad = (n: number) => String(n).padStart(2, "0");
  const dateStr = `${now.getFullYear()}${pad(now.getMonth() + 1)}${pad(now.getDate())}`;
  const timeStr = `${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}`;
  const outputDir = options.output || `./zoo-benchmark-${dateStr}-${timeStr}`;

  await mkdir(outputDir, { recursive: true });

  console.log(chalk.bold("\n========================================"));
  console.log(chalk.bold("Zoo Performance Benchmark"));
  console.log(chalk.bold("========================================\n"));

  console.log(`Output directory: ${chalk.cyan(outputDir)}`);
  console.log(`Mode: ${chalk.cyan(isDev ? "development" : "npx")}`);
  console.log(`Project: ${chalk.cyan(projectName)}`);
  console.log(`Proxy port: ${chalk.cyan(proxyPort)}`);
  console.log(`Sites only: ${chalk.cyan(sitesOnly)}`);
  console.log();

  // Get version
  const packageJson = await import("../../package.json", { with: { type: "json" } });
  const version = packageJson.default.version;

  // Collect system info
  console.log("Collecting system information...");
  const systemInfo = await collectSystemInfo();
  console.log(`  OS: ${systemInfo.os}`);
  console.log(`  CPU: ${systemInfo.cpu}`);
  console.log(`  Memory: ${systemInfo.memory_gb} GB`);
  console.log(`  Docker: ${systemInfo.docker_version}`);
  console.log();

  // Initialize results
  const results: BenchmarkResults = {
    timestamp: new Date().toISOString(),
    version,
    proxy_port: proxyPort,
    system: systemInfo,
    sites: {},
    core_services: {},
  };

  // Cold start timing (unless sites-only)
  if (!sitesOnly) {
    console.log(chalk.bold("========================================"));
    console.log(chalk.bold("Measuring cold start time..."));
    console.log(chalk.bold("========================================\n"));

    // Stop Zoo if running
    if (isRunning) {
      console.log("Stopping Zoo...");
      await stopZoo(projectName);
      await new Promise((resolve) => setTimeout(resolve, 2000));
    }

    // Start and time
    console.log("Starting Zoo and timing until proxy responds...");
    const startTime = Date.now();
    proxyPort = await startZoo(projectName, options.port);

    const proxyReady = await waitForProxy(proxyPort);
    const coldStartSeconds = (Date.now() - startTime) / 1000;

    if (proxyReady) {
      console.log(chalk.green(`Core services ready in ${coldStartSeconds.toFixed(2)}s`));
      results.cold_start_seconds = coldStartSeconds;
    } else {
      console.log(chalk.yellow("WARNING: Proxy not ready after 120s"));
    }

    // Let things settle
    await new Promise((resolve) => setTimeout(resolve, 3000));
  } else {
    // sites-only mode: ensure Zoo is running
    if (!isRunning) {
      console.log(`${projectName} is not running, starting it...`);
      proxyPort = await startZoo(projectName, options.port);

      const proxyReady = await waitForProxy(proxyPort);
      if (!proxyReady) {
        throw new CliError("Could not start Zoo - proxy not responding");
      }
      console.log(chalk.green("Zoo started successfully"));
      console.log();
    }
  }

  results.proxy_port = proxyPort;

  // Site benchmarks
  console.log();
  console.log(chalk.bold("========================================"));
  console.log(chalk.bold("Running site benchmarks..."));
  console.log(chalk.bold("========================================\n"));

  console.log("Site                    | Cold Start (ms) | Warm (ms) | Memory (MiB) | Status");
  console.log("-------------------------------------------------------------------------------");

  for (const { domain, service } of sitesToBenchmark) {
    // Cold start request
    const coldResult = await measureRequest(domain, proxyPort);

    // Small delay
    await new Promise((resolve) => setTimeout(resolve, 1000));

    // Warm request
    const warmResult = await measureRequest(domain, proxyPort);

    // Get memory
    const container = await findServiceContainer(projectName, service);
    const memoryMib = container ? await getContainerMemoryMib(container) : null;

    // Determine status
    const isOk =
      (coldResult.statusCode >= 200 && coldResult.statusCode < 400) ||
      (coldResult.statusCode >= 300 && coldResult.statusCode < 400);
    const status = isOk ? "OK" : `ERR:${coldResult.statusCode}`;

    // Store results
    results.sites[domain] = {
      cold_start_ms: isOk ? coldResult.timeMs : null,
      warm_response_ms: isOk ? warmResult.timeMs : null,
      memory_mib: memoryMib,
    };

    // Print row
    const coldStr = isOk ? String(coldResult.timeMs) : "FAIL";
    const warmStr = isOk ? String(warmResult.timeMs) : "FAIL";
    const memStr = memoryMib !== null ? String(memoryMib) : "null";

    console.log(
      `${domain.padEnd(23)} | ${coldStr.padStart(15)} | ${warmStr.padStart(9)} | ${memStr.padStart(12)} | ${status}`,
    );

    // Small delay between sites
    await new Promise((resolve) => setTimeout(resolve, 500));
  }

  console.log("-------------------------------------------------------------------------------");

  // Core services memory
  console.log();
  console.log(chalk.bold("========================================"));
  console.log(chalk.bold("Collecting core service memory..."));
  console.log(chalk.bold("========================================\n"));

  console.log("Service                 | Memory (MiB)");
  console.log("----------------------------------------");

  const coreContainers = await getCoreContainers(projectName);
  for (const container of coreContainers) {
    const memoryMib = await getContainerMemoryMib(container);
    results.core_services[container] = { memory_mib: memoryMib };

    const memStr = memoryMib !== null ? String(memoryMib) : "null";
    console.log(`${container.padEnd(23)} | ${memStr}`);
  }

  console.log("----------------------------------------");

  // Restart timing (unless sites-only)
  if (!sitesOnly) {
    console.log();
    console.log(chalk.bold("========================================"));
    console.log(chalk.bold("Measuring full restart time..."));
    console.log(chalk.bold("========================================\n"));

    const startTime = Date.now();
    console.log(chalk.gray(`  Restarting project: ${projectName}`));
    await stopZoo(projectName);
    proxyPort = await startZoo(projectName, String(proxyPort));

    const proxyReady = await waitForProxy(proxyPort);
    const restartSeconds = (Date.now() - startTime) / 1000;

    if (proxyReady) {
      console.log(chalk.green(`Full restart completed in ${restartSeconds.toFixed(2)}s`));
      results.restart_seconds = restartSeconds;
    } else {
      console.log(chalk.yellow("WARNING: Proxy not ready after restart"));
    }
  }

  // Write results
  const resultsPath = join(outputDir, "results.json");
  await writeFile(resultsPath, JSON.stringify(results, null, 2));

  console.log();
  console.log(chalk.bold("========================================"));
  console.log(chalk.bold("BENCHMARK COMPLETE"));
  console.log(chalk.bold("========================================\n"));

  console.log(`Results saved to: ${chalk.cyan(resultsPath)}`);
  console.log();

  // Summary
  console.log(chalk.bold("Summary:"));
  console.log(`  ${systemInfo.os} | ${systemInfo.cpu} | ${systemInfo.memory_gb} GB`);
  if (results.cold_start_seconds) {
    console.log(`  Cold start (core): ${results.cold_start_seconds.toFixed(2)}s`);
  }
  if (results.restart_seconds) {
    console.log(`  Full restart: ${results.restart_seconds.toFixed(2)}s`);
  }

  // Calculate total site memory
  const totalSiteMemory = Object.values(results.sites).reduce(
    (sum, s) => sum + (s.memory_mib || 0),
    0,
  );
  const totalCoreMemory = Object.values(results.core_services).reduce(
    (sum, s) => sum + (s.memory_mib || 0),
    0,
  );

  console.log(`  Total site memory: ${totalSiteMemory} MiB`);
  console.log(`  Total core memory: ${totalCoreMemory} MiB`);
  console.log();
}
