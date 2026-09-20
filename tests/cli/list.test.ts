import { mkdirSync, rmSync, writeFileSync } from "node:fs";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import cliPackageJson from "../../cli/package.json" with { type: "json" };
import { createFakeDocker, type FakeDocker, makeTempDir, runCLI } from "./helpers";

const version = cliPackageJson.version;
const currentProject = `thezoo-cli-instance-default-v${version.replace(/\./g, "-")}`;
const TIME = String.raw`\d{4}-\d\d-\d\d \d\d:\d\d`;

describe("the_zoo list", () => {
  let home: string;
  let docker: FakeDocker | undefined;

  function writeInstance(versionDir: string, instanceId: string, env: string) {
    const dir = path.join(home, "instances", versionDir, instanceId);
    mkdirSync(dir, { recursive: true });
    writeFileSync(path.join(dir, ".env"), env);
  }

  beforeEach(() => {
    home = makeTempDir("thezoo-list-home");
    writeInstance("v0.9.0", "default", "ZOO_PROXY_PORT=3100\n");
    writeInstance(`v${version}-rc.1`, "abc", "ZOO_PROXY_PORT=3140\n");
    writeInstance(`v${version}`, "default", `COMPOSE_PROJECT_NAME=${currentProject}\n`);
    writeInstance(`v${version}`, "k3", "ZOO_PROXY_PORT=3150\n");
    // Not an instance: no .env
    mkdirSync(path.join(home, "instances", `v${version}`, "partial"));
  });

  afterEach(() => {
    rmSync(home, { recursive: true, force: true });
    docker?.cleanup();
  });

  it("should list every version's instances, newest version first", async () => {
    docker = createFakeDocker({
      projects: [currentProject],
      rules: [
        {
          match: `^compose -p ${currentProject} ps proxy --format json$`,
          stdout: '{"Service":"proxy","Publishers":[{"PublishedPort":3999}]}\n',
        },
      ],
    });

    const { code, stdout, stderr } = await runCLI(["list"], {
      env: { ...docker.env, THE_ZOO_HOME: home, ZOO_DEV: undefined },
    });

    expect(code, stderr).toBe(0);
    const row = (id: string, state: string, port: string) =>
      new RegExp(`^  ${id.padEnd(7)}  ${state}  ${port}  ${TIME}$`);
    const expected = [
      /^ {2}ID {7}STATE {4}PORT {2}CREATED$/,
      `v${version} (this CLI)`,
      row("default", "running", "3999"),
      row("k3", "stopped", "3150"),
      "",
      `v${version}-rc.1`,
      row("abc", "stopped", "3140"),
      "",
      "v0.9.0",
      row("default", "stopped", "3100"),
    ];
    const lines = stdout.trimEnd().split("\n");
    expect(lines).toHaveLength(expected.length);
    lines.forEach((line, i) => {
      const want = expected[i];
      if (typeof want === "string") {
        expect(line, `line ${i}`).toBe(want);
      } else {
        expect(line, `line ${i}`).toMatch(want);
      }
    });
  });

  it("should still list the instances when Docker is not running", async () => {
    docker = createFakeDocker({ daemon: "down" });

    const { code, stdout } = await runCLI(["list"], {
      env: { ...docker.env, THE_ZOO_HOME: home, ZOO_DEV: undefined },
    });

    expect(code).toBe(0);
    expect(stdout).toContain("Docker is not running; running state unknown");
    expect(stdout).toMatch(new RegExp(`^  default  unknown  3128  ${TIME}$`, "m"));
    expect(stdout).not.toMatch(/^ {2}\S+ +(running|stopped) /m);
  });

  it("should say when there are no instances", async () => {
    docker = createFakeDocker();
    const empty = makeTempDir("thezoo-list-empty");
    try {
      const { code, stdout } = await runCLI(["list"], {
        env: { ...docker.env, THE_ZOO_HOME: empty, ZOO_DEV: undefined },
      });

      expect(code).toBe(0);
      expect(stdout).toContain("No Zoo CLI instances");
    } finally {
      rmSync(empty, { recursive: true, force: true });
    }
  });
});
