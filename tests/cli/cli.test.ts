import { existsSync, readFileSync, rmSync } from "node:fs";
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
    expect(docker.calls()).toContainEqual(
      expect.arrayContaining(["--env-file", defaultEnvPath(), "up", "-d"]),
    );
  });

  test("should write a custom proxy port into the instance .env", async () => {
    const { code } = await runCLI(["start", "--port", "8080"], { env });

    expect(code).toBe(0);
    expect(readEnvLines(defaultEnvPath())).toContain("ZOO_PROXY_PORT=8080");
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
    const created = await runCLI(["create", "--ip-base", "172.30.100.1"], { env });
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
    expect(lines).toContain("ZOO_DNS_IP=172.30.100.2");
    expect(lines).toContain("ZOO_CADDY_IP=172.30.100.3");
    expect(lines).toContain("ZOO_PROXY_IP=172.30.100.4");
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
