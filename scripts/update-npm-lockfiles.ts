#!/usr/bin/env -S npx tsx

/**
 * Update the npm lockfiles of the apps in sites/apps and core, each in a container of the
 * Node image its Dockerfile uses, with --ignore-scripts. No node_modules reach the host.
 *
 * Usage: ./update-npm-lockfiles.ts [--lockfile-only]
 *   --lockfile-only: Only update lockfiles without updating package.json versions
 */

import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

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

const appDirs = ["sites/apps", "core"].flatMap((parent) =>
  fs
    .readdirSync(path.join(ROOT, parent))
    .map((name) => path.join(ROOT, parent, name))
    .filter((dir) => fs.existsSync(path.join(dir, "package.json"))),
);

/** The node image the app's Dockerfile builds from */
function nodeImage(dir: string): string {
  const dockerfile = path.join(dir, "Dockerfile");
  const content = fs.existsSync(dockerfile) ? fs.readFileSync(dockerfile, "utf8") : "";
  const image = content.match(/^FROM\s+(?:--platform=\S+\s+)?(node:\S+)/im)?.[1];
  if (!image) {
    throw new Error(`${path.relative(ROOT, dockerfile)} has no FROM node:<tag> line`);
  }
  return image;
}

const lockfileInstall = "npm install --package-lock-only --ignore-scripts";

for (const dir of appDirs) {
  const appName = path.basename(dir);
  console.log(`📦 Updating ${appName}...`);

  try {
    const image = nodeImage(dir);
    const script = lockfileOnly
      ? lockfileInstall
      : `npx --yes npm-check-updates -u && ${lockfileInstall}`;
    // As the host user, so the files it writes stay the user's
    const user =
      process.getuid && process.getgid ? ["--user", `${process.getuid()}:${process.getgid()}`] : [];
    execFileSync(
      "docker",
      [
        "run",
        "--rm",
        ...user,
        "-e",
        "npm_config_cache=/tmp/npm-cache",
        "-v",
        `${dir}:/app`,
        "-w",
        "/app",
        image,
        "sh",
        "-c",
        script,
      ],
      { stdio: "inherit" },
    );

    console.log(`✅ Updated ${appName} (${image})`);
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
