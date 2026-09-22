import { beforeAll, describe, expect, test } from "vitest";
import { getCachedNetworkInfo, getCachedContainerNames } from "../utils/test-cache";
import { fetchWithProxy } from "../../scripts/lib/http-client";
import { ON_DEMAND_FETCH_TIMEOUT, ON_DEMAND_TIMEOUT } from "../constants";

describe("Northwind phpMyAdmin Tests", () => {
  beforeAll(async () => {
    // Ensure network info is cached for other tests
    await getCachedNetworkInfo();
    // Get dynamic container names
    await getCachedContainerNames(["mysql"]);
  });

  test(
    "phpMyAdmin should be accessible at northwind.zoo",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      const result = await fetchWithProxy("http://northwind.zoo", {
        timeout: ON_DEMAND_FETCH_TIMEOUT,
      });

      expect(result.success).toBe(true);
      expect(result.httpCode).toBe(200);
      expect(result.contentType).toContain("text/html");
    },
  );

  test(
    "phpMyAdmin should have correct title and content",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      const result = await fetchWithProxy("http://northwind.zoo", {
        timeout: ON_DEMAND_FETCH_TIMEOUT,
      });

      expect(result.success).toBe(true);
      expect(result.body).toContain("phpMyAdmin");
      // Should auto-login with northwind_user credentials
      expect(result.body).toContain("northwind_user");
      expect(result.body).toContain("northwind_db");
    },
  );

  test(
    "phpMyAdmin should be able to access Northwind tables",
    { timeout: ON_DEMAND_TIMEOUT },
    async () => {
      // Access the database directly via phpMyAdmin's SQL endpoint
      const result = await fetchWithProxy(
        "http://northwind.zoo/index.php?route=/database/structure&db=northwind_db",
        {
          timeout: ON_DEMAND_FETCH_TIMEOUT,
        },
      );

      expect(result.success).toBe(true);
      const tables = [...result.body.matchAll(/data-filter-row="([^"]+)"/g)].map((m) => m[1]);
      expect(tables).toEqual([
        "CUSTOMERS",
        "EMPLOYEES",
        "EMPLOYEE_PRIVILEGES",
        "INVENTORY_TRANSACTIONS",
        "INVENTORY_TRANSACTION_TYPES",
        "INVOICES",
        "ORDERS",
        "ORDERS_STATUS",
        "ORDERS_TAX_STATUS",
        "ORDER_DETAILS",
        "ORDER_DETAILS_STATUS",
        "PRIVILEGES",
        "PRODUCTS",
        "PURCHASE_ORDERS",
        "PURCHASE_ORDER_DETAILS",
        "PURCHASE_ORDER_STATUS",
        "SALES_REPORTS",
        "SHIPPERS",
        "STRINGS",
        "SUPPLIERS",
      ]);
    },
  );
});
