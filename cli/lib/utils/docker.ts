import { spawn } from "node:child_process";
import { accessSync, constants, existsSync } from "node:fs";
import path, { isAbsolute, join, relative, sep } from "node:path";
import chalk from "chalk";
import { getZooSourceRoot } from "./config";
import { CliError } from "./errors";
import { getVerbose, logVerboseCommand } from "./verbose";

/**
 * Find an available shell on the system
 */
function findShell(): string {
  // Common shell locations to try
  const shells = ["/bin/sh", "/bin/bash", "/bin/zsh", "/usr/bin/sh", "/usr/bin/bash"];
  for (const shell of shells) {
    try {
      accessSync(shell, constants.X_OK);
      return shell;
    } catch {
      // Shell not found, try next
    }
  }
  // Fallback to sh and let it fail with a clearer error
  return "sh";
}

/**
 * Execute a shell command (for commands requiring shell features like pipes)
 * Falls back to finding an available shell if /bin/sh is not found
 */
export function execShellCommand(
  command: string,
  options: ExecCommandOptions = {},
): Promise<{ stdout: string; stderr: string }> {
  const { cwd, env = {} } = options;
  const verbose = getVerbose();
  const shell = findShell();

  if (verbose) {
    logVerboseCommand(command, cwd);
  }

  return new Promise((resolve, reject) => {
    const proc = spawn(shell, ["-c", command], {
      cwd,
      env: {
        ...process.env,
        ...env,
        PATH: getEnhancedPath(),
      },
    });

    let stdout = "";
    let stderr = "";

    proc.stdout.on("data", (data) => {
      stdout += data.toString();
    });

    proc.stderr.on("data", (data) => {
      stderr += data.toString();
    });

    proc.on("error", (err) => {
      reject(new Error(`Failed to execute shell command: ${err.message}`));
    });

    proc.on("close", (code) => {
      if (code === 0) {
        resolve({ stdout, stderr });
      } else {
        reject(new Error(`Shell command failed with code ${code}: ${stderr}`));
      }
    });
  });
}

interface ExecCommandOptions {
  cwd?: string;
  env?: Record<string, string>;
  timeoutMs?: number; // Kill the command and fail with a TimeoutError after this long
  timeoutHint?: string;
}

export class TimeoutError extends CliError {}

// Common locations for docker and other tools, which a GUI-launched process's PATH can lack
const UNIX_TOOL_DIRS = [
  "/usr/local/bin",
  "/usr/bin",
  "/bin",
  "/opt/homebrew/bin", // Apple Silicon homebrew
  "/usr/local/opt/docker/bin", // Docker via homebrew
  "/Applications/Docker.app/Contents/Resources/bin", // Docker Desktop
];

/**
 * PATH for child processes: `basePath` plus, outside Windows, the common tool locations
 */
export function getEnhancedPath(
  basePath = process.env.PATH || "",
  platform: NodeJS.Platform = process.platform,
): string {
  const { delimiter } = platform === "win32" ? path.win32 : path.posix;
  const pathParts = basePath.split(delimiter).filter(Boolean);
  if (platform !== "win32") {
    for (const dir of UNIX_TOOL_DIRS) {
      if (!pathParts.includes(dir)) {
        pathParts.push(dir);
      }
    }
  }
  return pathParts.join(delimiter);
}

/**
 * Execute a command using spawn (no shell required)
 * This avoids issues with /bin/sh not being found in certain environments
 */
