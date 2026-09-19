import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import cliPackageJson from "../../cli/package.json" with { type: "json" };
import { pull } from "../../cli/lib/commands/pull";
import * as docker from "../../cli/lib/utils/docker";
import { CliError } from "../../cli/lib/utils/errors";
import * as project from "../../cli/lib/utils/project";

vi.hoisted(() => {
  process.env.THE_ZOO_HOME = "/test/.the_zoo";
  delete process.env.ZOO_DEV;
});

// Mock modules
vi.mock("../../cli/lib/utils/docker", () => ({
  checkDocker: vi.fn(),
  dockerCompose: vi.fn(),
}));

vi.mock("../../cli/lib/utils/project", () => ({
  getProjectName: vi.fn(),
}));

const version = cliPackageJson.version;
const projectVersion = `v${version.replace(/\./g, "-")}`;

describe("pull command", () => {
  const mockCheckDocker = docker.checkDocker as ReturnType<typeof vi.fn>;
  const mockDockerCompose = docker.dockerCompose as ReturnType<typeof vi.fn>;
  const mockGetProjectName = project.getProjectName as ReturnType<typeof vi.fn>;

  beforeEach(() => {
    vi.clearAllMocks();
    // Mock console methods to avoid output during tests
    vi.spyOn(console, "log").mockImplementation(() => {});
    vi.spyOn(process.stderr, "write").mockImplementation(() => true);
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("should check if Docker is running before pulling", async () => {
    mockCheckDocker.mockResolvedValue(false);

    await expect(pull({})).rejects.toThrow(
      new CliError("Docker is not running. Please start Docker first."),
    );
    expect(mockDockerCompose).not.toHaveBeenCalled();
  });

  it("should pull every profile from the instance's own sources", async () => {
    mockCheckDocker.mockResolvedValue(true);
    mockGetProjectName.mockResolvedValue(`thezoo-cli-instance-mytest-${projectVersion}`);
    mockDockerCompose.mockResolvedValue("");

    await pull({ instance: "mytest" });

    expect(mockGetProjectName).toHaveBeenCalledWith("mytest");
    expect(mockDockerCompose).toHaveBeenCalledWith(["--profile", "*", "pull", "--quiet"], {
      cwd: `/test/.the_zoo/instances/v${version}/mytest`,
      projectName: `thezoo-cli-instance-mytest-${projectVersion}`,
      envFile: undefined,
      showCommand: false,
    });
  });

  it("should use current directory for development environment", async () => {
    mockCheckDocker.mockResolvedValue(true);
    mockGetProjectName.mockResolvedValue("thezoo"); // Non-CLI instance name
    mockDockerCompose.mockResolvedValue("");

    await pull({});

    expect(mockDockerCompose).toHaveBeenCalledWith(
      ["--profile", "*", "pull", "--quiet"],
      expect.objectContaining({ cwd: process.cwd(), projectName: "thezoo" }),
    );
  });

  it("should handle errors when no instances are running", async () => {
    mockCheckDocker.mockResolvedValue(true);
    mockGetProjectName.mockRejectedValue(new Error("No Zoo CLI instances are currently running"));

    await expect(pull({})).rejects.toMatchObject({
      name: "CliError",
      message: "No Zoo CLI instances are currently running",
      hint: 'Run "the_zoo start" first to create an instance',
    });
    expect(mockDockerCompose).not.toHaveBeenCalled();
  });

  it("should handle docker compose pull failures", async () => {
    mockCheckDocker.mockResolvedValue(true);
    mockGetProjectName.mockResolvedValue(`thezoo-cli-instance-test-${projectVersion}`);
    mockDockerCompose.mockRejectedValue(new Error("Failed to pull images"));

    await expect(pull({})).rejects.toThrow(new CliError("Failed to pull images"));
  });
});
