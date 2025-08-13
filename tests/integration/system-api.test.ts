import { describe, expect, test } from "vitest";
import { testUrl } from "../utils/http-client";
import { ON_DEMAND_TIMEOUT } from "../constants";

describe("System API Docker Endpoints", () => {
  test(
    "system-api.zoo/docker/api/containers should return container list",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      const result = await testUrl("http://system-api.zoo/docker/api/containers", {
        fetchBody: true,
        timeout: ON_DEMAND_TIMEOUT,
      });
      expect(result.success).toBe(true);
      expect(result.httpCode).toBe(200);

      // Parse JSON response
      const response = JSON.parse(result.body);
      expect(response).toHaveProperty("containers");
      expect(Array.isArray(response.containers)).toBe(true);
      expect(response.containers.length).toBeGreaterThan(0);

      // Verify container structure
      const firstContainer = response.containers[0];
      expect(firstContainer).toHaveProperty("id");
      expect(firstContainer).toHaveProperty("name");
      expect(firstContainer).toHaveProperty("status");
      expect(firstContainer).toHaveProperty("state");
    },
  );

  test(
    "system-api.zoo/docker/api/containers?stats=true should return container list with stats",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      const result = await testUrl("http://system-api.zoo/docker/api/containers?stats=true", {
        fetchBody: true,
        timeout: ON_DEMAND_TIMEOUT,
      });

      // Debug output if test fails
      if (!result.success) {
        console.error("Request failed:", result.error);
        console.error("HTTP Code:", result.httpCode);
      }

      expect(result.success).toBe(true);
      expect(result.httpCode).toBe(200);

      // Parse JSON response
      const response = JSON.parse(result.body);
      expect(response).toHaveProperty("containers");
      expect(Array.isArray(response.containers)).toBe(true);
      expect(response.containers.length).toBeGreaterThan(0);

      // When stats=true, stats should be included at the response level
      expect(response).toHaveProperty("stats");

      // Verify container structure
      const firstContainer = response.containers[0];
      expect(firstContainer).toHaveProperty("id");
      expect(firstContainer).toHaveProperty("name");
      expect(firstContainer).toHaveProperty("state");
    },
  );

  test("system-api.zoo should include CORS headers", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    const result = await testUrl("http://system-api.zoo/docker/api/containers", {
      expectHeaders: [
        "access-control-allow-origin",
        "access-control-allow-methods",
        "access-control-allow-headers",
      ],
      timeout: ON_DEMAND_TIMEOUT,
    });

    expect(result.success).toBe(true);
    expect(result.httpCode).toBe(200);

    // Verify CORS headers are present
    expect(result.headers).toHaveProperty("access-control-allow-origin");
    expect(result.headers["access-control-allow-origin"]).toBe("*");
    expect(result.headers).toHaveProperty("access-control-allow-methods");
    expect(result.headers["access-control-allow-methods"]).toContain("GET");
    expect(result.headers).toHaveProperty("access-control-allow-headers");
  });
});
