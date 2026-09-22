#!/usr/bin/env -S npx tsx

/**
 * Checks that the CLI about to be published is the tagged release: no tracked file differs
 * from HEAD (after build:cli regenerated the config), HEAD is the v<version> tag's commit,
 * and, when gh is installed and logged in, both release-smoke-test legs passed on it.
 */

import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
// The legs of docker-publish.yml's release-smoke-test job
const SMOKE_TESTS = ["release-smoke-test (amd64)", "release-smoke-test (arm64)"];
const GITHUB_ACTIONS_APP_ID = "15368";

const readJson = (file: string) => JSON.parse(fs.readFileSync(path.join(ROOT, file), "utf8"));
const git = (...args: string[]) =>
  execFileSync("git", args, { cwd: ROOT, encoding: "utf8" }).trimEnd();

function fail(message: string): never {
  console.error(`✗ ${message}`);
  process.exit(1);
}

const tag = `v${readJson("cli/package.json").version}`;

const changed = git("status", "--porcelain", "--untracked-files=no");
if (changed) {
  fail(`Tracked files differ from HEAD:\n${changed}`);
}

let tagged: string;
try {
  tagged = git("rev-parse", "--verify", "--quiet", `${tag}^{commit}`);
} catch {
  fail(`No tag ${tag}; tag the release commit and push the tag first`);
}
const head = git("rev-parse", "HEAD");
if (head !== tagged) {
  fail(`HEAD (${head}) is not ${tag} (${tagged})`);
}
console.log(`✓ HEAD is ${tag}, with no local changes`);

const repository = new URL(readJson("package.json").repository.url).pathname
  .slice(1)
  .replace(/\.git$/, "");

function smokeTest(name: string): string {
  return execFileSync(
    "gh",
    [
      "api",
      "-X",
      "GET",
      `repos/${repository}/commits/${tagged}/check-runs`,
      "-f",
      `check_name=${name}`,
      "-f",
      `app_id=${GITHUB_ACTIONS_APP_ID}`,
      "--jq",
      '.check_runs[0] | select(.) | "\\(.status) \\(.conclusion)"',
    ],
    { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] },
  ).trim();
}

let results: string[];
try {
  results = SMOKE_TESTS.map(smokeTest);
} catch (error) {
  const { code, stderr } = error as NodeJS.ErrnoException & { stderr?: string };
  if (code === "ENOENT" || stderr?.includes("gh auth login")) {
    console.log(`- Not checking ${tag}'s release-smoke-test: gh is not installed or logged in`);
    process.exit(0);
  }
  fail(`Could not read ${tag}'s release-smoke-test checks: ${stderr?.trim()}`);
}
const failed = SMOKE_TESTS.map((name, i) => [name, results[i]]).filter(
  ([, result]) => result !== "completed success",
);
if (failed.length > 0) {
  fail(
    `${tag}'s smoke tests have not passed: ${failed.map(([name, result]) => `${name}: ${result || "no run"}`).join(", ")}`,
  );
}
console.log(`✓ ${SMOKE_TESTS.join(" and ")} passed on ${tag}`);
