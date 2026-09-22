import { afterAll, afterEach, beforeAll, describe, expect, it, vi } from "vitest";
import fs from "node:fs/promises";
import path from "node:path";
import os from "node:os";
import { paths, ensureDirectories, instanceProjectName } from "../../cli/lib/utils/config";
import { ROOT_DIR } from "./helpers";

async function loadConfig(env: { ZOO_DEV?: string; THE_ZOO_HOME?: string }) {
  vi.resetModules();
  vi.stubEnv("ZOO_DEV", env.ZOO_DEV ?? "");
  vi.stubEnv("THE_ZOO_HOME", env.THE_ZOO_HOME ?? "");
  return import("../../cli/lib/utils/config");
}

describe("CLI Config Utils", () => {
  const testDir = path.join(os.tmpdir(), `thezoo-cli-test-${Date.now()}`);

  beforeAll(async () => {
    await fs.mkdir(testDir, { recursive: true });
  });

  afterEach(() => {
    vi.unstubAllEnvs();
  });

  afterAll(async () => {
    await fs.rm(testDir, { recursive: true, force: true });
  });

  describe("paths configuration", () => {
    it("should use THE_ZOO_HOME when set", async () => {
      const config = await loadConfig({ ZOO_DEV: "1", THE_ZOO_HOME: testDir });

      expect(config.paths.home).toBe(testDir);
      expect(config.paths.runtime).toBe(path.join(testDir, "runtime"));
      expect(config.paths.instances).toBe(path.join(testDir, "instances"));
    });

    it("should keep development state and sources at the repository root", async () => {
      const config = await loadConfig({ ZOO_DEV: "1" });

      expect(config.paths.home).toBe(path.join(ROOT_DIR, ".the_zoo"));
      expect(config.getZooSourceRoot()).toBe(ROOT_DIR);
    });

    it("should use ~/.the_zoo in production and require the packaged sources", async () => {
      const config = await loadConfig({});

      expect(config.paths.home).toBe(path.join(os.homedir(), ".the_zoo"));
      expect(() => config.getZooSourceRoot()).toThrow("Could not find the packaged Zoo sources");
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

  describe("instanceProjectName", () => {
    it("should generate valid Docker project names", () => {
      const testCases = [
        { input: "simple", expectedBase: "thezoo-cli-instance-simple" },
        { input: "-spe.cial!@#chars_1", expectedBase: "thezoo-cli-instance--spe-cial---chars-1" },
      ];

      for (const { input, expectedBase } of testCases) {
        const result = instanceProjectName(input);
        // Check that it starts with the expected base and includes version
        expect(result).toMatch(new RegExp(`^${expectedBase}-v\\d+-\\d+-\\d+$`));
      }
    });

    it("should handle empty string", () => {
      const result = instanceProjectName("");
      expect(result).toMatch(/^thezoo-cli-instance--v\d+-\d+-\d+$/);
    });
  });
});
