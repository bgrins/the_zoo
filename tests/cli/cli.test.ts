import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import path from "node:path";
import { describe, expect, test } from "vitest";
import cliPackageJson from "../../cli/package.json" with { type: "json" };

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const cliPath = path.join(__dirname, "..", "..", "cli", "bin", "thezoo.ts");

interface CLIResult {
  code: number | null;
  stdout: string;
  stderr: string;
}

/**
 * Helper function to run CLI commands
 */
function runCLI(args: string[]): Promise<CLIResult> {
  return new Promise((resolve, reject) => {
    const proc = spawn("npx", ["tsx", cliPath, ...args], {
      env: { ...process.env },
    });

    let stdout = "";
    let stderr = "";

    proc.stdout.on("data", (data) => {
      stdout += data.toString();
    });

    proc.stderr.on("data", (data) => {
      stderr += data.toString();
    });

    proc.on("close", (code) => {
      resolve({ code, stdout, stderr });
    });

    proc.on("error", (err) => {
      reject(err);
    });
  });
}

describe("CLI version", () => {
  test("should display version from package.json", async () => {
    const { code, stdout } = await runCLI(["--version"]);

    expect(code).toBe(0);
    expect(stdout.trim()).toBe(cliPackageJson.version);
  });
});

describe("CLI --set-env option", () => {
  test("should show help for start command with --set-env option", async () => {
    const { code, stdout } = await runCLI(["start", "--help"]);

    expect(code).toBe(0);
    expect(stdout).toContain("--set-env <var>");
    expect(stdout).toContain("set environment variable (format: KEY=value)");
    expect(stdout).toContain("--dry-run");
    expect(stdout).toContain("show what would be executed without actually running");
  });

  test("should reject invalid environment variable format", async () => {
    const { code, stderr } = await runCLI(["start", "--set-env", "INVALID_FORMAT"]);

    expect(code).toBe(1);
    expect(stderr).toContain("Invalid environment variable format");
    expect(stderr).toContain("Expected format: KEY=value");
  });

  test("should accept valid environment variable format", async () => {
    const {
      code,
      stdout: _stdout,
      stderr,
    } = await runCLI([
      "start",
      "--set-env",
      "TEST_VAR=test_value",
      "--help", // Just check parsing, don't actually start
    ]);

    expect(code).toBe(0);
    expect(stderr).not.toContain("Invalid environment variable format");
  });

  test("should accept multiple --set-env options", async () => {
    const {
      code,
      stdout: _stdout,
      stderr,
    } = await runCLI([
      "start",
      "--set-env",
      "VAR1=value1",
      "--set-env",
      "VAR2=value2",
      "--help", // Just check parsing, don't actually start
    ]);

    expect(code).toBe(0);
    expect(stderr).not.toContain("Invalid environment variable format");
  });

  test("should handle environment variables with equals signs in values", async () => {
    const {
      code,
      stdout: _stdout,
      stderr,
    } = await runCLI([
      "start",
      "--set-env",
      "CONNECTION_STRING=postgresql://user:pass@host:5432/db?option=value",
      "--help", // Just check parsing, don't actually start
    ]);

    expect(code).toBe(0);
    expect(stderr).not.toContain("Invalid environment variable format");
  });

  test("should handle chaos mode environment variables", async () => {
    const {
      code,
      stdout: _stdout,
      stderr,
    } = await runCLI([
      "start",
      "--set-env",
      "CHAOS_MODE=1",
      "--set-env",
      "CHAOS_MODE_FAIL_PROBABILITY=0.5",
      "--set-env",
      "CHAOS_MODE_FAIL_SEED=12345",
      "--help", // Just check parsing, don't actually start
    ]);

    expect(code).toBe(0);
    expect(stderr).not.toContain("Invalid environment variable format");
  });
});

describe("CLI --dry-run option", () => {
  test("should show environment variables in dry-run mode", async () => {
    const { code, stdout } = await runCLI([
      "start",
      "--set-env",
      "CHAOS_MODE=1",
      "--set-env",
      "CHAOS_MODE_FAIL_PROBABILITY=0.5",
      "--dry-run",
    ]);

    expect(code).toBe(0);
    expect(stdout).toContain("Dry run mode");
    expect(stdout).toContain("Environment variables:");
    expect(stdout).toContain("CHAOS_MODE=1");
    expect(stdout).toContain("CHAOS_MODE_FAIL_PROBABILITY=0.5");
    expect(stdout).toContain("ZOO_PROXY_PORT=3128");
  });

  test("should show custom proxy port in dry-run mode", async () => {
    const { code, stdout } = await runCLI([
      "start",
      "--proxy-port",
      "8080",
      "--set-env",
      "TEST_VAR=123",
      "--dry-run",
    ]);

    expect(code).toBe(0);
    expect(stdout).toContain("ZOO_PROXY_PORT=8080");
    expect(stdout).toContain("TEST_VAR=123");
  });

  test("should show network IP environment variables in dry-run mode", async () => {
    const { code, stdout } = await runCLI(["start", "--dry-run"]);

    expect(code).toBe(0);
    expect(stdout).toContain("Environment variables:");

    // Check that all network IPs are present and follow the correct pattern
    // Format: 172.X.Y.Z where X is subnet (21-220), Y is high range (240-255), Z is service number
    const ipPattern = /ZOO_DNS_IP=172\.\d{1,3}\.\d{1,3}\.2/;
    const caddyPattern = /ZOO_CADDY_IP=172\.\d{1,3}\.\d{1,3}\.3/;
    const proxyPattern = /ZOO_PROXY_IP=172\.\d{1,3}\.\d{1,3}\.4/;

    expect(stdout).toMatch(ipPattern);
    expect(stdout).toMatch(caddyPattern);
    expect(stdout).toMatch(proxyPattern);
  });

  test("should show docker commands in dry-run mode", async () => {
    const { code, stdout, stderr } = await runCLI(["start", "--dry-run"]);

    if (code !== 0) {
      console.error("CLI failed with stderr:", stderr);
      console.error("CLI stdout:", stdout);
    }

    expect(code).toBe(0);
    expect(stdout).toContain("Commands that would be run:");
    expect(stdout).toContain("docker compose");
    expect(stdout).toContain("up -d");
    expect(stdout).toContain("--profile on-demand");
  });
});
