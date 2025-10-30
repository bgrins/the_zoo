#!/usr/bin/env tsx

import { listUniverses, loadUniverse } from "./universes/index";

/**
 * CLI script to load a universe
 */
async function main() {
  const args = process.argv.slice(2);

  // Show help
  if (args.length === 0 || args.includes("--help") || args.includes("-h")) {
    console.log(`
Usage: npm run universe:load <universe-id>

Load a universe into The Zoo environment.

Arguments:
  <universe-id>    ID of the universe to load (e.g., "default")

Options:
  --list           List available universes
  --help, -h       Show this help message

Examples:
  npm run universe:load default
  npm run universe:load -- --list
    `);
    process.exit(0);
  }

  // List universes
  if (args.includes("--list")) {
    const universes = listUniverses();
    if (universes.length === 0) {
      console.log("\nNo universes found in universes/ directory.\n");
    } else {
      console.log("\nAvailable universes:\n");
      for (const id of universes) {
        console.log(`  • ${id}`);
      }
      console.log();
    }
    process.exit(0);
  }

  // Load universe
  const universeId = args[0];
  await loadUniverse(universeId);
}

main().catch((error) => {
  console.error(`\n❌ Error: ${error.message}\n`);
  process.exit(1);
});
