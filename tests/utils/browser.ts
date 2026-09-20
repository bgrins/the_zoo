import { firefox, type Browser, type BrowserContext, type Page } from "playwright";
import { PLAYWRIGHT_CONFIG, PROXY_HOST, PROXY_PORT } from "../constants";

/**
 * Keep pages inside the zoo: Firefox otherwise connects to localhost directly instead of
 * through the proxy, and sends WebRTC (STUN over UDP) straight to the network
 */
export const ZOO_FIREFOX_PREFS = {
  "browser.fixup.domainsuffixwhitelist.zoo": true,
  "network.proxy.allow_hijacking_localhost": true,
  "media.peerconnection.ice.proxy_only": true,
};

/** Firefox routed through the zoo proxy (the only way to reach .zoo domains) */
export function launchZooBrowser(): Promise<Browser> {
  return firefox.launch({
    headless: PLAYWRIGHT_CONFIG.headless,
    proxy: { server: `http://${PROXY_HOST}:${PROXY_PORT}` },
    firefoxUserPrefs: ZOO_FIREFOX_PREFS,
  });
}

export async function newZooContext(browser: Browser): Promise<BrowserContext> {
  const context = await browser.newContext({
    ignoreHTTPSErrors: true,
    viewport: { width: 1280, height: 720 },
  });
  // Below the playwright config's testTimeout, so a stuck wait reports its URL or selector
  context.setDefaultTimeout(10000);
  return context;
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
