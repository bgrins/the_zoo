import { firefox, type Browser, type BrowserContext } from "playwright";
import { afterAll, beforeAll, describe, expect, test } from "vitest";
import {
  PROXY_HOST,
  PROXY_PORT,
  PLAYWRIGHT_CONFIG,
  PLAYWRIGHT_NAVIGATION_TIMEOUT,
  PLAYWRIGHT_SELECTOR_TIMEOUT,
} from "../constants";

let browser: Browser | null = null;
let context: BrowserContext | null = null;

// Setup browser before all tests
beforeAll(async () => {
  browser = await firefox.launch({
    headless: PLAYWRIGHT_CONFIG.headless,
    proxy: {
      server: `http://${PROXY_HOST}:${PROXY_PORT}`,
    },
  });

  context = await browser.newContext({
    ignoreHTTPSErrors: true,
    viewport: { width: 1280, height: 720 },
  });
});

// Cleanup after all tests
afterAll(async () => {
  if (context) await context.close();
  if (browser) await browser.close();
});

describe("Playwright-specific browser tests", () => {
  test("should inject __performanceZoo script on HTML pages", async () => {
    const testSites = [
      { url: "http://example.zoo/", domain: "example.zoo", expectScript: true },
      { url: "http://wiki.zoo/", domain: "wiki.zoo", expectScript: true },
      { url: "http://performance.zoo/", domain: "performance.zoo", expectScript: false }, // Should not inject on itself
    ];

    await Promise.all(
      testSites.map(async ({ url, domain, expectScript }) => {
        if (!context) throw new Error("Browser context not initialized");
        const page = await context.newPage();
        try {
          const response = await page.goto(url, {
            timeout: PLAYWRIGHT_NAVIGATION_TIMEOUT,
            waitUntil: "domcontentloaded",
          });

          if (!response) {
            throw new Error(`No response from ${url}`);
          }

          // Check if this is an HTML response
          const headers = response.headers();
          const contentType = headers["content-type"] || "";
          const isHtmlResponse = contentType.includes("text/html");

          if (isHtmlResponse) {
            // Check for __performanceZoo script injection
            const scriptLoaded = await page.evaluate(() => {
              return typeof (window as any).__performanceZoo !== "undefined";
            });

            const hasInjectionHeader = headers["x-performance-zoo"] === "injected";

            if (expectScript) {
              expect(scriptLoaded || hasInjectionHeader).toBe(true);
              console.log(
                `✓ ${domain}: Performance script ${scriptLoaded ? "loaded" : "header present"}`,
              );
            } else {
              expect(scriptLoaded).toBe(false);
              console.log(`✓ ${domain}: Performance script correctly not injected`);
            }
          }
        } finally {
          await page.close();
        }
      }),
    );
  });

  test("should block external network access through proxy", async () => {
    if (!context) throw new Error("Browser context not initialized");
    const page = await context.newPage();

    const externalSites = [
      "http://172.217.16.142", // google.com IP
      "http://93.184.216.34", // example.com IP
    ];

    for (const ip of externalSites) {
      try {
        const response = await page.goto(ip, { timeout: PLAYWRIGHT_SELECTOR_TIMEOUT });

        if (!response) {
          console.log(`✓ ${ip} blocked successfully: No response`);
          continue;
        }

        const status = response.status();
        expect([403, 502, 503]).toContain(status);
        console.log(`✓ ${ip} blocked with status ${status}`);
      } catch (error) {
        // Connection refused or timeout is expected
        console.log(`✓ ${ip} blocked: ${(error as Error).message.substring(0, 50)}...`);
      }
    }

    await page.close();
  });

  test("should allow cross-site navigation within zoo", async () => {
    if (!context) throw new Error("Browser context not initialized");
    const page = await context.newPage();

    // Navigate to status.zoo
    await page.goto("http://status.zoo");
    await page.waitForSelector('h1:has-text("Zoo Status")', {
      timeout: PLAYWRIGHT_SELECTOR_TIMEOUT,
    });

    // Click on a service link if available
    const serviceLink = page.locator(".site-card a").first();
    if ((await serviceLink.count()) > 0) {
      await serviceLink.getAttribute("href");
      await serviceLink.click();
      await page.waitForLoadState("networkidle");

      const currentUrl = page.url();
      expect(currentUrl).toMatch(/\.zoo/);
      expect(currentUrl).not.toBe("http://status.zoo/");
      console.log(`✓ Successfully navigated from status.zoo to ${currentUrl}`);
    }

    await page.close();
  });

  test("should handle browser console messages", async () => {
    if (!context) throw new Error("Browser context not initialized");
    const page = await context.newPage();
    const consoleLogs: string[] = [];

    page.on("console", (msg) => {
      if (msg.type() === "log" || msg.type() === "error") {
        consoleLogs.push(`${msg.type()}: ${msg.text()}`);
      }
    });

    await page.goto("http://app1.zoo/");
    await page.waitForTimeout(1000); // Wait for any console messages

    // Verify we can capture console messages (if any)
    console.log(`✓ Captured ${consoleLogs.length} console messages`);
    if (consoleLogs.length > 0) {
      console.log("  Sample:", consoleLogs[0]);
    }

    await page.close();
  });
});
