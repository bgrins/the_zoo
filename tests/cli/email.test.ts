import { exec } from "node:child_process";
import { promisify } from "node:util";
import { describe, expect, it } from "vitest";

const execAsync = promisify(exec);
const CLI_PATH = "ZOO_DEV=1 tsx cli/bin/thezoo.ts";

describe("thezoo email commands", () => {
  describe("email command", () => {
    it("should show available subcommands", async () => {
      const { stdout } = await execAsync(`${CLI_PATH} email --help`);
      expect(stdout).toContain("Manage email accounts and send/receive emails");
      expect(stdout).toContain("users");
      expect(stdout).toContain("send");
      expect(stdout).toContain("inbox");
      expect(stdout).toContain("swaks");
    });
  });

  describe("email users", () => {
    it("should show help for users command", async () => {
      const { stdout } = await execAsync(`${CLI_PATH} email users --help`);
      expect(stdout).toContain("List all email users");
      expect(stdout).toContain("--domain <domain>");
      expect(stdout).toContain("filter by domain");
    });

    it("should fail without running instance", async () => {
      try {
        // Default is production mode (only CLI instances)
        await execAsync(`tsx cli/bin/thezoo.ts email users`);
        expect.fail("Command should have failed due to no running instance");
      } catch (error: any) {
        const errorOutput = error.stderr || error.stdout || error.message || "";
        expect(errorOutput).toContain("No Zoo CLI instances are currently running");
      }
    });
  });

  describe("email send", () => {
    it("should show help for send command", async () => {
      const { stdout } = await execAsync(`${CLI_PATH} email send --help`);
      expect(stdout).toContain("Send an email");
      expect(stdout).toContain("--from");
      expect(stdout).toContain("sender email address");
      expect(stdout).toContain("--to");
      expect(stdout).toContain("recipient email address");
      expect(stdout).toContain("--subject");
      expect(stdout).toContain("email subject");
      expect(stdout).toContain("--body");
      expect(stdout).toContain("email body");
      expect(stdout).toContain("--password <password>");
    });

    it("should require --from option", async () => {
      try {
        await execAsync(`${CLI_PATH} email send --to test@example.com`);
        expect.fail("Command should have failed");
      } catch (error: any) {
        const errorOutput = error.stderr || error.stdout || error.message || "";
        expect(errorOutput).toContain("Required options:");
        expect(errorOutput).toContain("--from");
      }
    });

    it("should require --to option", async () => {
      try {
        await execAsync(`${CLI_PATH} email send --from test@example.com`);
        expect.fail("Command should have failed");
      } catch (error: any) {
        const errorOutput = error.stderr || error.stdout || error.message || "";
        expect(errorOutput).toContain("Required options:");
        expect(errorOutput).toContain("--to");
      }
    });
  });

  describe("email inbox", () => {
    it("should show help for inbox command", async () => {
      const { stdout } = await execAsync(`${CLI_PATH} email inbox --help`);
      expect(stdout).toContain("Check email inbox using IMAP");
      expect(stdout).toContain("--user <email>");
      expect(stdout).toContain("email account to check");
      expect(stdout).toContain("--folder <name>");
      expect(stdout).toContain("mailbox folder to check");
      expect(stdout).toContain("--limit <number>");
      expect(stdout).toContain("number of emails to show");
    });

    it("should fail without running instance", async () => {
      try {
        // Default is production mode (only CLI instances)
        await execAsync(
          `tsx cli/bin/thezoo.ts email inbox --user test@example.com --password testpass`,
        );
        expect.fail("Command should have failed due to no running instance");
      } catch (error: any) {
        const errorOutput = error.stderr || error.stdout || error.message || "";
        expect(errorOutput).toContain("No Zoo CLI instances are currently running");
      }
    });
  });

  describe("email swaks", () => {
    it.skip("should show help for swaks command", async () => {
      // Skipping as swaks --help fails when container doesn't exist
      const { stdout } = await execAsync(`${CLI_PATH} email swaks --help`);
      expect(stdout).toContain("Run swaks email testing tool");
      expect(stdout).toContain("(pass-through to swaks)");
      expect(stdout).toContain("--instance <id>");
      expect(stdout).toContain("--dry-run");
    });
  });
});
