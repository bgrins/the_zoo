import { exec } from "node:child_process";
import { promisify } from "node:util";
import { beforeAll, describe, expect, test } from "vitest";
import { getCachedNetworkInfo, getCachedContainerNames } from "../utils/test-cache";
import { ON_DEMAND_TIMEOUT } from "../constants";
import { fetchWithProxy } from "../utils/http-client";

const execAsync = promisify(exec);

describe("Mattermost Tests", () => {
  let containers: Record<string, string> = {};

  beforeAll(async () => {
    await getCachedNetworkInfo();
    containers = await getCachedContainerNames(["postgres"]);
  });

  test(
    "Mattermost should be accessible and return HTML",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      const result = await fetchWithProxy("http://mattermost.zoo", { timeout: 25000 });

      if (!result.success) {
        throw new Error(`Failed to access Mattermost: ${result.error}`);
      }

      expect(result.httpCode).toBe(200);
      expect(result.contentType).toContain("text/html");
    },
  );

  test("Mattermost should return proper HTML content", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    const result = await fetchWithProxy("http://mattermost.zoo", { timeout: 25000 });

    if (!result.success) {
      throw new Error(`Failed to fetch Mattermost content: ${result.error}`);
    }

    expect(result.body.toLowerCase()).toContain("<!doctype html>");
    expect(result.body).toContain("<html");
    expect(result.body).toContain("</html>");

    // Check for Mattermost-specific content
    expect(result.body.toLowerCase()).toMatch(/mattermost/i);
  });

  test("Performance Zoo script should be injected", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    const result = await fetchWithProxy("http://mattermost.zoo", { timeout: 25000 });
    expect(result.success).toBe(true);
    expect(result.httpCode).toBe(200);

    // Verify the performance script is injected
    expect(result.body).toContain("https://performance.zoo/shared.js");
  });

  test("Mattermost container should be healthy", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    // First ensure the container is started by accessing it
    await fetchWithProxy("http://mattermost.zoo", { timeout: 25000 });

    // Wait a bit for health check to run
    await new Promise((resolve) => setTimeout(resolve, 2000));

    // Check container health
    const cmd = `docker ps --filter "name=mattermost" --format "{{.Names}}:{{.Status}}"`;

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
      throw new Error("Mattermost container not found or not running");
    }

    const [_name, status] = stdout.split(":");
    expect(status).toContain("Up");
  });

  test(
    "Mattermost should connect to PostgreSQL database",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      // First ensure the container is started by accessing it
      await fetchWithProxy("http://mattermost.zoo", { timeout: 25000 });

      // Check that the database exists and is accessible
      const cmd = `docker exec ${containers.postgres} psql -U postgres -d zoodb -c "SELECT 1 FROM pg_database WHERE datname = 'mattermost_db';" 2>&1`;

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

  test("Mattermost API should return server info", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    const result = await fetchWithProxy("http://mattermost.zoo/api/v4/system/ping", {
      timeout: 25000,
    });

    expect(result.success).toBe(true);
    expect(result.httpCode).toBe(200);
    expect(result.contentType).toContain("application/json");
  });
});
