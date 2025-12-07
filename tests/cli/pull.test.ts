import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { pull } from "../../cli/lib/commands/pull";
import * as docker from "../../cli/lib/utils/docker";
import * as project from "../../cli/lib/utils/project";

// Mock modules
vi.mock("../../cli/lib/utils/docker", () => ({
  checkDocker: vi.fn(),
  dockerCompose: vi.fn(),
  isRunningFromZooRepository: vi.fn(),
}));

vi.mock("../../cli/lib/utils/project", () => ({
  getProjectName: vi.fn(),
}));

vi.mock("../../cli/lib/utils/config", () => ({
  paths: {
    runtime: "/test/.the_zoo/runtime",
  },
}));

describe("pull command", () => {
  const mockCheckDocker = docker.checkDocker as ReturnType<typeof vi.fn>;
  const mockDockerCompose = docker.dockerCompose as ReturnType<typeof vi.fn>;
  const mockGetProjectName = project.getProjectName as ReturnType<typeof vi.fn>;
  const mockIsRunningFromZooRepository = docker.isRunningFromZooRepository as ReturnType<
    typeof vi.fn
  >;

  beforeEach(() => {
    vi.clearAllMocks();
    // Mock console methods to avoid output during tests
    vi.spyOn(console, "log").mockImplementation(() => {});
    vi.spyOn(console, "error").mockImplementation(() => {});
    vi.spyOn(process, "exit").mockImplementation((code) => {
      throw new Error(`Process exited with code ${code}`);
    });
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("should check if Docker is running before pulling", async () => {
    mockCheckDocker.mockResolvedValue(false);

    await expect(pull({})).rejects.toThrow("Process exited with code 1");
    expect(mockCheckDocker).toHaveBeenCalled();
    expect(console.error).toHaveBeenCalledWith(expect.stringContaining("Docker is not running"));
  });

  it("should pull all profiles including on-demand", async () => {
    mockCheckDocker.mockResolvedValue(true);
    mockGetProjectName.mockResolvedValue("thezoo-cli-instance-test-v0-0-2");
    mockDockerCompose.mockResolvedValue("");
    mockIsRunningFromZooRepository.mockReturnValue(false);

    await pull({});

    expect(mockDockerCompose).toHaveBeenCalledWith(
      "--profile '*' pull --quiet",
      expect.objectContaining({
        projectName: "thezoo-cli-instance-test-v0-0-2",
        showCommand: false,
      }),
    );
  });

  it("should use the correct zoo source path for CLI instances", async () => {
    mockCheckDocker.mockResolvedValue(true);
    mockGetProjectName.mockResolvedValue("thezoo-cli-instance-mytest-v0-0-2");
    mockDockerCompose.mockResolvedValue("");

    await pull({ instance: "mytest" });

    expect(mockDockerCompose).toHaveBeenCalledWith(
      "--profile '*' pull --quiet",
      expect.objectContaining({
        cwd: "/test/.the_zoo/runtime/mytest/zoo",
      }),
    );
  });

  it("should use current directory for development environment", async () => {
    mockCheckDocker.mockResolvedValue(true);
    mockGetProjectName.mockResolvedValue("thezoo"); // Non-CLI instance name
    mockDockerCompose.mockResolvedValue("");

    const originalCwd = process.cwd();
    await pull({});

    expect(mockDockerCompose).toHaveBeenCalledWith(
      "--profile '*' pull --quiet",
      expect.objectContaining({
        cwd: originalCwd,
      }),
    );
  });

  it("should handle errors when no instances are running", async () => {
    mockCheckDocker.mockResolvedValue(true);
    mockGetProjectName.mockRejectedValue(new Error("No Zoo CLI instances are currently running"));

    await expect(pull({})).rejects.toThrow("Process exited with code 1");
    expect(console.error).toHaveBeenCalledWith(
      expect.stringContaining("No Zoo CLI instances are currently running"),
    );
  });

  it("should handle docker compose pull failures", async () => {
    mockCheckDocker.mockResolvedValue(true);
    mockGetProjectName.mockResolvedValue("thezoo-cli-instance-test-v0-0-2");
    mockDockerCompose.mockRejectedValue(new Error("Failed to pull images"));

    await expect(pull({})).rejects.toThrow("Process exited with code 1");
    expect(console.error).toHaveBeenCalledWith(expect.stringContaining("Failed to pull images"));
  });
});
