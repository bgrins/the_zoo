import { existsSync } from "node:fs";
import fs from "node:fs/promises";
import path from "node:path";
import chalk from "chalk";
import yoctoSpinner from "yocto-spinner";
import packageJson from "../../package.json" with { type: "json" };
import { generateEnvFile, readEnvFile, updateEnvFile } from "./network-env";
import { ensureDirectories, getProjectName, getZooSourceRoot, paths } from "./config";
import { checkDocker, dockerCompose } from "./docker";
import { logVerbose, logVerboseStep, logVerboseEnv } from "./verbose";

export const DEFAULT_PROXY_PORT = "3128";

/**
 * Get the default instance ID for the current CLI version
 */
export function getDefaultInstanceId(): string {
  return "default";
}

/**
 * Check if running in development mode (ZOO_DEV=1)
 */
export function isDevMode(): boolean {
  return process.env.ZOO_DEV === "1";
}

/**
 * Directory holding an instance's .env and, in production, its copy of the Zoo sources.
 * Development: <home>/runtime/<id>. Production: <home>/instances/v<version>/<id>.
 */
export function getInstanceDir(instanceId: string, version = `v${packageJson.version}`): string {
  if (!/^[\w-]+$/.test(instanceId)) {
    throw new Error(`Invalid instance ID: "${instanceId}"`);
  }
  return isDevMode()
    ? path.join(paths.runtime, instanceId)
    : path.join(paths.instances, version, instanceId);
}

/**
 * Directory containing the docker-compose.yaml an instance runs from.
 * Development instances run from the repository; production instances from their copy.
 */
export function getInstanceComposeDir(instanceId: string, version?: string): string {
  return isDevMode() ? getZooPackagePath() : getInstanceDir(instanceId, version);
}

export function getInstanceEnvPath(instanceId: string, version?: string): string {
  return path.join(getInstanceDir(instanceId, version), ".env");
}

/**
 * Check if an instance exists (has been created)
 */
export async function instanceExists(instanceId: string): Promise<boolean> {
  return existsSync(getInstanceEnvPath(instanceId));
}

interface CreateInstanceOptions {
  port?: string; // Defaults to the instance's saved port, then DEFAULT_PROXY_PORT
  setEnv?: string[];
  instanceId?: string; // Optional - if not provided, generates a new one
  ipBase?: string; // Custom base IP (e.g., 172.30.100.1)
}

interface InstanceInfo {
  instanceId: string;
  projectName: string;
  packagePath: string;
  envPath: string;
  env: Record<string, string>;
}

/**
 * Get the path to the zoo package root
 * In development: the repository root
 * In production: the zoo/ directory of the npm package
 */
export function getZooPackagePath(): string {
  const packagePath = getZooSourceRoot();
  logVerbose(`${isDevMode() ? "Development" : "Production"} mode - package path: ${packagePath}`);
  return packagePath;
}

/**
 * Parse a CLI instance project name into its components.
 * Project names follow the format: thezoo-cli-instance-{instanceId}-v{version}
 * where version has dots replaced with hyphens (e.g., v0-1-0 for v0.1.0)
 */
export function parseProjectName(projectName: string): {
  instanceId: string;
  version: string;
} | null {
  const match = projectName.match(/^thezoo-cli-instance-(.+?)-v(\d+-\d+-\d+.*)$/);
  if (match) {
    return {
      instanceId: match[1],
      version: `v${match[2].replace(/-/g, ".")}`,
    };
  }
  return null;
}

/**
 * Get the source path for a running instance based on its project name.
 * This is where docker-compose.yaml is located for that instance.
 *
 * For CLI instances (thezoo-cli-instance-{id}-v{version}): getInstanceComposeDir
 * For main development project (e.g., "the_zoo"): process.cwd()
 */
export function getInstanceSourcePath(projectName: string): string {
  const parsed = parseProjectName(projectName);
  if (parsed) {
    return getInstanceComposeDir(parsed.instanceId, parsed.version);
  }
  return process.cwd();
}

