import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import chalk from "chalk";
import yoctoSpinner from "yocto-spinner";
import { generateEnvFile } from "./network-env";
import { ensureDirectories, getProjectName, paths } from "./config";
import { checkDocker, dockerCompose } from "./docker";
import { logVerbose, logVerboseStep, logVerboseEnv } from "./verbose";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Get the default instance ID for the current CLI version
 */
export function getDefaultInstanceId(): string {
  return "default";
}

/**
 * Check if an instance exists (has been created)
 */
export async function instanceExists(instanceId: string): Promise<boolean> {
  const instanceDir = path.join(paths.runtime, instanceId, "zoo");
  try {
    await fs.access(instanceDir);
    return true;
  } catch {
    return false;
  }
}

interface CreateInstanceOptions {
  proxyPort: string;
  setEnv?: string[];
  dryRun?: boolean;
  instanceId?: string; // Optional - if not provided, generates a new one
  ipBase?: string; // Custom base IP (e.g., 172.30.100.1)
}

interface InstanceInfo {
  instanceId: string;
  projectName: string;
  zooSourcePath: string;
  env: Record<string, string>;
}

/**
 * Copy zoo sources to a working directory for development mode
 */
async function copyZooSources(srcDir: string, destDir: string): Promise<void> {
  // Ensure destination directory exists
  await fs.mkdir(destDir, { recursive: true });

  // List of directories and files to copy
  const itemsToCopy = ["docker-compose.yaml", "core", "sites"];

  // Copy each item
  for (const item of itemsToCopy) {
    const srcPath = path.join(srcDir, item);
    const destPath = path.join(destDir, item);

    try {
      const stats = await fs.stat(srcPath);
      if (stats.isDirectory()) {
        await copyDirectory(srcPath, destPath);
      } else {
        await fs.copyFile(srcPath, destPath);
      }
    } catch (error) {
      console.error(`Failed to copy ${item}:`, error);
      throw error;
    }
  }
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
      if (!key || valueParts.length === 0) {
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

  const env: Record<string, string> = {
    ZOO_PROXY_PORT: options.proxyPort,
    COMPOSE_PROJECT_NAME: projectName, // Pass project name to all containers
    ...envVars, // Include user-provided environment variables
  };

  // Ensure directories exist for CLI runtime
  logVerboseStep("Ensuring CLI runtime directories exist");
  await ensureDirectories();

  // Get the zoo directory
  // In development: copy sources to working directory to avoid modifying source files
  // In production: use the bundled zoo sources in dist/zoo
  const isDevelopment = !__dirname.includes("dist");
  logVerbose(`Running in ${isDevelopment ? "development" : "production"} mode`);

  let zooSourcePath: string;
  if (isDevelopment) {
    // Copy zoo sources to runtime directory to avoid modifying the source files
    logVerboseStep("Copying zoo sources to runtime directory");
    const devWorkingDir = path.join(paths.runtime, instanceId, "zoo");
    const rootDir = path.resolve(__dirname, "../../..");
    logVerbose(`Copying from ${rootDir} to ${devWorkingDir}`);
    await copyZooSources(rootDir, devWorkingDir);
    zooSourcePath = devWorkingDir;
  } else {
    // Production: use the bundled zoo directory
    // __dirname is in bin/, so we need to go up one level to package root
    zooSourcePath = path.resolve(__dirname, "../zoo");
  }
  logVerbose(`Zoo source path: ${zooSourcePath}`);

  // Generate .env file with high-range IP assignments
  logVerboseStep("Generating .env file with high-range IP assignments");
  const networkConfig = await generateEnvFile(zooSourcePath, projectName, {
    ipBase: options.ipBase,
  });

  // Add network IPs to environment
  env.ZOO_DNS_IP = networkConfig.dnsIP;
  env.ZOO_CADDY_IP = networkConfig.caddyIP;
  env.ZOO_PROXY_IP = networkConfig.proxyIP;
  env.ZOO_SUBNET = networkConfig.subnet;

  return {
    instanceId,
    projectName,
    zooSourcePath,
    env,
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

  console.log(chalk.cyan("Working directory for commands:"));
  console.log(`  ${info.zooSourcePath}`);

  console.log(chalk.cyan("\nCommands that would be run:"));
  console.log(`  1. docker compose up -d`);
  console.log(`  2. docker compose --profile on-demand up -d --no-start`);

  console.log(chalk.cyan("\nInstance details:"));
  console.log(`  Instance ID: ${info.instanceId}`);
  console.log(`  Project name: ${info.projectName}`);
  console.log(`  Network config: ${info.env.ZOO_SUBNET || "default"}`);
}

/**
 * Start Zoo services for an instance
 */
export async function startServices(info: InstanceInfo): Promise<void> {
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
    await dockerCompose("up -d", {
      cwd: info.zooSourcePath,
      projectName: info.projectName,
      env: info.env,
      showCommand: false,
    });

    // Then create the on-demand services (they won't start until requested)
    await dockerCompose("--profile on-demand up -d --no-start", {
      cwd: info.zooSourcePath,
      projectName: info.projectName,
      env: info.env,
      showCommand: false,
    });

    startSpinner.success("Zoo services started");
  } catch (error) {
    startSpinner.error("Failed to start services");
    console.error(chalk.red((error as Error).message));
    process.exit(1);
  }
}
