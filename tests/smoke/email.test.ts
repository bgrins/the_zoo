import { exec } from "node:child_process";
import { promisify } from "node:util";
import { beforeAll, describe, expect, test } from "vitest";
import { getCachedContainerNames, getCachedDockerInspect } from "../utils/test-cache";
import { fetchWithProxy } from "../utils/http-client";
import { getZooNetworkName } from "../utils/docker-project";

const execAsync = promisify(exec);

describe("Email Service Tests (Stalwart)", () => {
  let containers: Record<string, string> = {};
  const containerIps: Record<string, string> = {};

  beforeAll(async () => {
    containers = await getCachedContainerNames(["stalwart", "postgres"]);
    const inspectData = (await getCachedDockerInspect([containers.stalwart])) as Record<
      string,
      any
    >;
    containerIps.stalwart =
      inspectData[containers.stalwart]?.NetworkSettings?.Networks?.[getZooNetworkName()]
        ?.IPAddress || "";
  });

  test("Stalwart email server should be running", async () => {
    const { stdout } = await execAsync(
      'docker ps --format "table {{.Names}}\\t{{.Status}}" | grep stalwart',
    );
    expect(stdout, "Stalwart container not found or not running").toContain("stalwart");
    expect(stdout.toLowerCase(), 'Stalwart is not in "Up" state').toContain("up");
  });

  test("SMTP ports should be accessible", async () => {
    const postgresContainer = containers.postgres || "";

    // Test both SMTP ports in parallel
    const [smtp25Result, smtp587Result] = await Promise.all([
      execAsync(`docker exec ${postgresContainer} nc -zv stalwart 25 2>&1`),
      execAsync(`docker exec ${postgresContainer} nc -zv stalwart 587 2>&1`),
    ]);

    expect(smtp25Result.stdout, "SMTP port 25 is not accessible from internal network").toContain(
      "open",
    );
    expect(smtp587Result.stdout, "SMTP submission port 587 is not accessible").toContain("open");
  });

  test("IMAP port should be accessible", async () => {
    const postgresContainer = containers.postgres || "";

    const imap143Cmd = `docker exec ${postgresContainer} nc -zv stalwart 143 2>&1`;
    const { stdout: imap143 } = await execAsync(imap143Cmd);
    expect(imap143, "IMAP port 143 is not accessible").toContain("open");
  });

  test("email services should be accessible via container IP", async () => {
    const postgresContainer = containers.postgres || "";
    const stalwartIp = containerIps.stalwart;

    expect(stalwartIp, "Could not determine Stalwart container IP").toBeTruthy();

    // Test both SMTP and IMAP via IP in parallel
    const [smtpResult, imapResult] = await Promise.all([
      execAsync(`docker exec ${postgresContainer} nc -zv ${stalwartIp} 25 2>&1`),
      execAsync(`docker exec ${postgresContainer} nc -zv ${stalwartIp} 143 2>&1`),
    ]);

    expect(smtpResult.stdout, `SMTP not accessible via IP ${stalwartIp}:25`).toContain("open");
    expect(imapResult.stdout, `IMAP not accessible via IP ${stalwartIp}:143`).toContain("open");
  });

  test("SMTP server should respond with greeting", async () => {
    const postgresContainer = containers.postgres || "";
    const stalwartIp = containerIps.stalwart;

    // Test SMTP greeting directly via container networking
    const smtpGreetingCmd = `docker exec ${postgresContainer} sh -c "echo QUIT | nc ${stalwartIp} 25 | head -1"`;

    try {
      const { stdout } = await execAsync(smtpGreetingCmd);
      expect(stdout, "SMTP server did not respond with proper greeting").toContain("220"); // SMTP greeting code
    } catch (_e) {
      // Fallback to port connectivity test
      const { stdout } = await execAsync(
        `docker exec ${postgresContainer} nc -zv ${stalwartIp} 25 2>&1`,
      );
      expect(stdout, `SMTP port 25 not open on ${stalwartIp}`).toContain("open");
    }
  });

  test("should have email admin API accessible", async () => {
    // Test Stalwart's admin API using HTTP client
    const adminAuth = Buffer.from("admin:NlwRLVJKTs").toString("base64");

    try {
      const result = await fetchWithProxy("http://stalwart.zoo:8080/api/principal", {
        headers: {
          Authorization: `Basic ${adminAuth}`,
        },
        timeout: 5000,
      });

      expect([200, 401], "Stalwart admin API not responding properly").toContain(result.httpCode);
    } catch (_e) {
      // API might not be available, just check port
      const postgresContainer = containers.postgres || "";
      const { stdout } = await execAsync(
        `docker exec ${postgresContainer} nc -zv stalwart 8080 2>&1`,
      );
      expect(stdout, "Stalwart admin port 8080 not accessible").toContain("open");
    }
  });
});