/**
 * Get the .env file of a CLI instance project, if it has one.
 */
export function getInstanceEnvFile(projectName: string): string | undefined {
  const parsed = parseProjectName(projectName);
  if (!parsed) {
    return undefined;
  }
  const envPath = getInstanceEnvPath(parsed.instanceId, parsed.version);
  return existsSync(envPath) ? envPath : undefined;
}

/**
 * Recursively copy a directory
 */
async function copyDirectory(src: string, dest: string): Promise<void> {
  await fs.mkdir(dest, { recursive: true });
  const entries = await fs.readdir(src, { withFileTypes: true });

  for (const entry of entries) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);

    if (entry.isDirectory()) {
      // Skip node_modules and other unnecessary directories
      if (["node_modules", ".git", "data", ".the_zoo"].includes(entry.name)) {
        continue;
      }
      await copyDirectory(srcPath, destPath);
    } else if (entry.isSymbolicLink()) {
      // Handle symlinks
      const linkTarget = await fs.readlink(srcPath);
      await fs.symlink(linkTarget, destPath);
    } else {
      await fs.copyFile(srcPath, destPath);
    }
  }
}

/**
 * Parse environment variables from --set-env option
 */
export function parseEnvVars(setEnv?: string[]): Record<string, string> {
  const envVars: Record<string, string> = {};

  if (setEnv && setEnv.length > 0) {
    for (const envVar of setEnv) {
      const [key, ...valueParts] = envVar.split("=");
      if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(key) || valueParts.length === 0) {
        console.error(chalk.red(`Invalid environment variable format: ${envVar}`));
        console.error(chalk.red("Expected format: KEY=value"));
        process.exit(1);
      }
      const value = valueParts.join("="); // Handle values with = in them
      envVars[key] = value;
    }
    console.log(chalk.gray(`Setting environment variables: ${Object.keys(envVars).join(", ")}`));
    logVerboseEnv(envVars);
  }

  return envVars;
}

/**
 * Prepare instance configuration
 */
export async function prepareInstance(options: CreateInstanceOptions): Promise<InstanceInfo> {
  logVerboseStep("Parsing environment variables from --set-env option");
  const envVars = parseEnvVars(options.setEnv);

  // Use provided instance ID or generate a unique one
  const instanceId = options.instanceId || Date.now().toString(36);
  logVerbose(`Instance ID: ${instanceId}`);

  // Generate project name
  logVerboseStep("Generating project name");
  const projectName = getProjectName(instanceId);
  logVerbose(`Project name: ${projectName}`);

  // Ensure directories exist for CLI runtime
  logVerboseStep("Ensuring CLI runtime directories exist");
  await ensureDirectories();

  // In development (ZOO_DEV=1) instances run from the repository sources.
  // In production the sources are copied into the instance directory for Docker access.
  const isDev = isDevMode();
  logVerbose(`Running in ${isDev ? "development" : "production"} mode`);

  const instanceDir = getInstanceDir(instanceId);
  const packagePath = getInstanceComposeDir(instanceId);
  await fs.mkdir(instanceDir, { recursive: true });

  if (!isDev) {
    // Check if sources already exist for this version/instance
    // We check for docker-compose.yaml specifically, not just the directory,
    // because the directory might exist with only a .env file from a failed previous run
    const composeFile = path.join(instanceDir, "docker-compose.yaml");
    const sourcesExist = await fs
      .access(composeFile)
      .then(() => true)
      .catch(() => false);

    if (!sourcesExist) {
      logVerboseStep(`Copying zoo sources to ${instanceDir}`);
      const sourcePackagePath = getZooPackagePath();
      await copyDirectory(sourcePackagePath, instanceDir);
      logVerbose(`Sources copied to ${instanceDir}`);
    } else {
      logVerbose(`Using existing sources at ${instanceDir}`);
    }
  }

  logVerbose(`Package path: ${packagePath}`);

  // An existing .env keeps its network configuration (including any --ip-base
  // given to create); only the proxy port and --set-env values are updated.
  const envPath = path.join(instanceDir, ".env");
  let fileEnv = await readEnvFile(envPath);
  if (fileEnv) {
    logVerboseStep(`Updating existing ${envPath}`);
    const updates = { ...envVars };
    if (options.port) {
      updates.ZOO_PROXY_PORT = options.port;
    }
    fileEnv = await updateEnvFile(envPath, updates);
  } else {
    logVerboseStep("Generating .env file with network configuration");
    await generateEnvFile(instanceDir, projectName, {
      ipBase: options.ipBase,
      port: options.port ?? DEFAULT_PROXY_PORT,
      env: envVars,
    });
    fileEnv = (await readEnvFile(envPath)) ?? {};
  }

  return {
    instanceId,
    projectName,
    packagePath,
    envPath,
    env: { COMPOSE_PROJECT_NAME: projectName, ...fileEnv },
  };
}

