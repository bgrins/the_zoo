import { firefox, type Browser, type BrowserContext, type Page } from "playwright";
import { PLAYWRIGHT_CONFIG, PROXY_HOST, PROXY_PORT } from "../constants";

/** Firefox routed through the zoo proxy (the only way to reach .zoo domains) */
export function launchZooBrowser(): Promise<Browser> {
  return firefox.launch({
    headless: PLAYWRIGHT_CONFIG.headless,
    proxy: { server: `http://${PROXY_HOST}:${PROXY_PORT}` },
  });
}

export function newZooContext(browser: Browser): Promise<BrowserContext> {
  return browser.newContext({ ignoreHTTPSErrors: true, viewport: { width: 1280, height: 720 } });
}

/**
 * Fill in auth.zoo's OAuth login form (the page must already be on it), accept consent if
 * asked, and wait until the browser is back on `returnHost`.
 */
export async function signInOnAuthZoo(
  page: Page,
  username: string,
  password: string,
  returnHost: string,
): Promise<void> {
  await page.waitForURL(/^https?:\/\/auth\.zoo\/login\?login_challenge=/);
  await page.fill('input[name="username"]', username);
  await page.fill('input[name="password"]', password);
  await page.click('button[type="submit"]');

  await page.waitForURL(
    (url) =>
      url.hostname === returnHost || (url.hostname === "auth.zoo" && url.pathname === "/consent"),
  );
  if (new URL(page.url()).hostname === "auth.zoo") {
    await page.click('button[value="accept"]');
    await page.waitForURL((url) => url.hostname === returnHost);
  }
}
