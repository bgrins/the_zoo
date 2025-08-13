#!/usr/bin/env -S npx tsx

/**
 * Safe npm install script for updating lockfiles in all apps
 * Uses Docker container with --ignore-scripts for security
 *
 * Usage: ./update-npm-lockfiles.ts [--lockfile-only]
 *   --lockfile-only: Only update lockfiles without updating package.json versions
 */

import { execSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Parse command line arguments
const args = process.argv.slice(2);
let lockfileOnly = false;

for (const arg of args) {
  switch (arg) {
    case "--lockfile-only":
      lockfileOnly = true;
      break;
    default:
      console.error(`Unknown option: ${arg}`);
      console.error("Usage: ./update-npm-lockfiles.ts [--lockfile-only]");
      process.exit(1);
  }
}

if (lockfileOnly) {
  console.log("Updating npm lockfiles in Docker containers...");
} else {
  console.log("Updating all packages to latest versions in package.json files...");
}
console.log();

// Find all directories with package.json files
const patterns = ["sites/apps/*/package.json", "core/*/package.json"];
const packageJsonFiles: string[] = [];

for (const pattern of patterns) {
  const baseDir = path.join(__dirname, "..");
  const parts = pattern.split("/");
  const wildcard = parts.indexOf("*");

  if (wildcard !== -1) {
    const searchDir = path.join(baseDir, ...parts.slice(0, wildcard));
    const fileName = parts[wildcard + 1];

    if (fs.existsSync(searchDir)) {
      const dirs = fs.readdirSync(searchDir);
      for (const dir of dirs) {
        const packageJsonPath = path.join(searchDir, dir, fileName);
        if (fs.existsSync(packageJsonPath)) {
          packageJsonFiles.push(packageJsonPath);
        }
      }
    }
  }
}

// Process each package.json
for (const packageJsonPath of packageJsonFiles) {
  const dir = path.dirname(packageJsonPath);
  const appName = path.basename(dir);

  console.log(`📦 Updating ${appName}...`);

  try {
    if (lockfileOnly) {
      // Just update lockfile with existing package.json versions
      execSync(
        `docker run --rm -v "${path.resolve(dir)}:/app" -w /app node:20-alpine npm install --ignore-scripts`,
        { stdio: "inherit" },
      );
    } else {
      // First update package.json with latest versions using npm-check-updates
      execSync(
        `docker run --rm -v "${path.resolve(dir)}:/app" -w /app node:20-alpine sh -c "npm install -g npm-check-updates && ncu -u"`,
        { stdio: "inherit" },
      );

      // Then install with the updated versions
      execSync(
        `docker run --rm -v "${path.resolve(dir)}:/app" -w /app node:20-alpine npm install --ignore-scripts`,
        { stdio: "inherit" },
      );
    }

    console.log(`✅ Updated ${appName}`);
    console.log();
  } catch (error) {
    console.error(`❌ Failed to update ${appName}`);
    console.error(error);
    process.exit(1);
  }
}

if (lockfileOnly) {
  console.log("🎉 All lockfiles updated safely!");
} else {
  console.log("🎉 All packages updated to latest versions!");
}
