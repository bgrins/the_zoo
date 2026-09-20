import { existsSync } from "node:fs";
import fs from "node:fs/promises";
import { homedir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import packageJson from "../../package.json" with { type: "json" };

const isDev = process.env.ZOO_DEV === "1";
const moduleDir = path.dirname(fileURLToPath(import.meta.url));

/**
 * Walk up from this module to the first directory containing `marker`.
 * Works for both the tsx sources (cli/lib/utils) and the bundle (dist/bin or <pkg>/bin).
 */
function findAncestorWith(marker: string): string | null {
  let dir = moduleDir;
  while (true) {
    if (existsSync(path.join(dir, marker))) {
      return dir;
    }
    const parent = path.dirname(dir);
    if (parent === dir) {
      return null;
    }
    dir = parent;
  }
}

/**
 * Directory containing the Zoo docker-compose.yaml and sources.
 * Development (ZOO_DEV=1): the repository root.
 * Production: the zoo/ directory shipped next to bin/ in the npm package.
 */
export function getZooSourceRoot(): string {
  if (isDev) {
    const repoRoot = findAncestorWith("docker-compose.yaml");
    if (!repoRoot) {
      throw new Error(`Could not find the Zoo repository root above ${moduleDir}`);
    }
    return repoRoot;
  }
  const packageRoot = findAncestorWith(path.join("zoo", "docker-compose.yaml"));
  if (!packageRoot) {
    throw new Error(`Could not find the packaged Zoo sources above ${moduleDir}`);
  }
  return path.join(packageRoot, "zoo");
}

// THE_ZOO_HOME overrides the state directory (used by tests). Otherwise development
// uses <repo>/.the_zoo and production uses ~/.the_zoo.
const ZOO_HOME = process.env.THE_ZOO_HOME
  ? path.resolve(process.env.THE_ZOO_HOME)
  : isDev
    ? path.join(getZooSourceRoot(), ".the_zoo")
    : path.join(homedir(), ".the_zoo");

export const paths = {
  home: ZOO_HOME,
  runtime: path.join(ZOO_HOME, "runtime"),
  config: path.join(ZOO_HOME, "config.json"),
  versions: path.join(ZOO_HOME, "versions"),
  instances: path.join(ZOO_HOME, "instances"),
};

/**
 * Ensure all required directories exist
 */
export async function ensureDirectories(): Promise<void> {
  await fs.mkdir(paths.runtime, { recursive: true });
}

/**
 * The form of an instance ID used inside its Docker project name
 */
export function sanitizeInstanceId(instanceId: string): string {
  // Replace dots and special chars with hyphens for Docker compatibility
  return instanceId.replace(/[^a-zA-Z0-9]/g, "-");
}

/**
 * Get Docker project name for an instance
 */
export function instanceProjectName(instanceId: string): string {
  const versionSanitized = packageJson.version.replace(/\./g, "-");

  return `thezoo-cli-instance-${sanitizeInstanceId(instanceId)}-v${versionSanitized}`;
}

// Labels the Docker resources of an instance that outlast its projects
export const INSTANCE_LABEL = "zoo.instance";

/**
 * The volume an instance keeps its snapshots in. Its name has no version, so the instance's
 * projects under every CLI version share it, and it is external, so compose never removes it.
 */
export function instanceSnapshotsVolume(instanceId: string): string {
  return `thezoo-cli-instance-${sanitizeInstanceId(instanceId)}_zoo_snapshots`;
}
