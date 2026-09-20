import { rmSync, writeFileSync } from "node:fs";
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
    labels: { "zoo.core": "true", "zoo.snapshot": "/var/lib/postgresql/data" },
    volumes: { "/zoo-state": "abc_zoo_state", "/zoo-snapshots": "abc_zoo_snapshots" },
  },
  { service: "mysql", labels: { "zoo.core": "true", "zoo.snapshot": "/var/lib/mysql" } },
  { service: "caddy", labels: { "zoo.core": "true" } },
  { service: "gitea-zoo", labels: { "zoo.db": "postgres", "zoo.snapshot": "/data" } },
  { service: "hydra", labels: { "zoo.core": "true", "zoo.db": "postgres" } },
  { service: "northwind", labels: { "zoo.db": "mysql" } },
  { service: "analytics-zoo", running: false, labels: { "zoo.db": "mysql" } },
  { service: "wiki-zoo" },
  { service: "misc-zoo", running: false },
];

const recreate = ["--profile", "*", "up", "-d", "--no-deps", "--force-recreate", "--wait"];
const recreateStopped = ["--profile", "*", "up", "--no-start", "--no-deps", "--force-recreate"];
const restoreDatabases = ["up", "-d", "--no-deps", "--force-recreate", "--wait"];
const startDefaults = ["up", "-d", "--no-deps", "--no-recreate", "--wait"];

