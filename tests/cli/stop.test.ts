import { mkdirSync, rmSync, writeFileSync } from "node:fs";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import cliPackageJson from "../../cli/package.json" with { type: "json" };
import { createFakeDocker, type FakeDocker, makeTempDir, runCLI } from "./helpers";

const version = cliPackageJson.version;
const defaultProject = `thezoo-cli-instance-default-v${version.replace(/\./g, "-")}`;

describe("the_zoo stop command", () => {
  let home: string;
  let docker: FakeDocker | undefined;

  function envWith(projects: string[]) {
    docker = createFakeDocker({ projects });
    return { ...docker.env, THE_ZOO_HOME: home, ZOO_DEV: undefined };
  }

  beforeEach(() => {
    home = makeTempDir("thezoo-stop-home");
  });

  afterEach(() => {
    rmSync(home, { recursive: true, force: true });
    docker?.cleanup();
  });

  it("should show help for stop command", async () => {
    const { stdout } = await runCLI(["stop", "--help"]);
    expect(stdout).toContain("Stop The Zoo environment");
    expect(stdout).toContain("--all");
    expect(stdout).toContain("Stop all running Zoo CLI instances");
    expect(stdout).toContain("--instance <id>");
    expect(stdout).toContain("Stop a specific instance");
  });

  it("should show message when no instances are running", async () => {
    const { code, stdout } = await runCLI(["stop"], { env: envWith([]) });

    expect(code).toBe(0);
    expect(stdout).toContain("No Zoo CLI instances are running");
  });

  it("should not match an instance ID against part of a project name", async () => {
    const env = envWith([defaultProject]);
    const { code, stderr } = await runCLI(["stop", "--instance", "9"], { env });

    expect(code).toBe(1);
    expect(stderr).toContain('Instance "9" not found');
    expect(docker?.calls().some((args) => args.includes("down"))).toBe(false);
  });

  it("should stop the exact instance from its own directory", async () => {
    const env = envWith([defaultProject, "thezoo-cli-instance-default2-v0-9-0"]);
    const instanceDir = path.join(home, "instances", `v${version}`, "default");
    mkdirSync(instanceDir, { recursive: true });
    writeFileSync(path.join(instanceDir, "docker-compose.yaml"), "services: {}\n");
    const { code } = await runCLI(["stop", "--instance", "default"], { env });

    expect(code).toBe(0);
    const downCalls = docker?.calls().filter((args) => args.includes("down"));
    expect(downCalls).toEqual([
      [
        "compose",
        "-f",
        path.join(instanceDir, "docker-compose.yaml"),
        "-p",
        defaultProject,
        "--profile",
        "*",
        "down",
        "-v",
        "-t",
        "0",
        "--remove-orphans",
      ],
    ]);
  });

  it("should stop an instance whose files are gone by project name alone", async () => {
    const env = envWith([defaultProject]);
    const { code } = await runCLI(["stop", "--instance", "default"], { env });

    expect(code).toBe(0);
    const downCalls = docker?.calls().filter((args) => args.includes("down"));
    expect(downCalls).toEqual([
      [
        "compose",
        "-p",
        defaultProject,
        "--profile",
        "*",
        "down",
        "-v",
        "-t",
        "0",
        "--remove-orphans",
      ],
    ]);
  });

  it("should never pick the dev environment or a worktree without --instance", async () => {
    // In dev mode these count as running zoo projects for status and compose
    docker = createFakeDocker({
      projects: ["the_zoo", "agent-worktree"],
      rules: [{ match: "ps --format json$", stdout: '{"Service":"caddy"}\n' }],
    });
    const env = { ...docker.env, THE_ZOO_HOME: home, ZOO_DEV: "1" };

    for (const args of [["stop"], ["stop", "--all"]]) {
      const { code, stdout } = await runCLI(args, { env });
      expect(code).toBe(0);
      expect(stdout).toContain("No Zoo CLI instances are running");
    }
    expect(docker.calls().some((args) => args.includes("down"))).toBe(false);
  });

  it("restart should stop the instance started by another CLI version", async () => {
    const oldProject = "thezoo-cli-instance-default-v0-0-1";
    docker = createFakeDocker({ projects: [oldProject] });
    const { code } = await runCLI(["restart"], { env: { ...docker.env, THE_ZOO_HOME: home } });

    expect(code).toBe(0);
    const composeCalls = docker
      .calls()
      .filter((args) => args[0] === "compose" && (args.includes("down") || args.includes("up")))
      .map((args) => [args[args.indexOf("-p") + 1], args.includes("down") ? "down" : "up"]);
    expect(composeCalls).toEqual([
      [oldProject, "down"],
      [defaultProject, "up"],
      [defaultProject, "up"],
    ]);
  });

  it("restart should leave running projects alone when the instance doesn't exist", async () => {
    const env = envWith([defaultProject]);
    const { code, stderr } = await runCLI(["restart", "--instance", "missing"], { env });

    expect(code).toBe(1);
    expect(stderr).toContain('Instance "missing" does not exist.');
    expect(docker?.calls().some((args) => args.includes("down"))).toBe(false);
  });
});
