import { spawnSync } from "node:child_process";
import { chmodSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { afterEach, beforeEach, describe, expect, it } from "vitest";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "../..");
let directory: string;

function executable(name: string, source: string) {
  const path = join(directory, name);
  writeFileSync(path, `#!/bin/sh\n${source}\n`);
  chmodSync(path, 0o755);
}

function run(failures: number) {
  const calls = join(directory, "calls");
  const attempts = join(directory, "attempts");
  writeFileSync(attempts, "0");
  const result = spawnSync("bash", [join(root, "scripts/test-go.sh")], {
    cwd: root,
    encoding: "utf8",
    env: {
      ...process.env,
      PATH: `${directory}:${process.env.PATH}`,
      GO_CALLS: calls,
      GO_ATTEMPTS: attempts,
      GO_FAILURES: String(failures),
    },
  });
  return { result, commands: readFileSync(calls, "utf8").trim().split("\n") };
}

describe("test-go.sh", () => {
  beforeEach(() => {
    directory = mkdtempSync(join(tmpdir(), "zoo-test-go-"));
    executable(
      "docker",
      'if [ "$1" = image ]; then echo \'["GOLANG_VERSION=1.26.8"]\'; else for argument do :; done; sh -c "$argument"; fi',
    );
    executable("gofmt", "exit 0");
    executable("sleep", "exit 0");
    executable(
      "go",
      'echo "$*" >> "$GO_CALLS"\nif [ "$1" = list ]; then attempts=$(cat "$GO_ATTEMPTS"); attempts=$((attempts + 1)); echo "$attempts" > "$GO_ATTEMPTS"; [ "$attempts" -gt "$GO_FAILURES" ]; fi',
    );
  });

  afterEach(() => rmSync(directory, { recursive: true, force: true }));

  it("retries transient download failures before vetting and testing", () => {
    const { result, commands } = run(2);
    expect(result.status).toBe(0);
    expect(commands).toEqual([
      "list -deps -test github.com/thezoo/...",
      "list -deps -test github.com/thezoo/...",
      "list -deps -test github.com/thezoo/...",
      "vet github.com/thezoo/...",
      "test -race github.com/thezoo/...",
    ]);
  });

  it("fails after three downloads and skips vet and test", () => {
    const { result, commands } = run(3);
    expect(result.status).toBe(1);
    expect(result.stderr).toContain("Go dependency download failed after 3 attempts");
    expect(commands).toEqual(Array(3).fill("list -deps -test github.com/thezoo/..."));
  });
});
