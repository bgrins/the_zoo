import { beforeAll, describe, expect, test } from "vitest";
import { getCachedNetworkInfo } from "../utils/test-cache";
import { fetchWithProxy } from "../utils/http-client";

describe("home.zoo - Application Gallery", () => {
  beforeAll(async () => {
    await getCachedNetworkInfo();
  });

  test("home page should load and contain welcome message", async () => {
    const result = await fetchWithProxy("http://home.zoo");

    if (!result.success) {
      throw new Error(`Failed to fetch home.zoo: ${result.error}`);
    }

    expect(result.httpCode, "Expected 200 status code").toBe(200);
    expect(result.body, "Page should contain welcome heading").toContain("Welcome to The Zoo");
  });

  test("home page should display application gallery", async () => {
    const result = await fetchWithProxy("http://home.zoo");

    if (!result.success) {
      throw new Error(`Failed to fetch home.zoo: ${result.error}`);
    }

    expect(result.body, "Page should have apps grid").toContain('class="apps-grid"');
  });

  test("home page should have compact layout", async () => {
    const result = await fetchWithProxy("http://home.zoo");

    if (!result.success) {
      throw new Error(`Failed to fetch home.zoo: ${result.error}`);
    }

    expect(result.body, "Page should not have quick-links section").not.toContain("quick-links");
    expect(result.body, "Page should go straight to apps section").toContain("apps-section");
  });

  test("home page should list actual applications", async () => {
    const result = await fetchWithProxy("http://home.zoo");

    if (!result.success) {
      throw new Error(`Failed to fetch home.zoo: ${result.error}`);
    }

    // Check for some expected apps
    expect(result.body, "Page should list gitea").toContain("https://gitea.zoo");
    expect(result.body, "Page should list miniflux").toContain("https://miniflux.zoo");
    expect(result.body, "Page should list postmill").toContain("https://postmill.zoo");

    // Check for app cards with proper structure
    expect(result.body, "App cards should have icons").toContain('class="app-icon"');
    expect(result.body, "App cards should have descriptions").toContain('class="app-description"');
  });

  test("home page should not list system services", async () => {
    const result = await fetchWithProxy("http://home.zoo");

    if (!result.success) {
      throw new Error(`Failed to fetch home.zoo: ${result.error}`);
    }

    // System services should NOT be listed in the gallery
    expect(result.body, "Page should not list auth.zoo as an app").not.toContain(
      'href="https://auth.zoo" class="app-card"',
    );
    expect(result.body, "Page should not list status.zoo as an app").not.toContain(
      'href="https://status.zoo" class="app-card"',
    );
  });

  test("home page should show badges for app features", async () => {
    const result = await fetchWithProxy("http://home.zoo");

    if (!result.success) {
      throw new Error(`Failed to fetch home.zoo: ${result.error}`);
    }

    expect(result.body, "Page should show On-Demand badges").toContain("On-Demand");
    expect(result.body, "Page should show OAuth badges").toContain("OAuth");
  });
});
