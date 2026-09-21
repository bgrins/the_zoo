import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { afterAll, beforeAll, describe, expect, test } from "vitest";
import type { Browser, BrowserContext } from "playwright";
import { COLD_START_TIMEOUT, PLAYWRIGHT_NAVIGATION_TIMEOUT } from "../constants";
import { launchZooBrowser, newZooContext } from "../utils/browser";
import { warmUp } from "../utils/on-demand";

const execFileAsync = promisify(execFile);

let browser: Browser;
let context: BrowserContext;

beforeAll(async () => {
  // Pages report to analytics.zoo
  await Promise.all(["https://wiki.zoo/", "https://analytics.zoo/"].map(warmUp));
  browser = await launchZooBrowser();
  context = await newZooContext(browser);
}, COLD_START_TIMEOUT);

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
      const pageView = page.waitForResponse((response) =>
        /matomo\.php.*action_name=/.test(response.url()),
      );
      await page.goto("https://wiki.zoo", { timeout: PLAYWRIGHT_NAVIGATION_TIMEOUT });

      const response = await pageView;
      expect(response.url()).toContain("idsite=15");
      // The JS tracker sends a beacon, which Matomo answers with 204 (a pixel GET gets 200)
      expect(response.status()).toBe(204);
    } finally {
      await page.close();
    }
  });

  test("stores the run ID cookie and later events in Matomo", async () => {
    const runId = `analytics-test-${Date.now()}`;
    const runContext = await newZooContext(browser);
    await runContext.addCookies([
      { name: "zoo_run_id", value: runId, domain: "example.zoo", path: "/" },
    ]);
    const page = await runContext.newPage();

    try {
      const pageView = page.waitForResponse((response) =>
        /matomo\.php.*action_name=/.test(response.url()),
      );
      await page.goto("https://example.zoo/", { timeout: PLAYWRIGHT_NAVIGATION_TIMEOUT });
      expect((await pageView).status()).toBe(204);
      expect(
        await matomoRows(`SELECT ${DIMENSIONS} FROM matomo_log_visit ${forRun(runId)}`),
      ).toEqual([["Firefox (automated)", runId, "general", "1"]]);

      // matomo.js has replaced window._paq by now, so this checks events still get through
      const event = page.waitForResponse((response) => response.url().includes("e_c=TestCategory"));
      await page.evaluate(() => {
        window.__zooTracking.setAgentContext({
          agentType: "TestAgent",
          taskType: "TestTask",
          attemptNumber: 42,
        });
        window.__zooTracking.trackEvent("TestCategory", "TestAction", "TestName", 123);
      });
      expect((await event).status()).toBe(204);

      expect(
        await matomoRows(`SELECT ${DIMENSIONS} FROM matomo_log_visit ${forRun(runId)}`),
      ).toEqual([["TestAgent", runId, "TestTask", "42"]]);
      expect(
        await matomoRows(
          `SELECT c.name, a.name, n.name, l.custom_float FROM matomo_log_link_visit_action l
           JOIN matomo_log_visit v ON v.idvisit = l.idvisit
           JOIN matomo_log_action c ON c.idaction = l.idaction_event_category
           JOIN matomo_log_action a ON a.idaction = l.idaction_event_action
           JOIN matomo_log_action n ON n.idaction = l.idaction_name
           ${forRun(runId, "v")} AND c.name = 'TestCategory'`,
        ),
      ).toEqual([["TestCategory", "TestAction", "TestName", "123"]]);

      // The context outlasts the page
      const reloaded = page.waitForResponse((response) =>
        /matomo\.php.*action_name=/.test(response.url()),
      );
      await page.reload({ timeout: PLAYWRIGHT_NAVIGATION_TIMEOUT });
      expect((await reloaded).status()).toBe(204);
      expect(
        await matomoRows(`SELECT ${DIMENSIONS} FROM matomo_log_visit ${forRun(runId)}`),
      ).toEqual([["TestAgent", runId, "TestTask", "42"]]);
    } finally {
      await runContext.close();
    }
  });

  test("tracks with a cookie value that isn't URI-encoded", async () => {
    const runId = `analytics-test-${Date.now()}`;
    const runContext = await newZooContext(browser);
    await runContext.addCookies(
      [
        { name: "zoo_run_id", value: runId },
        { name: "zoo_task_type", value: "100%" },
      ].map((cookie) => ({ ...cookie, domain: "example.zoo", path: "/" })),
    );
    const page = await runContext.newPage();

    try {
      const pageView = page.waitForResponse((response) =>
        /matomo\.php.*action_name=/.test(response.url()),
      );
      await page.goto("https://example.zoo/", { timeout: PLAYWRIGHT_NAVIGATION_TIMEOUT });
      expect((await pageView).status()).toBe(204);
      expect(
        await matomoRows(`SELECT ${DIMENSIONS} FROM matomo_log_visit ${forRun(runId)}`),
      ).toEqual([["Firefox (automated)", runId, "100%", "1"]]);
    } finally {
      await runContext.close();
    }
  });

  test("leaves links between zoo sites as the page wrote them", async () => {
    const page = await context.newPage();

    try {
      const pageView = page.waitForResponse((response) =>
        /matomo\.php.*action_name=/.test(response.url()),
      );
      await page.goto("https://home.zoo/", { timeout: PLAYWRIGHT_NAVIGATION_TIMEOUT });
      await pageView;
      await page.click('footer a[href="https://status.zoo"]');
      await page.waitForURL((url) => url.hostname === "status.zoo");
      expect(page.url()).toBe("https://status.zoo/");
    } finally {
      await page.close();
    }
  });
});

// Visit-scope dimensions 1-4 configured in the analytics seed
const DIMENSIONS = "custom_dimension_1, custom_dimension_2, custom_dimension_3, custom_dimension_4";

const forRun = (runId: string, table = "matomo_log_visit") =>
  `WHERE ${table}.custom_dimension_2 = '${runId}'`;

// Matomo writes each tracking request before answering it, so rows are there once the page
// has its response; read-only queries against the golden-state database
async function matomoRows(sql: string): Promise<string[][]> {
  const { stdout } = await execFileAsync("docker", [
    "compose",
    "exec",
    "-T",
    "mysql",
    "mysql",
    "-u",
    "analytics_user",
    "-panalytics_pw",
    "analytics_db",
    "--batch",
    "--skip-column-names",
    "-e",
    sql,
  ]);
  return stdout
    .trim()
    .split("\n")
    .filter(Boolean)
    .map((line) => line.split("\t"));
}
