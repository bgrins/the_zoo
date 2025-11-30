import { afterAll, beforeAll, describe, expect, test } from "vitest";
import { firefox } from "playwright";
import type { Browser, BrowserContext } from "playwright";
import {
  PROXY_HOST,
  PROXY_PORT,
  PLAYWRIGHT_CONFIG,
  PLAYWRIGHT_NAVIGATION_TIMEOUT,
} from "../constants";

let browser: Browser | null = null;
let context: BrowserContext | null = null;

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

afterAll(async () => {
  if (context) await context.close();
  if (browser) await browser.close();
});

describe("Analytics Tracking", () => {
  test("should inject shared.js into pages", async () => {
    if (!context) throw new Error("Browser context not initialized");
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
    if (!context) throw new Error("Browser context not initialized");
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
    if (!context) throw new Error("Browser context not initialized");
    const page = await context.newPage();

    try {
      const requests: string[] = [];

      page.on("request", (request) => {
        const url = request.url();
        if (url.includes("matomo.php")) {
          requests.push(url);
        }
      });

      await page.goto("https://wiki.zoo", { timeout: PLAYWRIGHT_NAVIGATION_TIMEOUT });
      await page.waitForTimeout(2000);

      const pageViewRequest = requests.find((url) => url.includes("action_name="));
      expect(pageViewRequest).toBeDefined();
      expect(pageViewRequest).toContain("idsite=15");
    } finally {
      await page.close();
    }
  });

  test("should track custom events via API", async () => {
    if (!context) throw new Error("Browser context not initialized");
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
    if (!context) throw new Error("Browser context not initialized");
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
});
