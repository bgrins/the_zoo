#!/usr/bin/env tsx

import { execSync } from "node:child_process";
import { personas } from "./seed-data/personas";
import { apps } from "./seed-data/apps";

// Check if required containers are running
function checkContainers(): { missing: string[]; found: string[] } {
  const requiredContainers = ["postgres", "stalwart", "gitea-zoo", "auth-zoo", "miniflux"];

  const missing: string[] = [];
  const found: string[] = [];

  // Get list of running containers using docker compose
  try {
    const output = execSync(`docker compose ps --format json`, {
      encoding: "utf8",
    });

    const runningContainers = output
      .trim()
      .split("\n")
      .filter((line) => line)
      .map((line) => JSON.parse(line))
      .filter((container) => container.State === "running")
      .map((container) => container.Service);

    for (const container of requiredContainers) {
      if (runningContainers.includes(container)) {
        found.push(container);
      } else {
        missing.push(container);
      }
    }
  } catch {
    // If docker compose fails, all containers are considered missing
    missing.push(...requiredContainers);
  }

  return { missing, found };
}

async function main() {
  console.log("\n🌱 Zoo Seed Data Manager\n");

  // Check containers
  const { missing, found } = checkContainers();

  if (missing.length > 0) {
    console.error(`❌ Required containers are not running: ${missing.join(", ")}`);
    console.error("\nPlease start The Zoo first:");
    console.error("  npm start");
    console.error("\nOr start specific containers:");
    console.error(`  docker compose up -d ${missing.join(" ")}`);
    process.exit(1);
  }

  console.log(`✓ Found containers: ${found.join(", ")}\n`);

  // Seed each app with each persona
  for (const [appName, app] of Object.entries(apps)) {
    console.log(`\nSeeding ${appName}...`);

    for (const persona of personas) {
      try {
        await app.seed(persona);
      } catch (error) {
        console.error(`Failed to seed ${persona.username} in ${appName}:`, error);
      }
    }
  }

  console.log("\n✅ Seeding complete!\n");
}

// Run the main function
main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
