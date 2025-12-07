import { firefox } from "playwright";

const PROXY_PORT = process.env.ZOO_PROXY_PORT || "3128";

const browser = await firefox.launch({
  headless: false,
  proxy: { server: `http://localhost:${PROXY_PORT}` },
});

const context = await browser.newContext({ ignoreHTTPSErrors: true });
const page = await context.newPage();

// Navigate to home page
await page.goto("https://home.zoo");
console.log(`Title: ${await page.title()}`);

// List services
const cards = await page.locator(".app-card").all();
console.log(`Found ${cards.length} services`);

// Go to paste service
await page.goto("https://paste.zoo");
await page.waitForLoadState("networkidle");
console.log(`Navigated to: ${page.url()}`);

// Create a paste
await page.fill("#content-input", "Hello from Playwright JS!");
await page.click("#submit-button");
await page.waitForURL("**/upload/**");
console.log(`Created paste at: ${page.url()}`);

await page.waitForTimeout(3000);
await browser.close();
