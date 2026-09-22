import { beforeAll, describe, expect, test } from "vitest";
import { getCachedNetworkInfo } from "../utils/test-cache";
import { fetchWithProxy } from "../../scripts/lib/http-client";

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

  test("home page lists auth.zoo and docs.gitea.zoo but not system services", async () => {
    const result = await fetchWithProxy("https://home.zoo/");
    expect(result.httpCode, result.error).toBe(200);

    const cards = [...result.body.matchAll(/<a href="https:\/\/([^"]+)" class="app-card">/g)].map(
      (match) => match[1],
    );
    expect(cards).toEqual(expect.arrayContaining(["auth.zoo", "docs.gitea.zoo"]));
    for (const system of ["home.zoo", "mail-api.zoo"]) {
      expect(cards).not.toContain(system);
    }
  });

  test("app cards open in the same tab, inside the main landmark", async () => {
    const result = await fetchWithProxy("https://home.zoo/");
    expect(result.httpCode, result.error).toBe(200);

    expect(result.body).not.toContain('target="_blank"');
    const main = result.body.match(/<main>([\s\S]*)<\/main>/)?.[1] ?? "";
    expect(main.match(/class="app-card"/g)?.length).toBe(
      result.body.match(/class="app-card"/g)?.length,
    );
  });

  test("zoo-sites cards describe their own site", async () => {
    const result = await fetchWithProxy("https://home.zoo/");
    expect(result.httpCode, result.error).toBe(200);

    expect(result.body).not.toContain("Simulated websites from zoo-sites");
    expect(result.body).toMatch(
      /<a href="https:\/\/voltro\.zoo" class="app-card">[\s\S]*?<p class="app-description">Voltro — Computer Monitors<\/p>/,
    );
    expect(result.body).toContain("Grelsby Water &amp; Sewer Authority");
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
