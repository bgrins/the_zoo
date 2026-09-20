import type { Browser } from "playwright";
import { afterAll, beforeAll, describe, expect, test } from "vitest";
import { launchZooBrowser, newZooContext, signInOnAuthZoo } from "../utils/browser";

// Signs in as personas no other test uses, so Hydra consent state doesn't collide.
describe("auth.zoo in a browser", () => {
  let browser: Browser;

  beforeAll(async () => {
    browser = await launchZooBrowser();
  });

  afterAll(async () => {
    await browser.close();
  });

  test("home page shows the sign-in form to anonymous visitors", async () => {
    const context = await newZooContext(browser);
    const page = await context.newPage();

    await page.goto("https://auth.zoo/");
    expect(page.url()).toBe("https://auth.zoo/");
    await expect(page.locator("h1").textContent()).resolves.toBe("Unified Identity for Zoo");
    expect(await page.locator('form[action="/direct-login"]').count()).toBe(1);

    await context.close();
  });

  test("signing in through misc.zoo skips consent and lists it on the dashboard", async () => {
    const context = await newZooContext(browser);
    const page = await context.newPage();
    const miscApp = page.locator(".app-item", {
      has: page.locator('input[name="clientId"][value="zoo-misc-app"]'),
    });
    const visited: string[] = [];
    page.on("framenavigated", (frame) => visited.push(frame.url()));

    // Start without a grant, whatever earlier runs left behind
    await page.goto("https://auth.zoo/");
    await page.fill('form[action="/direct-login"] input[name="username"]', "eve");
    await page.fill('form[action="/direct-login"] input[name="password"]', "eve123");
    await page.click('form[action="/direct-login"] button[type="submit"]');
    await page.waitForURL("https://auth.zoo/dashboard");
    const revoke = await context.request.post("https://auth.zoo/revoke-app", {
      form: { clientId: "zoo-misc-app" },
    });
    expect(revoke.url()).toBe("https://auth.zoo/dashboard");
    await page.reload();
    expect(await miscApp.count()).toBe(0);

    // misc.zoo is a first-party client, so the first grant shows no consent screen either
    await page.goto("https://misc.zoo/");
    await page.click('a[href="/oauth/login"]');
    await page.waitForURL(/^https:\/\/auth\.zoo\/login\?login_challenge=/);
    await page.fill('input[name="username"]', "eve");
    await page.fill('input[name="password"]', "eve123");
    await page.click('button[type="submit"]');
    await page.waitForURL("https://misc.zoo/");
    expect(await page.content()).toContain('"preferred_username": "eve"');
    expect(visited.filter((url) => url.startsWith("https://auth.zoo/consent"))).toEqual([]);

    await page.goto("https://auth.zoo/dashboard");
    expect(page.url()).toBe("https://auth.zoo/dashboard");
    await expect(page.locator("h1").textContent()).resolves.toBe("Welcome to Your Zoo Identity");
    expect(await miscApp.count()).toBe(1);
    const details = (await miscApp.textContent())?.replace(/\s+/g, " ");
    expect(details).toMatch(/Zoo Misc Application Authorized: \d{4}-\d{2}-\d{2} /);
    expect(details).toContain("Permissions: openid, profile, email");

    await context.close();
  });

  test("logout ends the session for the next OAuth login too", async () => {
    const context = await newZooContext(browser);
    const page = await context.newPage();

    await page.goto("https://misc.zoo/oauth/login");
    await signInOnAuthZoo(page, "grace", "grace123", "misc.zoo");

    await page.goto("https://auth.zoo/dashboard");
    await page.click('form[action="/logout"] button');
    await page.waitForURL("https://auth.zoo/");
    expect(await page.locator('a[href="/dashboard"]').count()).toBe(0);

    // Without a Hydra session, a new OAuth flow must ask for credentials again
    await context.clearCookies({ domain: "misc.zoo" });
    await page.goto("https://misc.zoo/oauth/login");
    await page.waitForURL(/^https:\/\/auth\.zoo\/login\?login_challenge=/);
    expect(await page.locator('input[name="password"]').count()).toBe(1);

    await context.close();
  });
});
