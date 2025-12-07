import { exec } from "node:child_process";
import { promisify } from "node:util";
import { describe, expect, it } from "vitest";

const execAsync = promisify(exec);
const CLI_PATH = "ZOO_DEV=1 tsx cli/bin/thezoo.ts";

describe("thezoo status command", () => {
  it("should show help for status command", async () => {
    const { stdout } = await execAsync(`${CLI_PATH} status --help`);
    expect(stdout).toContain("Show status of running Zoo instances");
    expect(stdout).toContain("--instance <id>");
    expect(stdout).toContain("Show status for a specific instance");
  });

  it("should show no instances when none are running", async () => {
    // Default is production mode (only CLI instances)
    const { stdout } = await execAsync(`tsx cli/bin/thezoo.ts status`);
    expect(stdout).toContain("No Zoo CLI instances are currently running");
  });

  it("should support --instance option", async () => {
    const { stdout } = await execAsync(`${CLI_PATH} status --help`);
    expect(stdout).toContain("--instance <id>");
    expect(stdout).toContain("Show status for a specific instance");
  });
});
