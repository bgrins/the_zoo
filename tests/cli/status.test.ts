import { mkdirSync, rmSync, writeFileSync } from "node:fs";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { createFakeDocker, type FakeDocker, makeTempDir, ROOT_DIR, runCLI } from "./helpers";

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

  it("should include the development project only when run from inside the repository", async () => {
    docker = createFakeDocker({
      projects: ["the_zoo"],
      rules: [{ match: "^compose -p the_zoo ps", stdout: '{"Service":"caddy"}\n' }],
    });
    const env = { ...docker.env, THE_ZOO_HOME: home };

    const inside = await runCLI(["status"], { env, cwd: path.join(ROOT_DIR, "tests", "cli") });
    expect(inside.code).toBe(0);
    expect(inside.stdout).toContain("Project: the_zoo");
    expect(inside.stdout).toContain(`Directory: ${ROOT_DIR}\n`);

    const outside = await runCLI(["status"], { env, cwd: home });
    expect(outside.code).toBe(0);
    expect(outside.stdout).toContain("No Zoo CLI instances are currently running");
  });

  it("should find an instance by the project its .env names", async () => {
    // Neither the prerelease version nor the underscore survives the project name
    const project = "thezoo-cli-instance-my-box-v0-10-0-rc-1";
    const instanceDir = path.join(home, "instances", "v0.10.0-rc.1", "my_box");
    mkdirSync(instanceDir, { recursive: true });
    writeFileSync(path.join(instanceDir, ".env"), `COMPOSE_PROJECT_NAME=${project}\n`);
    const env = envWith({ projects: [project] });

    const { code, stdout } = await runCLI(["status", "--instance", "my_box"], { env });

    expect(code).toBe(0);
    expect(stdout).toContain(`Project: ${project}`);
    expect(stdout).toContain("Instance ID: my_box\n");
    expect(stdout).toContain(`Directory: ${instanceDir}\n`);
  });

  it("should find an instance whose .env an older CLI wrote without the project", async () => {
    const instanceDir = path.join(home, "instances", "v0.10.0-rc.1", "old");
    mkdirSync(instanceDir, { recursive: true });
    writeFileSync(path.join(instanceDir, ".env"), "ZOO_PROXY_PORT=3300\n");
    const env = envWith({ projects: ["thezoo-cli-instance-old-v0-10-0-rc-1"] });

    const { code, stdout } = await runCLI(["status"], { env });

    expect(code).toBe(0);
    expect(stdout).toContain(`Directory: ${instanceDir}\n`);
  });

  it("--json should describe the running instances", async () => {
    const project = "thezoo-cli-instance-abc-v0-9-0";
    const instanceDir = path.join(home, "instances", "v0.9.0", "abc");
    mkdirSync(path.join(instanceDir, "core", "caddy"), { recursive: true });
    writeFileSync(path.join(instanceDir, "core", "caddy", "root.crt"), "");
    writeFileSync(path.join(instanceDir, ".env"), `COMPOSE_PROJECT_NAME=${project}\n`);
    const env = envWith({
      projects: [project, "thezoo-cli-instance-gone-v0-9-0"],
      rules: [
        {
          match: `^compose -p ${project} ps --format json$`,
          stdout: [
            '{"Service":"caddy","State":"running","Health":"healthy"}',
            '{"Service":"proxy","State":"running","Health":"starting","Publishers":[{"PublishedPort":3140}]}',
            '{"Service":"miniflux","State":"running","Health":""}',
          ].join("\n"),
        },
      ],
    });

    const { code, stdout, stderr } = await runCLI(["status", "--json"], { env });

    expect(code, stderr).toBe(0);
    expect(JSON.parse(stdout)).toEqual({
      instances: [
        {
          project,
          instanceId: "abc",
          version: "v0.9.0",
          directory: instanceDir,
          proxyUrl: "http://localhost:3140",
          caCert: path.join(instanceDir, "core", "caddy", "root.crt"),
          services: [
            { service: "caddy", state: "running", health: "healthy" },
            { service: "proxy", state: "running", health: "starting" },
            { service: "miniflux", state: "running", health: null },
          ],
        },
        {
          project: "thezoo-cli-instance-gone-v0-9-0",
          instanceId: "gone",
          version: "v0.9.0",
          directory: path.join(home, "instances", "v0.9.0", "gone"),
          proxyUrl: null,
          caCert: null,
          services: [],
        },
      ],
    });
  });

  it("--json should list no instances when none are running", async () => {
    const { code, stdout } = await runCLI(["status", "--json"], { env: envWith({}) });

    expect(code).toBe(0);
    expect(JSON.parse(stdout)).toEqual({ instances: [] });
  });

  it("should match --instance exactly", async () => {
    const env = envWith({ projects: ["thezoo-cli-instance-default-v0-9-0"] });
    const { stdout, stderr } = await runCLI(["status", "--instance", "9"], { env });

    expect(stderr).toContain("No running instance found matching: 9");
    expect(stdout).not.toContain("Project:");
  });
});
