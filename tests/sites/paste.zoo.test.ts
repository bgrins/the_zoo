import { beforeAll, describe, expect, test } from "vitest";
import { getCachedNetworkInfo } from "../utils/test-cache";
import { ON_DEMAND_TIMEOUT } from "../constants";
import { fetchWithProxy } from "../utils/http-client";

describe("Microbin (paste.zoo) Tests", () => {
  beforeAll(async () => {
    await getCachedNetworkInfo();
  });

  test(
    "Microbin should be accessible and return HTML",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      const result = await fetchWithProxy("http://paste.zoo", { timeout: 25000 });
      expect(result.success).toBe(true);
      expect(result.httpCode).toBe(200);
      expect(result.contentType).toContain("text/html");

      expect(result.body.toLowerCase()).toContain("<!doctype html>");
      expect(result.body).toContain("<title>Zoo Pastebin</title>");
    },
  );

  test("Microbin should have expected UI elements", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    const result = await fetchWithProxy("http://paste.zoo", { timeout: 25000 });
    expect(result.success).toBe(true);
    expect(result.httpCode).toBe(200);

    // Check for key UI elements
    expect(result.body).toContain("New");
    expect(result.body).toContain("List");
    expect(result.body).toContain("Guide");
    expect(result.body).toContain("Expiration");
    expect(result.body).toContain("Save");
  });

  test("Microbin list endpoint should be accessible", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    const result = await fetchWithProxy("http://paste.zoo/list", { timeout: 25000 });
    expect(result.success).toBe(true);
    expect(result.httpCode).toBe(200);
    expect(result.contentType).toContain("text/html");
    expect(result.body).toContain("Zoo Pastebin");
  });

  test("Microbin guide endpoint should be accessible", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    const result = await fetchWithProxy("http://paste.zoo/guide", { timeout: 25000 });
    expect(result.success).toBe(true);
    expect(result.httpCode).toBe(200);
    expect(result.contentType).toContain("text/html");
    expect(result.body).toContain("Zoo Pastebin");
    expect(result.body).toContain("Guide");
  });
});
