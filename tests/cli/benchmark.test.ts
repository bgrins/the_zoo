import { readFileSync, rmSync, writeFileSync } from "node:fs";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import cliPackageJson from "../../cli/package.json" with { type: "json" };
import { loadSites } from "../../scripts/lib/sites";
import {
  createFakeCurl,
  createFakeDocker,
  FAKE_SNAPSHOTS_VOLUME,
  type FakeDocker,
  makeTempDir,
  runCLI,
} from "./helpers";

const project = `thezoo-cli-instance-default-v${cliPackageJson.version.replace(/\./g, "-")}`;

describe("the_zoo benchmark command", () => {
  let home: string;
  let docker: FakeDocker;
  let curl: ReturnType<typeof createFakeCurl>;
  let env: Record<string, string>;

  beforeEach(() => {
    home = makeTempDir("thezoo-benchmark-home");
    docker = createFakeDocker({
      projects: [project],
      rules: [
        {
          match: `^compose -p ${project} ps proxy --format json`,
          stdout: '{"Service":"proxy","Publishers":[{"PublishedPort":3150}]}\n',
        },
      ],
    });
    curl = createFakeCurl("200 0.050");
    env = {
      ...docker.env,
      PATH: `${curl.dir}${path.delimiter}${docker.env.PATH}`,
      THE_ZOO_HOME: home,
    };
  });

  afterEach(() => {
    rmSync(home, { recursive: true, force: true });
    docker.cleanup();
    curl.cleanup();
  });

  it("should not stop anything for an instance that doesn't exist", async () => {
    const { code, stderr } = await runCLI(
      ["benchmark", "--instance", "9", "--output", path.join(home, "out")],
      { env },
    );

    expect(code).toBe(1);
    expect(stderr).toContain('Instance "9" does not exist.');
    expect(docker.calls().some((args) => args.includes("down"))).toBe(false);
  });

  it("should refuse to restart an instance started by another CLI version", async () => {
    const oldProject = "thezoo-cli-instance-default-v0-0-1";
    const old = createFakeDocker({ projects: [oldProject] });
    try {
      const { code, stderr } = await runCLI(
        ["benchmark", "--instance", "default", "--output", path.join(home, "out")],
        { env: { ...env, ...old.env, PATH: `${curl.dir}${path.delimiter}${old.env.PATH}` } },
      );

      expect(code).toBe(1);
      expect(stderr).toContain(
        `${oldProject} was started by another CLI version (v0.0.1); benchmarking startup would replace it with ${project}`,
      );
      expect(stderr).toContain("--sites-only");
      expect(old.calls().some((args) => args.includes("down") || args.includes("up"))).toBe(false);
    } finally {
      old.cleanup();
    }
  });

  it(
    "should restart a dev project like start:quick from its own files, keeping its volumes",
    { timeout: 30_000 },
    async () => {
      const devProject = "zoo-benchmark-test";
      const worktree = makeTempDir("thezoo-benchmark-worktree");
      const files = ["docker-compose.yaml", ".env"].map((file) => path.join(worktree, file));
      for (const file of files) {
        writeFileSync(file, "");
      }
      const dev = createFakeDocker({
        projects: [devProject],
        rules: [
          { match: `^compose -p ${devProject} ps --format json`, stdout: '{"Service":"caddy"}\n' },
          // Another checkout's project, whose containers name its files until they are removed
          {
            match: `^ps -a --filter label=com.docker.compose.project=${devProject} --format`,
            stdout: `${worktree}\t${files[0]}\t${files[1]}\n`,
            once: true,
          },
        ],
      });
      try {
        const { code, stderr } = await runCLI(
          ["benchmark", "--force", "--sites", "paste", "--output", path.join(home, "out")],
          { env: { ...env, ...dev.env, PATH: `${curl.dir}${path.delimiter}${dev.env.PATH}` } },
        );

        expect(code, stderr).toBe(0);
        const actions = dev
          .calls()
          .filter((args) => args.includes("up") || args.includes("down"))
          .map((args) => args.slice(args.indexOf("-f")));
        const project = ["-f", files[0], "--env-file", files[1], "-p", devProject];
        // Without -t 0, so the databases shut down cleanly and restore at their next start
        const stop = [...project, "--profile", "*", "down", "--remove-orphans"];
        const coreThenOnDemand = [
          [...project, "up", "-d"],
          [...project, "--profile", "*", "up", "-d", "--no-start"],
        ];
        // Timing the cold start, then the restart
        expect(actions).toEqual([stop, ...coreThenOnDemand, stop, ...coreThenOnDemand]);
        expect(dev.calls()).toContainEqual(["volume", "create", FAKE_SNAPSHOTS_VOLUME]);
      } finally {
        dev.cleanup();
        rmSync(worktree, { recursive: true, force: true });
      }
    },
  );

  it("should need --instance when several projects run, and --force to stop one", async () => {
    const other = "thezoo-cli-instance-abc-v0-9-0";
    const several = createFakeDocker({ projects: [project, other] });
    try {
      const out = ["--output", path.join(home, "out")];
      const ambiguous = await runCLI(["benchmark", ...out], {
        env: { ...env, ...several.env, PATH: `${curl.dir}${path.delimiter}${several.env.PATH}` },
      });
      const unconfirmed = await runCLI(["benchmark", "--instance", "default", ...out], { env });

      expect(ambiguous.code).toBe(1);
      expect(ambiguous.stderr).toContain("Several Zoo projects are running");
      expect(ambiguous.stderr).toContain(`abc (${other})`);
      expect(unconfirmed.code).toBe(1);
      expect(unconfirmed.stderr).toContain(
        `Benchmarking startup stops ${project}, which is running`,
      );
      expect(unconfirmed.stderr).toContain("Pass --force");
      for (const calls of [several.calls(), docker.calls()]) {
        expect(calls.some((args) => args.includes("down") || args.includes("up"))).toBe(false);
      }
    } finally {
      several.cleanup();
    }
  });

  it("should benchmark through the running instance's published proxy port", async () => {
    const output = path.join(home, "out");
    const { code } = await runCLI(
      [
        "benchmark",
        "--sites-only",
        "--sites",
        "paste",
        "--instance",
        "default",
        "--output",
        output,
      ],
      { env },
    );

    expect(code).toBe(0);
    const results = JSON.parse(readFileSync(path.join(output, "results.json"), "utf-8"));
    expect(results.proxy_port).toBe(3150);
    expect(results.sites["paste.zoo"]).toMatchObject({ cold_start_ms: 50, warm_response_ms: 50 });
    // A cold request, then a warm one
    const request =
      "-s -o /dev/null -w %{http_code} %{time_total} --proxy http://localhost:3150 -k --connect-timeout 120 --max-time 120 https://paste.zoo/";
    expect(curl.calls()).toEqual([request, request]);
    expect(docker.calls().some((args) => args.includes("down") || args.includes("up"))).toBe(false);
    expect(docker.calls()).toContainEqual([
      "ps",
      "--filter",
      `label=com.docker.compose.project=${project}`,
      "--filter",
      "label=com.docker.compose.service=microbin",
      "--format",
      "{{.Names}}",
    ]);
  });

  it("should offer one site of every on-demand service", async () => {
    const { code, stderr } = await runCLI(
      ["benchmark", "--sites-only", "--sites", "auth.zoo", "--output", path.join(home, "out")],
      { env },
    );

    // auth.zoo starts with the core services
    expect(code).toBe(1);
    expect(stderr).toContain("No sites matched: auth.zoo");
    const offered = stderr.match(/Available sites: (.*)/)?.[1].split(", ") ?? [];
    const sites = loadSites();
    const serviceOf = new Map(sites.map((site) => [site.domain, site.service]));
    const onDemand = new Set(sites.filter((site) => site.onDemand).map((site) => site.service));
    expect(offered.map((domain) => serviceOf.get(domain)).sort()).toEqual([...onDemand].sort());
    expect(offered).toEqual(
      expect.arrayContaining(["docs.gitea.zoo", "mattermost.zoo", "secure.gravatar.com"]),
    );
    expect(curl.calls()).toEqual([]);
  });
});
