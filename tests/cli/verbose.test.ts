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
      env: { ...process.env, ZOO_DEV: "1" },
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

describe("CLI --verbose option", () => {
  test("should show help with --verbose option", async () => {
    const { code, stdout } = await runCLI(["--help"]);

    expect(code).toBe(0);
    expect(stdout).toContain("--verbose");
    expect(stdout).toContain("enable verbose output for all commands");
  });

  test("should show verbose output when --verbose is used with start dry-run", async () => {
    const { code, stdout } = await runCLI(["--verbose", "start", "--dry-run"]);

    expect(code).toBe(0);
    expect(stdout).toContain("[VERBOSE]");
    expect(stdout).toContain("Step:");
  });

  test("should not show verbose output when --verbose is not used", async () => {
    const { code, stdout } = await runCLI(["start", "--dry-run"]);

    expect(code).toBe(0);
    expect(stdout).not.toContain("[VERBOSE]");
  });

  test("should work with shell subcommand", async () => {
    const { code, stdout } = await runCLI(["--verbose", "shell", "--help"]);

    expect(code).toBe(0);
    expect(stdout).toContain("Run shell commands");
  });
});
