import { firefox, type Browser, type BrowserContext } from "playwright";
import { afterAll, beforeAll, describe, test } from "vitest";
import { getAllSites, type Site } from "../../scripts/sites-registry";
import { existsSync, mkdirSync } from "node:fs";
import { join } from "node:path";
import {
  PROXY_HOST,
  PROXY_PORT,
  PLAYWRIGHT_CONFIG,
  PLAYWRIGHT_NAVIGATION_TIMEOUT,
  PLAYWRIGHT_SCREENSHOT_BATCH_SIZE,
  EXTRA_EXTENDED_TEST_TIMEOUT,
} from "../constants";

// Test results directory
const TEST_RESULTS_DIR = join(process.cwd(), "tests", "test-results");

// Ensure test-results directory exists
if (!existsSync(TEST_RESULTS_DIR)) {
  mkdirSync(TEST_RESULTS_DIR, { recursive: true });
}

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

describe("Screenshots", () => {
  test(
    "should take screenshots of all sites",
    { timeout: EXTRA_EXTENDED_TEST_TIMEOUT },
    async () => {
      if (!PLAYWRIGHT_CONFIG.takeScreenshots) {
        console.log("Skipping screenshots (TEST_TAKE_SCREENSHOTS=false)");
        return;
      }

      const sites = getAllSites();
      const batchSize = PLAYWRIGHT_SCREENSHOT_BATCH_SIZE;

      // Process sites in batches
      for (let i = 0; i < sites.length; i += batchSize) {
        const batch = sites.slice(i, i + batchSize);

        await Promise.all(
          batch.map(async (site: Site) => {
            if (!context) throw new Error("Browser context not initialized");
            const page = await context.newPage();
            try {
              const response = await page.goto(site.httpHealthUrl, {
                timeout: PLAYWRIGHT_NAVIGATION_TIMEOUT,
                waitUntil: "domcontentloaded",
              });

              if (
                response &&
                (response.status() === 200 ||
                  response.status() === 304 ||
                  response.status() === 401)
              ) {
                const screenshotPath = join(
                  TEST_RESULTS_DIR,
                  `${site.domain.replace(/\./g, "_")}.jpeg`,
                );
                await page.screenshot({
                  path: screenshotPath,
                  fullPage: false,
                  type: "jpeg",
                });
                console.log(`✓ Screenshot saved: ${site.domain}`);
              }
            } catch (error) {
              console.warn(`Failed to screenshot ${site.domain}: ${(error as Error).message}`);
            } finally {
              await page.close();
            }
          }),
        );
      }
    },
  );
});
