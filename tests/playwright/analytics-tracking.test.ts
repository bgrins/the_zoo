import { afterAll, beforeAll, describe, expect, test } from "vitest";
import type { Browser, BrowserContext } from "playwright";
import { PLAYWRIGHT_NAVIGATION_TIMEOUT } from "../constants";
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

describe("Analytics Tracking", () => {
  test("should inject shared.js into pages", async () => {
    const page = await context.newPage();

    try {
      const response = await page.goto("https://wiki.zoo", {
        timeout: PLAYWRIGHT_NAVIGATION_TIMEOUT,
      });
      expect(response?.status()).toBe(200);

      const content = await page.content();
      expect(content).toContain("performance.zoo/shared.js");
    } finally {
      await page.close();
    }
  });

  test("should initialize window.__zooTracking API", async () => {
    const page = await context.newPage();

    try {
      await page.goto("https://wiki.zoo", { timeout: PLAYWRIGHT_NAVIGATION_TIMEOUT });
      await page.waitForFunction(() => window.__zooTracking !== undefined, { timeout: 10000 });

      const api = await page.evaluate(() => {
        return {
          hasTrackEvent: typeof window.__zooTracking.trackEvent === "function",
          hasTrackGoal: typeof window.__zooTracking.trackGoal === "function",
          hasSetAgentContext: typeof window.__zooTracking.setAgentContext === "function",
          hasTrackSearch: typeof window.__zooTracking.trackSearch === "function",
          version: window.__zooTracking.version,
          siteId: window.__zooTracking.siteId,
          domain: window.__zooTracking.domain,
        };
      });

      expect(api.hasTrackEvent).toBe(true);
      expect(api.hasTrackGoal).toBe(true);
      expect(api.hasSetAgentContext).toBe(true);
      expect(api.hasTrackSearch).toBe(true);
      expect(api.version).toBe("1.0.0");
      expect(api.siteId).toBe(15); // wiki.zoo is site ID 15
      expect(api.domain).toBe("wiki.zoo");
    } finally {
      await page.close();
    }
  });

  test("should track page views to matomo.php", async () => {
    const page = await context.newPage();

    try {
      const pageView = page.waitForRequest((request) =>
        /matomo\.php.*action_name=/.test(request.url()),
      );
      await page.goto("https://wiki.zoo", { timeout: PLAYWRIGHT_NAVIGATION_TIMEOUT });

      expect((await pageView).url()).toContain("idsite=15");
    } finally {
      await page.close();
    }
  });

  test("should track custom events via API", async () => {
    const page = await context.newPage();

    try {
      await page.goto("https://wiki.zoo", { timeout: PLAYWRIGHT_NAVIGATION_TIMEOUT });
      await page.waitForFunction(() => window.__zooTracking !== undefined, { timeout: 10000 });

      // Track custom event and verify it doesn't throw errors
      const result = await page.evaluate(() => {
        try {
          window.__zooTracking.trackEvent("TestCategory", "TestAction", "TestName", 123);
          return { success: true };
        } catch (error) {
          return { success: false, error: (error as Error).message };
        }
      });

      expect(result.success).toBe(true);
    } finally {
      await page.close();
    }
  });

  test("should allow setting agent context", async () => {
    const page = await context.newPage();

    try {
      await page.goto("https://wiki.zoo", { timeout: PLAYWRIGHT_NAVIGATION_TIMEOUT });
      await page.waitForFunction(() => window.__zooTracking !== undefined, { timeout: 10000 });

      const result = await page.evaluate(() => {
        try {
          window.__zooTracking.setAgentContext({
            agentType: "TestAgent",
            taskType: "TestTask",
            attemptNumber: 42,
          });
          return { success: true };
        } catch (error) {
          return { success: false, error: (error as Error).message };
        }
      });

      expect(result.success).toBe(true);
    } finally {
      await page.close();
    }
  });
});
