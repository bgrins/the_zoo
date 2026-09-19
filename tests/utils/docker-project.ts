import { execSync } from "node:child_process";

let projectName: string | undefined;

/**
 * The Docker Compose project name for the environment under test. Several environments
 * (main, fresh, CLI instances) can run side by side, so container lookups filter on it.
 */
export function getProjectName(): string {
  if (!projectName) {
    try {
      projectName = JSON.parse(
        execSync("docker compose config --format json", { encoding: "utf8" }),
      ).name as string;
    } catch (_error) {
      throw new Error(
        "Could not determine project name from `docker compose config --format json`",
      );
    }
  }
  return projectName;
}

/** `docker ps` filter selecting only this project's containers */
export function projectFilter(): string {
  return `--filter "label=com.docker.compose.project=${getProjectName()}"`;
}

/**
 * Get the Docker network name for the zoo environment
 * @returns The network name in format: {PROJECT_NAME}_zoo-network
 */
export function getZooNetworkName(): string {
  return `${getProjectName()}_zoo-network`;
}
