import { getRunningInstances } from "./docker";

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
    const projectName = runningProjects.find((p) => p.includes(instanceId));
    if (!projectName) {
      throw new Error(`Instance "${instanceId}" not found`);
    }
    return projectName;
  }

  if (runningProjects.length > 1) {
    throw new Error(
      "Multiple instances are running. Please specify an instance ID:\n" +
        runningProjects
          .map((p) => {
            const match = p.match(/^thezoo-cli-instance-(.+?)(?:-subnet\d+)?$/);
            return `  - ${match?.[1] || p}`;
          })
          .join("\n"),
    );
  }

  return runningProjects[0];
}
