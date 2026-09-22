import os from "node:os";
import { rmSync } from "node:fs";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import {
  createFakeCurl,
  createFakeDocker,
  type FakeDocker,
  makeTempDir,
  ROOT_DIR,
  runCLI,
} from "./helpers";

// Outside the repository, where a CLI instance is the only kind of project there is
const run = (args: string[], options: Parameters<typeof runCLI>[1] = {}) =>
  runCLI(args, { cwd: os.tmpdir(), ...options });

const project = "thezoo-cli-instance-def-v0-9-0";

describe("the_zoo email commands", () => {
  let home: string;
  let docker: FakeDocker | undefined;

  function envWith(options: Parameters<typeof createFakeDocker>[0] = {}): Record<string, string> {
    docker = createFakeDocker(options);
    return { ...docker.env, THE_ZOO_HOME: home };
  }

  function execCalls() {
    return docker?.calls().filter((args) => args.includes("exec"));
  }

  beforeEach(() => {
    home = makeTempDir("thezoo-email-home");
  });

  afterEach(() => {
    rmSync(home, { recursive: true, force: true });
    docker?.cleanup();
  });

  it("should show available subcommands", async () => {
    const { stdout } = await run(["email", "--help"]);
    expect(stdout).toContain("Manage email accounts and send/receive emails");
    expect(stdout).toContain("users");
    expect(stdout).toContain("send");
    expect(stdout).toContain("inbox");
    expect(stdout).toContain("swaks");
  });

  it("should show help for users command", async () => {
    const { stdout } = await run(["email", "users", "--help"]);
    expect(stdout).toContain("List all email users");
    expect(stdout).toContain("--domain <domain>");
  });

  it("users should fail without a running instance", async () => {
    const { code, stderr } = await run(["email", "users"], { env: envWith() });

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
    const curl = createFakeCurl('{"data":{"items":[{"type":"individual","name":"a@zoo"}]}}');

    try {
      const { code, stdout } = await run(["email", "users"], {
        env: { ...env, PATH: `${curl.dir}:${env.PATH}` },
      });

      expect(code).toBe(0);
      expect(curl.calls()).toEqual([
        "-s -k --proxy http://localhost:3141 -u admin:zoo-mail-admin-pw -H Content-Type: application/json https://mail-api.zoo/api/principal",
      ]);
      expect(stdout).toContain("  • a@zoo (No description)");
      expect(stdout).toContain("Total: 1 users");
    } finally {
      curl.cleanup();
    }
  });

  it("should show help for send command", async () => {
    const { stdout } = await run(["email", "send", "--help"]);
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
      const { code, stderr } = await run(["email", "send", ...args], { env });

      expect(code).toBe(1);
      expect(stderr).toContain("Required options: --from, --to, --subject, --body");
    }
  });

  it("send should send with swaks in the stalwart of the --instance", async () => {
    const env = envWith({ projects: ["thezoo-cli-instance-abc-v0-9-0", project] });
    const args = ["--from", "a@zoo", "--to", "b@zoo", "--subject", "Hi there", "--password", "pw"];

    const text = await run(["email", "--instance", "def", "send", ...args, "--body", "Hello"], {
      env,
    });
    const html = await run(
      ["email", "--instance", "def", "send", ...args, "--body", "<b>Hi</b>", "--html"],
      { env },
    );

    expect([text.code, html.code], text.stderr + html.stderr).toEqual([0, 0]);
    expect(text.stdout).toContain("Email sent successfully!");
    const swaks = [
      "compose",
      "-f",
      path.join(ROOT_DIR, "docker-compose.yaml"),
      "-p",
      project,
      "exec",
      "-T",
      "stalwart",
      "swaks",
      "--to",
      "b@zoo",
      "--from",
      "a@zoo",
      "--server",
      "stalwart:587",
      "--auth-user",
      "a@zoo",
      "--auth-password",
      "pw",
      "--header",
      "Subject: Hi there",
      "--tls",
    ];
    expect(execCalls()).toEqual([
      [...swaks, "--body", "Hello"],
      [...swaks, "--add-header", "Content-Type: text/html", "--body", "<b>Hi</b>"],
    ]);
  });

  it("send should fail when swaks does", async () => {
    const env = envWith({ projects: [project], rules: [{ match: " swaks ", exitCode: 2 }] });

    const { code, stderr } = await run(
      [
        "email",
        "send",
        "--from",
        "a@zoo",
        "--to",
        "b@zoo",
        "--subject",
        "s",
        "--body",
        "b",
        "--password",
        "pw",
      ],
      { env },
    );

    expect(code).toBe(1);
    expect(stderr).toContain("Failed to send email: swaks in stalwart exited with code 2");
  });

  it("inbox should show the newest --limit messages of the --folder", async () => {
    const env = envWith({
      projects: [project],
      rules: [
        { match: 'EXAMINE "Sent Items"$', stdout: "* FLAGS ()\r\n* 5 EXISTS\r\n* 0 RECENT\r\n" },
        { match: ";MAILINDEX=4$", stdout: "Subject: fourth\r\n" },
        { match: ";MAILINDEX=5$", stdout: "Subject: fifth\r\n" },
      ],
    });

    const { code, stdout, stderr } = await run(
      [
        "email",
        "inbox",
        "--user",
        "u@zoo",
        "--password",
        "pw",
        "--folder",
        "Sent Items",
        "--limit",
        "2",
      ],
      { env },
    );

    expect(code, stderr).toBe(0);
    const curl = ["exec", "-T", "stalwart", "curl", "-s", "-u", "u@zoo:pw"];
    expect(execCalls()?.map((args) => args.slice(args.indexOf("exec")))).toEqual([
      [...curl, "imap://localhost/Sent%20Items", "--request", 'EXAMINE "Sent Items"'],
      [...curl, "imap://localhost/Sent%20Items;MAILINDEX=5"],
      [...curl, "imap://localhost/Sent%20Items;MAILINDEX=4"],
    ]);
    expect(stdout).toContain("Messages: 5");
    expect(stdout).toMatch(
      /━━━ Message 5 ━━━\nSubject: fifth\r\n\n\n━━━ Message 4 ━━━\nSubject: fourth/,
    );
    expect(stdout).toContain("Showing 2 of 5 messages. Use --limit to see more.");
  });

  it("inbox should list the folders when the --folder doesn't exist", async () => {
    const env = envWith({
      projects: [project],
      rules: [
        { match: "EXAMINE Nope$", exitCode: 1 },
        {
          match: " imap://localhost$",
          stdout: '* LIST (\\HasNoChildren) "/" "INBOX"\r\n* LIST () "/" "Sent Items"\r\n',
        },
      ],
    });

    const { code, stderr } = await run(
      ["email", "inbox", "--user", "u@zoo", "--password", "pw", "--folder", "Nope"],
      { env },
    );

    expect(code).toBe(1);
    expect(stderr).toContain('Folder "Nope" not found or access denied.');
    expect(stderr).toContain("Available folders:\n  • INBOX\n  • Sent Items");
  });

  it("should show help for inbox command", async () => {
    const { stdout } = await run(["email", "inbox", "--help"]);
    expect(stdout).toContain("Check email inbox using IMAP");
    expect(stdout).toContain("--user <email>");
    expect(stdout).toContain("--folder <name>");
    expect(stdout).toContain("--limit <number>");
  });

  it("inbox should fail without a running instance", async () => {
    const { code, stderr } = await run(
      ["email", "inbox", "--user", "test@example.com", "--password", "testpass"],
      { env: envWith() },
    );

    expect(code).toBe(1);
    expect(stderr).toContain("No Zoo CLI instances are currently running");
  });
});