export function execCommand(
  command: string,
  args: string[],
  options: ExecCommandOptions = {},
): Promise<{ stdout: string; stderr: string }> {
  const { cwd, env = {}, timeoutMs, timeoutHint } = options;
  const verbose = getVerbose();

  if (verbose) {
    logVerboseCommand(`${command} ${args.join(" ")}`, cwd);
  }

  return new Promise((resolve, reject) => {
    const proc = spawn(command, args, {
      cwd,
      env: {
        ...process.env,
        ...env,
        PATH: getEnhancedPath(),
      },
    });

    let stdout = "";
    let stderr = "";

    // Fail without waiting for the pipes to close: a hung command's children can hold them
    const timer =
      timeoutMs === undefined
        ? undefined
        : setTimeout(() => {
            proc.kill("SIGKILL");
            proc.stdout.destroy();
            proc.stderr.destroy();
            reject(
              new TimeoutError(
                `"${command} ${args.join(" ")}" did not finish within ${timeoutMs / 1000}s`,
                { hint: timeoutHint },
              ),
            );
          }, timeoutMs);

    proc.stdout.on("data", (data) => {
      stdout += data.toString();
    });

    proc.stderr.on("data", (data) => {
      stderr += data.toString();
    });

    proc.on("error", (err) => {
      clearTimeout(timer);
      reject(new Error(`Failed to execute ${command}: ${err.message}`));
    });

    proc.on("close", (code) => {
      clearTimeout(timer);
      if (code === 0) {
        resolve({ stdout, stderr });
      } else {
        reject(new Error(`Command failed with code ${code}: ${stderr}`));
      }
    });
  });
}

/**
 * Check if we're running in development mode (ZOO_DEV=1) from inside the Zoo repository
 */
export function isRunningFromZooRepository(): boolean {
  if (process.env.ZOO_DEV !== "1") {
    return false;
  }
  const fromRoot = relative(getZooSourceRoot(), process.cwd());
  return fromRoot !== ".." && !fromRoot.startsWith(`..${sep}`) && !isAbsolute(fromRoot);
}

/**
 * `-f <dir>/docker-compose.yaml` when that file exists. Without it compose still finds
 * a project's containers by project name, e.g. to stop an instance whose files are gone.
 */
export function composeFileArgs(dir?: string): string[] {
  const file = dir && join(dir, "docker-compose.yaml");
  return file && existsSync(file) ? ["-f", file] : [];
}

/**
 * A working directory for a docker child process, if it exists
 */
export function existingDir(dir?: string): string | undefined {
  return dir && existsSync(dir) ? dir : undefined;
}

const DEFAULT_DOCKER_TIMEOUT_SECONDS = 15;

/**
 * How long a query to the Docker daemon may take. A hung Docker Desktop never answers.
 */
export function dockerTimeoutMs(): number {
  const seconds = Number(process.env.THE_ZOO_DOCKER_TIMEOUT);
  return (seconds > 0 ? seconds : DEFAULT_DOCKER_TIMEOUT_SECONDS) * 1000;
}

/**
 * Run a docker command that should answer quickly, failing with a TimeoutError if Docker
 * doesn't. `scale` allows proportionally more time for slower queries.
 */
export function dockerProbe(
  args: string[],
  options: ExecCommandOptions & { scale?: number } = {},
): Promise<{ stdout: string; stderr: string }> {
  const { scale = 1, ...execOptions } = options;
  return execCommand("docker", args, {
    ...execOptions,
    timeoutMs: dockerTimeoutMs() * scale,
    timeoutHint:
      "Docker is not responding. Restart it and try again, or allow more time with THE_ZOO_DOCKER_TIMEOUT=<seconds>",
  });
}

/**
 * Whether the Docker daemon is running. Throws a TimeoutError if it doesn't answer.
 */
export async function checkDocker(): Promise<boolean> {
  try {
    await dockerProbe(["info"]);
    return true;
  } catch (error) {
    if (error instanceof TimeoutError) {
      throw error;
    }
    return false;
  }
}

export async function requireDocker(): Promise<void> {
  if (!(await checkDocker())) {
    throw new CliError("Docker is not running", { hint: "Start Docker and try again" });
  }
}

interface ExecDockerOptions {
  cwd?: string;
  env?: Record<string, string>;
}

/**
 * Execute docker command using spawn with inherited stdio
 */
