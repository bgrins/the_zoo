import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import path from "node:path";
import { describe, expect, test } from "vitest";

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
      env: { ...process.env, NODE_ENV: "development" },
      cwd: path.join(__dirname, "..", ".."), // Run from project root
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

describe("CLI shell command", () => {
  test("shell redis ping returns PONG", async () => {
    const { code, stdout, stderr } = await runCLI(["shell", "redis", "ping"]);

    // The command should succeed if redis is running, or fail gracefully if not
    if (code === 0) {
      expect(stdout).toContain("PONG");
    } else {
      // If redis isn't running, we should get a clear error message
      expect(stderr).toMatch(
        /Redis container not found|No Zoo CLI instances are currently running|service "redis" is not running/,
      );
    }
  });

  test("shell postgres version check", async () => {
    const { code, stdout, stderr } = await runCLI(["shell", "postgres", "-c", "SELECT version();"]);

    // The command should succeed if postgres is running, or fail gracefully if not
    if (code === 0) {
      expect(stdout).toContain("PostgreSQL");
    } else {
      // If postgres isn't running, we should get a clear error message
      expect(stderr).toMatch(
        /PostgreSQL container not found|No Zoo CLI instances are currently running/,
      );
    }
  });

  test("shell command shows help", async () => {
    const { code, stdout } = await runCLI(["shell", "--help"]);

    expect(code).toBe(0);
    expect(stdout).toContain("Run shell commands for Zoo services");
    expect(stdout).toContain("--instance");
    expect(stdout).toContain("redis");
    expect(stdout).toContain("postgres");
    expect(stdout).toContain("stalwart");
    expect(stdout).toContain("mysql");
  });

  test("shell stalwart version check", async () => {
    const { code, stdout, stderr } = await runCLI(["shell", "stalwart", "--", "--version"]);

    // The command should succeed if stalwart is running, or fail gracefully if not
    if (code === 0) {
      expect(stdout).toContain("stalwart-cli");
    } else {
      // If stalwart isn't running, we should get a clear error message
      expect(stderr).toMatch(
        /Stalwart container not found|No Zoo CLI instances are currently running/,
      );
    }
  });

  test("shell mysql version check", async () => {
    const { code, stdout, stderr } = await runCLI(["shell", "mysql", "--", "--version"]);

    // The command should succeed if mysql is running, or fail gracefully if not
    if (code === 0) {
      expect(stdout).toContain("mysql");
    } else {
      // If mysql isn't running, we should get a clear error message
      expect(stderr).toMatch(
        /MySQL container not found|No Zoo CLI instances are currently running|service "mysql" is not running/,
      );
    }
  });
});
