import type { ChildProcess } from "node:child_process";
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
  terminateWhen,
} from "./helpers";

const project = "thezoo-cli-instance-abc-v0-9-0";

const containers: FakeContainer[] = [
  {
    service: "postgres",
    labels: { "zoo.core": "true", "zoo.snapshot": "/var/lib/postgresql/data" },
    volumes: { "/zoo-state": "abc_zoo_state", "/zoo-snapshots": "abc_zoo_snapshots" },
    env: ["ZOO_BASELINE=base"],
  },
  { service: "mysql", labels: { "zoo.core": "true", "zoo.snapshot": "/var/lib/mysql" } },
  { service: "gitea-zoo", labels: { "zoo.db": "postgres", "zoo.snapshot": "/data" } },
  { service: "northwind", labels: { "zoo.db": "mysql" } },
  {
    service: "mattermost",
    running: false,
    labels: { "zoo.db": "postgres", "zoo.snapshot": "/mattermost/data" },
  },
  { service: "wiki-zoo" },
];
const writers = ["gitea-zoo", "mysql", "northwind", "postgres"];

/**
 * Rules listing the containers as they are before a save, then with `stopped` stopped
 */
function stoppingRules(stopped: string[]): FakeDockerRule[] {
  const after = containers.map((c) => (stopped.includes(c.service) ? { ...c, running: false } : c));
  return [
    ...projectContainerRules(project, containers).map((rule) => ({ ...rule, once: true })),
    ...projectContainerRules(project, after),
  ];
}

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

  function envWith(
    rules: FakeDockerRule[] = [],
    listing = projectContainerRules(project, containers),
  ) {
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
        ...listing,
      ],
    });
    return { ...docker.env, THE_ZOO_HOME: home };
  }

  // Outside the repository only CLI instances count, so the only one running is the default
  function run(
    args: string[],
    env: Record<string, string>,
    onSpawn?: (proc: ChildProcess) => void,
  ) {
    return runCLI(args, { env, cwd: home, onSpawn });
  }

  function calls(first: string) {
    return docker?.calls().filter((args) => args[0] === first && !args.includes("ls")) ?? [];
  }

  function composeActions() {
    return calls("compose").filter((args) => ["stop", "up"].some((a) => args.includes(a)));
  }

  // The databases a save marked to keep their data, and the followers whose files it marked
  function keepMarkers() {
    const runs = calls("run");
    const databases = runs.find((args) => args.some((arg) => arg.includes("/zoo-state/$db.keep")));
    const followers = runs
      .filter((args) => args.includes(': > "$1/.zoo-keep"'))
      .map((args) => [args[args.indexOf("--volumes-from") + 1], args.at(-1)]);
    // The script's arguments follow it and $0
    return { databases: databases?.slice(databases.indexOf("-c") + 3), followers };
  }

  const restart = [
    "--profile",
    "*",
    "up",
    "-d",
    "--no-deps",
    "--no-recreate",
    "--wait",
    ...writers,
  ];

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
    const env = envWith(
      [{ match: "^run --rm .* -c set -e", stdout: "saved\n" }],
      stoppingRules(writers),
    );
    const { code, stderr } = await run(["snapshot", "save", "task1"], env);

    expect(code, stderr).toBe(0);
    expect(composeActions()).toEqual([
      [...compose, "stop", ...writers],
      [...compose, ...restart],
    ]);
    const runs = calls("run");
    // What an earlier save cut short goes before anything stops
    const all = docker?.calls() ?? [];
    const removal = all.findIndex((args) => args.includes('rm -rf "/zoo-out/$1"'));
    expect(all[removal].slice(-2)).toEqual(["sh", "task1"]);
    expect(removal).toBeLessThan(all.findIndex((args) => args.includes("stop")));
    const archives = runs.filter((args) => args.some((arg) => arg.startsWith("set -e")));
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
    // The databases restart with the data they were saved with instead of their baseline, and
    // the files that follow them stay as saved
    expect(keepMarkers()).toEqual({
      databases: ["postgres", "mysql"],
      followers: [
        ["id-gitea-zoo", "/data"],
        ["id-mattermost", "/mattermost/data"],
      ],
    });
    const keep = runs.find((args) => args.some((arg) => arg.includes("/zoo-state/$db.keep")));
    expect(keep).toContain("abc_zoo_state:/zoo-state");
    expect(runs.indexOf(keep as string[])).toBeGreaterThan(runs.indexOf(manifestRun as string[]));
  });

  test("a failed save starts the writers again and keeps only the databases that stopped", async () => {
    const env = envWith(
      [{ match: `^compose .* stop `, exitCode: 1, stderr: "mysql did not stop\n" }],
      stoppingRules(writers.filter((service) => service !== "mysql")),
    );
    const { code, stderr } = await run(["snapshot", "save", "task1"], env);

    expect(code).toBe(1);
    expect(stderr).toContain("Failed to save snapshot task1");
    expect(composeActions()).toEqual([
      [...compose, "stop", ...writers],
      [...compose, ...restart],
    ]);
    const runs = calls("run");
    expect(runs.some((args) => args.some((arg) => arg.startsWith("set -e")))).toBe(false);
    expect(runs.filter((args) => args.includes('rm -rf "/zoo-out/$1"'))).toHaveLength(2);
    expect(keepMarkers()).toEqual({
      databases: ["postgres"],
      followers: [
        ["id-gitea-zoo", "/data"],
        ["id-mattermost", "/mattermost/data"],
      ],
    });
  });

  test("an interrupted save removes what it archived and starts the writers again", async () => {
    const env = envWith(
      [
        // Slow enough to be interrupted while it runs
        { match: "--volumes-from id-postgres .* -c set -e", stdout: "saved\n", delaySeconds: 2 },
        { match: "^run --rm .* -c set -e", stdout: "saved\n" },
      ],
      stoppingRules(writers),
    );
    const { code, stderr } = await run(["snapshot", "save", "task1"], env, (proc) =>
      terminateWhen(proc, () => calls("run").some((args) => args.includes("id-postgres"))),
    );

    expect(code, stderr).toBe(143);
    expect(stderr).toContain("Snapshot save interrupted by SIGTERM");
    const runs = calls("run");
    const archived = runs.filter((args) => args.some((arg) => arg.startsWith("set -e")));
    expect(archived.map((args) => args[args.indexOf("--volumes-from") + 1])).toEqual([
      "id-postgres",
    ]);
    expect(runs.some((args) => args.some((arg) => arg.includes('> "/zoo-out/$1/manifest')))).toBe(
      false,
    );
    expect(runs.filter((args) => args.includes('rm -rf "/zoo-out/$1"'))).toHaveLength(2);
    expect(keepMarkers().databases).toEqual(["postgres", "mysql"]);
    expect(composeActions()).toEqual([
      [...compose, "stop", ...writers],
      [...compose, ...restart],
    ]);
  });

  test("save refuses a name that exists without stopping anything", async () => {
    const env = envWith([
      { match: "-c cd /zoo-snapshots", stdout: `task1\t1024\t${manifest(savedImages)}\n` },
    ]);
    const { code, stderr } = await run(["snapshot", "save", "task1"], env);

    expect(code).toBe(1);
    expect(stderr).toContain('Snapshot "task1" already exists');
    expect(composeActions()).toEqual([]);
  });

  test("restore sets the baseline in the instance .env and resets to it", async () => {
    const env = envWith([{ match: 'manifest.json" sh base$', stdout: manifest(savedImages) }]);
    const { code, stderr } = await run(["snapshot", "restore", "base"], env);

    expect(code, stderr).toBe(0);
    expect(readFileSync(envPath, "utf8")).toContain("ZOO_BASELINE=base");
    expect(composeActions()).toEqual([
      [...compose, "stop", "gitea-zoo", "northwind", "postgres", "mysql"],
      [...compose, "up", "-d", "--no-deps", "--force-recreate", "--wait", "postgres", "mysql"],
      [
        ...compose,
        ...["--profile", "*", "up", "-d", "--no-deps", "--force-recreate", "--wait"],
        ...["gitea-zoo", "northwind", "wiki-zoo"],
      ],
      [
        ...compose,
        ...["--profile", "*", "up", "--no-start", "--no-deps", "--force-recreate", "mattermost"],
      ],
      [...compose, "up", "-d", "--no-deps", "--no-recreate", "--wait"],
    ]);
  });

  test("restore refuses a snapshot saved with other images", async () => {
    const env = envWith([
      {
        match: 'manifest.json" sh base$',
        stdout: manifest({ ...savedImages, "gitea-zoo": "sha256:older" }),
      },
    ]);
    const { code, stderr } = await run(["snapshot", "restore", "base"], env);

    expect(code).toBe(1);
    expect(stderr).toContain('Snapshot "base" was saved with other images of gitea-zoo');
    expect(readFileSync(envPath, "utf8")).not.toContain("ZOO_BASELINE");
    expect(composeActions()).toEqual([]);
  });

  test("restore says a snapshot is missing only when it has no manifest", async () => {
    const env = envWith([
      {
        match: 'manifest.json" sh base$',
        exitCode: 125,
        stderr: "docker: Error response from daemon: No such image: sha256:postgres\n",
      },
    ]);
    const missing = await run(["snapshot", "restore", "nope"], env);
    const failing = await run(["snapshot", "restore", "base"], env);

    expect(missing.code).toBe(1);
    expect(missing.stderr).toContain('No snapshot named "nope"');
    expect(failing.code).toBe(1);
    expect(failing.stderr).toContain("No such image: sha256:postgres");
    expect(failing.stderr).not.toContain("No snapshot named");
    expect(composeActions()).toEqual([]);
  });

  test("restore refuses the dev environment, which has no instance .env", async () => {
    const dev = "zoo-dev";
    docker = createFakeDocker({
      projects: [dev],
      rules: [
        { match: `^compose -p ${dev} ps --format json$`, stdout: '{"Service":"caddy"}\n' },
        ...projectContainerRules(dev, containers),
      ],
    });
    // From the repository, where the dev environment counts
    const { code, stderr } = await runCLI(["snapshot", "restore", "base", "--instance", dev], {
      env: { ...docker.env, THE_ZOO_HOME: home },
    });

    expect(code).toBe(1);
    expect(stderr).toContain(
      `${dev} is not a CLI instance, so it has no .env to set its baseline in`,
    );
    expect(stderr).toContain("Set ZOO_BASELINE=base in the env file it runs with");
    expect(composeActions()).toEqual([]);
  });

  test("restore golden clears the baseline", async () => {
    writeFileSync(envPath, "COMPOSE_PROJECT_NAME=x\nZOO_BASELINE=base\n");
    const { code, stderr } = await run(["snapshot", "restore", "golden"], envWith());

    expect(code, stderr).toBe(0);
    expect(readFileSync(envPath, "utf8")).toBe("COMPOSE_PROJECT_NAME=x\nZOO_BASELINE=\n");
  });

  test("list shows each snapshot's size and marks the baseline", async () => {
    writeFileSync(envPath, "ZOO_BASELINE=base\n");
    const saved = manifest(savedImages);
    const listing = `base\t3984588\t${saved}\ntask1\t20480\t${saved}\n`;
    const { code, stdout, stderr } = await run(
      ["snapshot", "list"],
      envWith([{ match: "-c cd /zoo-snapshots", stdout: listing }]),
    );

    expect(code, stderr).toBe(0);
    const createdAt = JSON.parse(saved).createdAt;
    expect(stdout.trimEnd().split("\n")).toEqual([
      `base   ${createdAt}  3.8 GB  (baseline)`,
      `task1  ${createdAt}  20 MB`,
    ]);
  });

  test("rm refuses the baseline and removes another snapshot", async () => {
    writeFileSync(envPath, "ZOO_BASELINE=base\n");
    const listing = `base\t1024\t${manifest(savedImages)}\ntask1\t2048\t${manifest(savedImages)}\n`;
    const env = envWith([{ match: "-c cd /zoo-snapshots", stdout: listing }]);

    const active = await run(["snapshot", "rm", "base"], env);
    const other = await run(["snapshot", "rm", "task1"], env);

    expect(active.code).toBe(1);
    expect(active.stderr).toContain('Snapshot "base" is the baseline');
    expect(other.code, other.stderr).toBe(0);
    const removals = calls("run").filter((args) => args.includes('rm -rf "/zoo-out/$1"'));
    expect(removals.map((args) => args.at(-1))).toEqual(["task1"]);
  });
});
