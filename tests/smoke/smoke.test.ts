import { exec } from "node:child_process";
import { promisify } from "node:util";
import { describe, expect, test } from "vitest";
import { getAllSites, type Site } from "../../scripts/sites-registry";
import { PROXY_PORT } from "../constants";
import { serviceHealth } from "../utils/containers";
import { fetchWithProxy, testUrl } from "../utils/http-client";

const execAsync = promisify(exec);

describe("Smoke Tests (Critical Path Only)", () => {
  test("proxy should be healthy and reachable from the host", async () => {
    expect(serviceHealth("proxy")).toBe("healthy");
    const { stdout } = await execAsync(`nc -zv localhost ${PROXY_PORT} 2>&1`);
    expect(stdout).toContain("succeeded");
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

  test("every core service should be healthy", async () => {
    // Core services are the ones compose starts without a profile
    const { stdout: services } = await execAsync("docker compose config --services");
    const core = services.trim().split("\n").sort();

    const { stdout: ps } = await execAsync("docker compose ps --format json");
    const health = Object.fromEntries(
      ps
        .trim()
        .split("\n")
        .map((line) => JSON.parse(line))
        .map((c: { Service: string; Health: string }) => [c.Service, c.Health]),
    );

    expect(Object.fromEntries(core.map((s) => [s, health[s]]))).toEqual(
      Object.fromEntries(core.map((s) => [s, "healthy"])),
    );
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
