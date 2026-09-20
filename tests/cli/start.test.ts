import { existsSync, readFileSync, rmSync } from "node:fs";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import { createFakeDocker, type FakeDocker, makeTempDir, ROOT_DIR, runCLI } from "./helpers";

describe("the_zoo start", () => {
  let home: string;
  let docker: FakeDocker;
  let env: Record<string, string>;
  const envPath = () => path.join(home, "runtime", "default", ".env");

  function upCalls() {
    return docker
      .calls()
      .filter((args) => args.includes("up"))
      .map((args) => args.slice(args.indexOf("-p") + 2));
  }

  beforeEach(() => {
    home = makeTempDir("thezoo-start-home");
    docker = createFakeDocker();
    env = { ...docker.env, THE_ZOO_HOME: home };
  });

  afterEach(() => {
    rmSync(home, { recursive: true, force: true });
    docker.cleanup();
  });

  test("should create the on-demand apps but not the heavy ones", async () => {
    const { code, stdout, stderr } = await runCLI(["start"], { env });

    expect(code, stderr).toBe(0);
    expect(upCalls()).toEqual([
      ["up", "-d"],
      ["--profile", "on-demand", "up", "-d", "--no-start", "miniflux"],
    ]);
    expect(stdout).toContain(
      'Heavy apps not created: postmill. Add them with "the_zoo start --with-heavy"',
    );
    expect(readFileSync(envPath(), "utf-8")).not.toContain("ZOO_WITH_HEAVY");
  });

  test("--with-heavy should create the heavy apps from then on", async () => {
    const first = await runCLI(["start", "--with-heavy"], { env });
    const second = await runCLI(["start"], { env });

    expect([first.code, second.code], first.stderr + second.stderr).toEqual([0, 0]);
    const onDemand = ["--profile", "on-demand", "up", "-d", "--no-start", "miniflux", "postmill"];
    expect(upCalls()).toEqual([["up", "-d"], onDemand, ["up", "-d"], onDemand]);
    expect(first.stdout + second.stdout).not.toContain("Heavy apps not created");
    expect(readFileSync(envPath(), "utf-8")).toMatch(/^ZOO_WITH_HEAVY=1$/m);
  });

  test.each([
    { args: ["--wait"], seconds: "300" },
    { args: ["--wait-timeout", "60"], seconds: "60" },
    { args: ["--wait", "--wait-timeout", "5"], seconds: "5" },
  ])("$args should wait for the core services to be healthy", async ({ args, seconds }) => {
    const { code, stdout, stderr } = await runCLI(["start", ...args], { env });

    expect(code, stderr).toBe(0);
    expect(upCalls()[0]).toEqual(["up", "-d", "--wait", "--wait-timeout", seconds]);
    expect(stdout).toContain("The Zoo is running and healthy!");
  });

  test.each([["start"], ["restart"]])(
    "%s should reject an invalid --wait-timeout before changing anything",
    async (command) => {
      const running = createFakeDocker({ projects: ["thezoo-cli-instance-default-v0-0-1"] });
      try {
        const { code, stderr } = await runCLI([command, "--wait-timeout", "1.5"], {
          env: { ...env, ...running.env },
        });

        expect(code).toBe(1);
        expect(stderr).toContain('Invalid --wait-timeout: "1.5"');
        expect(running.calls().some((args) => args.includes("up") || args.includes("down"))).toBe(
          false,
        );
        expect(existsSync(envPath())).toBe(false);
      } finally {
        running.cleanup();
      }
    },
  );

  test("should say where the CA certificate and the credentials are", async () => {
    const { code, stdout } = await runCLI(["start"], { env });

    expect(code).toBe(0);
    expect(stdout).toContain(`CA cert: ${path.join(ROOT_DIR, "core", "caddy", "root.crt")}\n`);
    expect(stdout).toContain(`Credentials: ${path.join(ROOT_DIR, "docs", "credentials")}\n`);
  });

  test("dry-run should say whether the heavy apps would be created", async () => {
    const without = await runCLI(["start", "--dry-run"], { env });
    const withHeavy = await runCLI(["start", "--dry-run", "--with-heavy"], { env });

    expect(without.stdout).toContain(
      "2. docker compose --profile on-demand up -d --no-start <the on-demand services, except the heavy profile's>",
    );
    expect(withHeavy.stdout).toContain(
      "2. docker compose --profile on-demand up -d --no-start <the on-demand services>",
    );
    expect(withHeavy.stdout).toContain("ZOO_WITH_HEAVY=1");
  });
});
