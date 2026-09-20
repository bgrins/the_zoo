import { createServer } from "node:http";
import type { AddressInfo } from "node:net";
import type { Browser, BrowserContext } from "playwright";
import { afterAll, beforeAll, describe, expect, test } from "vitest";
import {
  COLD_START_TIMEOUT,
  PLAYWRIGHT_NAVIGATION_TIMEOUT,
  PLAYWRIGHT_SELECTOR_TIMEOUT,
} from "../constants";
import { launchZooBrowser, newZooContext } from "../utils/browser";
import { warmUp } from "../utils/on-demand";

let browser: Browser;
let context: BrowserContext;

beforeAll(async () => {
  await Promise.all(["https://wiki.zoo/", "https://gitea.zoo/"].map(warmUp));
  browser = await launchZooBrowser();
  context = await newZooContext(browser);
}, COLD_START_TIMEOUT);

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

  test("should not let pages reach services on the host's localhost", async () => {
    // A service on the host that pages must not see
    const server = createServer((_req, res) => res.end("host service"));
    await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
    const { port } = server.address() as AddressInfo;
    const page = await context.newPage();
    try {
      for (const url of [`http://127.0.0.1:${port}/`, `http://localhost:${port}/`]) {
        const response = await page.goto(url, { timeout: PLAYWRIGHT_SELECTOR_TIMEOUT });
        expect(response?.status(), url).toBe(403);
        expect(await page.content(), url).not.toContain("host service");
      }
    } finally {
      await page.close();
      server.close();
    }
  });

  test("should allow cross-site navigation within zoo", async () => {
    const page = await context.newPage();

    await page.goto("https://home.zoo");
    // App cards navigate in the same tab
    await page.click('a.app-card[href="https://gitea.zoo"]');
    await page.waitForURL((url) => url.hostname === "gitea.zoo");
    await expect(page.title()).resolves.toContain("Gitea");
    expect(context.pages()).toEqual([page]);

    await page.close();
  });
});
