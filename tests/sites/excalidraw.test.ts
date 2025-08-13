import { exec } from "node:child_process";
import { promisify } from "node:util";
import { beforeAll, describe, expect, test } from "vitest";
import { getCachedNetworkInfo } from "../utils/test-cache";
import { ON_DEMAND_TIMEOUT } from "../constants";
import { fetchWithProxy } from "../utils/http-client";

const execAsync = promisify(exec);

describe("Excalidraw Tests", () => {
  beforeAll(async () => {
    // Ensure network info is cached for other tests
    await getCachedNetworkInfo();
  });

  test(
    "Excalidraw should be accessible and return HTML",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      const result = await fetchWithProxy("http://excalidraw.zoo", { timeout: 25000 });

      if (!result.success) {
        throw new Error(`Failed to access Excalidraw: ${result.error}`);
      }

      expect(result.httpCode).toBe(200);
    },
  );

  test("Excalidraw should return proper HTML content", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    const result = await fetchWithProxy("http://excalidraw.zoo", { timeout: 25000 });

    if (!result.success) {
      throw new Error(`Failed to fetch Excalidraw content: ${result.error}`);
    }

    // Check for expected HTML structure (case-insensitive for DOCTYPE)
    expect(result.body.toLowerCase()).toContain("<!doctype html>");
    expect(result.body).toContain("<html");
    expect(result.body).toContain("</html>");

    // Check for Excalidraw-specific content
    expect(result.body.toLowerCase()).toMatch(/excalidraw|draw|canvas|sketch/i);
  });

  test("Excalidraw should have proper headers", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    const result = await fetchWithProxy("http://excalidraw.zoo", {
      method: "HEAD",
      timeout: 25000,
    });

    if (!result.success) {
      throw new Error(`Failed to fetch Excalidraw headers: ${result.error}`);
    }

    // Check for expected headers
    expect(result.contentType).toContain("text/html");
    expect(result.headers.server).toBeTruthy();
    expect(result.httpCode).toBe(200);
  });

  test("Excalidraw container should be healthy", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    // First ensure the container is started by accessing it
    await fetchWithProxy("http://excalidraw.zoo", { timeout: 25000 });

    // Wait a bit for health check to run
    await new Promise((resolve) => setTimeout(resolve, 2000));

    // Check container health
    const cmd = `docker ps --filter "name=excalidraw-zoo" --format "{{.Names}}:{{.Status}}"`;

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
      throw new Error("Excalidraw container not found or not running");
    }

    const [_name, status] = stdout.split(":");
    expect(status).toContain("Up");

    // For on-demand containers, we should also check if it's healthy
    if (status.includes("healthy") || status.includes("unhealthy")) {
      expect(status).toContain("healthy");
      expect(status).not.toContain("unhealthy");
    }
  });
});
