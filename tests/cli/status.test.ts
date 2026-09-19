import { rmSync } from "node:fs";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { createFakeDocker, type FakeDocker, makeTempDir, runCLI } from "./helpers";

describe("the_zoo status command", () => {
  let home: string;
  let docker: FakeDocker | undefined;

  function envWith(options: Parameters<typeof createFakeDocker>[0]) {
    docker = createFakeDocker(options);
    return { ...docker.env, THE_ZOO_HOME: home, ZOO_DEV: undefined };
  }

  beforeEach(() => {
    home = makeTempDir("thezoo-status-home");
  });

  afterEach(() => {
    rmSync(home, { recursive: true, force: true });
    docker?.cleanup();
  });

  it("should show help for status command", async () => {
    const { stdout } = await runCLI(["status", "--help"]);
    expect(stdout).toContain("Show status of running Zoo instances");
    expect(stdout).toContain("--instance <id>");
    expect(stdout).toContain("Show status for a specific instance");
  });

  it("should show no instances when none are running", async () => {
    const { code, stdout } = await runCLI(["status"], { env: envWith({}) });

    expect(code).toBe(0);
    expect(stdout).toContain("No Zoo CLI instances are currently running");
  });

  it("should show the instance directory and published proxy port", async () => {
    const project = "thezoo-cli-instance-abc-v0-9-0";
    const env = envWith({
      projects: [project],
      rules: [
        {
          match: `^compose -p ${project} ps proxy --format json`,
          stdout: '{"Service":"proxy","Publishers":[{"PublishedPort":3140}]}\n',
        },
      ],
    });
    const { code, stdout } = await runCLI(["status", "--instance", "abc"], { env });

    expect(code).toBe(0);
    expect(stdout).toContain(`Project: ${project}`);
    expect(stdout).toContain("Instance ID: abc");
    expect(stdout).toContain(`Directory: ${path.join(home, "instances", "v0.9.0", "abc")}`);
    expect(stdout).toContain("Proxy: http://localhost:3140");
  });

  it("should match --instance exactly", async () => {
    const env = envWith({ projects: ["thezoo-cli-instance-default-v0-9-0"] });
    const { stdout, stderr } = await runCLI(["status", "--instance", "9"], { env });

    expect(stderr).toContain("No running instance found matching: 9");
    expect(stdout).not.toContain("Project:");
  });
});
