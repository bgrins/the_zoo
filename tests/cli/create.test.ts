import { exec } from "node:child_process";
import { promisify } from "node:util";
import { describe, test, expect } from "vitest";

const execAsync = promisify(exec);
const CLI_PATH = "ZOO_DEV=1 tsx cli/bin/thezoo.ts";

describe("thezoo create command", () => {
  test("should show help for create command", async () => {
    const { stdout } = await execAsync(`${CLI_PATH} create --help`);
    expect(stdout).toContain("Prepare a new Zoo instance without starting it");
    expect(stdout).toContain("--dry-run");
  });

  test("should create instance with dry-run mode", async () => {
    const { stdout, stderr } = await execAsync(`${CLI_PATH} create --dry-run`);

    expect(stderr).toBe("");
    expect(stdout).toContain("Creating new Zoo instance...");
    expect(stdout).toContain("Dry run mode - showing what would be created:");
    expect(stdout).toContain("Instance details:");
    expect(stdout).toContain("Instance ID:");
    expect(stdout).toContain("Instance directory: ~/.the_zoo/runtime/");
    expect(stdout).toContain("Project name: thezoo-cli-instance-");
    expect(stdout).toContain("To create this instance, run without --dry-run");
    expect(stdout).toContain("Then start it with: thezoo start --instance");
  });

  test("should generate unique instance IDs", async () => {
    const { stdout: stdout1 } = await execAsync(`${CLI_PATH} create --dry-run`);
    const { stdout: stdout2 } = await execAsync(`${CLI_PATH} create --dry-run`);

    // Extract instance IDs from outputs
    const idMatch1 = stdout1.match(/Instance ID: (\w+)/);
    const idMatch2 = stdout2.match(/Instance ID: (\w+)/);

    expect(idMatch1).toBeTruthy();
    expect(idMatch2).toBeTruthy();

    if (!idMatch1 || !idMatch2) {
      throw new Error("Failed to extract instance IDs");
    }

    expect(idMatch1[1]).not.toBe(idMatch2[1]);
    expect(idMatch1[1]).not.toBe("default");
    expect(idMatch2[1]).not.toBe("default");
  });

  test("should create and clean up actual instances", async () => {
    // Create an actual instance (not dry-run)
    const { stdout: createOutput } = await execAsync(`${CLI_PATH} create`);

    // Extract instance ID
    const idMatch = createOutput.match(/Instance ID: (\w+)/);
    expect(idMatch).toBeTruthy();

    if (!idMatch) {
      throw new Error("Failed to extract instance ID");
    }

    const instanceId = idMatch[1];

    // Verify output
    expect(createOutput).toContain("New Zoo instance prepared!");
    expect(createOutput).toContain(`Instance ID: ${instanceId}`);
    expect(createOutput).toContain("To start this instance:");
    expect(createOutput).toContain(`thezoo start --instance ${instanceId}`);

    // Clean up the instance
    const { stdout: cleanOutput } = await execAsync(
      `${CLI_PATH} clean --instance ${instanceId} --force`,
    );
    expect(cleanOutput).toContain(`Instance "${instanceId}" has been cleaned up`);

    // Verify instance is gone by trying to start it
    try {
      await execAsync(`${CLI_PATH} start --instance ${instanceId} --dry-run`);
      expect.fail("Should have thrown an error");
    } catch (error: any) {
      expect(error.stderr).toContain(`Instance "${instanceId}" does not exist`);
    }
  });
});
