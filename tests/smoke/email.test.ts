import { exec } from "node:child_process";
import { promisify } from "node:util";
import { beforeAll, describe, expect, test } from "vitest";
import { getCachedContainerNames, getCachedDockerInspect } from "../utils/test-cache";
import { fetchWithProxy } from "../../scripts/lib/http-client";
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

    const { stdout } = await execAsync(
      `docker exec ${postgresContainer} sh -c "echo QUIT | nc ${stalwartIp} 25 | head -1"`,
    );
    expect(stdout, "SMTP server did not respond with a 220 greeting").toMatch(/^220 /);
  });

  test("should have email admin API accessible", async () => {
    // mail-api.zoo is Caddy's route to Stalwart's management API
    const adminAuth = Buffer.from("admin:zoo-mail-admin-pw").toString("base64");
    const result = await fetchWithProxy("https://mail-api.zoo/api/principal", {
      headers: { Authorization: `Basic ${adminAuth}` },
      timeout: 5000,
    });

    expect(result.httpCode, result.error || result.body).toBe(200);
    expect(JSON.parse(result.body).data.total).toBeGreaterThan(0);
  });
});
