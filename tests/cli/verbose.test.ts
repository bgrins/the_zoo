import { rmSync } from "node:fs";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import { createFakeDocker, type FakeDocker, makeTempDir, runCLI } from "./helpers";

describe("CLI --verbose option", () => {
  let home: string;
  let docker: FakeDocker;
  let env: Record<string, string>;

  beforeEach(() => {
    home = makeTempDir("thezoo-verbose-home");
    docker = createFakeDocker();
    env = { ...docker.env, THE_ZOO_HOME: home };
  });

  afterEach(() => {
    rmSync(home, { recursive: true, force: true });
    docker.cleanup();
  });

  test("should show help with --verbose option", async () => {
    const { code, stdout } = await runCLI(["--help"]);

    expect(code).toBe(0);
    expect(stdout).toContain("--verbose");
    expect(stdout).toContain("enable verbose output for all commands");
  });

  test("should show verbose output when --verbose is used with start dry-run", async () => {
    const { code, stdout } = await runCLI(["--verbose", "start", "--dry-run"], { env });

    expect(code).toBe(0);
    expect(stdout).toContain("[VERBOSE]");
    expect(stdout).toContain("Step:");
  });

  test("should not show verbose output when --verbose is not used", async () => {
    const { code, stdout } = await runCLI(["start", "--dry-run"], { env });

    expect(code).toBe(0);
    expect(stdout).not.toContain("[VERBOSE]");
  });

  test("should work with shell subcommand", async () => {
    const { code, stdout } = await runCLI(["--verbose", "shell", "--help"]);

    expect(code).toBe(0);
    expect(stdout).toContain("Run shell commands");
  });
});
