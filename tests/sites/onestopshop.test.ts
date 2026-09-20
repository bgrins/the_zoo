import { beforeAll, describe, expect, test } from "vitest";
import { getCachedNetworkInfo, getCachedContainerNames } from "../utils/test-cache";
import { fetchWithProxy } from "../../scripts/lib/http-client";
import { COLD_START_TIMEOUT, ON_DEMAND_FETCH_TIMEOUT, ON_DEMAND_TIMEOUT } from "../constants";
import { warmUp } from "../utils/on-demand";

describe.skipIf(process.env.CI === "true")("OneStopShop (Magento) Tests", () => {
  beforeAll(async () => {
    // Ensure network info is cached for other tests
    await getCachedNetworkInfo();
    // Get dynamic container names
    await getCachedContainerNames(["onestopshop", "mysql"]);
    await warmUp("https://onestopshop.zoo/");
  }, COLD_START_TIMEOUT);

  test(
    "OneStopShop should be accessible at onestopshop.zoo",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      const result = await fetchWithProxy("http://onestopshop.zoo", {
        timeout: ON_DEMAND_FETCH_TIMEOUT,
      });

      expect(result.success).toBe(true);
      expect(result.httpCode).toBe(200);
      expect(result.contentType).toContain("text/html");
    },
  );

  test(
    "OneStopShop should display Magento storefront with products",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      const result = await fetchWithProxy("http://onestopshop.zoo", {
        timeout: ON_DEMAND_FETCH_TIMEOUT,
      });

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

  test("OneStopShop search returns catalog results", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    // Search runs against the Elasticsearch index inside the container
    const result = await fetchWithProxy("https://onestopshop.zoo/catalogsearch/result/?q=shirt", {
      timeout: ON_DEMAND_FETCH_TIMEOUT,
    });

    expect(result.httpCode, result.error).toBe(200);
    expect(result.body).toContain("Search results for: &#039;shirt&#039;");
    expect(result.body).toContain('of <span class="toolbar-number">8280</span>');
  });
});
