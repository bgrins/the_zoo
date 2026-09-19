import { existsSync, rmSync } from "node:fs";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import cliPackageJson from "../../cli/package.json" with { type: "json" };
import { createFakeDocker, type FakeDocker, makeTempDir, ROOT_DIR, runCLI } from "./helpers";

const versionSuffix = `v${cliPackageJson.version.replace(/\./g, "-")}`;

describe("the_zoo create command", () => {
  let home: string;
  let docker: FakeDocker;
  let env: Record<string, string>;

  beforeEach(() => {
    home = makeTempDir("thezoo-create-home");
    docker = createFakeDocker();
    env = { ...docker.env, THE_ZOO_HOME: home };
  });

  afterEach(() => {
    rmSync(home, { recursive: true, force: true });
    docker.cleanup();
  });

  test("should show help for create command", async () => {
    const { stdout } = await runCLI(["create", "--help"]);
    expect(stdout).toContain("Prepare a new Zoo instance without starting it");
    expect(stdout).toContain("--dry-run");
  });

  test("dry-run should show the real instance directory and project name", async () => {
    const { code, stdout, stderr } = await runCLI(["create", "--dry-run"], { env });

    expect(code).toBe(0);
    expect(stderr).toBe("");
    const instanceId = stdout.match(/Instance ID: (\w+)/)?.[1];
    expect(instanceId).toBeTruthy();
    expect(stdout).toContain(`Instance directory: ${path.join(home, "runtime", `${instanceId}`)}`);
    expect(stdout).toContain(`Project name: thezoo-cli-instance-${instanceId}-${versionSuffix}`);
    expect(stdout).toContain(`Then start it with: the_zoo start --instance ${instanceId}`);
    expect(existsSync(path.join(home, "runtime", `${instanceId}`))).toBe(false);
  });

  test("dev mode without THE_ZOO_HOME should keep state in the repository root", async () => {
    const { code, stdout } = await runCLI(["create", "--dry-run"]);

    expect(code).toBe(0);
    expect(stdout).toContain(`Instance directory: ${path.join(ROOT_DIR, ".the_zoo", "runtime")}`);
  });

  test("should generate unique instance IDs", async () => {
    const { stdout: stdout1 } = await runCLI(["create", "--dry-run"], { env });
    const { stdout: stdout2 } = await runCLI(["create", "--dry-run"], { env });

    const id1 = stdout1.match(/Instance ID: (\w+)/)?.[1];
    const id2 = stdout2.match(/Instance ID: (\w+)/)?.[1];

    expect(id1).toBeTruthy();
    expect(id2).toBeTruthy();
    expect(id1).not.toBe(id2);
    expect(id1).not.toBe("default");
  });

  test("should create an instance that start accepts, and clean should remove it", async () => {
    const created = await runCLI(["create"], { env });
    expect(created.code).toBe(0);
    const instanceId = created.stdout.match(/Instance ID: (\w+)/)?.[1];
    expect(instanceId).toBeTruthy();
    const instanceDir = path.join(home, "runtime", `${instanceId}`);

    expect(created.stdout).toContain("New Zoo instance prepared!");
    expect(created.stdout).toContain(`Instance directory: ${instanceDir}`);
    expect(created.stdout).toContain(`the_zoo start --instance ${instanceId}`);
    expect(existsSync(path.join(instanceDir, ".env"))).toBe(true);

    const started = await runCLI(["start", "--instance", `${instanceId}`, "--dry-run"], { env });
    expect(started.code).toBe(0);
    expect(started.stdout).toContain(`Using instance: ${instanceId}`);

    const cleaned = await runCLI(["clean", "--instance", `${instanceId}`, "--force"], { env });
    expect(cleaned.code).toBe(0);
    expect(cleaned.stdout).toContain(`Instance "${instanceId}" has been cleaned up`);
    expect(existsSync(instanceDir)).toBe(false);

    const restarted = await runCLI(["start", "--instance", `${instanceId}`, "--dry-run"], { env });
    expect(restarted.code).toBe(1);
    expect(restarted.stderr).toContain(`Instance "${instanceId}" does not exist`);
  });

  test("clean should stop the instance's Docker resources", async () => {
    const created = await runCLI(["create"], { env });
    const instanceId = created.stdout.match(/Instance ID: (\w+)/)?.[1];
    const project = `thezoo-cli-instance-${instanceId}-${versionSuffix}`;
    const fake = createFakeDocker({
      rules: [
        {
          match: "^ps -a --filter label=com.docker.compose.project --format",
          stdout: `${project}\n`,
        },
        {
          match: `^ps -a -q --filter label=com.docker.compose.project=${project}$`,
          stdout: "c1\n",
        },
        {
          match: `^network ls -q --filter label=com.docker.compose.project=${project}$`,
          stdout: "n1\n",
        },
      ],
    });

    try {
      const cleaned = await runCLI(["clean", "--instance", `${instanceId}`, "--force"], {
        env: { ...env, ...fake.env },
      });

      expect(cleaned.code).toBe(0);
      const calls = fake.calls().map((args) => args.join(" "));
      expect(calls).toContain("rm -f c1");
      expect(calls).toContain("network rm n1");
      expect(calls).toContain(
        `image prune -f --filter label=com.docker.compose.project=${project}`,
      );
    } finally {
      fake.cleanup();
    }
  });
});
