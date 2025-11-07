import { firefox, type Browser } from "playwright";
import { afterAll, beforeAll, describe, expect, test } from "vitest";

const PROXY_SERVER = "http://localhost:3128";

describe("Auth Dashboard Integration Tests", () => {
  let browser: Browser;

  beforeAll(async () => {
    browser = await firefox.launch({ headless: true });
  });

  afterAll(async () => {
    await browser.close();
  });

  test("auth.zoo home page loads for unauthenticated users", async () => {
    const context = await browser.newContext({
      proxy: { server: PROXY_SERVER },
    });
    const page = await context.newPage();

    await page.goto("http://auth.zoo/", { waitUntil: "networkidle" });

    const content = await page.content();
    expect(content).toContain("Zoo Authentication Service");
    expect(page.url()).not.toContain("/dashboard");

    await context.close();
  });

  test("OAuth login flow through oauth-example.zoo", async () => {
    const context = await browser.newContext({
      proxy: { server: PROXY_SERVER },
    });
    const page = await context.newPage();

    // Start at oauth-example.zoo
    await page.goto("http://oauth-example.zoo/", { waitUntil: "networkidle" });

    // Click login link
    await page.click('a[href="/login"]');

    // Should redirect to auth.zoo login
    await page.waitForURL("**/login?login_challenge=*");
    expect(page.url()).toContain("auth.zoo/login");

    // Login with credentials
    await page.fill('input[name="username"]', "admin");
    await page.fill('input[name="password"]', "admin123");
    await page.click('button[type="submit"]');

    // Handle consent if shown
    if (page.url().includes("/consent")) {
      await page.click('button[value="accept"]');
    }

    // Should be back at oauth-example.zoo
    await page.waitForURL("http://oauth-example.zoo/**");
    expect(page.url()).toContain("oauth-example.zoo");

    await context.close();
  });

  test("authenticated user can access dashboard", async () => {
    const context = await browser.newContext({
      proxy: { server: PROXY_SERVER },
    });
    const page = await context.newPage();

    // First authenticate through oauth-example.zoo
    await page.goto("http://oauth-example.zoo/", { waitUntil: "networkidle" });
    await page.click('a[href="/login"]');
    await page.waitForURL("**/login?login_challenge=*");
    await page.fill('input[name="username"]', "admin");
    await page.fill('input[name="password"]', "admin123");
    await page.click('button[type="submit"]');
    if (page.url().includes("/consent")) {
      await page.click('button[value="accept"]');
    }
    await page.waitForURL("http://oauth-example.zoo/**");

    // Navigate to auth.zoo after authentication
    await page.goto("http://auth.zoo/", { waitUntil: "networkidle" });

    // Should redirect to dashboard
    await page.waitForURL("http://auth.zoo/dashboard");

    const content = await page.content();
    expect(content).toContain("User Dashboard");
    expect(content).toContain("Welcome, Admin User!");
    expect(content).toContain("zoo-example-app");

    await context.close();
  });

  test("logout functionality works correctly", async () => {
    const context = await browser.newContext({
      proxy: { server: PROXY_SERVER },
    });
    const page = await context.newPage();

    // First authenticate
    await page.goto("http://oauth-example.zoo/", { waitUntil: "networkidle" });
    await page.click('a[href="/login"]');
    await page.waitForURL("**/login?login_challenge=*");
    await page.fill('input[name="username"]', "admin");
    await page.fill('input[name="password"]', "admin123");
    await page.click('button[type="submit"]');
    if (page.url().includes("/consent")) {
      await page.click('button[value="accept"]');
    }
    await page.waitForURL("http://oauth-example.zoo/**");

    // Ensure we're on the dashboard
    await page.goto("http://auth.zoo/dashboard", { waitUntil: "networkidle" });

    // Click logout button
    await page.click('button:has-text("Logout")');
    await page.waitForURL("http://auth.zoo/");

    const content = await page.content();
    expect(content).toContain("Zoo Authentication Service");
    expect(content).not.toContain("Dashboard");
    expect(content).not.toContain("Welcome, Admin User!");

    await context.close();
  });

  test("dashboard shows connected applications", { timeout: 20000 }, async () => {
    const context = await browser.newContext({
      proxy: { server: PROXY_SERVER },
    });
    const page = await context.newPage();

    // Authenticate through oauth-example.zoo
    await page.goto("http://oauth-example.zoo/", { waitUntil: "networkidle" });
    await page.click('a[href="/login"]');
    await page.waitForURL("**/login?login_challenge=*");
    await page.fill('input[name="username"]', "admin");
    await page.fill('input[name="password"]', "admin123");
    await page.click('button[type="submit"]');
    if (page.url().includes("/consent")) {
      await page.click('button[value="accept"]');
    }
    await page.waitForURL("http://oauth-example.zoo/**");

    // Now go to auth.zoo dashboard
    await page.goto("http://auth.zoo/dashboard", { waitUntil: "networkidle" });

    const content = await page.content();
    expect(content).toContain("Connected Applications");
    expect(content).toContain("zoo-example-app");

    await context.close();
  });
});
