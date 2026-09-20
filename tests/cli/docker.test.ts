import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { dockerCompose, getEnhancedPath, getRunningInstances } from "../../cli/lib/utils/docker";
import { createFakeDocker, type FakeDocker, ROOT_DIR } from "./helpers";

describe("Docker Utils", () => {
  let fake: FakeDocker;
  const originalEnv = { ...process.env };

  function useFakeDocker(options: Parameters<typeof createFakeDocker>[0]) {
    fake = createFakeDocker(options);
    Object.assign(process.env, fake.env);
  }

  beforeEach(() => {
    vi.spyOn(console, "log").mockImplementation(() => {});
  });

  afterEach(() => {
    process.env = { ...originalEnv };
    fake?.cleanup();
    vi.restoreAllMocks();
  });

  describe("getRunningInstances", () => {
    it("returns only CLI instances when onlyCliInstances is true", async () => {
      useFakeDocker({ projects: ["the_zoo", "thezoo-cli-instance-abc-v0-9-0", "unrelated"] });

      const instances = await getRunningInstances({ onlyCliInstances: true });

      expect(instances).toEqual(["thezoo-cli-instance-abc-v0-9-0"]);
    });

    it("includes non-CLI projects running Zoo core services, listed first", async () => {
      useFakeDocker({
        projects: ["thezoo-cli-instance-abc-v0-9-0", "the_zoo", "unrelated"],
        rules: [
          { match: "^compose -p the_zoo ps", stdout: '{"Service":"caddy"}\n{"Service":"proxy"}\n' },
          { match: "^compose -p unrelated ps", stdout: '{"Service":"web"}\n' },
        ],
      });

      const instances = await getRunningInstances({ onlyCliInstances: false });

      expect(instances).toEqual(["the_zoo", "thezoo-cli-instance-abc-v0-9-0"]);
    });
  });

  describe("getEnhancedPath", () => {
    it("keeps a Windows PATH as it is", () => {
      const windowsPath = "C:\\Program Files\\Docker\\Docker\\resources\\bin;C:\\Windows\\system32";

      expect(getEnhancedPath(windowsPath, "win32")).toBe(windowsPath);
    });

    it("appends the Docker locations missing from a Unix PATH", () => {
      expect(getEnhancedPath("/custom/bin:/usr/bin", "darwin").split(":")).toEqual([
        "/custom/bin",
        "/usr/bin",
        "/usr/local/bin",
        "/bin",
        "/opt/homebrew/bin",
        "/usr/local/opt/docker/bin",
        "/Applications/Docker.app/Contents/Resources/bin",
      ]);
    });
  });

  describe("dockerCompose", () => {
    it("passes arguments through without shell quoting", async () => {
      useFakeDocker({});

      await dockerCompose(["--profile", "*", "pull", "--quiet"], {
        cwd: ROOT_DIR,
        projectName: "thezoo-cli-instance-abc-v0-9-0",
        envFile: "/zoo/home/.env",
        showCommand: false,
      });

      expect(fake.calls()).toEqual([
        [
          "compose",
          "-f",
          `${ROOT_DIR}/docker-compose.yaml`,
          "--env-file",
          "/zoo/home/.env",
          "-p",
          "thezoo-cli-instance-abc-v0-9-0",
          "--profile",
          "*",
          "pull",
          "--quiet",
        ],
      ]);
    });
  });
});
