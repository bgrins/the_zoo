import { chromium, type Browser, type BrowserContext, type Page } from "playwright";
import { afterAll, beforeAll, describe, expect, test } from "vitest";

describe("OAuth Flow Integration Tests", () => {
  let browser: Browser;
  let context: BrowserContext;
  let page: Page;

  beforeAll(async () => {
    browser = await chromium.launch({ headless: true });
    context = await browser.newContext({
      proxy: { server: "http://localhost:3128" },
    });
    page = await context.newPage();
  });

  afterAll(async () => {
    await browser.close();
  });

  test("complete OAuth authorization flow", async () => {
    // Step 1: Start OAuth flow
    const authUrl =
      "http://auth.zoo/oauth2/auth?client_id=zoo-misc-app&redirect_uri=http://misc.zoo/oauth/callback&response_type=code&scope=openid+profile+email&state=test123456789";

    await page.goto(authUrl, { waitUntil: "networkidle" });

    // Verify we're redirected to login page
    expect(page.url()).toContain("/login");

    // Check cookies are being set
    const cookies = await context.cookies();
    expect(cookies.length).toBeGreaterThan(0);
    const csrfCookie = cookies.find((c) => c.name.includes("csrf"));
    expect(csrfCookie).toBeDefined();

    // Step 2: Login
    await page.fill('input[name="username"]', "admin");
    await page.fill('input[name="password"]', "admin123");
    await page.click('button[type="submit"]');
    await page.waitForLoadState("networkidle");

    // Step 3: Handle consent if needed
    if (page.url().includes("/consent")) {
      await page.click('button[value="accept"]');
      await page.waitForLoadState("networkidle");
    }

    // Step 4: Verify callback redirect
    expect(page.url()).toContain("misc.zoo/oauth/callback");

    const url = new URL(page.url());
    const code = url.searchParams.get("code");
    const state = url.searchParams.get("state");

    expect(code).toBeTruthy();
    expect(code?.length).toBeGreaterThan(20);
    expect(state).toBe("test123456789");
  });

  test("OAuth wellknown endpoint provides discovery", async () => {
    const response = await page.goto("http://auth.zoo/.well-known/openid-configuration");
    expect(response?.status()).toBe(200);

    const discovery = await response?.json();
    expect(discovery).toHaveProperty("issuer");
    expect(discovery).toHaveProperty("authorization_endpoint");
    expect(discovery).toHaveProperty("token_endpoint");
    expect(discovery).toHaveProperty("userinfo_endpoint");
    expect(discovery).toHaveProperty("jwks_uri");
  });

  test("invalid OAuth request returns appropriate error", async () => {
    // Test with missing required parameters
    const invalidAuthUrl = "http://auth.zoo/oauth2/auth?client_id=invalid-client";
    await page.goto(invalidAuthUrl, { waitUntil: "networkidle" });

    // Should show error or redirect to error page
    expect(page.url()).toMatch(/error|login/);
  });
});
