import { existsSync, readdirSync, statSync } from "node:fs";
import { join } from "node:path";
import { loadUniverseFromDisk, validateUniverse } from "./loader";
import { seeders } from "./seeders";
import type { UniverseData } from "./types";

/**
 * Load and populate a universe
 * @param universeId - The ID of the universe to load
 */
export async function loadUniverse(universeId: string): Promise<void> {
  console.log(`\n🌍 Loading universe: ${universeId}\n`);
  console.log("-".repeat(60));

  // Load universe data from disk
  let data: UniverseData;
  try {
    data = await loadUniverseFromDisk(universeId);
  } catch (error) {
    console.error(`\n❌ Failed to load universe: ${error}`);
    process.exit(1);
  }

  // Display universe info
  console.log(`\n📋 Universe: ${data.universe.name || data.universe.id}`);
  if (data.universe.description) {
    console.log(`   ${data.universe.description}`);
  }
  if (data.universe.version) {
    console.log(`   Version: ${data.universe.version}`);
  }
  console.log(`   Personas: ${data.universe.personas.join(", ")}`);

  // Validate universe
  try {
    validateUniverse(data);
  } catch (error) {
    console.error(`\n❌ Universe validation failed: ${error}`);
    process.exit(1);
  }

  console.log(`\n${"-".repeat(60)}`);

  // Run all seeders
  for (const seeder of seeders) {
    try {
      await seeder.load(data, data.universe.personas);
    } catch (error) {
      console.error(`\n❌ Seeder ${seeder.name} failed: ${error}`);
      // Continue with other seeders
    }
  }

  console.log(`\n${"-".repeat(60)}`);
  console.log(`\n✅ Universe "${universeId}" loaded successfully!`);
  console.log("\nYou can now:");
  console.log("  • Browse to http://snappymail.zoo and login");
  console.log("  • Browse to http://gitea.zoo and explore repositories");
  console.log("  • Use the populated environment for testing\n");
}

/**
 * List available universes
 */
export function listUniverses(): string[] {
  const universesDir = join(process.cwd(), "universes");
  if (!existsSync(universesDir)) {
    return [];
  }

  return readdirSync(universesDir).filter((name: string) => {
    const path = join(universesDir, name);
    return statSync(path).isDirectory() && existsSync(join(path, "universe.json"));
  });
}
