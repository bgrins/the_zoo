import { execSync } from "node:child_process";

/**
 * Get the Docker Compose project name for the current development environment
 */
function getProjectName(): string {
  try {
    const result = execSync("docker compose config --format json", {
      encoding: "utf8",
      cwd: process.cwd(),
    });
    const config = JSON.parse(result);
    return config.name;
  } catch (_error) {
    throw new Error("Could not determine project name from `docker compose config --format json`");
  }
}

/**
 * Get the Docker network name for the zoo environment
 * @returns The network name in format: {PROJECT_NAME}_zoo-network
 */
export function getZooNetworkName(): string {
  const projectName = getProjectName();
  return `${projectName}_zoo-network`;
}
