import { exec } from "node:child_process";
import { promisify } from "node:util";
import { beforeAll, describe, expect, test } from "vitest";
import { getCachedNetworkInfo } from "../utils/test-cache";
import { ON_DEMAND_TIMEOUT } from "../constants";
import { fetchWithProxy } from "../utils/http-client";

const execAsync = promisify(exec);

describe("Matomo Analytics Tests", () => {
  beforeAll(async () => {
    await getCachedNetworkInfo();
  });

  test(
    "Analytics.zoo should be accessible and return HTML",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      const result = await fetchWithProxy("http://analytics.zoo", { timeout: 25000 });

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
      const result = await fetchWithProxy("http://analytics.zoo", { timeout: 25000 });

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
      timeout: 25000,
    });

    if (!result.success) {
      throw new Error(`Failed to fetch analytics.zoo headers: ${result.error}`);
    }

    expect(result.contentType).toContain("text/html");
    expect(result.httpCode).toBe(200);
  });

  test("Analytics.zoo container should be healthy", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    await fetchWithProxy("http://analytics.zoo", { timeout: 25000 });

    await new Promise((resolve) => setTimeout(resolve, 2000));

    const cmd = `docker ps --filter "name=analytics-zoo" --format "{{.Names}}:{{.Status}}"`;

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
      throw new Error("Analytics container not found or not running");
    }

    const [_name, status] = stdout.split(":");
    expect(status).toContain("Up");

    if (status.includes("healthy") || status.includes("unhealthy")) {
      expect(status).toContain("healthy");
      expect(status).not.toContain("unhealthy");
    }
  });

  test(
    "Analytics.zoo should connect to MySQL database",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      const cmd = `docker compose exec -T mysql-analytics mysql -u analytics_user -panalytics_pw analytics_db -e "SELECT 1 AS test" 2>/dev/null`;

      let stdout: string;
      try {
        const result = await execAsync(cmd);
        stdout = result.stdout.trim();
      } catch (error: any) {
        throw new Error(
          `Failed to connect to MySQL database.\nCommand: ${cmd}\nError: ${error.message}`,
        );
      }

      expect(stdout).toContain("test");
      expect(stdout).toContain("1");
    },
  );
});
