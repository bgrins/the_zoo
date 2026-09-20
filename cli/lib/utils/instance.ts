import { existsSync } from "node:fs";
import fs from "node:fs/promises";
import path from "node:path";
import chalk from "chalk";
import packageJson from "../../package.json" with { type: "json" };
import {
  allocateNetwork,
  allocateProjectPublicSubnet,
  applyEnvUpdates,
  findSubnetConflicts,
  getDockerSubnets,
  isAllocatedNetwork,
  legacyIpBase,
  networkEnv,
  parseEnvContent,
  readEnvContent,
  readEnvFile,
  renderEnvFile,
} from "./network-env";
import { ensureDirectories, getProjectName, getZooSourceRoot, paths } from "./config";
import { checkDocker, dockerCompose, getPublishedProxyPort } from "./docker";
import { CliError, errorMessage } from "./errors";
import { startSpinner } from "./output";
import { logVerbose, logVerboseStep, logVerboseEnv } from "./verbose";

export const DEFAULT_PROXY_PORT = "3128";

/**
 * Parse a TCP port given as `name` (e.g. "--port"): an integer from 1 to 65535
 */
export function parsePort(value: string, name: string): number {
  const port = Number(value);
  if (!/^[1-9]\d*$/.test(value) || port > 65535) {
    throw new CliError(`Invalid ${name}: "${value}"`, {
      hint: "Expected an integer from 1 to 65535",
    });
  }
  return port;
}

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
    throw new CliError(`Invalid instance ID: "${instanceId}"`);
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
  dryRun?: boolean; // Compute the instance env without writing files
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
 * For other projects (e.g., "the_zoo"): the repository in development, else process.cwd()
 */
