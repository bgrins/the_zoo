import { exec } from "node:child_process";
import { promisify } from "node:util";
import { describe, expect, test } from "vitest";
import { getAllSites, type Site } from "../../scripts/sites-registry";
import { fetchWithProxy, testUrl } from "../utils/http-client";

const execAsync = promisify(exec);

describe("Smoke Tests (Critical Path Only)", () => {
  test("proxy should be running", async () => {
    // In CI, the proxy might take longer to be ready, so let's check its health status
    try {
      const { stdout: healthStatus } = await execAsync(
        'docker ps --filter "name=proxy" --filter "health=healthy" --format "{{.Names}}"',
      );

      if (healthStatus.trim().includes("proxy")) {
        // Proxy is healthy, now test the port
        const { stdout } = await execAsync("nc -zv localhost 3128 2>&1");
        expect(stdout).toContain("succeeded");
      } else {
        // If proxy isn't healthy yet, check if it's at least running
        const { stdout: runningStatus } = await execAsync(
          'docker ps --filter "name=proxy" --format "{{.Names}} {{.Status}}"',
        );

        // If proxy is running but not healthy, that's still a failure but with better context
        throw new Error(`Proxy service not healthy yet. Status: ${runningStatus.trim()}`);
      }
    } catch (error) {
      // If nc fails, provide more context
      if (error instanceof Error && error.message.includes("nc -zv")) {
        const { stdout: proxyLogs } = await execAsync(
          "docker compose logs proxy --tail=10 2>&1 || echo 'Could not get proxy logs'",
        );
        throw new Error(`Proxy port 3128 not accessible. Proxy logs:\n${proxyLogs}`);
      }
      throw error;
    }
  });

  test("critical sites should respond", async () => {
    const criticalSites: string[] = ["http://status.zoo", "http://system-api.zoo"];

    const tests = criticalSites.map(async (url: string) => {
      const result = await fetchWithProxy(url, { timeout: 10000 });
      return { url, code: result.httpCode, error: result.error };
    });

    const results = await Promise.all(tests);

    results.forEach(({ url, code, error }) => {
      expect(
        [200, 302],
        `Critical site ${url} is not responding correctly. Got HTTP ${code} instead of 200/302${error ? `. Error: ${error}` : ""}`,
      ).toContain(code);
    });
  });

  test("docker services should be healthy", async () => {
    const { stdout } = await execAsync(
      'docker ps --filter health=healthy --format "{{.Names}}" | wc -l',
    );
    const healthyCount = parseInt(stdout.trim());
    expect(
      healthyCount,
      `Only ${healthyCount} healthy containers found, expected >= 5`,
    ).toBeGreaterThanOrEqual(5);
  });

  test("all static sites should be accessible", async () => {
    const allSites = getAllSites();
    const staticSites = allSites.filter((site: Site) => site.type === "static");

    const tests = staticSites.map(async (site: Site) => {
      const result = await testUrl(site.httpsHealthUrl, {
        expectStatus: [200, 302],
        method: "GET",
        timeout: 5000, // Increased timeout for HTTPS
      });
      return {
        site: site.domain,
        healthUrl: site.httpsHealthUrl,
        success: result.success,
        httpCode: result.httpCode,
        error: result.error,
      };
    });

    const results = await Promise.all(tests);

    results.forEach(({ site, success, healthUrl, httpCode }) => {
      expect(success, `Static site ${site} (${healthUrl}) is not accessible`).toBe(true);
      expect(
        [200, 302],
        `Static site ${site} returned HTTP ${httpCode} instead of 200/302`,
      ).toContain(httpCode);
    });
  });

  test("proxy should block external domains", async () => {
    const blockTests = ["http://google.com", "http://172.217.16.142", "http://github.com"].map(
      async (url) => {
        const result = await fetchWithProxy(url, { timeout: 2000 });
        return { url, success: result.success, code: result.httpCode, error: result.error };
      },
    );

    const blockResults = await Promise.all(blockTests);

    blockResults.forEach((result) => {
      const { url, success, code, error } = result;
      expect(
        success,
        `Expected ${url} to be blocked by proxy, but got success with HTTP ${code}`,
      ).toBe(false);

      expect(error, `Expected proxy rejection error for ${url}`).toMatch(/fetch failed|403|Proxy/);
    });
  });

  test("containers should not access external IPs directly", async () => {
    const cmd =
      'docker compose exec -T caddy curl -s --max-time 3 -H "Host: example.com" http://23.192.228.80';
    await expect(execAsync(cmd)).rejects.toThrow();
  });

  test("DNS should return NXDOMAIN for external domains", async () => {
    const { stdout, stderr } = await execAsync(
      "docker compose exec -T caddy nslookup example.com 2>&1 || true",
    );

    const output = stdout + stderr;
    expect(output, "DNS should return NXDOMAIN for external domains").toMatch(/NXDOMAIN/);
  });
});
