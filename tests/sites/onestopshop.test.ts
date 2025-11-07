import { beforeAll, describe, expect, test } from "vitest";
import { getCachedNetworkInfo, getCachedContainerNames } from "../utils/test-cache";
import { fetchWithProxy } from "../utils/http-client";
import { ON_DEMAND_TIMEOUT } from "../constants";

describe("OneStopShop (Magento) Tests", () => {
  beforeAll(async () => {
    // Ensure network info is cached for other tests
    await getCachedNetworkInfo();
    // Get dynamic container names
    await getCachedContainerNames(["onestopshop", "mysql"]);
  });

  test(
    "OneStopShop should be accessible at onestopshop.zoo",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      const result = await fetchWithProxy("http://onestopshop.zoo", { timeout: 25000 });

      expect(result.success).toBe(true);
      expect(result.httpCode).toBe(200);
      expect(result.contentType).toContain("text/html");
    },
  );

  test(
    "OneStopShop should display Magento storefront with products",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      const result = await fetchWithProxy("http://onestopshop.zoo", { timeout: 25000 });

      expect(result.success).toBe(true);
      expect(result.body.toLowerCase()).toContain("<!doctype html>");

      // Check for specific product in the Magento database
      expect(result.body).toContain("Orange Vanilla Caffeine-free");

      // Check for Magento-specific elements or common product-related terms
      const hasProductIndicators =
        result.body.includes("product") ||
        result.body.includes("catalog") ||
        result.body.includes("shop") ||
        result.body.includes("cart");

      expect(hasProductIndicators).toBe(true);
    },
  );

  test("OneStopShop should have search functionality", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    const result = await fetchWithProxy("http://onestopshop.zoo", { timeout: 25000 });

    expect(result.success).toBe(true);

    // Look for search-related elements (input field, form, etc)
    const hasSearch =
      result.body.includes('type="search"') ||
      result.body.includes('name="q"') ||
      result.body.includes("search");

    expect(hasSearch).toBe(true);
  });
});
