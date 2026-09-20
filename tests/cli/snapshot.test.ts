import { mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
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

const containers: FakeContainer[] = [
  {
    service: "postgres",
    labels: { "zoo.snapshot": "/var/lib/postgresql/data" },
    volumes: { "/zoo-state": "abc_zoo_state", "/zoo-snapshots": "abc_zoo_snapshots" },
    env: ["ZOO_BASELINE=base"],
  },
  { service: "mysql", labels: { "zoo.snapshot": "/var/lib/mysql" } },
  { service: "gitea-zoo", labels: { "zoo.db": "postgres", "zoo.snapshot": "/data" } },
  { service: "northwind", labels: { "zoo.db": "mysql" } },
  {
    service: "mattermost",
    running: false,
    labels: { "zoo.db": "postgres", "zoo.snapshot": "/mattermost/data" },
  },
  { service: "wiki-zoo" },
];

function manifest(images: Record<string, string>) {
  return JSON.stringify({
    name: "base",
    createdAt: "2026-09-19T21:40:02.000Z",
    cliVersion: "0.9.0",
    services: Object.fromEntries(
      Object.entries(images).map(([service, image]) => [
        service,
        { image, digests: [], archive: "saved" },
      ]),
    ),
  });
}

const savedImages = {
  postgres: "sha256:postgres",
  mysql: "sha256:mysql",
  "gitea-zoo": "sha256:gitea-zoo",
  mattermost: "sha256:mattermost",
};

describe("the_zoo snapshot", () => {
  let home: string;
  let envPath: string;
  let docker: FakeDocker | undefined;
  let compose: string[];

  function envWith(rules: FakeDockerRule[] = []) {
    docker = createFakeDocker({
      projects: [project],
      rules: [
        ...rules,
        {
          match: "^image inspect",
          stdout: JSON.stringify(
            Object.values(savedImages).map((Id) => ({ Id, RepoDigests: [`repo@${Id}`] })),
          ),
        },
        ...projectContainerRules(project, containers),
      ],
    });
    return { ...docker.env, THE_ZOO_HOME: home };
  }

  function calls(first: string) {
    return docker?.calls().filter((args) => args[0] === first && !args.includes("ls")) ?? [];
  }

  beforeEach(() => {
    home = makeTempDir("thezoo-snapshot-home");
    envPath = path.join(home, "runtime", "abc", ".env");
    mkdirSync(path.dirname(envPath), { recursive: true });
    writeFileSync(envPath, "COMPOSE_PROJECT_NAME=thezoo-cli-instance-abc-v0-9-0\n");
    compose = [
      "compose",
      "--progress",
      "quiet",
      "-f",
      path.join(ROOT_DIR, "docker-compose.yaml"),
      "--env-file",
      envPath,
      "-p",
      project,
    ];
  });

  afterEach(() => {
    rmSync(home, { recursive: true, force: true });
    docker?.cleanup();
  });

  test("save archives each stateful service with its own image while the writers are stopped", async () => {
    const env = envWith([{ match: "^run --rm .* -c set -e", stdout: "saved\n" }]);
    const { code, stderr } = await runCLI(["snapshot", "save", "task1"], { env });

    expect(code, stderr).toBe(0);
    expect(calls("compose")).toEqual([
      [...compose, "stop", "gitea-zoo", "mysql", "northwind", "postgres"],
      [...compose, "start", "--wait", "gitea-zoo", "mysql", "northwind", "postgres"],
    ]);
    const runs = calls("run");
    const archives = runs.filter((args) => args.includes("--volumes-from"));
    expect(
      archives.map((args) => {
        const image = args[args.indexOf("--entrypoint") + 2];
        return [args[args.indexOf("--volumes-from") + 1], image, ...args.slice(-4)];
      }),
    ).toEqual([
      ["id-postgres", "sha256:postgres", "task1", "postgres", "/var/lib/postgresql/data", ""],
      ["id-mysql", "sha256:mysql", "task1", "mysql", "/var/lib/mysql", ""],
      ["id-gitea-zoo", "sha256:gitea-zoo", "task1", "gitea-zoo", "/data", "postgres"],
      ["id-mattermost", "sha256:mattermost", "task1", "mattermost", "/mattermost/data", "postgres"],
    ]);
    for (const args of archives) {
      expect(args).toContain("abc_zoo_snapshots:/zoo-out");
    }
    const manifestRun = runs.find((args) =>
      args.some((arg) => arg.includes('> "/zoo-out/$1/manifest.json"')),
    );
    const written = JSON.parse(manifestRun?.at(-1) as string);
    expect(written.name).toBe("task1");
    expect(written.services["gitea-zoo"]).toEqual({
      image: "sha256:gitea-zoo",
      digests: ["repo@sha256:gitea-zoo"],
      archive: "saved",
    });
    expect(Object.keys(written.services)).toEqual(Object.keys(savedImages));
    // The databases restart with the data they were saved with instead of their baseline
    const keep = runs.find((args) => args.some((arg) => arg.includes(".keep")));
    expect(keep?.slice(-2)).toEqual(["mysql", "postgres"]);
    expect(keep).toContain("abc_zoo_state:/zoo-state");
    expect(runs.indexOf(keep as string[])).toBe(runs.length - 1);
  });

  test("save refuses a name that exists without stopping anything", async () => {
    const env = envWith([
      { match: "-c cd /zoo-snapshots", stdout: `task1\t1024\t${manifest(savedImages)}\n` },
    ]);
    const { code, stderr } = await runCLI(["snapshot", "save", "task1"], { env });

    expect(code).toBe(1);
    expect(stderr).toContain('Snapshot "task1" already exists');
    expect(calls("compose")).toEqual([]);
  });

  test("restore sets the baseline in the instance .env and recreates the databases", async () => {
    const env = envWith([{ match: 'manifest.json" sh base$', stdout: manifest(savedImages) }]);
    const { code, stderr } = await runCLI(["snapshot", "restore", "base"], { env });

    expect(code, stderr).toBe(0);
    expect(readFileSync(envPath, "utf8")).toContain("ZOO_BASELINE=base");
    expect(calls("compose")).toEqual([
      [...compose, "stop", "gitea-zoo", "northwind", "postgres", "mysql"],
      [...compose, "up", "-d", "--no-deps", "--force-recreate", "--wait", "postgres", "mysql"],
      [...compose, "start", "--wait", "postgres", "mysql", "gitea-zoo", "northwind"],
    ]);
  });

  test("restore refuses a snapshot saved with other images", async () => {
    const env = envWith([
      {
        match: 'manifest.json" sh base$',
        stdout: manifest({ ...savedImages, "gitea-zoo": "sha256:older" }),
      },
    ]);
    const { code, stderr } = await runCLI(["snapshot", "restore", "base"], { env });

    expect(code).toBe(1);
    expect(stderr).toContain('Snapshot "base" was saved with other images of gitea-zoo');
    expect(readFileSync(envPath, "utf8")).not.toContain("ZOO_BASELINE");
    expect(calls("compose")).toEqual([]);
  });

  test("restore golden clears the baseline", async () => {
    writeFileSync(envPath, "COMPOSE_PROJECT_NAME=x\nZOO_BASELINE=base\n");
    const { code, stderr } = await runCLI(["snapshot", "restore", "golden"], { env: envWith() });

    expect(code, stderr).toBe(0);
    expect(readFileSync(envPath, "utf8")).toBe("COMPOSE_PROJECT_NAME=x\nZOO_BASELINE=\n");
  });

  test("rm refuses the baseline and removes another snapshot", async () => {
    writeFileSync(envPath, "ZOO_BASELINE=base\n");
    const listing = `base\t1024\t${manifest(savedImages)}\ntask1\t2048\t${manifest(savedImages)}\n`;
    const env = envWith([{ match: "-c cd /zoo-snapshots", stdout: listing }]);

    const active = await runCLI(["snapshot", "rm", "base"], { env });
    const other = await runCLI(["snapshot", "rm", "task1"], { env });

    expect(active.code).toBe(1);
    expect(active.stderr).toContain('Snapshot "base" is the baseline');
    expect(other.code, other.stderr).toBe(0);
    const removals = calls("run").filter((args) => args.includes('rm -rf "/zoo-out/$1"'));
    expect(removals.map((args) => args.at(-1))).toEqual(["task1"]);
  });
});
