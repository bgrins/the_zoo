import { mkdirSync, rmSync } from "node:fs";
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
    mkdirSync(path.join(home, "instances", `v${version}`, "default"), { recursive: true });
    const { code } = await runCLI(["stop", "--instance", "default"], { env });

    expect(code).toBe(0);
    const downCalls = docker?.calls().filter((args) => args.includes("down"));
    expect(downCalls).toEqual([
      [
        "compose",
        "-f",
        path.join(home, "instances", `v${version}`, "default", "docker-compose.yaml"),
        "-p",
        defaultProject,
        "down",
        "-v",
        "-t",
        "0",
        "--remove-orphans",
      ],
    ]);
  });
});
