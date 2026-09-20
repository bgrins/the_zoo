import { readFileSync, rmSync } from "node:fs";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import cliPackageJson from "../../cli/package.json" with { type: "json" };
import { loadSites } from "../../scripts/lib/sites";
import { createFakeCurl, createFakeDocker, type FakeDocker, makeTempDir, runCLI } from "./helpers";

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
    "should start a dev project like start:quick: core first, then on-demand containers",
    { timeout: 30_000 },
    async () => {
      const devProject = "zoo-benchmark-test";
      const dev = createFakeDocker({
        projects: [devProject],
        rules: [
          { match: `^compose -p ${devProject} ps --format json`, stdout: '{"Service":"caddy"}\n' },
        ],
      });
      try {
        const { code, stderr } = await runCLI(
          ["benchmark", "--sites", "paste", "--output", path.join(home, "out")],
          { env: { ...env, ...dev.env, PATH: `${curl.dir}${path.delimiter}${dev.env.PATH}` } },
        );

        expect(code, stderr).toBe(0);
        const starts = dev
          .calls()
          .filter((args) => args.includes("up"))
          .map((args) => args.slice(args.indexOf("-p")));
        const coreThenOnDemand = [
          ["-p", devProject, "up", "-d"],
          ["-p", devProject, "--profile", "*", "up", "-d", "--no-start"],
        ];
        // Timing the cold start, then the restart
        expect(starts).toEqual([...coreThenOnDemand, ...coreThenOnDemand]);
      } finally {
        dev.cleanup();
      }
    },
  );

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
