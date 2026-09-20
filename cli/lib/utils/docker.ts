import { type ChildProcess, spawn } from "node:child_process";
import { accessSync, constants, existsSync } from "node:fs";
import path, { isAbsolute, join, relative, sep } from "node:path";
import chalk from "chalk";
import { getZooSourceRoot } from "./config";
import { CliError } from "./errors";
import { getOutputCapture } from "./output";
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
}

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
  const { cwd, env = {} } = options;
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

    proc.stdout.on("data", (data) => {
      stdout += data.toString();
    });

    proc.stderr.on("data", (data) => {
      stderr += data.toString();
    });

    proc.on("error", (err) => {
      reject(new Error(`Failed to execute ${command}: ${err.message}`));
    });

    proc.on("close", (code) => {
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

/**
 * Check if Docker is running
 */
export async function checkDocker(): Promise<boolean> {
  try {
    await execCommand("docker", ["info"]);
    return true;
  } catch (_error) {
    return false;
  }
}

interface ExecDockerOptions {
  cwd?: string;
  env?: Record<string, string>;
}

/**
 * Spawn a command attached to the terminal, or with its output collected into the
 * active capture when running inside the MCP server (which owns stdin/stdout).
 */
function spawnAttached(
  command: string,
  args: string[],
  options: { cwd?: string; env: NodeJS.ProcessEnv },
): ChildProcess {
  const capture = getOutputCapture();
  const proc = spawn(command, args, {
    ...options,
    stdio: capture ? ["ignore", "pipe", "pipe"] : "inherit",
  });
  if (capture) {
    proc.stdout?.on("data", (data) => capture.chunks.push(data.toString()));
    proc.stderr?.on("data", (data) => capture.chunks.push(data.toString()));
  }
  return proc;
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
    const proc = spawnAttached("docker", args, {
      cwd,
      env: {
        ...process.env,
        ...env,
        PATH: getEnhancedPath(),
      },
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
  if (interactive && !getOutputCapture() && process.stdin.isTTY && process.stdout.isTTY) {
    args.push("-it");
  } else {
    args.push("-T");
  }

  args.push(service, ...command);

  if (getVerbose()) {
    logVerboseCommand(`docker ${args.join(" ")}`, cwd);
  }

  return new Promise((resolve, reject) => {
    const proc = spawnAttached("docker", args, {
      cwd: existingDir(cwd),
      env: {
        ...process.env,
        ...env,
        PATH: getEnhancedPath(),
      },
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

/**
 * Host port published by a project's proxy container, if it is running
 */
export async function getPublishedProxyPort(projectName: string): Promise<string | undefined> {
  try {
    const { stdout } = await execCommand("docker", [
      "compose",
      "-p",
      projectName,
      "ps",
      "proxy",
      "--format",
      "json",
    ]);
    const line = stdout.trim().split("\n")[0];
    if (!line) {
      return undefined;
    }
    // Older compose versions print an array instead of one object per line
    const parsed = JSON.parse(line);
    const container = Array.isArray(parsed) ? parsed[0] : parsed;
    const publisher = container?.Publishers?.find(
      (p: { PublishedPort?: number }) => p.PublishedPort,
    );
    return publisher ? String(publisher.PublishedPort) : undefined;
  } catch {
    return undefined;
  }
}

/**
 * Get list of running Zoo instances
 * @param options - Optional configuration
 * @param options.onlyCliInstances - If true, only return CLI instances (useful for testing)
 */
export async function getRunningInstances(options?: {
  onlyCliInstances?: boolean;
}): Promise<string[]> {
  try {
    // First check if Docker is running
    const dockerRunning = await checkDocker();
    if (!dockerRunning) {
      console.warn(chalk.yellow("Warning: Docker is not running"));
      return [];
    }

    // Get list of docker compose projects
    // CLI instances have names like "{projectname}-cli-instance-{version}"
    // Main dev environment is just the project name
    const { stdout: lsOutput } = await execCommand("docker", ["compose", "ls", "--format", "json"]);

    // Parse JSON output to get project names
    let projectNames: string[] = [];
    try {
      const projects = JSON.parse(lsOutput);
      projectNames = projects.map((p: { Name: string }) => p.Name);
    } catch {
      // Fallback: empty if parsing fails
      projectNames = [];
    }

    const stdout = projectNames.join("\n");

    const projects: string[] = [];
    // In development (ZOO_DEV=1 from zoo repo), include all Zoo projects
    // Otherwise only include CLI instances
    const isDevEnvironment = isRunningFromZooRepository();
    const onlyCliInstances = options?.onlyCliInstances ?? !isDevEnvironment;

    if (getVerbose()) {
      console.log(chalk.gray(`[VERBOSE] isDevEnvironment: ${isDevEnvironment}`));
      console.log(chalk.gray(`[VERBOSE] onlyCliInstances: ${onlyCliInstances}`));
    }

    for (const line of stdout.split("\n")) {
      const projectName = line.trim();
      if (!projectName) continue;

      // Always include CLI instances
      if (projectName.includes("-cli-instance-")) {
        projects.push(projectName);
      }
      // For non-CLI instances, include them unless onlyCliInstances is true
      else if (!onlyCliInstances) {
        try {
          // Check if this project has Zoo-specific services using docker compose
          const { stdout: servicesOutput } = await execCommand("docker", [
            "compose",
            "-p",
            projectName,
            "ps",
            "--format",
            "json",
          ]);

          // Parse each line as JSON and check for Zoo-specific services
          const services = servicesOutput
            .trim()
            .split("\n")
            .filter((line) => line)
            .map((line) => {
              try {
                return JSON.parse(line).Service;
              } catch {
                return null;
              }
            })
            .filter((service) => service);

          // Check if any of the services are Zoo-specific
          const hasZooServices = services.some((service) => /^(caddy|coredns|proxy)/.test(service));

          if (hasZooServices) {
            // This is a Zoo project
            projects.push(projectName);
          }
        } catch {
          // Not a Zoo project or error checking, skip it
        }
      }
    }

    if (projects.length > 1) {
      // Sort to ensure main project (without -cli-instance-) comes first
      projects.sort((a, b) => {
        if (!a.includes("-cli-instance-") && b.includes("-cli-instance-")) return -1;
        if (a.includes("-cli-instance-") && !b.includes("-cli-instance-")) return 1;
        return 0;
      });
    }

    return projects;
  } catch (_error) {
    // No instances running or error in command
    return [];
  }
}
