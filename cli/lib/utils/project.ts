import { getProjectName as getInstanceProjectName, sanitizeInstanceId } from "./config";
import { getRunningInstances } from "./docker";
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
  const matches = runningProjects.filter((p) => parseProjectName(p)?.instanceId === sanitized);
  const current = getInstanceProjectName(instanceId);
  return matches.includes(current) ? [current] : matches;
}

function listProjects(projects: string[]): string {
  return projects.map((p) => `  - ${parseProjectName(p)?.instanceId ?? p} (${p})`).join("\n");
}

/**
 * Get the Docker Compose project name for a Zoo instance
 * @param instanceId - Optional instance ID to look for
 * @returns The project name
 * @throws Error if no instances are running or instance not found
 */
export async function getProjectName(instanceId?: string): Promise<string> {
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

  if (runningProjects.length > 1) {
    throw new Error(
      `Multiple instances are running. Please specify an instance ID:\n${listProjects(runningProjects)}`,
    );
  }

  return runningProjects[0];
}
