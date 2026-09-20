import { beforeAll, describe, expect, test } from "vitest";
import { getCachedNetworkInfo } from "../utils/test-cache";
import { ON_DEMAND_FETCH_TIMEOUT, ON_DEMAND_TIMEOUT } from "../constants";
import { serviceHealth } from "../utils/containers";
import { fetchWithProxy } from "../../scripts/lib/http-client";

describe("Excalidraw Tests", () => {
  beforeAll(async () => {
    // Ensure network info is cached for other tests
    await getCachedNetworkInfo();
  });

  test(
    "Excalidraw should be accessible and return HTML",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      const result = await fetchWithProxy("http://excalidraw.zoo", {
        timeout: ON_DEMAND_FETCH_TIMEOUT,
      });

      if (!result.success) {
        throw new Error(`Failed to access Excalidraw: ${result.error}`);
      }

      expect(result.httpCode).toBe(200);
    },
  );

  test("Excalidraw should return proper HTML content", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    const result = await fetchWithProxy("http://excalidraw.zoo", {
      timeout: ON_DEMAND_FETCH_TIMEOUT,
    });

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
      timeout: ON_DEMAND_FETCH_TIMEOUT,
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
    // Caddy holds the first request until the container's healthcheck passes
    const result = await fetchWithProxy("http://excalidraw.zoo", {
      timeout: ON_DEMAND_FETCH_TIMEOUT,
    });
    expect(result.httpCode, result.error).toBe(200);
    expect(serviceHealth("excalidraw-zoo")).toBe("healthy");
  });
});
