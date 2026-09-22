import os from "node:os";
import { rmSync } from "node:fs";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import { createFakeDocker, type FakeDocker, makeTempDir, ROOT_DIR, runCLI } from "./helpers";

// Outside the repository, where a CLI instance is the only kind of project there is
const run = (args: string[], options: Parameters<typeof runCLI>[1] = {}) =>
  runCLI(args, { cwd: os.tmpdir(), ...options });

const abc = "thezoo-cli-instance-abc-v0-9-0";
const def = "thezoo-cli-instance-def-v0-9-0";

describe("the_zoo compose", () => {
  let home: string;
  let docker: FakeDocker | undefined;

  function envWith(options: Parameters<typeof createFakeDocker>[0]) {
    docker = createFakeDocker(options);
    return { ...docker.env, THE_ZOO_HOME: home };
  }

  function composeCalls() {
    return docker?.calls().filter((args) => args[0] === "compose" && args.includes("-f"));
  }

  beforeEach(() => {
    home = makeTempDir("thezoo-compose-home");
  });

  afterEach(() => {
    rmSync(home, { recursive: true, force: true });
    docker?.cleanup();
  });

  test("should run docker compose for the running instance", async () => {
    const env = envWith({ projects: [abc] });

    const { code } = await run(["compose", "ps", "--services", "-a"], { env });

    expect(code).toBe(0);
    expect(composeCalls()).toEqual([
      [
        "compose",
        "-f",
        path.join(ROOT_DIR, "docker-compose.yaml"),
        "-p",
        abc,
        "ps",
        "--services",
        "-a",
      ],
    ]);
  });

  test("--instance should pick one of several running instances", async () => {
    const env = envWith({ projects: [abc, def] });

    const picked = await run(["compose", "--instance", "def", "logs", "caddy"], { env });
    const ambiguous = await run(["compose", "logs", "caddy"], { env });

    expect(picked.code).toBe(0);
    expect(composeCalls()).toEqual([
      ["compose", "-f", path.join(ROOT_DIR, "docker-compose.yaml"), "-p", def, "logs", "caddy"],
    ]);
    expect(ambiguous.code).toBe(1);
    expect(ambiguous.stderr).toContain("Multiple instances are running");
  });

  test("in the repository, runs for this checkout's project while an instance runs too", async () => {
    const checkout = "zoo-checkout";
    const env = envWith({
      projects: [abc, checkout],
      rules: [
        {
          match: `^compose -f ${ROOT_DIR}/docker-compose.yaml --profile \\* config --format json$`,
          stdout: JSON.stringify({ name: checkout, services: {} }),
        },
        { match: `^compose -p ${checkout} ps --format json$`, stdout: '{"Service":"caddy"}\n' },
      ],
    });

    const { code, stderr } = await runCLI(["compose", "ps"], { env, cwd: ROOT_DIR });

    expect(code, stderr).toBe(0);
    expect(composeCalls()?.at(-1)?.slice(-3)).toEqual(["-p", checkout, "ps"]);
  });

  test("should exit with docker compose's exit code", async () => {
    const env = envWith({
      projects: [abc],
      rules: [{ match: " exec -T redis false$", exitCode: 4 }],
    });

    const { code, stderr } = await run(["compose", "exec", "-T", "redis", "false"], { env });

    expect(code).toBe(4);
    expect(stderr).toBe("");
  });
});
