import { exec } from "node:child_process";
import { readFileSync } from "node:fs";
import { promisify } from "node:util";
import { describe, expect, test } from "vitest";
import { getAllSites, type Site } from "../../scripts/sites-registry";
import { PROXY_PORT, PROXY_URL } from "../../scripts/lib/proxy";
import { fetchWithProxy, testUrl } from "../../scripts/lib/http-client";

const execAsync = promisify(exec);

describe("Smoke Tests (Critical Path Only)", () => {
  test("proxy should be reachable from the host", async () => {
    const { stdout } = await execAsync(`nc -zv localhost ${PROXY_PORT} 2>&1`);
    expect(stdout).toContain("succeeded");
  });

  test("critical sites should respond", async () => {
    const criticalSites: string[] = ["http://status.zoo", "http://system-api.zoo"];

    const tests = criticalSites.map(async (url: string) => {
      const result = await fetchWithProxy(url, { timeout: 5000 });
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
    const urls = ["http://google.com", "http://172.217.16.142", "http://github.com"];
    const results = await Promise.all(urls.map((url) => fetchWithProxy(url, { timeout: 2000 })));

    // Squid's ACL denies both a CONNECT tunnel and a plain proxied request
    expect(results.map((result) => [result.url, result.error])).toEqual(
      urls.map((url) => [url, expect.stringContaining("Proxy response (403) !== 200")]),
    );
    const plain = await Promise.all(
      urls.map(async (url) => {
        const { stdout } = await execAsync(
          `curl -s -o /dev/null -w "%{http_code} %header{x-squid-error}" --proxy ${PROXY_URL} ${url}`,
        );
        return stdout;
      }),
    );
    expect(plain).toEqual(urls.map(() => "403 ERR_ACCESS_DENIED 0"));
  });

  test("proxy should deny the service names DNS resolves past Caddy", async () => {
    // e.g. stalwart.zoo would reach Stalwart's own HTTPS listener
    const corefile = readFileSync(new URL("../../core/coredns/Corefile", import.meta.url), "utf8");
    const zones = corefile.match(/^((?:[a-z0-9-]+\.zoo:53 )+)\{$/m)?.[1] ?? "";
    const aliases = zones
      .trim()
      .split(" ")
      .map((zone) => zone.replace(/:53$/, ""));
    expect(aliases).toEqual([
      "postgres.zoo",
      "redis.zoo",
      "stalwart.zoo",
      "hydra.zoo",
      "mysql.zoo",
    ]);

    // curl, because undici tunnels plain HTTP too and hides the status of a refused CONNECT
    const statuses = await Promise.all(
      aliases.flatMap((domain) =>
        ["http", "https"].map(async (scheme) => {
          const url = `${scheme}://${domain}/`;
          const { stdout } = await execAsync(
            `curl -sk -o /dev/null -w '%{http_code} %{http_connect}' --max-time 5 --proxy ${PROXY_URL} ${url} || true`,
          );
          return `${url} ${stdout}`;
        }),
      ),
    );
    expect(statuses).toEqual(
      aliases.flatMap((domain) => [`http://${domain}/ 403 000`, `https://${domain}/ 000 403`]),
    );
  });

  test("containers should not access external IPs directly", async () => {
    // The zoo network is internal: there is no route out
    const result = execAsync(
      'docker compose exec -T caddy curl -sS --max-time 3 -H "Host: example.com" http://23.192.228.80',
    );
    await expect(result).rejects.toMatchObject({
      code: 7,
      stderr: expect.stringContaining("Failed to connect to 23.192.228.80 port 80"),
    });
  });

  test("DNS should return NXDOMAIN for external domains", async () => {
    const { stdout, stderr } = await execAsync(
      "docker compose exec -T caddy nslookup example.com 2>&1 || true",
    );

    const output = stdout + stderr;
    expect(output, "DNS should return NXDOMAIN for external domains").toMatch(/NXDOMAIN/);
  });
});
