import { rmSync } from "node:fs";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import {
  createFakeDocker,
  type FakeContainer,
  type FakeDocker,
  type FakeDockerRule,
  makeTempDir,
  projectContainerRules,
  ROOT_DIR,
  runCLI,
} from "./helpers";

const project = "thezoo-cli-instance-abc-v0-9-0";
const compose = [
  "compose",
  "--progress",
  "quiet",
  "-f",
  path.join(ROOT_DIR, "docker-compose.yaml"),
  "-p",
  project,
];

const containers: FakeContainer[] = [
  {
    service: "postgres",
    labels: { "zoo.snapshot": "/var/lib/postgresql/data" },
    volumes: { "/zoo-state": "abc_zoo_state", "/zoo-snapshots": "abc_zoo_snapshots" },
  },
  { service: "mysql", labels: { "zoo.snapshot": "/var/lib/mysql" } },
  { service: "gitea-zoo", labels: { "zoo.db": "postgres", "zoo.snapshot": "/data" } },
  { service: "hydra", labels: { "zoo.db": "postgres" } },
  { service: "northwind", labels: { "zoo.db": "mysql" } },
  { service: "analytics-zoo", running: false, labels: { "zoo.db": "mysql" } },
  { service: "wiki-zoo" },
  { service: "misc-zoo", running: false },
];

describe("the_zoo reset and state", () => {
  let home: string;
  let docker: FakeDocker | undefined;

  function envWith(rules: FakeDockerRule[] = []) {
    docker = createFakeDocker({
      projects: [project],
      rules: [...rules, ...projectContainerRules(project, containers)],
    });
    return { ...docker.env, THE_ZOO_HOME: home };
  }

  function composeCalls() {
    return docker?.calls().filter((args) => args[0] === "compose" && !args.includes("ls"));
  }

  beforeEach(() => {
    home = makeTempDir("thezoo-reset-home");
  });

  afterEach(() => {
    rmSync(home, { recursive: true, force: true });
    docker?.cleanup();
  });

  test("restores both databases with the running services that keep state in them stopped", async () => {
    const { code, stderr } = await runCLI(["reset"], { env: envWith() });

    expect(code, stderr).toBe(0);
    expect(composeCalls()).toEqual([
      [...compose, "stop", "gitea-zoo", "hydra", "northwind", "postgres", "mysql"],
      [...compose, "start", "--wait", "postgres", "mysql", "gitea-zoo", "hydra", "northwind"],
    ]);
    // The spinner writes to stderr
    expect(stderr).toContain("Restored postgres and mysql");
  });

  test("resets an app's database and the other running services in it", async () => {
    const { code, stderr } = await runCLI(["reset", "analytics-zoo"], { env: envWith() });

    expect(code, stderr).toBe(0);
    expect(composeCalls()).toEqual([
      [...compose, "stop", "northwind", "mysql"],
      [...compose, "start", "--wait", "mysql", "northwind"],
    ]);
  });

  test("restarts a running app that has no database, and leaves a stopped one alone", async () => {
    const env = envWith();
    const wiki = await runCLI(["reset", "wiki-zoo"], { env });
    const misc = await runCLI(["reset", "misc-zoo"], { env });

    expect([wiki.code, misc.code]).toEqual([0, 0]);
    expect(misc.stdout).toContain("misc-zoo is not running");
    expect(composeCalls()).toEqual([[...compose, "restart", "wiki-zoo"]]);
  });

  test("rejects an unknown service without touching the instance", async () => {
    const { code, stderr } = await runCLI(["reset", "nope"], { env: envWith() });

    expect(code).toBe(1);
    expect(stderr).toContain('No service "nope" in this instance');
    expect(composeCalls()).toEqual([]);
  });

  test("state reports each database's last restore", async () => {
    const records = [
      "/zoo-state/postgres:generation=g1",
      "/zoo-state/postgres:source=snapshot:base",
      "/zoo-state/postgres:baseline=base",
      "/zoo-state/postgres:restored_at=2026-09-19T21:40:02Z",
      "/zoo-state/postgres:restore_seconds=2.310",
      "/zoo-state/postgres:started_at=2026-09-19T22:10:00Z",
      "/zoo-state/postgres:kept=unclean shutdown (cluster state: in production)",
      "/zoo-state/mysql:generation=g2",
      "/zoo-state/mysql:source=golden",
      "/zoo-state/mysql:baseline=base",
      "/zoo-state/mysql:restored_at=2026-09-19T21:40:03Z",
      "/zoo-state/mysql:restore_seconds=3.101",
      "/zoo-state/mysql:started_at=2026-09-19T21:40:03Z",
      "/zoo-state/mysql:kept=",
    ].join("\n");
    const env = envWith([{ match: "^run --rm .* -c cd /zoo-state", stdout: `${records}\n` }]);

    const text = await runCLI(["state"], { env });
    const json = await runCLI(["state", "--json"], { env });

    expect(text.code, text.stderr).toBe(0);
    expect(text.stdout).toBe(
      [
        "postgres snapshot base, restored 2026-09-19T21:40:02Z in 2.31s",
        "         start at 2026-09-19T22:10:00Z kept the data: unclean shutdown (cluster state: in production)",
        "mysql    golden, restored 2026-09-19T21:40:03Z in 3.10s",
        "         baseline base has no snapshot for it",
        "",
      ].join("\n"),
    );
    expect(JSON.parse(json.stdout).databases.postgres).toEqual({
      source: "snapshot:base",
      baseline: "base",
      restoredAt: "2026-09-19T21:40:02Z",
      restoreSeconds: 2.31,
      startedAt: "2026-09-19T22:10:00Z",
      skippedRestore: "unclean shutdown (cluster state: in production)",
      generation: "g1",
    });
    const helper = docker?.calls().find((args) => args[0] === "run");
    expect(helper?.slice(0, 11)).toEqual([
      "run",
      "--rm",
      "--network",
      "none",
      "--user",
      "0",
      "-v",
      "abc_zoo_state:/zoo-state:ro",
      "--entrypoint",
      "sh",
      "sha256:postgres",
    ]);
  });
});
