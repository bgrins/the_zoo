import { describe, it, beforeAll, afterAll, expect } from "vitest";
import fs from "node:fs/promises";
import path from "node:path";
import os from "node:os";
import { paths, ensureDirectories, getProjectName } from "../../cli/lib/utils/config";

describe("CLI Config Utils", () => {
  const testDir = path.join(os.tmpdir(), `thezoo-cli-test-${Date.now()}`);
  const originalZooDev = process.env.ZOO_DEV;

  beforeAll(async () => {
    // Create test directory
    await fs.mkdir(testDir, { recursive: true });
  });

  afterAll(async () => {
    // Restore ZOO_DEV
    if (originalZooDev !== undefined) {
      process.env.ZOO_DEV = originalZooDev;
    } else {
      delete process.env.ZOO_DEV;
    }
    // Clean up test directory
    await fs.rm(testDir, { recursive: true, force: true });
  });

  describe("paths configuration", () => {
    it("should use appropriate directory based on ZOO_DEV", () => {
      // Since the paths are computed at module load time, we can't easily test
      // different ZOO_DEV values in the same process with ES modules
      // Instead, we'll test the actual behavior based on current ZOO_DEV
      const isDevelopment = process.env.ZOO_DEV === "1";

      if (isDevelopment) {
        expect(paths.home).toContain(".the_zoo");
        // In development, it uses a relative path which might still include homedir
        // depending on where the code is located
      } else {
        expect(paths.home).toContain(os.homedir());
        expect(paths.home).toContain(".the_zoo");
      }
    });

    it("should contain expected path properties", () => {
      expect(paths.home).toBeTruthy();
      expect(paths.runtime).toBeTruthy();
      expect(paths.config).toBeTruthy();

      expect(paths.runtime).toContain("runtime");
      expect(paths.config).toContain("config.json");
    });
  });

  describe("ensureDirectories", () => {
    it("should create runtime directory", async () => {
      const customPaths = {
        runtime: path.join(testDir, "runtime"),
      };

      // Mock the paths
      const originalRuntime = paths.runtime;
      paths.runtime = customPaths.runtime;

      try {
        await ensureDirectories();

        const stats = await fs.stat(customPaths.runtime);
        expect(stats.isDirectory()).toBe(true);
      } finally {
        paths.runtime = originalRuntime;
      }
    });
  });

  describe("getProjectName", () => {
    it("should generate valid Docker project names", () => {
      const testCases = [
        { input: "simple", expectedBase: "thezoo-cli-instance-simple" },
        { input: "-spe.cial!@#chars_1", expectedBase: "thezoo-cli-instance--spe-cial---chars-1" },
      ];

      for (const { input, expectedBase } of testCases) {
        const result = getProjectName(input);
        // Check that it starts with the expected base and includes version
        expect(result).toMatch(new RegExp(`^${expectedBase}-v\\d+-\\d+-\\d+$`));
      }
    });

    it("should handle empty string", () => {
      const result = getProjectName("");
      expect(result).toMatch(/^thezoo-cli-instance--v\d+-\d+-\d+$/);
    });

    it("should handle very long instance IDs", () => {
      const longId = "a".repeat(100);
      const result = getProjectName(longId);
      expect(result.startsWith("thezoo-cli-instance-")).toBe(true);
      expect(result.length).toBeGreaterThan(20);
    });
  });
});
