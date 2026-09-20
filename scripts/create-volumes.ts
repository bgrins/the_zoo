#!/usr/bin/env -S npx tsx

/**
 * Create the volumes docker-compose.yaml declares external (the snapshots volume), which
 * `docker compose up` needs but never creates. The arguments are docker compose options,
 * e.g. --env-file .env.fresh.
 * Usage: tsx scripts/create-volumes.ts [docker compose options]
 */

import { execFileSync } from "node:child_process";

const config = JSON.parse(
  execFileSync("docker", ["compose", ...process.argv.slice(2), "config", "--format", "json"], {
    encoding: "utf-8",
  }),
);
for (const [key, volume] of Object.entries<{ name?: string; external?: unknown }>(
  config.volumes ?? {},
)) {
  if (volume.external) {
    execFileSync("docker", ["volume", "create", volume.name ?? key], { stdio: "ignore" });
  }
}
