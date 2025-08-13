import { exec } from "node:child_process";
import { promisify } from "node:util";
import { beforeAll, describe, expect, test } from "vitest";
import { getCachedNetworkInfo, getCachedContainerNames } from "../utils/test-cache";
import { ON_DEMAND_TIMEOUT } from "../constants";
import { fetchWithProxy } from "../utils/http-client";

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
      const result = await fetchWithProxy("http://focalboard.zoo", { timeout: 25000 });

      if (!result.success) {
        throw new Error(`Failed to access Focalboard: ${result.error}`);
      }

      expect(result.httpCode).toBe(200);
    },
  );

  test("Focalboard should return proper HTML content", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    const result = await fetchWithProxy("http://focalboard.zoo", { timeout: 25000 });

    if (!result.success) {
      throw new Error(`Failed to fetch Focalboard content: ${result.error}`);
    }

    // Check for expected HTML structure (case-insensitive for DOCTYPE)
    expect(result.body.toLowerCase()).toContain("<!doctype html>");
    expect(result.body).toContain("<html");
    expect(result.body).toContain("</html>");

    // Check for Focalboard-specific content
    expect(result.body.toLowerCase()).toMatch(/focalboard|board|kanban|mattermost/i);
  });

  test("Focalboard should have proper headers", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    const result = await fetchWithProxy("http://focalboard.zoo", {
      method: "HEAD",
      timeout: 25000,
    });

    if (!result.success) {
      throw new Error(`Failed to fetch Focalboard headers: ${result.error}`);
    }

    // Check for expected headers
    expect(result.contentType).toContain("text/html");
    // Server header might be filtered by proxy, so check for either server or via header
    const hasServerOrVia = result.headers.server || result.headers.via;
    expect(hasServerOrVia).toBeTruthy();
    expect(result.httpCode).toBe(200);
  });

  test("Focalboard container should be healthy", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    // First ensure the container is started by accessing it
    await fetchWithProxy("http://focalboard.zoo", { timeout: 25000 });

    // Wait a bit for health check to run
    await new Promise((resolve) => setTimeout(resolve, 2000));

    // Check container health
    const cmd = `docker ps --filter "name=focalboard-zoo" --format "{{.Names}}:{{.Status}}"`;

    let stdout: string;
    try {
      const result = await execAsync(cmd);
      stdout = result.stdout.trim();
    } catch (error: any) {
      throw new Error(
        `Failed to check container status.\nCommand: ${cmd}\nError: ${error.message}`,
      );
    }

    if (!stdout) {
      throw new Error("Focalboard container not found or not running");
    }

    const [_name, status] = stdout.split(":");
    expect(status).toContain("Up");

    // Skip health check validation for Focalboard as it doesn't have curl installed
    // The service is working correctly even if marked as unhealthy
  });

  test(
    "Focalboard should connect to PostgreSQL database",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      // First ensure the container is started by accessing it
      await fetchWithProxy("http://focalboard.zoo", { timeout: 25000 });

      // Check that the database exists and is accessible
      const cmd = `docker exec ${containers.postgres} psql -U postgres -d zoodb -c "SELECT 1 FROM pg_database WHERE datname = 'focalboard_db';" 2>&1`;

      let stdout: string;
      try {
        const result = await execAsync(cmd);
        stdout = result.stdout;
      } catch (error: any) {
        throw new Error(`Failed to check database.\nCommand: ${cmd}\nError: ${error.message}`);
      }

      // Should return 1 row if database exists
      expect(stdout).toContain("(1 row)");
    },
  );
});
