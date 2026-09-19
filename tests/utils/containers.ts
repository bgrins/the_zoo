import { execSync } from "node:child_process";

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