/**
 * Show dry run information
 */
export function showDryRunInfo(info: InstanceInfo): void {
  console.log(chalk.yellow("\n🔍 Dry run mode - showing what would be executed:\n"));

  console.log(chalk.cyan("Environment variables:"));
  for (const [key, value] of Object.entries(info.env)) {
    console.log(`  ${key}=${value}`);
  }

  console.log(chalk.cyan("Package directory:"));
  console.log(`  ${info.packagePath}`);
  console.log(chalk.cyan("Instance env file:"));
  console.log(`  ${info.envPath}`);

  console.log(chalk.cyan("\nCommands that would be run:"));
  console.log(`  1. docker compose up -d`);
  console.log(`  2. docker compose --profile on-demand up -d --no-start`);

  console.log(chalk.cyan("\nInstance details:"));
  console.log(`  Instance ID: ${info.instanceId}`);
  console.log(`  Project name: ${info.projectName}`);
  console.log(`  Network config: ${info.env.ZOO_SUBNET || "default"}`);
}

interface StartServicesOptions {
  quiet?: boolean;
}

/**
 * Start Zoo services for an instance
 */
export async function startServices(
  info: InstanceInfo,
  options: StartServicesOptions = {},
): Promise<void> {
  // Check Docker
  const dockerSpinner = yoctoSpinner({ text: "Checking Docker..." }).start();
  const dockerRunning = await checkDocker();

  if (!dockerRunning) {
    dockerSpinner.error("Docker is not running");
    console.error(chalk.red("Please start Docker and try again"));
    process.exit(1);
  }

  dockerSpinner.success("Docker is running");
  console.log(chalk.gray(`Instance ID: ${info.instanceId}`));
  console.log(chalk.gray(`Project: ${info.projectName}`));
  console.log(chalk.gray(`Subnet: ${info.env.ZOO_SUBNET || "default"}`));

  // Start services
  const startSpinner = yoctoSpinner({ text: "Starting Zoo services..." }).start();

  try {
    // Start core services first to ensure they get their fixed IPs
    // info.env is passed too so the instance's values win over the caller's shell environment
    const composeOptions = {
      cwd: info.packagePath,
      projectName: info.projectName,
      envFile: info.envPath,
      env: info.env,
      showCommand: false,
      progress: options.quiet ? ("quiet" as const) : undefined,
    };

    // Start core services first to ensure they get their fixed IPs
    await dockerCompose(["up", "-d"], composeOptions);

    // Then create the on-demand services (they won't start until requested)
    await dockerCompose(["--profile", "on-demand", "up", "-d", "--no-start"], composeOptions);

    startSpinner.success("Zoo services started");
  } catch (error) {
    startSpinner.error("Failed to start services");
    console.error(chalk.red((error as Error).message));
    process.exit(1);
  }
}
