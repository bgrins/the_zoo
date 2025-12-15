import { exec, spawn } from "node:child_process";
import { mkdir, writeFile } from "node:fs/promises";
import { promisify } from "node:util";
import { platform, cpus, totalmem } from "node:os";
import { join } from "node:path";
import chalk from "chalk";
import { isRunningFromZooRepository, getRunningInstances } from "../utils/docker";

const execAsync = promisify(exec);

interface BenchmarkOptions {
  sitesOnly?: boolean;
  sites?: string;
  output?: string;
  port?: string;
  instance?: string;
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

// All benchmarkable sites (on-demand app containers)
const DEFAULT_SITES = [
  "analytics.zoo",
  "auth.zoo",
  "classifieds.zoo",
  "excalidraw.zoo",
  "focalboard.zoo",
  "gitea.zoo",
  "miniflux.zoo",
  "misc.zoo",
  "northwind.zoo",
  "onestopshop.zoo",
  "paste.zoo",
  "postmill.zoo",
  "snappymail.zoo",
  "wiki.zoo",
];

async function getDockerVersion(): Promise<string> {
  try {
    const { stdout } = await execAsync("docker --version");
    return stdout.trim();
  } catch {
    return "unknown";
  }
}

async function getCpuInfo(): Promise<string> {
  if (platform() === "darwin") {
    try {
      const { stdout } = await execAsync("sysctl -n machdep.cpu.brand_string");
      return stdout.trim();
    } catch {
      // Apple Silicon doesn't have this, check for chip info
      try {
        const { stdout } = await execAsync(
          "sysctl -n machdep.cpu.brand_string 2>/dev/null || echo 'Apple Silicon'",
        );
        return stdout.trim();
      } catch {
        return "Apple Silicon";
      }
    }
  } else {
    try {
      const { stdout } = await execAsync("grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2");
      return stdout.trim();
    } catch {
      return cpus()[0]?.model || "unknown";
    }
  }
}

async function collectSystemInfo(): Promise<BenchmarkResults["system"]> {
  const osInfo =
    platform() === "darwin"
      ? await execAsync("sw_vers -productVersion")
          .then((r) => `macOS ${r.stdout.trim()}`)
          .catch(() => "macOS")
      : await execAsync("cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2")
          .then((r) => r.stdout.trim().replace(/"/g, ""))
          .catch(() => "Linux");

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
    const { stdout } = await execAsync(
      `curl -s -o /dev/null -w "%{http_code} %{time_total}" --proxy "http://localhost:${proxyPort}" -k --connect-timeout 120 --max-time 120 "${url}"`,
      { timeout: 130000 },
    );

    const [statusCode, timeTotal] = stdout.trim().split(" ");
    return {
      statusCode: parseInt(statusCode, 10),
      timeMs: Math.round(parseFloat(timeTotal) * 1000),
    };
  } catch {
    return { statusCode: 0, timeMs: 0 };
  }
}

async function findContainerByDomain(domain: string): Promise<string | null> {
  try {
    const { stdout } = await execAsync(
      'docker ps --filter "label=zoo.domains" --format "{{.Names}}"',
    );
    const containers = stdout.trim().split("\n").filter(Boolean);

    for (const container of containers) {
      const { stdout: labelOutput } = await execAsync(
        `docker inspect "${container}" --format '{{index .Config.Labels "zoo.domains"}}'`,
      );
      const domains = labelOutput.trim();

      // Handle port suffix like "paste.zoo:8080"
      if (domains === domain || domains.startsWith(`${domain}:`)) {
        return container;
      }
    }
  } catch {
    // Ignore errors
  }
  return null;
}

async function getContainerMemoryMib(container: string): Promise<number | null> {
  try {
    const { stdout } = await execAsync(
      `docker stats --no-stream --format "{{.MemUsage}}" "${container}"`,
    );

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

async function getCoreContainers(): Promise<string[]> {
  try {
    const { stdout } = await execAsync(
      'docker ps --filter "label=zoo.core=true" --format "{{.Names}}"',
    );
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

async function stopZoo(isDev: boolean, projectName?: string): Promise<void> {
  if (isDev) {
    console.log(chalk.gray("  Running: npm run stop"));
    await execAsync("npm run stop", { timeout: 60000 });
  } else if (projectName) {
    console.log(chalk.gray(`  Running: docker compose -p ${projectName} down -v -t 0`));
    await execAsync(`docker compose -p ${projectName} down -v -t 0`, { timeout: 60000 });
  }
}

async function startZoo(isDev: boolean, proxyPort: number): Promise<void> {
  if (isDev) {
    console.log(chalk.gray("  Running: npm run start:quick (background)"));
    // Start in background
    const child = spawn("npm", ["run", "start:quick"], {
      detached: true,
      stdio: "ignore",
      env: { ...process.env, ZOO_PROXY_PORT: String(proxyPort) },
    });
    child.unref();
  } else {
    // For npx mode, we'd use the_zoo start but that's complex
    // For now, just use docker compose directly
    console.log(chalk.gray("  Starting Zoo..."));
    const child = spawn("docker", ["compose", "up", "-d"], {
      detached: true,
      stdio: "ignore",
    });
    child.unref();
  }
}

async function restartZoo(isDev: boolean): Promise<void> {
  if (isDev) {
    console.log(chalk.gray("  Running: npm run reset"));
    await execAsync("npm run reset", { timeout: 120000 });
  } else {
    console.log(chalk.gray("  Running: docker compose restart"));
    await execAsync("docker compose down -v -t 0 && docker compose up -d", { timeout: 120000 });
  }
}

export async function benchmark(options: BenchmarkOptions): Promise<void> {
  const isDev = isRunningFromZooRepository();
  const proxyPort = parseInt(options.port || (isDev ? "3128" : "3130"), 10);
  const sitesOnly = options.sitesOnly ?? false;

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

  // Determine which sites to benchmark
  let sitesToBenchmark: string[];
  if (options.sites) {
    const requestedSites = options.sites.split(",").map((s) => s.trim());
    sitesToBenchmark = DEFAULT_SITES.filter((site) =>
      requestedSites.some((req) => site.includes(req)),
    );
    if (sitesToBenchmark.length === 0) {
      console.error(chalk.red(`No sites matched: ${options.sites}`));
      console.log(`Available sites: ${DEFAULT_SITES.join(", ")}`);
      process.exit(1);
    }
  } else {
    sitesToBenchmark = DEFAULT_SITES;
  }

  // Get running instance info
  const runningInstances = await getRunningInstances();
  let projectName: string | undefined;

  const instanceFilter = options.instance;
  if (instanceFilter) {
    projectName = runningInstances.find((p) => p.includes(instanceFilter));
  } else if (runningInstances.length > 0) {
    projectName = runningInstances[0];
  }

  // Cold start timing (unless sites-only)
  if (!sitesOnly) {
    console.log(chalk.bold("========================================"));
    console.log(chalk.bold("Measuring cold start time..."));
    console.log(chalk.bold("========================================\n"));

    // Stop Zoo
    console.log("Stopping Zoo...");
    try {
      await stopZoo(isDev, projectName);
    } catch {
      // May not be running
    }
    await new Promise((resolve) => setTimeout(resolve, 2000));

    // Start and time
    console.log("Starting Zoo and timing until proxy responds...");
    const startTime = Date.now();
    await startZoo(isDev, proxyPort);

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
  }

  // Site benchmarks
  console.log();
  console.log(chalk.bold("========================================"));
  console.log(chalk.bold("Running site benchmarks..."));
  console.log(chalk.bold("========================================\n"));

  console.log("Site                    | Cold Start (ms) | Warm (ms) | Memory (MiB) | Status");
  console.log("-------------------------------------------------------------------------------");

  for (const site of sitesToBenchmark) {
    // Cold start request
    const coldResult = await measureRequest(site, proxyPort);

    // Small delay
    await new Promise((resolve) => setTimeout(resolve, 1000));

    // Warm request
    const warmResult = await measureRequest(site, proxyPort);

    // Get memory
    const container = await findContainerByDomain(site);
    const memoryMib = container ? await getContainerMemoryMib(container) : null;

    // Determine status
    const isOk =
      (coldResult.statusCode >= 200 && coldResult.statusCode < 400) ||
      (coldResult.statusCode >= 300 && coldResult.statusCode < 400);
    const status = isOk ? "OK" : `ERR:${coldResult.statusCode}`;

    // Store results
    results.sites[site] = {
      cold_start_ms: isOk ? coldResult.timeMs : null,
      warm_response_ms: isOk ? warmResult.timeMs : null,
      memory_mib: memoryMib,
    };

    // Print row
    const coldStr = isOk ? String(coldResult.timeMs) : "FAIL";
    const warmStr = isOk ? String(warmResult.timeMs) : "FAIL";
    const memStr = memoryMib !== null ? String(memoryMib) : "null";

    console.log(
      `${site.padEnd(23)} | ${coldStr.padStart(15)} | ${warmStr.padStart(9)} | ${memStr.padStart(12)} | ${status}`,
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

  const coreContainers = await getCoreContainers();
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
    await restartZoo(isDev);

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
