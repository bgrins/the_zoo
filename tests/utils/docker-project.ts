import { execSync } from "node:child_process";

let projectName: string | undefined;

/**
 * The Docker Compose project name for the environment under test. Several environments
 * (main, fresh, CLI instances) can run side by side, so container lookups filter on it.
 */
export function composeProjectName(): string {
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

/**
 * `docker ps` filter selecting only the containers compose created for this project. A
 * container run by hand from a compose-built image inherits its project label, not oneoff.
 */
export function projectFilter(): string {
  return `--filter "label=com.docker.compose.project=${composeProjectName()}" --filter "label=com.docker.compose.oneoff=False"`;
}

/**
 * Get the Docker network name for the zoo environment
 * @returns The network name in format: {PROJECT_NAME}_zoo-network
 */
export function getZooNetworkName(): string {
  return `${composeProjectName()}_zoo-network`;
}