export function getInstanceSourcePath(projectName: string): string {
  const parsed = parseProjectName(projectName);
  if (parsed) {
    return getInstanceComposeDir(parsed.instanceId, parsed.version);
  }
  return isDevMode() ? getZooSourceRoot() : process.cwd();
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
 * Proxy port of a project: the port its proxy publishes, else the one saved in its
 * instance .env, else the default
 */
export async function getProxyPort(projectName: string): Promise<string> {
  const published = await getPublishedProxyPort(projectName);
  if (published) {
    return published;
  }
  const envFile = getInstanceEnvFile(projectName);
  const env = envFile ? await readEnvFile(envFile) : null;
  return env?.ZOO_PROXY_PORT || DEFAULT_PROXY_PORT;
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
 * Validate the settings a start writes into the instance .env: the --port value and the
 * --set-env values, which may set the proxy port too. Returns the --set-env variables.
 */
export function parseInstanceSettings(options: {
  port?: string;
  setEnv?: string[];
}): Record<string, string> {
  if (options.port !== undefined) {
    parsePort(options.port, "--port");
  }

  const envVars: Record<string, string> = {};
  for (const envVar of options.setEnv ?? []) {
    const [key, ...valueParts] = envVar.split("=");
    if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(key) || valueParts.length === 0) {
      throw new CliError(`Invalid environment variable format: ${envVar}`, {
        hint: "Expected format: KEY=value",
      });
    }
    const value = valueParts.join("="); // Handle values with = in them
    envVars[key] = value;
  }
  if (envVars.ZOO_PROXY_PORT !== undefined) {
    parsePort(envVars.ZOO_PROXY_PORT, "--set-env ZOO_PROXY_PORT");
  }
  return envVars;
}

/**
 * Content for an existing instance .env with the proxy port and --set-env values applied,
 * and the project name and proxy port filled in if an older CLI left them out. Unless it
 * came from --ip-base, the saved network is reallocated when it now overlaps another Docker
 * network (e.g. one created while the instance was stopped), or when this CLI would not
 * have picked it (an older CLI's .env). An --ip-base network keeps its /16 and only gets a
 * new public /30 when that is missing or taken.
 */
async function updateInstanceEnv(
  instanceId: string,
  projectName: string,
  content: string,
  envVars: Record<string, string>,
  port?: string,
): Promise<string> {
  const saved = parseEnvContent(content);
  const settings: Record<string, string> = {};
  if (saved.COMPOSE_PROJECT_NAME !== projectName) {
    settings.COMPOSE_PROJECT_NAME = projectName;
  }
  const proxyPort = port || saved.ZOO_PROXY_PORT || DEFAULT_PROXY_PORT;
  if (proxyPort !== saved.ZOO_PROXY_PORT) {
    settings.ZOO_PROXY_PORT = proxyPort;
  }

  const usedSubnets = await getDockerSubnets(projectName);
  const conflicts = findSubnetConflicts(saved, usedSubnets);
  const ipBase = saved.ZOO_IP_BASE || (isAllocatedNetwork(saved) ? null : legacyIpBase(saved));
  if (ipBase) {
    if (!saved.ZOO_IP_BASE) {
      settings.ZOO_IP_BASE = ipBase;
    }
    if (conflicts.includes(saved.ZOO_SUBNET)) {
      throw new CliError(
        `Subnet ${saved.ZOO_SUBNET} of instance "${instanceId}" (from --ip-base ${ipBase}) overlaps an existing Docker network`,
        {
          hint: `Remove it with "the_zoo clean --instance ${instanceId}", then create a new instance with a different --ip-base`,
        },
      );
    }
    if (!saved.ZOO_PUBLIC_SUBNET || conflicts.includes(saved.ZOO_PUBLIC_SUBNET)) {
      settings.ZOO_PUBLIC_SUBNET = allocateProjectPublicSubnet(
        projectName,
        usedSubnets,
        saved.ZOO_SUBNET,
      );
      console.log(
        chalk.yellow(
          `Public subnet ${saved.ZOO_PUBLIC_SUBNET ?? "(none)"} of instance "${instanceId}" is missing or taken; moving it to ${settings.ZOO_PUBLIC_SUBNET}`,
        ),
      );
    }
  } else if (conflicts.length > 0 || !isAllocatedNetwork(saved)) {
    const network = await allocateNetwork(projectName, { usedSubnets });
    const reason =
      conflicts.length > 0
        ? `Subnet ${conflicts.join(", ")} of instance "${instanceId}" overlaps another Docker network`
        : `Network ${saved.ZOO_SUBNET ?? "(none)"}, public ${saved.ZOO_PUBLIC_SUBNET ?? "(none)"} of instance "${instanceId}" was saved by an older CLI`;
    console.log(
      chalk.yellow(`${reason}; moving it to ${network.subnet} (public ${network.publicSubnet})`),
    );
    Object.assign(settings, networkEnv(network));
  }

  return applyEnvUpdates(applyEnvUpdates(content, settings, "# Instance configuration"), envVars);
}

// Instance .env variables that belong to one CLI version rather than to the user. Compose
// settings and the image tag pin the old version's project and images.
const VERSION_KEYS = new Set([
  "ZOO_IMAGE_TAG",
  "ZOO_SUBNET",
  "ZOO_PUBLIC_SUBNET",
  "ZOO_DNS_IP",
  "ZOO_CADDY_IP",
  "ZOO_PROXY_IP",
  "ZOO_IP_BASE",
]);
const isVersionKey = (key: string) => key.startsWith("COMPOSE_") || VERSION_KEYS.has(key);

function parseVersion(version: string): number[] | null {
  const match = version.match(/^v?(\d+)\.(\d+)\.(\d+)/);
  return match ? match.slice(1).map(Number) : null;
}

function compareVersions(a: number[], b: number[]): number {
  const index = a.findIndex((part, i) => part !== b[i]);
  return index === -1 ? 0 : a[index] - b[index];
}

/**
 * The user's settings (proxy port, --set-env values) in the .env of the same instance
 * under the newest older CLI version. Production instance directories are per version,
 * so after an upgrade that is where they are.
 */
async function previousVersionSettings(
  instanceId: string,
): Promise<{ version: string; settings: Record<string, string> } | null> {
  const current = parseVersion(packageJson.version);
  if (isDevMode() || !current) {
    return null;
  }

  let versions: string[];
  try {
    versions = await fs.readdir(paths.instances);
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") {
      return null;
    }
    throw error;
  }

  const previous = versions
    .map((version) => ({ version, parsed: parseVersion(version) }))
    .filter(
      (entry): entry is { version: string; parsed: number[] } =>
        entry.parsed !== null &&
        compareVersions(entry.parsed, current) < 0 &&
        existsSync(getInstanceEnvPath(instanceId, entry.version)),
    )
    .sort((a, b) => compareVersions(b.parsed, a.parsed))[0];
  if (!previous) {
    return null;
  }

  const env = (await readEnvFile(getInstanceEnvPath(instanceId, previous.version))) ?? {};
  const settings = Object.fromEntries(Object.entries(env).filter(([key]) => !isVersionKey(key)));
  return { version: previous.version, settings };
}

/**
 * Copy the packaged Zoo sources into a production instance directory, unless a
 * previous run already did. The directory may hold only a .env from a failed run,
 * so check for docker-compose.yaml.
 */
