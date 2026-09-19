import { chmodSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { createFakeDocker, type FakeDocker, makeTempDir, runCLI } from "./helpers";

describe("the_zoo email commands", () => {
  let home: string;
  let docker: FakeDocker | undefined;

  function envWith(options: Parameters<typeof createFakeDocker>[0] = {}): Record<string, string> {
    docker = createFakeDocker(options);
    return { ...docker.env, THE_ZOO_HOME: home };
  }

  beforeEach(() => {
    home = makeTempDir("thezoo-email-home");
  });

  afterEach(() => {
    rmSync(home, { recursive: true, force: true });
    docker?.cleanup();
  });

  it("should show available subcommands", async () => {
    const { stdout } = await runCLI(["email", "--help"]);
    expect(stdout).toContain("Manage email accounts and send/receive emails");
    expect(stdout).toContain("users");
    expect(stdout).toContain("send");
    expect(stdout).toContain("inbox");
    expect(stdout).toContain("swaks");
  });

  it("should show help for users command", async () => {
    const { stdout } = await runCLI(["email", "users", "--help"]);
    expect(stdout).toContain("List all email users");
    expect(stdout).toContain("--domain <domain>");
  });

  it("users should fail without a running instance", async () => {
    const { code, stderr } = await runCLI(["email", "users"], { env: envWith() });

    expect(code).toBe(1);
    expect(stderr).toContain("No Zoo CLI instances are currently running");
  });

  it("users should query the API through the instance's proxy port", async () => {
    const project = "thezoo-cli-instance-abc-v0-9-0";
    const env = envWith({
      projects: [project],
      rules: [
        {
          match: `^compose -p ${project} ps proxy --format json`,
          stdout: '{"Service":"proxy","Publishers":[{"PublishedPort":3141}]}\n',
        },
      ],
    });
    const curlDir = makeTempDir("thezoo-fake-curl");
    writeFileSync(
      `${curlDir}/curl`,
      `#!/bin/sh\necho "$*" > "${curlDir}/args"\necho '{"data":{"items":[{"type":"individual","name":"a@zoo"}]}}'\n`,
    );
    chmodSync(`${curlDir}/curl`, 0o755);

    try {
      const { code, stdout } = await runCLI(["email", "users"], {
        env: { ...env, PATH: `${curlDir}:${env.PATH}` },
      });

      expect(code).toBe(0);
      expect(stdout).toContain("a@zoo");
      expect(readFileSync(`${curlDir}/args`, "utf-8")).toContain("--proxy http://localhost:3141");
    } finally {
      rmSync(curlDir, { recursive: true, force: true });
    }
  });

  it("should show help for send command", async () => {
    const { stdout } = await runCLI(["email", "send", "--help"]);
    expect(stdout).toContain("Send an email");
    expect(stdout).toContain("--from");
    expect(stdout).toContain("--to");
    expect(stdout).toContain("--subject");
    expect(stdout).toContain("--body");
    expect(stdout).toContain("--password <password>");
  });

  it("send should require --from, --to, --subject and --body", async () => {
    const env = envWith();
    for (const args of [
      ["--to", "test@example.com"],
      ["--from", "test@example.com"],
    ]) {
      const { code, stderr } = await runCLI(["email", "send", ...args], { env });

      expect(code).toBe(1);
      expect(stderr).toContain("Required options: --from, --to, --subject, --body");
    }
  });

  it("should show help for inbox command", async () => {
    const { stdout } = await runCLI(["email", "inbox", "--help"]);
    expect(stdout).toContain("Check email inbox using IMAP");
    expect(stdout).toContain("--user <email>");
    expect(stdout).toContain("--folder <name>");
    expect(stdout).toContain("--limit <number>");
  });

  it("inbox should fail without a running instance", async () => {
    const { code, stderr } = await runCLI(
      ["email", "inbox", "--user", "test@example.com", "--password", "testpass"],
      { env: envWith() },
    );

    expect(code).toBe(1);
    expect(stderr).toContain("No Zoo CLI instances are currently running");
  });
});
