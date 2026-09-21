import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import cliPackageJson from "../../cli/package.json" with { type: "json" };
import {
  baselineRules,
  createFakeDocker,
  FAKE_SNAPSHOTS_VOLUME,
  type FakeDocker,
  makeTempDir,
  projectContainerRules,
  ROOT_DIR,
  runCLI,
} from "./helpers";

const project = `thezoo-cli-instance-default-v${cliPackageJson.version.replace(/\./g, "-")}`;

describe("the_zoo start", () => {
  let home: string;
  let docker: FakeDocker;
  let env: Record<string, string>;
  const envPath = () => path.join(home, "runtime", "default", ".env");

  function upCalls() {
    return docker
      .calls()
      .filter((args) => args.includes("up"))
      .map((args) => args.slice(args.indexOf("-p") + 2));
  }

  beforeEach(() => {
    home = makeTempDir("thezoo-start-home");
    docker = createFakeDocker();
    env = { ...docker.env, THE_ZOO_HOME: home };
  });

  afterEach(() => {
    rmSync(home, { recursive: true, force: true });
    docker.cleanup();
  });

  test("should create the on-demand apps but not the heavy ones", async () => {
    const { code, stdout, stderr } = await runCLI(["start"], { env });

    expect(code, stderr).toBe(0);
    expect(upCalls()).toEqual([
      ["up", "-d"],
      ["--profile", "on-demand", "up", "-d", "--no-start", "miniflux"],
    ]);
    expect(stdout).toContain(
      'Heavy apps not created: postmill. Add them with "the_zoo start --with-heavy"',
    );
    expect(readFileSync(envPath(), "utf-8")).not.toContain("ZOO_WITH_HEAVY");
  });

  test("--with-heavy should create the heavy apps from then on", async () => {
    const first = await runCLI(["start", "--with-heavy"], { env });
    const second = await runCLI(["start"], { env });

    expect([first.code, second.code], first.stderr + second.stderr).toEqual([0, 0]);
    const onDemand = ["--profile", "on-demand", "up", "-d", "--no-start", "miniflux", "postmill"];
    expect(upCalls()).toEqual([["up", "-d"], onDemand, ["up", "-d"], onDemand]);
    expect(first.stdout + second.stdout).not.toContain("Heavy apps not created");
    expect(readFileSync(envPath(), "utf-8")).toMatch(/^ZOO_WITH_HEAVY=1$/m);
  });

  test.each([
    { args: ["--wait"], seconds: "300" },
    { args: ["--wait-timeout", "60"], seconds: "60" },
    { args: ["--wait", "--wait-timeout", "5"], seconds: "5" },
  ])("$args should wait for the core services to be healthy", async ({ args, seconds }) => {
    const { code, stdout, stderr } = await runCLI(["start", ...args], { env });

    expect(code, stderr).toBe(0);
    expect(upCalls()[0]).toEqual(["up", "-d", "--wait", "--wait-timeout", seconds]);
    expect(stdout).toContain("The Zoo is running and healthy!");
  });

  test.each([["start"], ["restart"]])(
    "%s should reject an invalid --wait-timeout before changing anything",
    async (command) => {
      const running = createFakeDocker({ projects: ["thezoo-cli-instance-default-v0-0-1"] });
      try {
        const { code, stderr } = await runCLI([command, "--wait-timeout", "1.5"], {
          env: { ...env, ...running.env },
        });

        expect(code).toBe(1);
        expect(stderr).toContain('Invalid --wait-timeout: "1.5"');
        expect(running.calls().some((args) => args.includes("up") || args.includes("down"))).toBe(
          false,
        );
        expect(existsSync(envPath())).toBe(false);
      } finally {
        running.cleanup();
      }
    },
  );

  test("should create the instance's snapshots volume before starting it", async () => {
    const { code, stderr } = await runCLI(["start"], { env });

    expect(code, stderr).toBe(0);
    const calls = docker.calls();
    const created = calls.findIndex((args) => args[0] === "volume");
    expect(calls[created]).toEqual([
      "volume",
      "create",
      "--label",
      "zoo.instance=default",
      FAKE_SNAPSHOTS_VOLUME,
    ]);
    expect(created).toBeLessThan(calls.findIndex((args) => args.includes("up")));
    // Without a version in it, the instance's projects under every CLI version share it
    expect(readFileSync(envPath(), "utf-8")).toMatch(
      /^ZOO_SNAPSHOTS_VOLUME=thezoo-cli-instance-default_zoo_snapshots$/m,
    );
  });

  test("should refuse a ZOO_BASELINE that has no snapshot instead of starting golden", async () => {
    mkdirSync(path.dirname(envPath()), { recursive: true });
    writeFileSync(envPath(), "ZOO_BASELINE=task1\n");

    const missing = await runCLI(["start"], { env });

    expect(missing.code).toBe(1);
    expect(missing.stderr).toContain(
      `Instance "default" has no snapshot "task1", its ZOO_BASELINE (volume ${FAKE_SNAPSHOTS_VOLUME})`,
    );
    expect(missing.stderr).toContain(
      'Start it from the golden state with "the_zoo start --instance default --set-env ZOO_BASELINE="',
    );
    expect(upCalls()).toEqual([]);
    const check = docker.calls().find((args) => args[0] === "run");
    expect(check).toContain(`${FAKE_SNAPSHOTS_VOLUME}:/zoo-snapshots:ro`);
    expect(check?.at(-1)).toBe("task1");
    const typo = await runCLI(["start", "--set-env", "ZOO_BASELINE=typo"], { env });
    expect(typo.code).toBe(1);
    expect(typo.stderr).toContain('Instance "default" has no snapshot "typo", its ZOO_BASELINE');
    // Refused before the start saves anything
    expect(readFileSync(envPath(), "utf-8")).toBe("ZOO_BASELINE=task1\n");

    const golden = await runCLI(["start", "--set-env", "ZOO_BASELINE="], { env });
    expect(golden.code, golden.stderr).toBe(0);
    expect(upCalls()).toHaveLength(2);
  });

  test("restart should refuse a ZOO_BASELINE without a snapshot before stopping the instance", async () => {
    const running = createFakeDocker({ projects: [project] });
    mkdirSync(path.dirname(envPath()), { recursive: true });
    writeFileSync(envPath(), "ZOO_BASELINE=task1\n");
    try {
      const typo = await runCLI(["restart", "--set-env", "ZOO_BASELINE=typo"], {
        env: { ...env, ...running.env },
      });
      const saved = await runCLI(["restart"], { env: { ...env, ...running.env } });

      expect(typo.code).toBe(1);
      expect(typo.stderr).toContain('Instance "default" has no snapshot "typo", its ZOO_BASELINE');
      expect(typo.stderr).toContain(
        'Start it from the golden state with "the_zoo restart --instance default --set-env ZOO_BASELINE="',
      );
      expect(saved.code).toBe(1);
      expect(saved.stderr).toContain(
        'Instance "default" has no snapshot "task1", its ZOO_BASELINE',
      );
      expect(running.calls().some((args) => args.includes("down") || args.includes("up"))).toBe(
        false,
      );
      expect(readFileSync(envPath(), "utf-8")).toBe("ZOO_BASELINE=task1\n");
    } finally {
      running.cleanup();
    }
  });

  test("should start from a ZOO_BASELINE snapshot saved with its images", async () => {
    const found = createFakeDocker({
      rules: baselineRules("task1", { postgres: "sha256:postgres", mysql: "sha256:mysql" }),
    });
    mkdirSync(path.dirname(envPath()), { recursive: true });
    writeFileSync(envPath(), "ZOO_BASELINE=task1\n");
    try {
      const { code, stderr } = await runCLI(["start"], { env: { ...env, ...found.env } });

      expect(code, stderr).toBe(0);
      expect(found.calls().filter((args) => args.includes("up"))).toHaveLength(2);
    } finally {
      found.cleanup();
    }
  });

  test.each(["start", "restart"])(
    "%s should refuse a ZOO_BASELINE saved with other images, as after an upgrade",
    async (command) => {
      const running = createFakeDocker({
        projects: [project],
        rules: baselineRules(
          "task1",
          { postgres: "sha256:postgres-17", mysql: "sha256:mysql" },
          { postgres: "sha256:postgres-18", mysql: "sha256:mysql" },
        ),
      });
      mkdirSync(path.dirname(envPath()), { recursive: true });
      writeFileSync(envPath(), "ZOO_BASELINE=task1\n");
      try {
        const { code, stderr } = await runCLI([command], { env: { ...env, ...running.env } });

        expect(code).toBe(1);
        expect(stderr).toContain(
          'Snapshot "task1", the ZOO_BASELINE of instance "default", was saved with other images of postgres\n',
        );
        expect(stderr).toContain(
          `Start it from the golden state with "the_zoo ${command} --instance default --set-env ZOO_BASELINE=" and save a new snapshot, or start it with the images it was saved with (by CLI 0.9.0)`,
        );
        expect(running.calls().some((args) => args.includes("down") || args.includes("up"))).toBe(
          false,
        );
      } finally {
        running.cleanup();
      }
    },
  );

  test("should say a ZOO_BASELINE can't be checked against images that aren't pulled", async () => {
    const unpulled = createFakeDocker({
      rules: [
        {
          match: "^image inspect .* the_zoo-postgres$",
          exitCode: 1,
          stderr: "Error response from daemon: No such image: the_zoo-postgres\n",
        },
        ...baselineRules("task1", { postgres: "sha256:postgres", mysql: "sha256:mysql" }),
      ],
    });
    mkdirSync(path.dirname(envPath()), { recursive: true });
    writeFileSync(envPath(), "ZOO_BASELINE=task1\n");
    try {
      const { code, stderr } = await runCLI(["start"], { env: { ...env, ...unpulled.env } });

      expect(code).toBe(1);
      expect(stderr).toContain(
        `Snapshot "task1", the ZOO_BASELINE of instance "default", can't be checked against the images of postgres, which are not pulled\n`,
      );
      expect(stderr).toContain('Pull them with "the_zoo pull --instance default", then try again');
      expect(unpulled.calls().some((args) => args.includes("up"))).toBe(false);
    } finally {
      unpulled.cleanup();
    }
  });

  test("should warn when a database kept its data after an unclean shutdown", async () => {
    const records = [
      "/zoo-state/postgres:started_at=2026-09-20T08:00:01Z",
      "/zoo-state/postgres:kept=unclean shutdown (cluster state: in production)",
      // From a start before the running container's
      "/zoo-state/mysql:started_at=2026-09-19T08:00:00Z",
      "/zoo-state/mysql:kept=unclean shutdown (/var/lib/mysql/mysqld.pid left behind)",
    ];
    const unclean = createFakeDocker({
      rules: [
        { match: "^run --rm .* -c cd /zoo-state", stdout: `${records.join("\n")}\n` },
        ...projectContainerRules(project, [
          {
            service: "postgres",
            startedAt: "2026-09-20T08:00:00.9Z",
            volumes: { "/zoo-state": "s", "/zoo-snapshots": "n" },
          },
          { service: "mysql", startedAt: "2026-09-20T08:00:00.9Z" },
        ]),
      ],
    });
    try {
      const { code, stderr } = await runCLI(["start"], { env: { ...env, ...unclean.env } });

      expect(code, stderr).toBe(0);
      expect(stderr).toContain(
        "⚠ postgres kept its data at 2026-09-20T08:00:01Z, after an unclean shutdown (cluster state: in production)\n",
      );
      expect(stderr).toContain('Run "the_zoo reset --instance default" to restore the baseline');
      expect(stderr).not.toContain("mysql kept");
    } finally {
      unclean.cleanup();
    }
  });

  test("should say where the CA certificate and the credentials are", async () => {
    const { code, stdout } = await runCLI(["start"], { env });

    expect(code).toBe(0);
    expect(stdout).toContain(`CA cert: ${path.join(ROOT_DIR, "core", "caddy", "root.crt")}\n`);
    expect(stdout).toContain(`Credentials: ${path.join(ROOT_DIR, "docs", "credentials")}\n`);
  });

  test("dry-run should say whether the heavy apps would be created", async () => {
    const without = await runCLI(["start", "--dry-run"], { env });
    const withHeavy = await runCLI(["start", "--dry-run", "--with-heavy"], { env });

    expect(without.stdout).toContain(
      "2. docker compose --profile on-demand up -d --no-start <the on-demand services, except the heavy profile's>",
    );
    expect(withHeavy.stdout).toContain(
      "2. docker compose --profile on-demand up -d --no-start <the on-demand services>",
    );
    expect(withHeavy.stdout).toContain("ZOO_WITH_HEAVY=1");
  });
});