export function execDocker(args: string[], options: ExecDockerOptions = {}): Promise<void> {
  const { cwd, env = {} } = options;
  const verbose = getVerbose();

  if (verbose) {
    logVerboseCommand(`docker ${args.join(" ")}`, cwd);
  }

  return new Promise((resolve, reject) => {
    const proc = spawn("docker", args, {
      cwd,
      env: {
        ...process.env,
        ...env,
        PATH: getEnhancedPath(),
      },
      stdio: "inherit",
    });

    proc.on("close", (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`Docker command failed with code ${code}`));
      }
    });

    proc.on("error", (err) => {
      reject(new Error(`Failed to start docker: ${err.message}`));
    });
  });
}

interface DockerComposeOptions {
  cwd?: string;
  projectName?: string;
  env?: Record<string, string>;
  envFile?: string;
  showCommand?: boolean;
  progress?: "auto" | "tty" | "plain" | "json" | "quiet";
}

/**
 * Run docker compose with proper args
 */
export async function dockerCompose(
  command: string[],
  options: DockerComposeOptions = {},
): Promise<void> {
  const { cwd, projectName, env = {}, envFile, showCommand = true, progress } = options;
  const verbose = getVerbose();

  const args = ["compose"];

  if (progress) {
    args.push("--progress", progress);
  }

  args.push(...composeFileArgs(cwd));

  if (envFile) {
    args.push("--env-file", envFile);
  }

  if (projectName) {
    args.push("-p", projectName);
  }

  args.push(...command);

  if (showCommand || verbose) {
    console.log(chalk.gray(`  Running: docker ${args.join(" ")}`));
  }

  await execDocker(args, { cwd: existingDir(cwd), env });
}

/**
 * Run docker compose exec and capture output (no shell required)
 */
export async function dockerComposeExecCapture(
  service: string,
  command: string[],
  options: DockerComposeOptions = {},
): Promise<{ stdout: string; stderr: string }> {
  const { cwd, projectName, envFile } = options;
  const verbose = getVerbose();

  const args = ["compose", ...composeFileArgs(cwd)];

  if (envFile) {
    args.push("--env-file", envFile);
  }

  if (projectName) {
    args.push("-p", projectName);
  }

  args.push("exec", "-T", service, ...command);

  if (verbose) {
    logVerboseCommand(`docker ${args.join(" ")}`, cwd);
  }

  return new Promise((resolve, reject) => {
    const proc = spawn("docker", args, {
      cwd: existingDir(cwd),
      env: {
        ...process.env,
        PATH: getEnhancedPath(),
      },
    });

    let stdout = "";
    let stderr = "";

    proc.stdout.on("data", (data) => {
      stdout += data.toString();
    });

    proc.stderr.on("data", (data) => {
      stderr += data.toString();
    });

    proc.on("error", (err) => {
      reject(new Error(`Failed to execute docker compose exec: ${err.message}`));
    });

    proc.on("close", (code) => {
      if (code === 0) {
        resolve({ stdout, stderr });
      } else {
        reject(new Error(`Docker command failed with code ${code}: ${stderr}`));
      }
    });
  });
}

/**
 * Run docker compose exec with interactive support
 */
export async function dockerComposeExecInteractive(
  service: string,
  command: string[],
  options: DockerComposeOptions & { interactive?: boolean } = {},
): Promise<void> {
  const { cwd, projectName, env = {}, envFile, interactive = true } = options;

  const args = ["compose", ...composeFileArgs(cwd)];

  if (envFile) {
    args.push("--env-file", envFile);
  }

  if (projectName) {
    args.push("-p", projectName);
  }

  args.push("exec");
  if (interactive && process.stdin.isTTY && process.stdout.isTTY) {
    args.push("-it");
  } else {
    args.push("-T");
  }

  args.push(service, ...command);

  if (getVerbose()) {
    logVerboseCommand(`docker ${args.join(" ")}`, cwd);
  }

  return new Promise((resolve, reject) => {
    const proc = spawn("docker", args, {
      cwd: existingDir(cwd),
      env: {
        ...process.env,
        ...env,
        PATH: getEnhancedPath(),
      },
      stdio: "inherit",
    });

    proc.on("error", (err) => {
      reject(new Error(`Failed to execute docker compose exec: ${err.message}`));
    });

    proc.on("close", (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(
          new CliError(`${command[0]} in ${service} exited with code ${code}`, {
            exitCode: code || 1,
          }),
        );
      }
    });
  });
}

