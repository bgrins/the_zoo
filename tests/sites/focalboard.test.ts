import { exec } from "node:child_process";
import { promisify } from "node:util";
import { personas } from "../../scripts/seed-data/personas";
import { beforeAll, describe, expect, test } from "vitest";
import { getCachedNetworkInfo, getCachedContainerNames } from "../utils/test-cache";
import { ON_DEMAND_FETCH_TIMEOUT, ON_DEMAND_TIMEOUT } from "../constants";
import { serviceHealth } from "../utils/containers";
import { fetchWithProxy } from "../../scripts/lib/http-client";

const execAsync = promisify(exec);

describe("Focalboard Tests", () => {
  let containers: Record<string, string> = {};

  beforeAll(async () => {
    // Ensure network info is cached for other tests
    await getCachedNetworkInfo();
    // Get dynamic container names
    containers = await getCachedContainerNames(["postgres"]);
  });

  test(
    "Focalboard should be accessible and return HTML",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      const result = await fetchWithProxy("http://focalboard.zoo", {
        timeout: ON_DEMAND_FETCH_TIMEOUT,
      });

      if (!result.success) {
        throw new Error(`Failed to access Focalboard: ${result.error}`);
      }

      expect(result.httpCode).toBe(200);
    },
  );

  test("Focalboard should return proper HTML content", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    const result = await fetchWithProxy("http://focalboard.zoo", {
      timeout: ON_DEMAND_FETCH_TIMEOUT,
    });

    if (!result.success) {
      throw new Error(`Failed to fetch Focalboard content: ${result.error}`);
    }

    // Check for expected HTML structure (case-insensitive for DOCTYPE)
    expect(result.body.toLowerCase()).toContain("<!doctype html>");
    expect(result.body).toContain("<html");
    expect(result.body).toContain("</html>");

    expect(result.body).toContain("<title>Focalboard</title>");
    expect(result.body).toContain('<div id="focalboard-app"></div>');
  });

  test("Focalboard should have proper headers", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    const result = await fetchWithProxy("http://focalboard.zoo", {
      method: "HEAD",
      timeout: ON_DEMAND_FETCH_TIMEOUT,
    });

    if (!result.success) {
      throw new Error(`Failed to fetch Focalboard headers: ${result.error}`);
    }

    // Check for expected headers
    expect(result.contentType).toContain("text/html");
    // Focalboard sends no Server header; Caddy adds Via
    expect(result.headers.server).toBeUndefined();
    expect(result.headers.via).toBe("1.1 Caddy");
    expect(result.httpCode).toBe(200);
  });

  test("Focalboard container should be healthy", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    // Caddy holds the first request until the container's healthcheck passes
    const result = await fetchWithProxy("http://focalboard.zoo", {
      timeout: ON_DEMAND_FETCH_TIMEOUT,
    });
    expect(result.httpCode, result.error).toBe(200);
    expect(serviceHealth("focalboard-zoo")).toBe("healthy");
  });

  test("Focalboard database should have the seeded users", async () => {
    const { stdout } = await execAsync(
      `docker exec ${containers.postgres} psql -U focalboard_user -d focalboard_db -t -A -c "SELECT username FROM users"`,
    );
    expect(stdout.trim().split("\n")).toEqual(
      expect.arrayContaining(personas.map((p) => p.username)),
    );
  });
});
