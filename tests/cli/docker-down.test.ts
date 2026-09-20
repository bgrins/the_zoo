import { existsSync, rmSync } from "node:fs";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import { createFakeDocker, type FakeDocker, makeTempDir, runCLI } from "./helpers";

describe("the_zoo without a working Docker daemon", () => {
  let home: string;
  let docker: FakeDocker | undefined;

  function envWith(daemon: "down" | "hung") {
    docker = createFakeDocker({ daemon, projects: ["thezoo-cli-instance-abc-v0-9-0"] });
    // A short timeout only for the hung daemon: a busy machine can take longer to answer
    const timeout = daemon === "hung" ? { THE_ZOO_DOCKER_TIMEOUT: "0.5" } : {};
    return { ...docker.env, THE_ZOO_HOME: home, ...timeout };
  }

  function composeActions() {
    return docker
      ?.calls()
      .filter((args) => ["up", "down", "exec", "pull"].some((a) => args.includes(a)));
  }

  beforeEach(() => {
    home = makeTempDir("thezoo-docker-down-home");
  });

  afterEach(() => {
    rmSync(home, { recursive: true, force: true });
    docker?.cleanup();
  });

  test.each(
    [
      ["stop"],
      ["stop", "--all"],
      ["status"],
      ["start"],
      ["restart"],
      ["pull"],
      ["compose", "ps"],
      ["shell", "redis", "ping"],
      ["email", "users"],
      ["clean", "--force"],
    ].map((args) => ({ args })),
  )("$args should say Docker is not running", async ({ args }) => {
    const { code, stdout, stderr } = await runCLI(args, { env: envWith("down") });

    expect(code).toBe(1);
    expect(stderr).toContain("Docker is not running");
    expect(stderr).toContain("Start Docker and try again");
    expect(stdout).not.toContain("No Zoo CLI instances");
    expect(composeActions()).toEqual([]);
    expect(existsSync(path.join(home, "runtime"))).toBe(false);
  });

  test("start --dry-run should work without Docker", async () => {
    const { code, stdout } = await runCLI(["start", "--dry-run"], { env: envWith("down") });

    expect(code).toBe(0);
    expect(stdout).toContain("Dry run mode");
  });

  test.each([
    { args: ["start", "--dry-run"], command: "docker network ls -q" },
    { args: ["status"], command: "docker info" },
    { args: ["stop"], command: "docker info" },
  ])("$args should give up on a hung Docker", async ({ args, command }) => {
    const started = Date.now();
    const { code, stderr } = await runCLI(args, { env: envWith("hung") });

    expect(code).toBe(1);
    expect(stderr).toContain(`"${command}" did not finish within 0.5s`);
    expect(stderr).toContain("Docker is not responding");
    expect(Date.now() - started).toBeLessThan(8000);
    expect(composeActions()).toEqual([]);
  });
});
