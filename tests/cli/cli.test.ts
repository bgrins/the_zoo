import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import cliPackageJson from "../../cli/package.json" with { type: "json" };
import { createFakeDocker, type FakeDocker, makeTempDir, runCLI } from "./helpers";

function readEnvLines(envPath: string): string[] {
  return readFileSync(envPath, "utf-8")
    .split("\n")
    .filter((line) => /^[A-Z_]+=/.test(line));
}

function readEnv(envPath: string): Record<string, string> {
  return Object.fromEntries(
    readEnvLines(envPath).map((line) => {
      const equals = line.indexOf("=");
      return [line.slice(0, equals), line.slice(equals + 1)];
    }),
  );
}

const versionSuffix = `v${cliPackageJson.version.replace(/\./g, "-")}`;

/**
 * A fake docker that reports one existing network with `subnet`, owned by `owner`
 */
function dockerWithNetwork(subnet: string, owner: string): FakeDocker {
  return createFakeDocker({
    rules: [
      { match: "^network ls -q$", stdout: "n1\n" },
      {
        match: "^network inspect n1$",
        stdout: JSON.stringify([
          {
            Labels: { "com.docker.compose.project": owner },
            IPAM: { Config: [{ Subnet: subnet }] },
          },
        ]),
      },
    ],
  });
}

describe("CLI version", () => {
  test("should display version from package.json", async () => {
    const { code, stdout } = await runCLI(["--version"]);

    expect(code).toBe(0);
    expect(stdout.trim()).toBe(cliPackageJson.version);
  });
});

describe("CLI commands", () => {
  test("should list all expected commands in help", async () => {
    const { code, stdout } = await runCLI(["--help"]);

    expect(code).toBe(0);
    expect(stdout).toContain("start");
    expect(stdout).toContain("stop");
    expect(stdout).toContain("restart");
    expect(stdout).toContain("status");
    expect(stdout).toContain("clean");
    expect(stdout).toContain("compose");
    expect(stdout).toContain("shell");
    expect(stdout).toContain("email");
    expect(stdout).toContain("mcp");
  });

  test("restart command should have expected options", async () => {
    const { code, stdout } = await runCLI(["restart", "--help"]);

    expect(code).toBe(0);
    expect(stdout).toContain("--port");
    expect(stdout).toContain("--instance");
    expect(stdout).toContain("--set-env");
  });

  test("start command should document --set-env and --dry-run", async () => {
    const { code, stdout } = await runCLI(["start", "--help"]);

    expect(code).toBe(0);
    expect(stdout).toContain("--set-env <var>");
    expect(stdout).toContain("set environment variable (format: KEY=value)");
    expect(stdout).toContain("--dry-run");
  });
});

