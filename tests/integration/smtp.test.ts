import { exec } from "node:child_process";
import { promisify } from "node:util";
import { beforeAll, describe, expect, test } from "vitest";
import { personas } from "../../scripts/seed-data/personas";
import { PROXY_URL } from "../../scripts/lib/proxy";
import { EXTENDED_TEST_TIMEOUT } from "../constants";
import { getCachedNetworkInfo } from "../utils/test-cache";
import { fetchWithProxy } from "../../scripts/lib/http-client";

const execAsync = promisify(exec);

// Mail accounts in the golden Stalwart state that aren't personas
const NON_PERSONA_ACCOUNTS = [
  "admin@zoo",
  "newuser@zoo",
  "test@zoo",
  "user@snappymail.zoo",
  "user@zoo",
];

// Each CLI call starts an npm + tsx process, which gets slow under a loaded host
describe("SMTP Email Tests", { timeout: EXTENDED_TEST_TIMEOUT }, () => {
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

    const listed = [...stdout.matchAll(/^\s*• (\S+@\S+)/gm)].map((m) => m[1]).sort();
    const expected = [
      ...personas.map((p) => `${p.username}@snappymail.zoo`),
      ...NON_PERSONA_ACCOUNTS,
    ].sort();
    expect(listed).toEqual(expected);
    expect(stdout).toContain(`Total: ${expected.length} users`);
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

  test(
    "email inbox command should read emails from inbox",
    { timeout: EXTENDED_TEST_TIMEOUT },
    async () => {
      const testEnd = Date.now() + EXTENDED_TEST_TIMEOUT;
      const testId = Date.now();
      const subject = `Check Test ${testId}`;

      await execAsync(
        `npm run cli -- email swaks --from alex.chen@snappymail.zoo --to blake.sullivan@snappymail.zoo --server stalwart:25 --header "Subject: ${subject}" --body "Test email for inbox check"`,
      );

      // Delivery is asynchronous; poll the newest messages until ours arrives. Polling stops
      // when another poll as long as the last would end within a second of the test timeout,
      // so a miss reports the assertion below instead of timing out.
      let stdout = "";
      let poll = 0;
      while (!stdout.includes(`Subject: ${subject}`) && Date.now() + poll + 1000 < testEnd) {
        const pollStart = Date.now();
        if (stdout) await new Promise((resolve) => setTimeout(resolve, 1000));
        ({ stdout } = await execAsync(
          `npm run cli -- email inbox --user blake.sullivan@snappymail.zoo --password "Password.123" --limit 5`,
        ));
        poll = Date.now() - pollStart;
      }

      expect(stdout).toContain("Checking INBOX for blake.sullivan@snappymail.zoo");
      expect(stdout, "sent message never reached the inbox").toContain(`Subject: ${subject}`);
    },
  );
});
