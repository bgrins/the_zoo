import { mkdirSync, rmSync, writeFileSync } from "node:fs";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import cliPackageJson from "../../cli/package.json" with { type: "json" };
import { createFakeDocker, type FakeDocker, makeTempDir, ROOT_DIR, runCLI } from "./helpers";

const version = cliPackageJson.version;
const project = `thezoo-cli-instance-mytest-v${version.replace(/\./g, "-")}`;

describe("the_zoo pull command", () => {
  let home: string;
  let docker: FakeDocker | undefined;

  function pullCalls() {
    return docker?.calls().filter((args) => args.includes("pull"));
  }

  beforeEach(() => {
    home = makeTempDir("thezoo-pull-home");
  });

  afterEach(() => {
    rmSync(home, { recursive: true, force: true });
    docker?.cleanup();
  });

  it.each([
    { saved: "", pulled: ["caddy", "miniflux", "redis"] },
    { saved: "ZOO_WITH_HEAVY=1", pulled: ["caddy", "miniflux", "postmill", "redis"] },
  ])(
    "should pull the images the instance uses from its own sources ($saved)",
    async ({ saved, pulled }) => {
      const instanceDir = path.join(home, "instances", `v${version}`, "mytest");
      mkdirSync(instanceDir, { recursive: true });
      writeFileSync(path.join(instanceDir, "docker-compose.yaml"), "services: {}\n");
      writeFileSync(path.join(instanceDir, ".env"), `COMPOSE_PROJECT_NAME=${project}\n${saved}\n`);
      docker = createFakeDocker({ projects: [project] });

      const { code, stdout, stderr } = await runCLI(["pull", "--instance", "mytest"], {
        env: { ...docker.env, THE_ZOO_HOME: home, ZOO_DEV: undefined },
      });

      expect(code, stderr).toBe(0);
      expect(pullCalls()).toEqual([
        [
          "compose",
          "-f",
          path.join(instanceDir, "docker-compose.yaml"),
          "--env-file",
          path.join(instanceDir, ".env"),
          "-p",
          project,
          "--profile",
          "*",
          "pull",
          "--quiet",
          ...pulled,
        ],
      ]);
      expect(stdout.includes("Not pulled, as the instance doesn't use them: postmill")).toBe(
        !saved,
      );
    },
  );

  it("should pull this version's images for an instance an older CLI version runs", async () => {
    const oldProject = "thezoo-cli-instance-mytest-v0-9-0";
    const oldDir = path.join(home, "instances", "v0.9.0", "mytest");
    mkdirSync(oldDir, { recursive: true });
    writeFileSync(path.join(oldDir, "docker-compose.yaml"), "services: {}\n");
    writeFileSync(
      path.join(oldDir, ".env"),
      `COMPOSE_PROJECT_NAME=${oldProject}\nZOO_WITH_HEAVY=1\n`,
    );
    // Sources copied by an earlier run, since the CLI sources ship none
    const instanceDir = path.join(home, "instances", `v${version}`, "mytest");
    mkdirSync(instanceDir, { recursive: true });
    writeFileSync(path.join(instanceDir, "docker-compose.yaml"), "services: {}\n");
    docker = createFakeDocker({ projects: [oldProject] });

    for (const args of [["pull"], ["pull", "--instance", "mytest"]]) {
      const { code, stderr } = await runCLI(args, {
        env: { ...docker.env, THE_ZOO_HOME: home, ZOO_DEV: undefined },
      });
      expect(code, stderr).toBe(0);
    }

    const pull = [
      ...["compose", "-f", path.join(instanceDir, "docker-compose.yaml"), "-p", project],
      ...["--profile", "*", "pull", "--quiet", "caddy", "miniflux", "postmill", "redis"],
    ];
    expect(pullCalls()).toEqual([pull, pull]);
  });

  it("should pull the development environment from the repository", async () => {
    docker = createFakeDocker({
      projects: ["the_zoo"],
      rules: [{ match: "^compose -p the_zoo ps", stdout: '{"Service":"caddy"}\n' }],
    });

    const { code, stderr } = await runCLI(["pull"], {
      env: { ...docker.env, THE_ZOO_HOME: home },
    });

    expect(code, stderr).toBe(0);
    expect(pullCalls()).toEqual([
      [
        "compose",
        "-f",
        path.join(ROOT_DIR, "docker-compose.yaml"),
        "-p",
        "the_zoo",
        "--profile",
        "*",
        "pull",
        "--quiet",
        "caddy",
        "miniflux",
        "postmill",
        "redis",
      ],
    ]);
  });

  it("should pull for an instance that exists but isn't running, as its next start runs it", async () => {
    const envPath = path.join(home, "runtime", "mytest", ".env");
    mkdirSync(path.dirname(envPath), { recursive: true });
    writeFileSync(envPath, `COMPOSE_PROJECT_NAME=${project}\nZOO_WITH_HEAVY=1\n`);
    docker = createFakeDocker();

    const { code, stderr } = await runCLI(["pull", "--instance", "mytest"], {
      env: { ...docker.env, THE_ZOO_HOME: home },
    });

    expect(code, stderr).toBe(0);
    expect(pullCalls()).toEqual([
      [
        "compose",
        "-f",
        path.join(ROOT_DIR, "docker-compose.yaml"),
        "-p",
        project,
        "--profile",
        "*",
        "pull",
        "--quiet",
        "caddy",
        "miniflux",
        "postmill",
        "redis",
      ],
    ]);
  });

  it("should fail when no instance is running or created", async () => {
    docker = createFakeDocker();

    const { code, stderr } = await runCLI(["pull"], {
      env: { ...docker.env, THE_ZOO_HOME: home, ZOO_DEV: undefined },
    });

    expect(code).toBe(1);
    expect(stderr).toContain("No Zoo instance is running or created");
    expect(stderr).toContain('Run "the_zoo start" first to create an instance');
    expect(pullCalls()).toEqual([]);
  });

  it("should fail when docker compose pull fails", async () => {
    docker = createFakeDocker({
      projects: [project],
      rules: [{ match: " pull --quiet", exitCode: 18 }],
    });

    const { code, stderr } = await runCLI(["pull"], {
      env: { ...docker.env, THE_ZOO_HOME: home, ZOO_DEV: undefined },
    });

    expect(code).toBe(1);
    expect(stderr).toContain("Docker command failed with code 18");
  });
});
