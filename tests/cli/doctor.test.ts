import { mkdirSync, rmSync, writeFileSync } from "node:fs";
import net from "node:net";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import cliPackageJson from "../../cli/package.json" with { type: "json" };
import {
  createFakeDocker,
  type FakeDocker,
  type FakeDockerRule,
  makeTempDir,
  ROOT_DIR,
  runCLI,
} from "./helpers";

const defaultProject = `thezoo-cli-instance-default-v${cliPackageJson.version.replace(/\./g, "-")}`;

const DF_OUTPUT = (availableKB: number) =>
  `Filesystem 1024-blocks Used Available Capacity Mounted on\noverlay 200000000 1000 ${availableKB} 1% /\n`;

function dockerInfo(overrides: object = {}): FakeDockerRule {
  return {
    match: "^info --format",
    stdout: JSON.stringify({
      ServerVersion: "28.3.2",
      OperatingSystem: "Docker Desktop",
      NCPU: 8,
      MemTotal: 16e9,
      ...overrides,
    }),
  };
}

const HEALTHY: FakeDockerRule[] = [
  dockerInfo(),
  { match: "^compose version --short$", stdout: "2.39.1\n" },
  {
    match: "^system df --format",
    stdout: [
      '{"Type":"Images","Reclaimable":"9.2GB (7%)"}',
      '{"Type":"Containers","Reclaimable":"1.5GB (91%)"}',
      '{"Type":"Local Volumes","Reclaimable":"16.9GB (72%)"}',
      '{"Type":"Build Cache","Reclaimable":"0B"}',
    ].join("\n"),
  },
  // Above the 20 GB minimum, and below the host's free space, which doctor reports when
  // Docker Desktop's disk image can't grow that far
  {
    match: "^run --rm --network none --entrypoint df redis:7.4.7-alpine -Pk /$",
    stdout: DF_OUTPUT(25e6),
  },
];

/**
 * Listen on a free loopback port, like a program holding the proxy port
 */
async function listen(): Promise<net.Server & { port: string }> {
  const server = net.createServer();
  await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
  return Object.assign(server, { port: String((server.address() as net.AddressInfo).port) });
}

async function freePort(): Promise<string> {
  const server = await listen();
  await new Promise((resolve) => server.close(resolve));
  return server.port;
}

