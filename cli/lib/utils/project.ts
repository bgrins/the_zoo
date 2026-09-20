import path from "node:path";
import { getZooSourceRoot, instanceProjectName, sanitizeInstanceId } from "./config";
import { getComposeConfig, getRunningInstances, isRunningFromZooRepository } from "./docker";
import { parseProjectName } from "./instance";

/**
 * Find the running projects for an --instance value: either an exact project name
 * or a CLI instance with exactly that ID. The current CLI version wins over others.
 */
export function findInstanceProjects(runningProjects: string[], instanceId: string): string[] {
  if (runningProjects.includes(instanceId)) {
    return [instanceId];
  }
  const sanitized = sanitizeInstanceId(instanceId);
  const matches = runningProjects.filter((p) => {
    const parsed = parseProjectName(p);
    return parsed !== null && sanitizeInstanceId(parsed.instanceId) === sanitized;
  });
  const current = instanceProjectName(instanceId);
  return matches.includes(current) ? [current] : matches;
}

export function listProjects(projects: string[]): string {
  return projects.map((p) => `  - ${parseProjectName(p)?.instanceId ?? p} (${p})`).join("\n");
}

/**
 * The project compose runs this checkout as: its configured name, else the directory's
 * name as compose normalizes it
 */
export async function checkoutProject(): Promise<string> {
  const root = getZooSourceRoot();
  const { name } = await getComposeConfig({ cwd: root });
  return (
    name ||
    path
      .basename(root)
      .toLowerCase()
      .replace(/[^a-z0-9_-]/g, "")
      .replace(/^[^a-z0-9]+/, "")
  );
}

/**
 * Get the Docker Compose project name for a Zoo instance
 * @param instanceId - Optional instance ID to look for
 * @param options.preferCheckout - Without an instance ID, in development from the repository,
 *   use this checkout's own project rather than whichever one is running
 * @returns The project name
 * @throws Error if no instances are running or instance not found
 */
export async function findRunningProject(
  instanceId?: string,
  options: { preferCheckout?: boolean } = {},
): Promise<string> {
  const runningProjects = await getRunningInstances();

  if (runningProjects.length === 0) {
    throw new Error("No Zoo CLI instances are currently running");
  }

  if (instanceId) {
    const matches = findInstanceProjects(runningProjects, instanceId);
    if (matches.length === 0) {
      throw new Error(`Instance "${instanceId}" not found`);
    }
    if (matches.length > 1) {
      throw new Error(
        `Instance "${instanceId}" matches several projects; pass the project name instead:\n${listProjects(matches)}`,
      );
    }
    return matches[0];
  }

  if (options.preferCheckout && isRunningFromZooRepository()) {
    const own = await checkoutProject();
    if (!runningProjects.includes(own)) {
      throw new Error(
        `${own}, this checkout's project, is not running. Pass --instance to pick one of:\n${listProjects(runningProjects)}`,
      );
    }
    return own;
  }

  if (runningProjects.length > 1) {
    throw new Error(
      `Multiple instances are running. Please specify an instance ID:\n${listProjects(runningProjects)}`,
    );
  }

  return runningProjects[0];
}
