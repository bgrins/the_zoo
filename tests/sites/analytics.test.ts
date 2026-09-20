import { exec } from "node:child_process";
import { promisify } from "node:util";
import { beforeAll, describe, expect, test } from "vitest";
import { getCachedNetworkInfo } from "../utils/test-cache";
import { ON_DEMAND_FETCH_TIMEOUT, ON_DEMAND_TIMEOUT } from "../constants";
import { serviceHealth } from "../utils/containers";
import { fetchWithProxy } from "../../scripts/lib/http-client";

const execAsync = promisify(exec);

describe("Matomo Analytics Tests", () => {
  beforeAll(async () => {
    await getCachedNetworkInfo();
  });

  test(
    "Analytics.zoo should be accessible and return HTML",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      const result = await fetchWithProxy("http://analytics.zoo", {
        timeout: ON_DEMAND_FETCH_TIMEOUT,
      });

      if (!result.success) {
        throw new Error(`Failed to access analytics.zoo: ${result.error}`);
      }

      expect(result.httpCode).toBe(200);
    },
  );

  test(
    "Analytics.zoo should display Matomo interface",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      const result = await fetchWithProxy("http://analytics.zoo", {
        timeout: ON_DEMAND_FETCH_TIMEOUT,
      });

      if (!result.success) {
        throw new Error(`Failed to fetch analytics.zoo content: ${result.error}`);
      }

      expect(result.body.toLowerCase()).toContain("<!doctype html>");
      expect(result.body).toContain("<html");
      expect(result.body).toContain("</html>");
      expect(result.body).toContain("Matomo");
    },
  );

  test("Analytics.zoo should have proper headers", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    const result = await fetchWithProxy("http://analytics.zoo", {
      method: "HEAD",
      timeout: ON_DEMAND_FETCH_TIMEOUT,
    });

    if (!result.success) {
      throw new Error(`Failed to fetch analytics.zoo headers: ${result.error}`);
    }

    expect(result.contentType).toContain("text/html");
    expect(result.httpCode).toBe(200);
  });

  test("Analytics.zoo container should be healthy", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    // Caddy holds the first request until the container's healthcheck passes
    const result = await fetchWithProxy("http://analytics.zoo", {
      timeout: ON_DEMAND_FETCH_TIMEOUT,
    });
    expect(result.httpCode, result.error).toBe(200);
    expect(serviceHealth("analytics-zoo")).toBe("healthy");
  });

  test(
    "Analytics.zoo database should have the tracked sites",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      const { stdout } = await execAsync(
        `docker compose exec -T mysql mysql -u analytics_user -panalytics_pw analytics_db -N -e "SELECT name FROM matomo_site" 2>/dev/null`,
      );
      expect(stdout.trim().split("\n")).toEqual(
        expect.arrayContaining(["snappymail", "miniflux", "wiki", "onestopshop"]),
      );
    },
  );
});
