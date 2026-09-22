import os from "node:os";
import { rmSync } from "node:fs";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import { createFakeDocker, type FakeDocker, makeTempDir, ROOT_DIR, runCLI } from "./helpers";

// Outside the repository, where a CLI instance is the only kind of project there is
const run = (args: string[], options: Parameters<typeof runCLI>[1] = {}) =>
  runCLI(args, { cwd: os.tmpdir(), ...options });

const project = "thezoo-cli-instance-abc-v0-9-0";

describe("CLI shell command", () => {
  let home: string;
  let docker: FakeDocker | undefined;

  function envWith(options: Parameters<typeof createFakeDocker>[0] = {}) {
    docker = createFakeDocker(options);
    return { ...docker.env, THE_ZOO_HOME: home };
  }

  function execCalls() {
    return docker?.calls().filter((args) => args.includes("exec"));
  }

  beforeEach(() => {
    home = makeTempDir("thezoo-shell-home");
  });

  afterEach(() => {
    rmSync(home, { recursive: true, force: true });
    docker?.cleanup();
  });

  test("fails clearly when no instance is running", async () => {
    const { code, stderr } = await run(["shell", "redis", "ping"], { env: envWith() });

    expect(code).toBe(1);
    expect(stderr).toContain("No Zoo CLI instances are currently running");
    expect(execCalls()).toEqual([]);
  });

  test("runs the service CLI in the running instance", async () => {
    const env = envWith({ projects: [project] });
    const composeFile = path.join(ROOT_DIR, "docker-compose.yaml");

    const redis = await run(["shell", "redis", "ping"], { env });
    const postgres = await run(["shell", "postgres", "-c", "SELECT version();"], { env });
    const stalwart = await run(["shell", "stalwart", "--", "--version"], { env });

    expect([redis.code, postgres.code, stalwart.code]).toEqual([0, 0, 0]);
    const prefix = ["compose", "-f", composeFile, "-p", project, "exec", "-T"];
    expect(execCalls()).toEqual([
      [...prefix, "redis", "redis-cli", "ping"],
      [...prefix, "postgres", "psql", "-U", "postgres", "-c", "SELECT version();"],
      [
        ...prefix,
        "stalwart",
        "stalwart-cli",
        "-c",
        "admin:zoo-mail-admin-pw",
        "-u",
        "http://localhost:8080",
        "--version",
      ],
    ]);
  });

  test("--instance picks one of several running instances", async () => {
    const other = "thezoo-cli-instance-def-v0-9-0";
    const env = envWith({ projects: [project, other] });

    const picked = await run(["shell", "--instance", "def", "redis", "ping"], { env });
    const ambiguous = await run(["shell", "redis", "ping"], { env });

    expect(picked.code).toBe(0);
    expect(execCalls()).toEqual([
      [
        "compose",
        "-f",
        path.join(ROOT_DIR, "docker-compose.yaml"),
        "-p",
        other,
        "exec",
        "-T",
        "redis",
        "redis-cli",
        "ping",
      ],
    ]);
    expect(ambiguous.code).toBe(1);
    expect(ambiguous.stderr).toContain("Multiple instances are running");
  });

  test("passes through the service's exit code", async () => {
    const env = envWith({
      projects: [project],
      rules: [{ match: " exec -T mysql ", exitCode: 3 }],
    });

    const { code, stderr } = await run(["shell", "mysql", "-e", "bad"], { env });

    expect(code).toBe(3);
    expect(stderr).toContain("mysql in mysql exited with code 3");
  });
});