describe("the_zoo doctor", () => {
  let home: string;
  let docker: FakeDocker | undefined;
  let server: (net.Server & { port: string }) | undefined;

  function run(args: string[], options: Parameters<typeof createFakeDocker>[0], env = {}) {
    docker = createFakeDocker(options);
    return runCLI(["doctor", ...args], { env: { ...docker.env, THE_ZOO_HOME: home, ...env } });
  }

  beforeEach(() => {
    home = makeTempDir("thezoo-doctor-home");
  });

  afterEach(() => {
    rmSync(home, { recursive: true, force: true });
    docker?.cleanup();
    server?.close();
  });

  it("should pass on a machine that can run the Zoo", async () => {
    const port = await freePort();
    const { code, stdout, stderr } = await run(["--port", port], { rules: HEALTHY });

    expect(code, stderr).toBe(0);
    const lines = stdout.trimEnd().split("\n");
    expect(lines.slice(0, -1)).toEqual([
      "✓ Docker daemon    Docker Desktop, 8 CPUs",
      "✓ Docker Compose   2.39.1",
      "✓ Docker Engine    28.3.2",
      "✓ Disk             25.6 GB free; reclaimable: images 9.2GB, volumes 16.9GB, build cache 0B",
      "✓ Memory           16.0 GB for Docker; the core services' mem_limits total 1.6 GB",
      `✓ Proxy port ${port.padEnd(5)} free`,
      "✓ Subnets          no conflicts with 0 Docker networks",
    ]);
    expect(lines.at(-1)).toMatch(
      new RegExp(
        `^✓ CA certificate   ${path.join(ROOT_DIR, "core", "caddy", "root.crt")} \\(valid until \\d{4}-\\d\\d-\\d\\d\\)$`,
      ),
    );
  });

  it("should fail on old Docker versions and a taken port, and warn about space", async () => {
    server = await listen();
    const { code, stdout, stderr } = await run(["--port", server.port], {
      rules: [
        dockerInfo({ ServerVersion: "24.0.7", MemTotal: 1e9 }),
        { match: "^compose version --short$", stdout: "v2.20.1\n" },
        { match: "^system df", exitCode: 1 },
        { match: "^run --rm", stdout: DF_OUTPUT(5e6) },
      ],
    });

    expect(code).toBe(1);
    expect(stdout).toContain("✗ Docker Compose   v2.20.1; the Zoo needs 2.20.2+\n");
    expect(stdout).toContain("✗ Docker Engine    24.0.7; the Zoo needs 25.0.0+\n");
    expect(stdout).toContain("! Disk             5.1 GB free\n");
    expect(stdout).toContain("A cold start downloads ~15 GB of images (~35 GB with --with-heavy)");
    expect(stdout).toContain(
      "! Memory           1.0 GB for Docker; the core services' mem_limits total 1.6 GB\n",
    );
    expect(stdout).toMatch(/^✗ Proxy port \d+ +in use by another program$/m);
    expect(stderr).toContain("3 checks failed");
  });

  it.each([
    { project: defaultProject, level: "✓", detail: `the proxy of ${defaultProject}` },
    { project: "the_zoo", level: "✗", detail: "in use by the_zoo-proxy-1 of the_zoo" },
    { project: "", level: "✗", detail: "in use by container the_zoo-proxy-1" },
  ])("should say which container holds the port ($project)", async ({ project, level, detail }) => {
    server = await listen();
    const { port } = server;
    const { stdout } = await run(["--port", port], {
      rules: [
        ...HEALTHY,
        { match: `^ps --filter publish=${port} `, stdout: `the_zoo-proxy-1\t${project}\n` },
      ],
    });

    expect(stdout).toMatch(new RegExp(`^${level} Proxy port ${port} +${detail}$`, "m"));
  });

  it("should fail an --ip-base instance whose subnet another network took", async () => {
    const envDir = path.join(home, "runtime", "fixed");
    mkdirSync(envDir, { recursive: true });
    writeFileSync(
      path.join(envDir, ".env"),
      [
        "COMPOSE_PROJECT_NAME=thezoo-cli-instance-fixed-v0-10-0",
        "ZOO_SUBNET=10.50.0.0/16",
        "ZOO_PUBLIC_SUBNET=172.16.0.8/30",
        "ZOO_IP_BASE=10.50.100.1",
        "",
      ].join("\n"),
    );
    const { code, stdout } = await run(["--port", await freePort()], {
      rules: [
        ...HEALTHY,
        { match: "^network ls -q$", stdout: "n1\n" },
        {
          match: "^network inspect n1$",
          stdout: JSON.stringify([{ Labels: {}, IPAM: { Config: [{ Subnet: "10.50.0.0/16" }] } }]),
        },
      ],
    });

    expect(code).toBe(1);
    expect(stdout).toContain(
      '✗ Subnets          10.50.0.0/16 of instance "fixed" (from --ip-base 10.50.100.1) overlaps another Docker network\n',
    );
  });

  it("should skip Docker's checks when it is not running", async () => {
    const { code, stdout, stderr } = await run(["--port", await freePort()], {
      daemon: "down",
      rules: [{ match: "^compose version --short$", stdout: "2.39.1\n" }],
    });

    expect(code).toBe(1);
    expect(stdout).toContain("✗ Docker daemon    not running\n");
    expect(stdout).toContain("✓ Docker Compose   2.39.1\n");
    for (const check of ["Docker Engine", "Disk", "Memory", "Subnets"]) {
      expect(stdout).toContain(`- ${check.padEnd(16)} skipped, Docker is not running\n`);
    }
    expect(stdout).toMatch(/^✓ Proxy port \d+ +free$/m);
    expect(stderr).toContain("1 check failed");
  });

  it("should say why it can't use Docker", async () => {
    const denied =
      "permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock";
    const { code, stdout } = await run(["--port", await freePort()], {
      rules: [
        { match: "^compose version --short$", stdout: "2.39.1\n" },
        { match: "^info", exitCode: 1, stderr: `${denied}\n` },
      ],
    });

    expect(code).toBe(1);
    expect(stdout).toContain(`✗ Docker daemon    permission denied: ${denied}\n`);
    expect(stdout).toContain("Add your user to the docker group");
  });

  it("should give up on a hung Docker", async () => {
    const { code, stdout } = await run(
      ["--port", await freePort()],
      { daemon: "hung", rules: [{ match: "^compose version --short$", stdout: "2.39.1\n" }] },
      { THE_ZOO_DOCKER_TIMEOUT: "0.5" },
    );

    expect(code).toBe(1);
    expect(stdout).toContain(
      '✗ Docker daemon    not responding: "docker info --format {{json .}}" did not finish within 0.5s\n',
    );
  });
});
