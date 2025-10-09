import { exec } from "node:child_process";
import { promisify } from "node:util";
import { beforeAll, describe, expect, test } from "vitest";
import { getCachedNetworkInfo } from "../utils/test-cache";
import { fetchWithProxy } from "../utils/http-client";

const execAsync = promisify(exec);
const PROXY_URL = "http://localhost:3128";

describe("SMTP Email Tests", () => {
  beforeAll(async () => {
    // Ensure network info is cached for other tests
    await getCachedNetworkInfo();

    // Verify proxy is accessible before running tests
    try {
      const result = await fetchWithProxy("http://example.zoo", { timeout: 5000 });
      expect(result.httpCode).toBeGreaterThanOrEqual(200);
      expect(result.httpCode).toBeLessThan(500);
    } catch (_error) {
      throw new Error(
        `Proxy at ${PROXY_URL} is not accessible. This test requires the proxy to be running.`,
      );
    }
  });

  test("stalwart SMTP service should be healthy", async () => {
    // Check if stalwart is running and accepting connections
    const cmd = `docker compose ps stalwart --format json | head -1`;
    const { stdout } = await execAsync(cmd);
    const containerInfo = JSON.parse(stdout);

    expect(containerInfo.State).toBe("running");
    expect(containerInfo.Health).toBe("healthy");
  });

  test("email can be sent between seeded users using CLI", async () => {
    // Use seeded users alex.chen and blake.sullivan
    const testId = Date.now();
    const subject = `Test Email ${testId}`;

    // Send email using CLI
    const { stdout, stderr } = await execAsync(
      `npm run cli -- email swaks --from alex.chen@snappymail.zoo --to blake.sullivan@snappymail.zoo --server stalwart:25 --header "Subject: ${subject}" --body "Automated test email from SMTP test suite"`,
    );

    // Verify email was sent successfully
    expect(stderr).toBe("");
    expect(stdout).toContain("Connected to stalwart");
    expect(stdout).toContain("250 2.0.0 Message queued");
  });

  test("email users command should list seeded users", async () => {
    const { stdout } = await execAsync("npm run cli -- email users");

    // Check for seeded users
    expect(stdout).toContain("alex.chen@snappymail.zoo");
    expect(stdout).toContain("blake.sullivan@snappymail.zoo");
    expect(stdout).toContain("admin@snappymail.zoo");
    expect(stdout).toContain("user@snappymail.zoo");
    expect(stdout).toContain("mallory@snappymail.zoo");
    expect(stdout).toContain("Total: 20 users");
  });

  test("multiple emails can be sent in succession using CLI", async () => {
    const baseTime = Date.now();
    const emailPromises = [];

    // Send 3 emails in quick succession
    for (let i = 0; i < 3; i++) {
      const subject = `Batch Test ${baseTime}-${i}`;
      emailPromises.push(
        execAsync(
          `npm run cli -- email swaks --from alex.chen@snappymail.zoo --to blake.sullivan@snappymail.zoo --server stalwart:25 --header "Subject: ${subject}" --body "Batch email ${i}"`,
        ),
      );
    }

    const results = await Promise.all(emailPromises);

    // All emails should succeed
    for (let i = 0; i < results.length; i++) {
      const result = results[i];
      expect(result.stderr).toBe("");
      expect(result.stdout).toContain("250 2.0.0 Message queued");
    }
  });

  test("email can be sent between different zoo domains using CLI", async () => {
    const testCases = [
      { from: "admin@zoo", to: "test@zoo" },
      { from: "alex.chen@snappymail.zoo", to: "blake.sullivan@snappymail.zoo" },
      { from: "admin@snappymail.zoo", to: "user@snappymail.zoo" },
    ];

    for (const testCase of testCases) {
      const { stdout, stderr } = await execAsync(
        `npm run cli -- email swaks --from ${testCase.from} --to ${testCase.to} --server stalwart:25 --header "Subject: Cross-user test" --body "Testing email between users"`,
      );

      expect(stderr, `Email from ${testCase.from} to ${testCase.to} failed`).toBe("");
      expect(stdout).toContain("250 2.0.0 Message queued");
    }
  });

  test("email inbox command should read emails from inbox", async () => {
    // First send a test email
    const testId = Date.now();
    const subject = `Check Test ${testId}`;

    await execAsync(
      `npm run cli -- email swaks --from alex.chen@snappymail.zoo --to blake.sullivan@snappymail.zoo --server stalwart:25 --header "Subject: ${subject}" --body "Test email for inbox check"`,
    );

    // Give email time to be delivered
    await new Promise((resolve) => setTimeout(resolve, 1000));

    // Check Blake's inbox
    const { stdout } = await execAsync(
      `npm run cli -- email inbox --user blake.sullivan@snappymail.zoo --password "Password.123" --limit 5`,
    );

    expect(stdout).toContain("Checking INBOX for blake.sullivan@snappymail.zoo");
    expect(stdout).toContain("Messages:");
  });
});
