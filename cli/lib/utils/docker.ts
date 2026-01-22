import { spawn, exec, execSync } from "node:child_process";
import { promisify } from "node:util";
import { existsSync } from "node:fs";
import { join } from "node:path";
import chalk from "chalk";
import { getVerbose, logVerboseCommand } from "./verbose";

const execAsync = promisify(exec);

/**
 * Find the docker executable path
 */
function findDockerPath(): string {
  // Common docker installation locations
  const dockerPaths = ["/opt/homebrew/bin/docker", "/usr/local/bin/docker", "/usr/bin/docker"];

  // First try to use 'which docker' with enhanced PATH
  try {
    const enhancedPath = [
      "/opt/homebrew/bin",
      "/usr/local/bin",
      "/usr/bin",
      "/bin",
      process.env.PATH || "",
    ].join(":");

    const result = execSync("which docker", {
      encoding: "utf8",
      env: { ...process.env, PATH: enhancedPath },
    }).trim();

    if (result && existsSync(result)) {
      return result;
    }
  } catch {
    // which failed, try known paths
  }

  // Try known locations
  for (const path of dockerPaths) {
    if (existsSync(path)) {
      return path;
    }
  }

  // Fall back to just "docker" and hope it's in PATH
  return "docker";
}

// Cache the docker path
let cachedDockerPath: string | null = null;

function getDockerCommand(): string {
  if (cachedDockerPath === null) {
    cachedDockerPath = findDockerPath();
    if (getVerbose()) {
      console.log(chalk.gray(`[VERBOSE] Using docker at: ${cachedDockerPath}`));
    }
  }
  return cachedDockerPath;
}

/**
 * Check if we're running in development mode (ZOO_DEV=1) from the Zoo repository
 */
export function isRunningFromZooRepository(): boolean {
  // If ZOO_DEV=1 is explicitly set, trust it regardless of cwd
  // This allows using the dev CLI from other directories
  return process.env.ZOO_DEV === "1";
}

/**
 * Check if Docker is running
 */
export async function checkDocker(): Promise<boolean> {
  try {
    await execAsync("docker info");
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
 * Execute docker command using spawn with inherited stdio
 */
export function execDocker(args: string[], options: ExecDockerOptions = {}): Promise<void> {
  const { cwd, env = {} } = options;
  const verbose = getVerbose();

  if (verbose) {
    logVerboseCommand(`docker ${args.join(" ")}`, cwd);
  }

  return new Promise((resolve, reject) => {
    const dockerCmd = getDockerCommand();
    const proc = spawn(dockerCmd, args, {
      cwd,
      env: {
        ...process.env,
        ...env,
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
  command: string,
  options: DockerComposeOptions = {},
): Promise<void> {
  const { cwd, projectName, env = {}, envFile, showCommand = true, progress } = options;
  const verbose = getVerbose();

  const args = ["compose"];

  if (progress) {
    args.push("--progress", progress);
  }

  if (cwd) {
    args.push("-f", join(cwd, "docker-compose.yaml"));
  }

  if (envFile) {
    args.push("--env-file", envFile);
  }

  if (projectName) {
    args.push("-p", projectName);
  }

  // Split command properly
  const commandParts = command.match(/[^\s"]+|"([^"]*)"/gi);
  if (commandParts) {
    args.push(...commandParts.map((part) => part.replace(/^"|"$/g, "")));
  }

  if (showCommand || verbose) {
    console.log(chalk.gray(`  Running: docker ${args.join(" ")}`));
  }

  await execDocker(args, { cwd, env });
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

  const args = ["compose"];

  if (cwd) {
    args.push("-f", join(cwd, "docker-compose.yaml"));
  }

  if (envFile) {
    args.push("--env-file", envFile);
  }

  if (projectName) {
    args.push("-p", projectName);
  }

  args.push("exec");
  if (interactive && process.stdin.isTTY && process.stdout.isTTY) {
    args.push("-it");
  }

  args.push(service, ...command);

  return new Promise((resolve, reject) => {
    const dockerCmd = getDockerCommand();
    const proc = spawn(dockerCmd, args, {
      stdio: "inherit",
      cwd,
      env: {
        ...process.env,
        ...env,
      },
    });

    proc.on("error", (err) => {
      reject(new Error(`Failed to execute docker compose exec: ${err.message}`));
    });

    proc.on("exit", (code) => {
      if (code === 0) {
        resolve();
      } else {
        process.exit(code || 1);
      }
    });
  });
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
    const { stdout } = await execAsync(
      "docker compose ls --format table | tail -n +2 | awk '{print $1}'",
    );

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
          const { stdout: servicesOutput } = await execAsync(
            `docker compose -p ${projectName} ps --format json`,
          );

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
