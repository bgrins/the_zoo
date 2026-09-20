import type { Browser } from "playwright";
import { afterAll, beforeAll, describe, expect, test } from "vitest";
import { launchZooBrowser, newZooContext } from "../utils/browser";

describe("SnappyMail in a browser", () => {
  let browser: Browser;

  beforeAll(async () => {
    browser = await launchZooBrowser();
  });

  afterAll(async () => {
    await browser.close();
  });

  test("a bare username signs in to its @snappymail.zoo mailbox", async () => {
    const context = await newZooContext(browser);
    const page = await context.newPage();

    await page.goto("https://snappymail.zoo/");
    await page.fill('input[name="Email"]', "alice");
    await page.fill('input[name="Password"]', "alice123");
    await page.click(".buttonLogin");
    await expect(page.locator(".accountPlace").textContent()).resolves.toBe("alice@snappymail.zoo");

    await context.close();
  });
});
