#!/usr/bin/env tsx
// Captures the golden state of the compose project the cwd resolves to. See docs/golden-state.md.
// Usage: npm run golden:capture -- [--check] [service...]
//   --check  capture into a temp dir and diff it against the committed files

import { execFileSync, spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { type Capture, captures, DUMP_ENCODING, normalizeDump } from "./golden-state";

const repoRoot = join(dirname(fileURLToPath(import.meta.url)), "..");

function compose(args: string[]): string {
  return execFileSync("docker", ["compose", ...args], {
    encoding: DUMP_ENCODING,
    maxBuffer: 1 << 30,
    stdio: ["ignore", "pipe", "inherit"],
  });
}

function dump(capture: Capture): string {
  if (capture.engine === "mysql") {
    return compose([
      "exec",
      "-T",
      "-e",
      "MYSQL_PWD=password",
      "mysql",
      "mysqldump",
      "-h",
      "127.0.0.1",
      "-u",
      "root",
      "--skip-dump-date",
      capture.db,
    ]);
  }
  return compose([
    "exec",
    "-T",
    "postgres",
    "pg_dump",
    "--no-acl",
    "--restrict-key=zoo",
    ...capture.excludeTableData.map((table) => `--exclude-table-data=${table}`),
    "-U",
    capture.db.replace(/_db$/, "_user"),
    capture.db,
  ]);
}

const args = process.argv.slice(2);
const check = args.includes("--check");
const services = args.filter((arg) => arg !== "--check");
const unknown = services.filter((service) => !(service in captures));
if (unknown.length > 0) {
  console.error(
    `Unknown service(s): ${unknown.join(", ")}. Known: ${Object.keys(captures).join(", ")}`,
  );
  process.exit(1);
}
const selected = services.length > 0 ? services : Object.keys(captures);

const outDir = check ? mkdtempSync(join(tmpdir(), "golden-state-")) : repoRoot;
const written: string[] = [];
for (const service of selected) {
  const capture = captures[service];
  console.log(`Capturing ${service}...`);
  const file = join(outDir, capture.file);
  mkdirSync(dirname(file), { recursive: true });
  writeFileSync(file, normalizeDump(service, dump(capture)), DUMP_ENCODING);
  written.push(capture.file);

  for (const [container, from, to] of capture.files ?? []) {
    const dest = join(outDir, to);
    rmSync(dest, { recursive: true, force: true });
    mkdirSync(dirname(dest), { recursive: true });
    compose(["cp", `${container}:${from}`, dest]);
    written.push(to);
  }
}

if (check) {
  let changed = false;
  for (const path of written) {
    const diff = spawnSync("diff", ["-ru", join(repoRoot, path), join(outDir, path)], {
      stdio: "inherit",
    });
    changed ||= diff.status !== 0;
  }
  rmSync(outDir, { recursive: true, force: true });
  console.log(changed ? "\nCapture differs from the committed golden state." : "\nNo changes.");
  process.exit(changed ? 1 : 0);
}

const images = [...new Set(selected.flatMap((service) => captures[service].rebuild))].join(" ");
console.log(`
Captured: ${written.join(", ")}
The images bake this state in at build time. Rebuild them to load it:
  docker compose build ${images} && docker compose up -d ${images}`);
