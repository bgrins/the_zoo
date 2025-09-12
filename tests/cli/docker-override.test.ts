import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import * as docker from "../../cli/lib/utils/docker";

// Mock node modules
vi.mock("node:child_process", () => ({
  spawn: vi.fn(),
  exec: vi.fn(),
}));

vi.mock("node:fs", () => ({
  existsSync: vi.fn(),
}));

vi.mock("../../cli/lib/utils/verbose", () => ({
  getVerbose: vi.fn(() => false),
  logVerboseCommand: vi.fn(),
}));

describe("Docker Compose Package Override", () => {
  const mockSpawn = spawn as unknown as ReturnType<typeof vi.fn>;
  const mockExistsSync = existsSync as unknown as ReturnType<typeof vi.fn>;

  beforeEach(() => {
    vi.clearAllMocks();
    // Mock console to avoid output during tests
    vi.spyOn(console, "log").mockImplementation(() => {});
    vi.spyOn(console, "warn").mockImplementation(() => {});
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe("dockerCompose with package override", () => {
    it("should use package override when not in repository and override file exists", async () => {
      // Setup: Not in repository, override file exists
      mockExistsSync.mockImplementation((path: string) => {
        if (path.includes(".env.fresh")) return false; // Not in repo
        if (path.includes("docker-compose.packages.yaml")) return true; // Override exists
        return false;
      });

      // Mock spawn to return a successful process
      const mockProcess = {
        stdout: {
          on: vi.fn((event, callback) => {
            if (event === "data") callback(Buffer.from("Success"));
          }),
        },
        stderr: {
          on: vi.fn(),
        },
        on: vi.fn((event, callback) => {
          if (event === "close") callback(0);
        }),
      };
      mockSpawn.mockReturnValue(mockProcess);

      await docker.dockerCompose("pull", {
        cwd: "/test/zoo",
        projectName: "test-project",
      });

      // Verify spawn was called with override files
      expect(mockSpawn).toHaveBeenCalledWith(
        "docker",
        expect.arrayContaining([
          "compose",
          "-f",
          "/test/zoo/docker-compose.yaml",
          "-f",
          "/test/zoo/docker-compose.packages.yaml",
          "-p",
          "test-project",
          "pull",
        ]),
        expect.any(Object),
      );
    });

    it("should not use package override when in repository", async () => {
      // Setup: In repository (all marker files exist)
      mockExistsSync.mockImplementation((path: string) => {
        if (path.includes("docker-compose.yaml")) return true;
        if (path.includes(".env.fresh")) return true;
        if (path.includes("Caddyfile")) return true;
        if (path.includes("docker-compose.packages.yaml")) return true;
        return false;
      });

      // Mock spawn
      const mockProcess = {
        stdout: { on: vi.fn() },
        stderr: { on: vi.fn() },
        on: vi.fn((event, callback) => {
          if (event === "close") callback(0);
        }),
      };
      mockSpawn.mockReturnValue(mockProcess);

      await docker.dockerCompose("pull", {
        cwd: "/test/zoo",
        projectName: "test-project",
      });

      // Verify spawn was called with only the main compose file (no override since in repository)
      expect(mockSpawn).toHaveBeenCalledWith(
        "docker",
        expect.arrayContaining([
          "compose",
          "-f",
          "/test/zoo/docker-compose.yaml",
          "-p",
          "test-project",
          "pull",
        ]),
        expect.any(Object),
      );
      expect(mockSpawn).not.toHaveBeenCalledWith(
        "docker",
        expect.arrayContaining(["-f", "/test/zoo/docker-compose.packages.yaml"]),
        expect.any(Object),
      );
    });

    it("should not use package override when override file doesn't exist", async () => {
      // Setup: Not in repository, but override file doesn't exist
      mockExistsSync.mockReturnValue(false);

      // Mock spawn
      const mockProcess = {
        stdout: { on: vi.fn() },
        stderr: { on: vi.fn() },
        on: vi.fn((event, callback) => {
          if (event === "close") callback(0);
        }),
      };
      mockSpawn.mockReturnValue(mockProcess);

      await docker.dockerCompose("pull", {
        cwd: "/test/zoo",
        projectName: "test-project",
      });

      // Verify spawn was called with only the main compose file (no override)
      expect(mockSpawn).toHaveBeenCalledWith(
        "docker",
        expect.arrayContaining([
          "compose",
          "-f",
          "/test/zoo/docker-compose.yaml",
          "-p",
          "test-project",
          "pull",
        ]),
        expect.any(Object),
      );
      expect(mockSpawn).not.toHaveBeenCalledWith(
        "docker",
        expect.arrayContaining(["-f", "/test/zoo/docker-compose.packages.yaml"]),
        expect.any(Object),
      );
    });
  });

  describe("dockerComposeExecInteractive with package override", () => {
    it("should use package override for exec commands when appropriate", async () => {
      // Setup: Not in repository, override file exists
      mockExistsSync.mockImplementation((path: string) => {
        if (path.includes(".env.fresh")) return false; // Not in repo
        if (path.includes("docker-compose.packages.yaml")) return true; // Override exists
        return false;
      });

      // Mock spawn
      const mockProcess = {
        on: vi.fn((event, callback) => {
          if (event === "exit") callback(0);
        }),
      };
      mockSpawn.mockReturnValue(mockProcess);

      await docker.dockerComposeExecInteractive("postgres", ["psql"], {
        cwd: "/test/zoo",
        projectName: "test-project",
      });

      // Verify spawn was called with override files
      expect(mockSpawn).toHaveBeenCalledWith(
        "docker",
        expect.arrayContaining([
          "compose",
          "-f",
          "/test/zoo/docker-compose.yaml",
          "-f",
          "/test/zoo/docker-compose.packages.yaml",
          "-p",
          "test-project",
          "exec",
          "postgres",
          "psql",
        ]),
        expect.any(Object),
      );
    });
  });

  describe("isRunningFromZooRepository", () => {
    it("should return true when all marker files exist", () => {
      mockExistsSync.mockImplementation((path: string) => {
        if (path.includes("docker-compose.yaml")) return true;
        if (path.includes(".env.fresh")) return true;
        if (path.includes("Caddyfile")) return true;
        return false;
      });

      expect(docker.isRunningFromZooRepository()).toBe(true);
    });

    it("should return false when any marker file is missing", () => {
      mockExistsSync.mockImplementation((path: string) => {
        if (path.includes("docker-compose.yaml")) return true;
        if (path.includes(".env.fresh")) return false; // Missing this one
        if (path.includes("Caddyfile")) return true;
        return false;
      });

      expect(docker.isRunningFromZooRepository()).toBe(false);
    });

    it("should return false when all marker files are missing", () => {
      mockExistsSync.mockReturnValue(false);
      expect(docker.isRunningFromZooRepository()).toBe(false);
    });
  });
});