describe("the_zoo reset and state", () => {
  let home: string;
  let docker: FakeDocker | undefined;

  function envWith(rules: FakeDockerRule[] = [], projects = [project]) {
    docker = createFakeDocker({
      projects,
      rules: [...rules, ...projectContainerRules(project, containers)],
    });
    return { ...docker.env, THE_ZOO_HOME: home };
  }

  // Outside the repository only CLI instances count, so the only one running is the default
  function run(args: string[], env: Record<string, string>) {
    return runCLI(args, { env, cwd: home });
  }

  // The ones that change the instance
  function composeCalls() {
    return docker
      ?.calls()
      .filter((args) => args[0] === "compose" && ["stop", "up"].some((a) => args.includes(a)));
  }

  function clearedDatabases() {
    return docker
      ?.calls()
      .filter((args) => args[0] === "run" && args.some((arg) => arg.includes(".keep")))
      .map((args) => [args[args.indexOf("--volumes-from") + 1], ...args.slice(-2)]);
  }

  beforeEach(() => {
    home = makeTempDir("thezoo-reset-home");
  });

  afterEach(() => {
    rmSync(home, { recursive: true, force: true });
    docker?.cleanup();
  });

  test("restores both databases and recreates every app and the services that use them", async () => {
    const { code, stderr } = await run(["reset"], envWith());

    expect(code, stderr).toBe(0);
    expect(composeCalls()).toEqual([
      [...compose, "stop", "gitea-zoo", "hydra", "northwind", "postgres", "mysql"],
      [...compose, ...restoreDatabases, "postgres", "mysql"],
      [...compose, ...recreate, "gitea-zoo", "hydra", "northwind", "wiki-zoo"],
      [...compose, ...recreateStopped, "analytics-zoo", "misc-zoo"],
      [...compose, ...startDefaults],
    ]);
    // The spinner writes to stderr
    expect(stderr).toContain("Restored postgres and mysql in");
    expect(stderr).toContain(
      "; recreated analytics-zoo, gitea-zoo, hydra, misc-zoo, northwind, wiki-zoo",
    );
  });

  test("restores even data a crash or a snapshot save left to keep", async () => {
    const { code, stderr } = await run(["reset"], envWith());

    expect(code, stderr).toBe(0);
    // The entrypoints restore an empty data directory without a .keep file whatever the
    // last shutdown was like
    expect(clearedDatabases()).toEqual([
      ["id-postgres", "postgres", "/var/lib/postgresql/data"],
      ["id-mysql", "mysql", "/var/lib/mysql"],
    ]);
    const calls = docker?.calls() ?? [];
    const cleared = calls.findIndex((args) => args[0] === "run");
    expect(calls.findIndex((args) => args.includes("stop"))).toBeLessThan(cleared);
    expect(calls.findIndex((args) => args.includes("--force-recreate"))).toBeGreaterThan(cleared);
  });

  test("an app reset recreates the app and restores its database with the services in it", async () => {
    const env = envWith();
    const gitea = await run(["reset", "gitea-zoo"], env);
    const analytics = await run(["reset", "analytics-zoo"], env);

    expect([gitea.code, analytics.code], gitea.stderr + analytics.stderr).toEqual([0, 0]);
    expect(composeCalls()).toEqual([
      [...compose, "stop", "gitea-zoo", "hydra", "postgres"],
      [...compose, ...restoreDatabases, "postgres"],
      [...compose, ...recreate, "gitea-zoo", "hydra"],
      [...compose, "stop", "northwind", "mysql"],
      [...compose, ...restoreDatabases, "mysql"],
      [...compose, ...recreate, "northwind"],
      [...compose, ...recreateStopped, "analytics-zoo"],
    ]);
  });

  test("recreates an app that has no database, running or not", async () => {
    const env = envWith();
    const wiki = await run(["reset", "wiki-zoo"], env);
    const misc = await run(["reset", "misc-zoo"], env);

    expect([wiki.code, misc.code]).toEqual([0, 0]);
    expect(composeCalls()).toEqual([
      [...compose, ...recreate, "wiki-zoo"],
      [...compose, ...recreateStopped, "misc-zoo"],
    ]);
    expect(clearedDatabases()).toEqual([]);
  });

  test("rejects an unknown service without touching the instance", async () => {
    const { code, stderr } = await run(["reset", "nope"], envWith());

    expect(code).toBe(1);
    expect(stderr).toContain('No service "nope" in this instance');
    expect(composeCalls()).toEqual([]);
  });

  test("in the repository, resets this checkout's project from the files its containers name", async () => {
    const checkout = "zoo-checkout";
    const worktree = makeTempDir("thezoo-reset-worktree");
    const files = ["docker-compose.yaml", ".env"].map((file) => path.join(worktree, file));
    for (const file of files) {
      writeFileSync(file, "");
    }
    const rules: FakeDockerRule[] = [
      {
        match: `^compose -f ${ROOT_DIR}/docker-compose.yaml --profile \\* config --format json$`,
        stdout: JSON.stringify({ name: checkout, services: {} }),
      },
      { match: `^compose -p ${checkout} ps --format json$`, stdout: '{"Service":"caddy"}\n' },
      {
        match: `^ps -a --filter label=com.docker.compose.project=${checkout} --format`,
        stdout: `${worktree}\t${files[0]}\t${files[1]}\n`,
      },
      ...projectContainerRules(checkout, [{ service: "wiki-zoo" }]),
    ];
    try {
      const both = await runCLI(["reset", "wiki-zoo"], {
        env: envWith(rules, [project, checkout]),
      });
      expect(both.code, both.stderr).toBe(0);
      expect(composeCalls()).toEqual([
        [
          "compose",
          "--progress",
          "quiet",
          "-f",
          files[0],
          "--env-file",
          files[1],
          "-p",
          checkout,
          ...recreate,
          "wiki-zoo",
        ],
      ]);

      const other = await runCLI(["reset"], { env: envWith(rules, [project]) });
      expect(other.code).toBe(1);
      expect(other.stderr).toContain(`${checkout}, this checkout's project, is not running`);
      expect(other.stderr).toContain(`abc (${project})`);
      expect(composeCalls()).toEqual([]);
    } finally {
      rmSync(worktree, { recursive: true, force: true });
    }
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

    const text = await run(["state"], env);
    const json = await run(["state", "--json"], env);

    expect(text.code, text.stderr).toBe(0);
    expect(text.stdout).toBe(
      [
        "postgres snapshot base, restored 2026-09-19T21:40:02Z in 2.31s",
        '         ⚠ start at 2026-09-19T22:10:00Z kept the data: unclean shutdown (cluster state: in production); "the_zoo reset" restores it',
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
