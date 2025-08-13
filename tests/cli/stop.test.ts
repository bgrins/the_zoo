import { exec } from "node:child_process";
import { promisify } from "node:util";
import { describe, expect, it } from "vitest";

const execAsync = promisify(exec);
const CLI_PATH = "tsx cli/bin/thezoo.ts";

describe("thezoo stop command", () => {
  it("should show help for stop command", async () => {
    const { stdout } = await execAsync(`NODE_ENV=development ${CLI_PATH} stop --help`);
    expect(stdout).toContain("Stop The Zoo environment");
    expect(stdout).toContain("--all");
    expect(stdout).toContain("Stop all running Zoo CLI instances");
    expect(stdout).toContain("--instance <id>");
    expect(stdout).toContain("Stop a specific instance");
  });

  it("should show message when no instances are running", async () => {
    // Use NODE_ENV=production to only look for CLI instances
    const { stdout } = await execAsync(`NODE_ENV=production ${CLI_PATH} stop`);
    expect(stdout).toContain("No Zoo CLI instances are running");
  });

  it("should support --all option", async () => {
    const { stdout } = await execAsync(`NODE_ENV=development ${CLI_PATH} stop --help`);
    expect(stdout).toContain("--all");
    expect(stdout).toContain("Stop all running Zoo CLI instances");
  });

  it("should support --instance option", async () => {
    const { stdout } = await execAsync(`NODE_ENV=development ${CLI_PATH} stop --help`);
    expect(stdout).toContain("--instance <id>");
    expect(stdout).toContain("Stop a specific instance");
  });
});
