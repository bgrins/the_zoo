import type { Browser } from "playwright";
import { afterAll, beforeAll, describe, expect, test } from "vitest";
import { launchZooBrowser, newZooContext, signInOnAuthZoo } from "../utils/browser";

describe("OAuth authorization flow in a browser", () => {
  let browser: Browser;

  beforeAll(async () => {
    browser = await launchZooBrowser();
  });

  afterAll(async () => {
    await browser.close();
  });

  test("returns an authorization code and the client's state to the callback", async () => {
    const context = await newZooContext(browser);
    const page = await context.newPage();

    const callback = page.waitForRequest((req) =>
      req.url().startsWith("https://misc.zoo/oauth/callback"),
    );
    await page.goto(
      "https://auth.zoo/oauth2/auth?client_id=zoo-misc-app&redirect_uri=https://misc.zoo/oauth/callback" +
        "&response_type=code&scope=openid+profile+email&state=test123456789",
    );
    await signInOnAuthZoo(page, "user1", "password", "misc.zoo");

    const callbackUrl = new URL((await callback).url());
    expect(callbackUrl.searchParams.get("code")?.length).toBeGreaterThan(20);
    expect(callbackUrl.searchParams.get("state")).toBe("test123456789");

    await context.close();
  });

  test("an unknown client lands on auth.zoo's error page", async () => {
    const context = await newZooContext(browser);
    const page = await context.newPage();

    await page.goto("https://auth.zoo/oauth2/auth?client_id=invalid-client&response_type=code");
    await page.waitForURL(/^https:\/\/auth\.zoo\/error\?/);
    await expect(page.locator("h1").textContent()).resolves.toBe("Authorization Error");
    expect(await page.locator(".error").textContent()).toBe("invalid_client");

    await context.close();
  });
});
