import { existsSync, mkdirSync, rmSync, writeFileSync } from "node:fs";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import cliPackageJson from "../../cli/package.json" with { type: "json" };
import {
  createFakeDocker,
  type FakeDocker,
  type FakeDockerRule,
  makeTempDir,
  runCLI,
} from "./helpers";

const version = cliPackageJson.version;
const busyProject = "thezoo-cli-instance-busy-v0-9-0";
const goneProject = "thezoo-cli-instance-gone-v0-8-0";

describe("the_zoo clean", () => {
  let home: string;
  let docker: FakeDocker | undefined;

  function instanceDir(versionDir: string, instanceId: string): string {
    return path.join(home, "instances", versionDir, instanceId);
  }

  function writeInstance(versionDir: string, instanceId: string, project: string) {
    mkdirSync(instanceDir(versionDir, instanceId), { recursive: true });
    writeFileSync(
      path.join(instanceDir(versionDir, instanceId), ".env"),
      `COMPOSE_PROJECT_NAME=${project}\n`,
    );
  }

  function run(args: string[], rules: FakeDockerRule[] = []) {
    docker = createFakeDocker({
      projects: [busyProject],
      rules: [
        ...rules,
        // Leftover resources of a stopped old instance, and of the running one
        {
          match: "^ps -a --filter label=com.docker.compose.project --format",
          stdout: `${goneProject}\n${busyProject}\n`,
        },
        {
          match: "^ps -a --format \\{\\{.Image\\}\\}",
          stdout: [
            `ghcr.io/bgrins/the_zoo/caddy:0.9.0\t${busyProject}`,
            // Stopped, but removed with its project
            `ghcr.io/bgrins/the_zoo/postgres:0.9.0\t${goneProject}`,
            // Stopped, and not in a project removed here
            "ghcr.io/bgrins/the_zoo/mysql:0.9.0\t",
            "",
          ].join("\n"),
        },
        {
          match: "^volume ls --filter label=zoo.instance ",
          stdout: [
            "thezoo-cli-instance-default_zoo_snapshots\tdefault",
            "thezoo-cli-instance-busy_zoo_snapshots\tbusy",
            "thezoo-cli-instance-old_zoo_snapshots\told",
            "",
          ].join("\n"),
        },
        {
          match: "^image ls --format",
          stdout: [
            "ghcr.io/bgrins/the_zoo/caddy:0.9.0",
            "ghcr.io/bgrins/the_zoo/mysql:0.9.0",
            "ghcr.io/bgrins/the_zoo/postgres:0.9.0",
            "ghcr.io/bgrins/the_zoo/postgres:0.0.6-dev",
            `ghcr.io/bgrins/the_zoo/postgres:${version}-rc.1`,
            `ghcr.io/bgrins/the_zoo/postgres:${version}`,
            "ghcr.io/bgrins/the_zoo/postgres:latest",
            "ghcr.io/bgrins/other:0.1.0",
            "<none>:<none>",
          ].join("\n"),
        },
      ],
    });
    return runCLI(args, { env: { ...docker.env, THE_ZOO_HOME: home, ZOO_DEV: undefined } });
  }

  function removals() {
    return docker
      ?.calls()
      .filter((args) => args.includes("rm") || (args[0] === "ps" && args.includes("-q")))
      .map((args) => args.join(" "));
  }

  beforeEach(() => {
    home = makeTempDir("thezoo-clean-home");
    writeInstance("v0.9.0", "default", "thezoo-cli-instance-default-v0-9-0");
    writeInstance("v0.9.0", "busy", busyProject);
    writeInstance("v0.9.0", "old", "thezoo-cli-instance-old-v0-9-0");
    writeInstance(`v${version}-rc.1`, "default", "whatever");
    writeInstance(`v${version}`, "default", "current");
  });

  afterEach(() => {
    rmSync(home, { recursive: true, force: true });
    docker?.cleanup();
  });

  it("should remove what older versions left, except what is running or still used", async () => {
    const { code, stdout, stderr } = await run(["clean", "--old-versions", "--force"]);

    expect(code, stderr).toBe(0);
    expect(stdout).toContain(`Keeping ${instanceDir("v0.9.0", "busy")}, which is running`);
    expect(existsSync(instanceDir("v0.9.0", "default"))).toBe(false);
    expect(existsSync(instanceDir("v0.9.0", "old"))).toBe(false);
    expect(existsSync(path.join(home, "instances", `v${version}-rc.1`))).toBe(false);
    expect(existsSync(instanceDir("v0.9.0", "busy"))).toBe(true);
    expect(existsSync(instanceDir(`v${version}`, "default"))).toBe(true);
    // The snapshots of "default" carry over to this version's instance; "old" has none left
    expect(removals()).toEqual([
      `ps -a -q --filter label=com.docker.compose.project=${goneProject}`,
      "volume rm thezoo-cli-instance-old_zoo_snapshots",
      "image rm ghcr.io/bgrins/the_zoo/postgres:0.9.0",
      "image rm ghcr.io/bgrins/the_zoo/postgres:0.0.6-dev",
      `image rm ghcr.io/bgrins/the_zoo/postgres:${version}-rc.1`,
    ]);
  });

  it("should remove an instance's snapshots with it, and every instance's with clean", async () => {
    const one = await run(["clean", "--instance", "old", "--force"]);
    expect(one.code, one.stderr).toBe(0);
    expect(removals()).toEqual(["volume rm thezoo-cli-instance-old_zoo_snapshots"]);
    expect(existsSync(instanceDir("v0.9.0", "old"))).toBe(false);

    const all = await run(["clean", "--force"]);
    expect(all.code, all.stderr).toBe(0);
    expect(removals()).toContain(
      "volume rm thezoo-cli-instance-default_zoo_snapshots thezoo-cli-instance-busy_zoo_snapshots thezoo-cli-instance-old_zoo_snapshots",
    );
  });

  it("should remove the other images when one can't be", async () => {
    const { code, stderr } = await run(
      ["clean", "--old-versions", "--force"],
      [
        {
          match: "^image rm ghcr.io/bgrins/the_zoo/postgres:0.9.0$",
          exitCode: 1,
          stderr: "image is being used by stopped container 1a2b\n",
        },
      ],
    );

    expect(code).toBe(1);
    expect(stderr).toContain(
      "ghcr.io/bgrins/the_zoo/postgres:0.9.0: Command failed with code 1: image is being used by stopped container 1a2b",
    );
    expect(removals()).toContain(`image rm ghcr.io/bgrins/the_zoo/postgres:${version}-rc.1`);
    expect(existsSync(instanceDir("v0.9.0", "default"))).toBe(false);
  });

  it("should not take --instance too", async () => {
    const { code, stderr } = await run(["clean", "--old-versions", "--instance", "busy"]);

    expect(code).toBe(1);
    expect(stderr).toContain("Pass either --instance or --old-versions");
    expect(existsSync(instanceDir("v0.9.0", "busy"))).toBe(true);
  });
});