describe("CLI instance .env", () => {
  let home: string;
  let docker: FakeDocker;
  let env: Record<string, string>;
  const defaultEnvPath = () => path.join(home, "runtime", "default", ".env");

  beforeEach(() => {
    home = makeTempDir("thezoo-cli-home");
    docker = createFakeDocker();
    env = { ...docker.env, THE_ZOO_HOME: home };
  });

  afterEach(() => {
    rmSync(home, { recursive: true, force: true });
    docker.cleanup();
  });

  test("should reject invalid environment variable format", async () => {
    for (const bad of ["INVALID_FORMAT", "1BAD=value", "=value"]) {
      const { code, stderr } = await runCLI(["start", "--set-env", bad, "--dry-run"], { env });

      expect(code).toBe(1);
      expect(stderr).toContain(`Invalid environment variable format: ${bad}`);
      expect(stderr).toContain("Expected format: KEY=value");
    }
  });

  test("should write --set-env values into the instance .env", async () => {
    const { code } = await runCLI(
      [
        "start",
        "--set-env",
        "CHAOS_MODE=1",
        "--set-env",
        "CHAOS_MODE_FAIL_PROBABILITY=0.5",
        "--set-env",
        "CHAOS_MODE_FAIL_SEED=12345",
        "--set-env",
        "CONNECTION_STRING=postgresql://user:pass@host:5432/db?option=value",
      ],
      { env },
    );

    expect(code).toBe(0);
    const lines = readEnvLines(defaultEnvPath());
    expect(lines).toContain("CHAOS_MODE=1");
    expect(lines).toContain("CHAOS_MODE_FAIL_PROBABILITY=0.5");
    expect(lines).toContain("CHAOS_MODE_FAIL_SEED=12345");
    expect(lines).toContain("CONNECTION_STRING=postgresql://user:pass@host:5432/db?option=value");
    expect(lines).toContain("ZOO_PROXY_PORT=3128");
    const project = `thezoo-cli-instance-default-${versionSuffix}`;
    expect(lines).toContain(`COMPOSE_PROJECT_NAME=${project}`);
    expect(docker.calls()).toContainEqual(
      expect.arrayContaining(["--env-file", defaultEnvPath(), "-p", project, "up", "-d"]),
    );
  });

  test("should write a custom proxy port into the instance .env", async () => {
    const { code } = await runCLI(["start", "--port", "8080"], { env });

    expect(code).toBe(0);
    expect(readEnvLines(defaultEnvPath())).toContain("ZOO_PROXY_PORT=8080");
  });

  test("should reject a proxy port docker can't publish without saving it", async () => {
    const cases = [
      { args: ["start", "--port", "abc"], name: "--port", value: "abc" },
      { args: ["start", "--port", "80abc"], name: "--port", value: "80abc" },
      { args: ["start", "--port", "0"], name: "--port", value: "0" },
      { args: ["start", "--port", "65536"], name: "--port", value: "65536" },
      {
        args: ["start", "--set-env", "ZOO_PROXY_PORT=abc"],
        name: "--set-env ZOO_PROXY_PORT",
        value: "abc",
      },
    ];
    for (const { args, name, value } of cases) {
      const { code, stderr } = await runCLI(args, { env });

      expect(code, args.join(" ")).toBe(1);
      expect(stderr).toContain(`Invalid ${name}: "${value}"`);
      expect(stderr).toContain("Expected an integer from 1 to 65535");
    }
    expect(existsSync(path.join(home, "runtime"))).toBe(false);
    expect(docker.calls().some((args) => args.includes("up"))).toBe(false);
  });

  test("restart should reject an invalid port before stopping the instance", async () => {
    const project = `thezoo-cli-instance-default-${versionSuffix}`;
    const running = createFakeDocker({ projects: [project] });
    try {
      const { code, stderr } = await runCLI(["restart", "--port", "abc"], {
        env: { ...env, ...running.env },
      });

      expect(code).toBe(1);
      expect(stderr).toContain('Invalid --port: "abc"');
      expect(running.calls().some((args) => args.includes("down"))).toBe(false);
      expect(existsSync(path.join(home, "runtime"))).toBe(false);
    } finally {
      running.cleanup();
    }
  });

  test("dry-run should not create the instance .env", async () => {
    const { code, stdout } = await runCLI(
      ["start", "--port", "4000", "--set-env", "CHAOS_MODE=1", "--dry-run"],
      { env },
    );

    expect(code).toBe(0);
    expect(stdout).toContain("ZOO_PROXY_PORT=4000");
    expect(stdout).toContain("CHAOS_MODE=1");
    expect(existsSync(path.join(home, "runtime"))).toBe(false);
  });

  test("dry-run should leave an existing instance .env unchanged", async () => {
    const created = await runCLI(["create"], { env });
    const instanceId = created.stdout.match(/Instance ID: (\w+)/)?.[1];
    const envPath = path.join(home, "runtime", `${instanceId}`, ".env");
    const before = readFileSync(envPath, "utf-8");

    const { code, stdout } = await runCLI(
      ["start", "--instance", `${instanceId}`, "--port", "4000", "--set-env", "X=1", "--dry-run"],
      { env },
    );

    expect(code).toBe(0);
    expect(stdout).toContain("ZOO_PROXY_PORT=4000");
    expect(stdout).toContain("X=1");
    expect(readFileSync(envPath, "utf-8")).toBe(before);
    expect(docker.calls().some((args) => args.includes("up"))).toBe(false);
  });

  test("should keep an existing instance's network config and update its settings", async () => {
    // A base outside the allocator's ranges, which only --ip-base keeps
    const created = await runCLI(["create", "--ip-base", "10.50.100.1"], { env });
    expect(created.code).toBe(0);
    const instanceId = created.stdout.match(/Instance ID: (\w+)/)?.[1];
    expect(instanceId).toBeTruthy();
    const envPath = path.join(home, "runtime", `${instanceId}`, ".env");
    const networkLines = readEnvLines(envPath).filter((line) => line.startsWith("ZOO_SUBNET"));

    const first = await runCLI(
      ["start", "--instance", `${instanceId}`, "--port", "3999", "--set-env", "CHAOS_MODE=1"],
      { env },
    );
    expect(first.code).toBe(0);

    const second = await runCLI(
      ["start", "--instance", `${instanceId}`, "--set-env", "CHAOS_MODE=0"],
      { env },
    );
    expect(second.code).toBe(0);

    const lines = readEnvLines(envPath);
    expect(lines).toContain("ZOO_DNS_IP=10.50.100.2");
    expect(lines).toContain("ZOO_CADDY_IP=10.50.100.3");
    expect(lines).toContain("ZOO_PROXY_IP=10.50.100.4");
    expect(lines.filter((line) => line.startsWith("ZOO_SUBNET"))).toEqual(networkLines);
    expect(lines.filter((line) => line.startsWith("ZOO_PROXY_PORT="))).toEqual([
      "ZOO_PROXY_PORT=3999",
    ]);
    expect(lines.filter((line) => line.startsWith("CHAOS_MODE="))).toEqual(["CHAOS_MODE=0"]);
  });

  test("should move an instance off a subnet another Docker network now uses", async () => {
    const created = await runCLI(["create"], { env });
    const instanceId = created.stdout.match(/Instance ID: (\w+)/)?.[1];
    const project = `thezoo-cli-instance-${instanceId}-${versionSuffix}`;
    const envPath = path.join(home, "runtime", `${instanceId}`, ".env");
    const saved = readEnv(envPath);

    // The instance's own (running) network is not a conflict
    const own = dockerWithNetwork(saved.ZOO_SUBNET, project);
    try {
      const { code } = await runCLI(["start", "--instance", `${instanceId}`], {
        env: { ...env, ...own.env },
      });
      expect(code).toBe(0);
      expect(readEnv(envPath)).toEqual(saved);
    } finally {
      own.cleanup();
    }

    const other = dockerWithNetwork(saved.ZOO_SUBNET, "someone-else");
    try {
      const { code, stdout } = await runCLI(
        ["start", "--instance", `${instanceId}`, "--set-env", "KEEP=1"],
        { env: { ...env, ...other.env } },
      );

      expect(code).toBe(0);
      const moved = readEnv(envPath);
      expect(stdout).toContain(
        `Subnet ${saved.ZOO_SUBNET} of instance "${instanceId}" overlaps another Docker network; moving it to ${moved.ZOO_SUBNET}`,
      );
      expect(moved.ZOO_SUBNET).not.toBe(saved.ZOO_SUBNET);
      expect(moved.ZOO_SUBNET).toMatch(/^172\.(1[7-9]|2[4-9]|3[01])\.0\.0\/16$/);
      const prefix = moved.ZOO_SUBNET.replace(/0\.0\/16$/, "");
      for (const key of ["ZOO_DNS_IP", "ZOO_CADDY_IP", "ZOO_PROXY_IP"]) {
        expect(moved[key].startsWith(prefix), key).toBe(true);
      }
      expect(moved).toMatchObject({ ZOO_PROXY_PORT: "3128", KEEP: "1" });
      expect(other.calls()).toContainEqual(
        expect.arrayContaining(["--env-file", envPath, "up", "-d"]),
      );
    } finally {
      other.cleanup();
    }
  });

  test("should move a network an older CLI saved and fill in its port and project", async () => {
    const envPath = path.join(home, "runtime", "old", ".env");
    mkdirSync(path.dirname(envPath), { recursive: true });
    // Without ZOO_PUBLIC_SUBNET compose would use the dev environment's 172.21.0.0/30
    writeFileSync(
      envPath,
      [
        "ZOO_SUBNET=172.25.0.0/16",
        "ZOO_DNS_IP=172.25.250.2",
        "ZOO_CADDY_IP=172.25.250.3",
        "ZOO_PROXY_IP=172.25.250.4",
        "CHAOS_MODE=1",
        "",
      ].join("\n"),
    );

    const { code, stdout } = await runCLI(["start", "--instance", "old"], { env });

    expect(code).toBe(0);
    const updated = readEnv(envPath);
    expect(stdout).toContain(
      `Network 172.25.0.0/16, public (none) of instance "old" was saved by an older CLI; ` +
        `moving it to ${updated.ZOO_SUBNET} (public ${updated.ZOO_PUBLIC_SUBNET})`,
    );
    expect(updated.ZOO_PUBLIC_SUBNET).toMatch(/^172\.16\.\d+\.\d+\/30$/);
    expect(updated).toMatchObject({
      COMPOSE_PROJECT_NAME: `thezoo-cli-instance-old-${versionSuffix}`,
      ZOO_PROXY_PORT: "3128",
      CHAOS_MODE: "1",
    });
    expect(stdout).toContain("Proxy: http://localhost:3128");
  });

  test("restart after an upgrade should keep the previous version's port and --set-env values", async () => {
    const instances = path.join(home, "instances");
    const writeInstanceEnv = (version: string, lines: string[]) => {
      mkdirSync(path.join(instances, version, "default"), { recursive: true });
      writeFileSync(path.join(instances, version, "default", ".env"), `${lines.join("\n")}\n`);
    };
    const oldProject = "thezoo-cli-instance-default-v0-0-10";
    writeInstanceEnv("v0.0.9", ["ZOO_PROXY_PORT=3100", "CHAOS_MODE=0"]);
    writeInstanceEnv("v0.0.10", [
      `COMPOSE_PROJECT_NAME=${oldProject}`,
      "ZOO_SUBNET=172.25.0.0/16",
      "ZOO_PUBLIC_SUBNET=172.16.0.8/30",
      "ZOO_DNS_IP=172.25.250.2",
      "ZOO_CADDY_IP=172.25.250.3",
      "ZOO_PROXY_IP=172.25.250.4",
      "ZOO_PROXY_PORT=3200",
      "PROXY_USER=",
      "CHAOS_MODE=1",
      // Tie the old instance to its own version's images and compose files
      "ZOO_IMAGE_TAG=0.0.10",
      "COMPOSE_FILE=docker-compose.yaml",
    ]);
    writeInstanceEnv("v999.0.0", ["ZOO_PROXY_PORT=3999", "CHAOS_MODE=2"]);
    // Sources copied by an earlier run, since the CLI sources ship none
    const instanceDir = path.join(instances, `v${cliPackageJson.version}`, "default");
    mkdirSync(instanceDir, { recursive: true });
    writeFileSync(path.join(instanceDir, "docker-compose.yaml"), "");

    const running = createFakeDocker({ projects: [oldProject] });
    try {
      const { code, stdout, stderr } = await runCLI(["restart"], {
        env: { ...env, ...running.env, ZOO_DEV: undefined },
      });

      expect(code, stderr).toBe(0);
      expect(running.calls()).toContainEqual(expect.arrayContaining(["-p", oldProject, "down"]));
      expect(stdout).toContain(
        'Keeping ZOO_PROXY_PORT, CHAOS_MODE of instance "default" from v0.0.10',
      );
      const upgraded = readEnv(path.join(instanceDir, ".env"));
      expect(upgraded).toMatchObject({
        COMPOSE_PROJECT_NAME: `thezoo-cli-instance-default-${versionSuffix}`,
        ZOO_PROXY_PORT: "3200",
        CHAOS_MODE: "1",
      });
      expect(upgraded).not.toHaveProperty("ZOO_IMAGE_TAG");
      expect(upgraded).not.toHaveProperty("COMPOSE_FILE");
      expect(stdout).toContain("Proxy: http://localhost:3200");
    } finally {
      running.cleanup();
    }
  });

  test("should refuse to start an instance another CLI version is running", async () => {
    const oldProject = "thezoo-cli-instance-default-v0-0-10";
    const running = createFakeDocker({ projects: [oldProject] });
    try {
      const { code, stderr } = await runCLI(["start"], { env: { ...env, ...running.env } });

      expect(code).toBe(1);
      expect(stderr).toContain(
        `Instance "default" is running under another CLI version (${oldProject})`,
      );
      expect(stderr).toContain('Run "the_zoo restart"');
      expect(running.calls().some((args) => args.includes("up"))).toBe(false);
    } finally {
      running.cleanup();
    }
  });

  test("should keep the network of an --ip-base instance an older CLI created", async () => {
    const envPath = path.join(home, "runtime", "legacy", ".env");
    mkdirSync(path.dirname(envPath), { recursive: true });
    // Older CLIs didn't record ZOO_IP_BASE and put the public /30 in the next /16
    const network = [
      "ZOO_SUBNET=10.50.0.0/16",
      "ZOO_PUBLIC_SUBNET=10.51.0.0/30",
      "ZOO_DNS_IP=10.50.100.2",
      "ZOO_CADDY_IP=10.50.100.3",
      "ZOO_PROXY_IP=10.50.100.4",
    ];
    writeFileSync(envPath, `${[...network, "ZOO_PROXY_PORT=3300"].join("\n")}\n`);

    const { code, stdout } = await runCLI(["start", "--instance", "legacy"], { env });

    expect(code).toBe(0);
    expect(stdout).not.toContain("moving it");
    const lines = readEnvLines(envPath);
    expect(lines).toEqual(expect.arrayContaining([...network, "ZOO_IP_BASE=10.50.100.1"]));
  });

  test("should give an --ip-base instance a new public subnet when its own is taken", async () => {
    const created = await runCLI(["create", "--ip-base", "10.50.100.1"], { env });
    const instanceId = created.stdout.match(/Instance ID: (\w+)/)?.[1];
    const envPath = path.join(home, "runtime", `${instanceId}`, ".env");
    const saved = readEnv(envPath);

    const other = dockerWithNetwork(saved.ZOO_PUBLIC_SUBNET, "someone-else");
    try {
      const { code, stdout } = await runCLI(["start", "--instance", `${instanceId}`], {
        env: { ...env, ...other.env },
      });

      expect(code).toBe(0);
      const updated = readEnv(envPath);
      expect(updated.ZOO_PUBLIC_SUBNET).toMatch(/^172\.16\.\d+\.\d+\/30$/);
      expect(updated.ZOO_PUBLIC_SUBNET).not.toBe(saved.ZOO_PUBLIC_SUBNET);
      expect(stdout).toContain(
        `Public subnet ${saved.ZOO_PUBLIC_SUBNET} of instance "${instanceId}" is missing or taken; moving it to ${updated.ZOO_PUBLIC_SUBNET}`,
      );
      expect({ ...updated, ZOO_PUBLIC_SUBNET: saved.ZOO_PUBLIC_SUBNET }).toEqual(saved);
    } finally {
      other.cleanup();
    }
  });

  test("should refuse to start an --ip-base instance whose subnet is now taken", async () => {
    const created = await runCLI(["create", "--ip-base", "172.30.100.1"], { env });
    const instanceId = created.stdout.match(/Instance ID: (\w+)/)?.[1];
    const envPath = path.join(home, "runtime", `${instanceId}`, ".env");
    const before = readFileSync(envPath, "utf-8");

    const other = dockerWithNetwork("172.30.0.0/16", "someone-else");
    try {
      const { code, stderr } = await runCLI(["start", "--instance", `${instanceId}`], {
        env: { ...env, ...other.env },
      });

      expect(code).toBe(1);
      expect(stderr).toContain(
        `Subnet 172.30.0.0/16 of instance "${instanceId}" (from --ip-base 172.30.100.1) overlaps an existing Docker network`,
      );
      expect(stderr).toContain(`the_zoo clean --instance ${instanceId}`);
      expect(readFileSync(envPath, "utf-8")).toBe(before);
      expect(other.calls().some((args) => args.includes("up"))).toBe(false);
    } finally {
      other.cleanup();
    }
  });

  test("should show docker commands and network IPs in dry-run mode", async () => {
    const { code, stdout } = await runCLI(["start", "--dry-run"], { env });

    expect(code).toBe(0);
    expect(stdout).toContain("Commands that would be run:");
    expect(stdout).toContain("docker compose up -d");
    expect(stdout).toContain("docker compose --profile on-demand up -d --no-start");
    expect(stdout).toMatch(/ZOO_DNS_IP=172\.\d+\.\d+\.2/);
    expect(stdout).toMatch(/ZOO_CADDY_IP=172\.\d+\.\d+\.3/);
    expect(stdout).toMatch(/ZOO_PROXY_IP=172\.\d+\.\d+\.4/);
  });
});
