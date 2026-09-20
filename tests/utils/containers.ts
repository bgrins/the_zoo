import { execSync } from "node:child_process";
import { projectFilter } from "./docker-project";

/**
 * Health of a compose service's container ("healthy", "starting", "unhealthy", or "" when
 * it has no healthcheck). Throws if the container isn't running.
 */
export function serviceHealth(service: string): string {
  const output = execSync(`docker compose ps --format json ${service}`, {
    encoding: "utf8",
  }).trim();
  if (!output) {
    throw new Error(`${service} is not running`);
  }
  return (JSON.parse(output.split("\n")[0]) as { Health: string }).Health;
}

export interface ContainerState {
  // created, running, exited, ...
  status: string;
  // "" without a healthcheck
  health: string;
}

/**
 * State of a compose service's container in the project under test, running or not;
 * undefined when the service has no container
 */
export function serviceState(service: string): ContainerState | undefined {
  const id = execSync(
    `docker ps -a -q ${projectFilter()} --filter "label=com.docker.compose.service=${service}"`,
    { encoding: "utf8" },
  )
    .trim()
    .split("\n")[0];
  if (!id) {
    return undefined;
  }
  const state = JSON.parse(
    execSync(`docker inspect --format '{{json .State}}' ${id}`, { encoding: "utf8" }),
  ) as { Status: string; Health?: { Status: string } };
  return { status: state.Status, health: state.Health?.Status ?? "" };
}

/** Status (created, running, exited, ...) of each service of the project under test that has a container */
export function serviceStatuses(): Map<string, string> {
  const output = execSync(
    `docker ps -a ${projectFilter()} --format '{{.Label "com.docker.compose.service"}}\t{{.State}}'`,
    { encoding: "utf8" },
  );
  return new Map(
    output
      .split("\n")
      .filter(Boolean)
      .map((line) => line.split("\t") as [string, string]),
  );
}