async function ensureInstanceSources(instanceDir: string): Promise<void> {
  if (existsSync(path.join(instanceDir, "docker-compose.yaml"))) {
    logVerbose(`Using existing sources at ${instanceDir}`);
    return;
  }
  logVerboseStep(`Copying zoo sources to ${instanceDir}`);
  await copyDirectory(getZooPackagePath(), instanceDir);
}

/**
 * Prepare instance configuration: its .env and, in production, its copy of the sources.
 * With dryRun nothing is written; the returned env is what would be written.
 */
export async function prepareInstance(options: CreateInstanceOptions): Promise<InstanceInfo> {
  logVerboseStep("Parsing environment variables from --set-env option");
  const envVars = parseInstanceSettings(options);
  if (Object.keys(envVars).length > 0) {
    console.log(chalk.gray(`Setting environment variables: ${Object.keys(envVars).join(", ")}`));
    logVerboseEnv(envVars);
  }

  // Use provided instance ID or generate a unique one
  const instanceId = options.instanceId || Date.now().toString(36);
  logVerbose(`Instance ID: ${instanceId}`);

  const projectName = getProjectName(instanceId);
  logVerbose(`Project name: ${projectName}`);

  // In development (ZOO_DEV=1) instances run from the repository sources.
  // In production the sources are copied into the instance directory for Docker access.
  const isDev = isDevMode();
  logVerbose(`Running in ${isDev ? "development" : "production"} mode`);

  const instanceDir = getInstanceDir(instanceId);
  const packagePath = getInstanceComposeDir(instanceId);
  const envPath = path.join(instanceDir, ".env");
  logVerbose(`Package path: ${packagePath}`);

  // An existing .env keeps its network configuration (including any --ip-base given to
  // create) unless updateInstanceEnv has to move it. A new one starts from the settings
  // the instance had under the previous CLI version.
  const savedContent = await readEnvContent(envPath);
  let content: string;
  if (savedContent !== null) {
    logVerboseStep(`Updating existing ${envPath}`);
    content = await updateInstanceEnv(instanceId, projectName, savedContent, envVars, options.port);
  } else {
    logVerboseStep("Generating .env file with network configuration");
    const previous = await previousVersionSettings(instanceId);
    const { ZOO_PROXY_PORT: previousPort, ...previousSettings } = previous?.settings ?? {};
    if (previous) {
      const kept = Object.entries(previous.settings)
        .filter(([key, value]) => value && !(key in envVars))
        .filter(([key]) => !(key === "ZOO_PROXY_PORT" && options.port))
        .map(([key]) => key);
      if (kept.length > 0) {
        console.log(
          chalk.gray(
            `Keeping ${kept.join(", ")} of instance "${instanceId}" from ${previous.version}`,
          ),
        );
      }
    }
    const rendered = await renderEnvFile(projectName, {
      ipBase: options.ipBase,
      port: options.port || previousPort || DEFAULT_PROXY_PORT,
      env: { ...previousSettings, ...envVars },
    });
    content = rendered.content;
    console.log(
      chalk.gray(`Network: ${rendered.network.subnet}, public ${rendered.network.publicSubnet}`),
    );
  }

  if (!options.dryRun) {
    await ensureDirectories();
    await fs.mkdir(instanceDir, { recursive: true });
    if (!isDev) {
      await ensureInstanceSources(instanceDir);
    }
    await fs.writeFile(envPath, content, "utf-8");
  }

  return {
    instanceId,
    projectName,
    packagePath,
    envPath,
    env: parseEnvContent(content),
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
  console.log(chalk.cyan("Instance env file (not written in dry run):"));
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
  const dockerSpinner = startSpinner("Checking Docker...");
  const dockerRunning = await checkDocker();

  if (!dockerRunning) {
    dockerSpinner.error("Docker is not running");
    throw new CliError("Please start Docker and try again");
  }

  dockerSpinner.success("Docker is running");
  console.log(chalk.gray(`Instance ID: ${info.instanceId}`));
  console.log(chalk.gray(`Project: ${info.projectName}`));
  console.log(chalk.gray(`Subnet: ${info.env.ZOO_SUBNET || "default"}`));

  // Start services
  const servicesSpinner = startSpinner("Starting Zoo services...");

  try {
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

    servicesSpinner.success("Zoo services started");
  } catch (error) {
    servicesSpinner.error("Failed to start services");
    throw new CliError(errorMessage(error));
  }
}
