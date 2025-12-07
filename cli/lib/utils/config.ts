import fs from "node:fs/promises";
import { homedir } from "node:os";
import path from "node:path";
import packageJson from "../../package.json" with { type: "json" };

// Use local .the_zoo directory during development (ZOO_DEV=1), ~/.the_zoo in production
const isDev = process.env.ZOO_DEV === "1";
const __dirname = path.dirname(new URL(import.meta.url).pathname);
const ZOO_HOME = isDev
  ? path.resolve(__dirname, "../../.the_zoo")
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
 * Get Docker project name for an instance
 */
export function getProjectName(instanceId: string): string {
  // Replace dots and special chars with hyphens for Docker compatibility
  const sanitized = instanceId.replace(/[^a-zA-Z0-9]/g, "-");
  const versionSanitized = packageJson.version.replace(/\./g, "-");

  return `thezoo-cli-instance-${sanitized}-v${versionSanitized}`;
}
