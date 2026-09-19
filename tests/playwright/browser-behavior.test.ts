import type { Browser, BrowserContext } from "playwright";
import { afterAll, beforeAll, describe, expect, test } from "vitest";
import { PLAYWRIGHT_NAVIGATION_TIMEOUT, PLAYWRIGHT_SELECTOR_TIMEOUT } from "../constants";
import { launchZooBrowser, newZooContext } from "../utils/browser";

let browser: Browser;
let context: BrowserContext;

beforeAll(async () => {
  browser = await launchZooBrowser();
  context = await newZooContext(browser);
});

afterAll(async () => {
  await context.close();
  await browser.close();
});

describe("Playwright-specific browser tests", () => {
  test("should inject the performance.zoo tracking script on HTML pages", async () => {
    const testSites = [
      { url: "http://example.zoo/", expectScript: true },
      { url: "http://wiki.zoo/", expectScript: true },
      // performance.zoo serves shared.js and must not inject into itself
      { url: "http://performance.zoo/", expectScript: false },
    ];

    await Promise.all(
      testSites.map(async ({ url, expectScript }) => {
        const page = await context.newPage();
        try {
          const response = await page.goto(url, {
            timeout: PLAYWRIGHT_NAVIGATION_TIMEOUT,
            waitUntil: "load",
          });
          expect(response?.headers()["content-type"], url).toContain("text/html");

          const scriptLoaded = await page.evaluate(
            () => typeof (window as any).__zooTracking !== "undefined",
          );
          expect(scriptLoaded, url).toBe(expectScript);
          expect(response?.headers()["x-performance-zoo"], url).toBe(
            expectScript ? "injected" : undefined,
          );
        } finally {
          await page.close();
        }
      }),
    );
  });

  test("should block external network access through proxy", async () => {
    const page = await context.newPage();

    for (const ip of [
      "http://172.217.16.142", // google.com IP
      "http://93.184.216.34", // example.com IP
    ]) {
      // Squid refuses anything outside .zoo with 403
      const response = await page.goto(ip, { timeout: PLAYWRIGHT_SELECTOR_TIMEOUT });
      expect(response?.status(), ip).toBe(403);
    }

    await page.close();
  });

  test("should allow cross-site navigation within zoo", async () => {
    const page = await context.newPage();

    await page.goto("https://home.zoo");
    // App cards open in a new tab
    const [appPage] = await Promise.all([
      context.waitForEvent("page"),
      page.click('a.app-card[href="https://gitea.zoo"]'),
    ]);
    await appPage.waitForLoadState("load");
    expect(new URL(appPage.url()).hostname).toBe("gitea.zoo");
    await expect(appPage.title()).resolves.toContain("Gitea");

    await appPage.close();
    await page.close();
  });
});