export interface ComposeContainer {
  Service?: string;
  State?: string;
  Health?: string;
  Publishers?: Array<{ PublishedPort?: number }>;
}

/**
 * Parse `docker compose ps --format json`: one object per line, or in older compose
 * versions one array
 */
export function parseComposePs(stdout: string): ComposeContainer[] {
  return stdout
    .split("\n")
    .filter((line) => line.trim())
    .flatMap((line) => {
      try {
        const parsed = JSON.parse(line);
        return Array.isArray(parsed) ? parsed : [parsed];
      } catch {
        return [];
      }
    });
}

/**
 * The host port the proxy among a project's containers publishes
 */
export function publishedProxyPort(containers: ComposeContainer[]): string | undefined {
  const proxy = containers.find((container) => container.Service === "proxy");
  const publisher = proxy?.Publishers?.find((p) => p.PublishedPort);
  return publisher ? String(publisher.PublishedPort) : undefined;
}

/**
 * Host port published by a project's proxy container, if it is running
 */
export async function getPublishedProxyPort(projectName: string): Promise<string | undefined> {
  try {
    const { stdout } = await dockerProbe([
      "compose",
      "-p",
      projectName,
      "ps",
      "proxy",
      "--format",
      "json",
    ]);
    return publishedProxyPort(parseComposePs(stdout));
  } catch (error) {
    if (error instanceof TimeoutError) {
      throw error;
    }
    return undefined;
  }
}

/**
 * Get list of running Zoo instances. Throws a CliError if Docker is not running.
 * @param options - Optional configuration
 * @param options.onlyCliInstances - If true, only return CLI instances (useful for testing)
 */
export async function getRunningInstances(options?: {
  onlyCliInstances?: boolean;
}): Promise<string[]> {
  await requireDocker();

  // CLI instances have names like "thezoo-cli-instance-{id}-v{version}"; the dev
  // environment and worktrees have other names
  const { stdout: lsOutput } = await dockerProbe(["compose", "ls", "--format", "json"]);
  let projectNames: string[];
  try {
    projectNames = JSON.parse(lsOutput).map((p: { Name: string }) => p.Name);
  } catch {
    projectNames = [];
  }

  const projects: string[] = [];
  // In development (ZOO_DEV=1 from zoo repo), include all Zoo projects
  // Otherwise only include CLI instances
  const isDevEnvironment = isRunningFromZooRepository();
  const onlyCliInstances = options?.onlyCliInstances ?? !isDevEnvironment;

  if (getVerbose()) {
    console.log(chalk.gray(`[VERBOSE] isDevEnvironment: ${isDevEnvironment}`));
    console.log(chalk.gray(`[VERBOSE] onlyCliInstances: ${onlyCliInstances}`));
  }

  for (const projectName of projectNames) {
    if (projectName.includes("-cli-instance-")) {
      projects.push(projectName);
    } else if (!onlyCliInstances) {
      // Another project is a Zoo if it runs Zoo core services
      let containers: ComposeContainer[];
      try {
        const { stdout } = await dockerProbe([
          "compose",
          "-p",
          projectName,
          "ps",
          "--format",
          "json",
        ]);
        containers = parseComposePs(stdout);
      } catch (error) {
        if (error instanceof TimeoutError) {
          throw error;
        }
        continue;
      }
      if (containers.some((c) => /^(caddy|coredns|proxy)/.test(c.Service ?? ""))) {
        projects.push(projectName);
      }
    }
  }

  // The dev environment (not a CLI instance) comes first
  return projects.sort(
    (a, b) => Number(a.includes("-cli-instance-")) - Number(b.includes("-cli-instance-")),
  );
}
