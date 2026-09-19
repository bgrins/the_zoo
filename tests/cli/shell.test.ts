import { rmSync } from "node:fs";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import { createFakeDocker, type FakeDocker, makeTempDir, ROOT_DIR, runCLI } from "./helpers";

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

  test("shell command shows help", async () => {
    const { code, stdout } = await runCLI(["shell", "--help"]);

    expect(code).toBe(0);
    expect(stdout).toContain("Run shell commands for Zoo services");
    expect(stdout).toContain("--instance");
    expect(stdout).toContain("redis");
    expect(stdout).toContain("postgres");
    expect(stdout).toContain("stalwart");
    expect(stdout).toContain("mysql");
  });

  test("fails clearly when no instance is running", async () => {
    const { code, stderr } = await runCLI(["shell", "redis", "ping"], { env: envWith() });

    expect(code).toBe(1);
    expect(stderr).toContain("No Zoo CLI instances are currently running");
    expect(execCalls()).toEqual([]);
  });

  test("runs the service CLI in the running instance", async () => {
    const env = envWith({ projects: [project] });
    const composeFile = path.join(ROOT_DIR, "docker-compose.yaml");

    const redis = await runCLI(["shell", "redis", "ping"], { env });
    const postgres = await runCLI(["shell", "postgres", "-c", "SELECT version();"], { env });
    const stalwart = await runCLI(["shell", "stalwart", "--", "--version"], { env });

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

  test("passes through the service's exit code", async () => {
    const env = envWith({
      projects: [project],
      rules: [{ match: " exec -T mysql ", exitCode: 3 }],
    });

    const { code, stderr } = await runCLI(["shell", "mysql", "-e", "bad"], { env });

    expect(code).toBe(3);
    expect(stderr).toContain("mysql in mysql exited with code 3");
  });
});
