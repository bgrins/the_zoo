import { describe, it, expect } from "vitest";
import { execSync } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

describe("thezoo create network options", () => {
  const cliPath = path.resolve(__dirname, "../../cli/bin/thezoo.ts");
  const command = `npx tsx ${cliPath}`;

  function runCLI(args: string[]): { code: number; stdout: string; stderr: string } {
    try {
      const stdout = execSync(`${command} ${args.join(" ")}`, {
        encoding: "utf8",
        env: { ...process.env, NODE_ENV: "production" },
      });
      return { code: 0, stdout, stderr: "" };
    } catch (error: any) {
      return {
        code: error.status || 1,
        stdout: error.stdout?.toString() || "",
        stderr: error.stderr?.toString() || "",
      };
    }
  }

  it("should show custom base IP in dry-run", async () => {
    const { code, stdout } = runCLI(["create", "--dry-run", "--ip-base", "10.10.100.50"]);

    expect(code).toBe(0);
    expect(stdout).toContain("Custom base IP: 10.10.100.50");
    expect(stdout).toContain("Service IPs will be: 10.10.100.50 + 1, 2, 3");
  });

  it("should show defaults when no custom options", async () => {
    const { code, stdout } = runCLI(["create", "--dry-run"]);

    expect(code).toBe(0);
    expect(stdout).toContain("Network: <randomly generated with high-range IPs>");
  });
});
