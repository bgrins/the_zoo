#!/usr/bin/env tsx

import { firefox } from "playwright";
import { promises as fs } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import * as yaml from "yaml";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT_DIR = path.resolve(__dirname, "..");
const SCREENSHOTS_DIR = path.join(ROOT_DIR, "docs", "screenshots");
const SITES_YAML = path.join(ROOT_DIR, "core", "SITES.yaml");

const SKIP_SITES = new Set(["status.zoo", "secure.gravatar.com"]);

interface Site {
  domain: string;
  description?: string;
  icon?: string;
  onDemand?: boolean;
  httpsOnly?: boolean;
}

interface SitesConfig {
  sites: Site[];
}

async function ensureScreenshotsDir() {
  await fs.mkdir(SCREENSHOTS_DIR, { recursive: true });
}

async function loadSites(): Promise<Site[]> {
  const content = await fs.readFile(SITES_YAML, "utf-8");
  const config = yaml.parse(content) as SitesConfig;
  return config.sites;
}

async function loginToSnappyMail(page: any) {
  try {
    // Wait for login form to be visible
    await page.waitForSelector('input[name="Email"]', { timeout: 5000 });

    // Fill in credentials - SnappyMail uses name="Email" and name="Password"
    await page.fill('input[name="Email"]', "alex.chen@snappymail.zoo");
    await page.fill('input[name="Password"]', "Password.123");

    // Click login button
    await page.click(".buttonLogin");

    // Wait for navigation away from login page or for mailbox UI to appear
    await Promise.race([
      page.waitForURL("**/?/**", { timeout: 10000 }), // Wait for URL change
      page.waitForSelector(".messageList, .folderList, .mailbox", { timeout: 10000 }), // Or wait for mailbox UI
    ]).catch(() => {
      // If neither happens, wait a bit for content to load
      return page.waitForTimeout(3000);
    });
  } catch (error: any) {
    console.error(`    Failed to login to SnappyMail: ${error.message}`);
  }
}

async function loginToMiniflux(page: any) {
  try {
    // Wait for login form
    await page.waitForSelector('input[name="username"]', { timeout: 5000 });

    // Fill credentials
    await page.fill('input[name="username"]', "alice");
    await page.fill('input[name="password"]', "alice123");

    // Submit form
    await page.click('button[type="submit"]');

    // Wait for navigation to unread page
    await page.waitForURL("**/unread", { timeout: 10000 });

    // Navigate to add feed page
    await page.goto("http://miniflux.zoo/subscribe", {
      waitUntil: "networkidle",
      timeout: 15000,
    });

    // Fill in the postmill feed URL (todayilearned forum)
    await page.waitForSelector('input[name="url"]', { timeout: 5000 });
    await page.fill('input[name="url"]', "https://postmill.zoo/f/todayilearned/new.atom");

    // Click "Find a feed" button to add the feed
    await page.click('button:has-text("Find a feed")');

    // Wait for feed entries to load (URL changes to /feed/X/entries)
    // If feed already exists, this will timeout - that's OK
    try {
      await page.waitForURL("**/feed/*/entries", { timeout: 10000 });
    } catch {
      // Feed may already exist - navigate to feeds list to find the todayilearned feed
      await page.goto("http://miniflux.zoo/feeds", {
        waitUntil: "networkidle",
        timeout: 15000,
      });
      // Click on the todayilearned feed link
      await page.click('a:has-text("todayilearned")').catch(() => {});
    }

    await page.waitForSelector("article", { timeout: 5000 }).catch(() => {});
    await page.waitForTimeout(1000);
  } catch (error: any) {
    console.error(`    Failed to login to Miniflux: ${error.message}`);
  }
}

async function loginToMattermost(page: any) {
  try {
    // Wait for login form
    await page.waitForSelector('input[id="input_loginId"]', { timeout: 5000 });

    // Fill credentials - using alice account (member of both teams)
    await page.fill('input[id="input_loginId"]', "alice");
    await page.fill('input[id="input_password-input"]', "alice123");

    // Click login button
    await page.click('button[id="saveSetting"]');

    // Wait for team selection or channel view
    await Promise.race([
      page.waitForURL("**/channels/**", { timeout: 15000 }),
      page.waitForSelector(".channel-header, .post-list", { timeout: 15000 }),
    ]).catch(() => {
      return page.waitForTimeout(3000);
    });

    // Wait for content to fully load
    await page.waitForTimeout(2000);
  } catch (error: any) {
    console.error(`    Failed to login to Mattermost: ${error.message}`);
  }
}

async function loginToFocalboard(page: any) {
  try {
    // Wait for login form
    await page.waitForSelector('input[placeholder="Enter username"]', { timeout: 5000 });

    // Fill credentials - using alex account
    await page.fill('input[placeholder="Enter username"]', "alex.lee@snappymail.zoo");
    await page.fill('input[placeholder="Enter password"]', "Password.123");

    // Click login button
    await page.click('button:has-text("Log in")');

    // Wait for navigation to boards page
    await Promise.race([
      page.waitForURL("**/board/**", { timeout: 10000 }),
      page.waitForURL("**/workspace/**", { timeout: 10000 }),
      page.waitForSelector(".BoardComponent, .Workspace, .Board", { timeout: 10000 }),
    ]).catch(() => {
      return page.waitForTimeout(3000);
    });
  } catch (error: any) {
    console.error(`    Failed to login to Focalboard: ${error.message}`);
  }
}

async function loginToGitea(page: any) {
  try {
    // Click Sign In link
    await page.click('a[href*="/user/login"]');
    await page.waitForSelector('input[name="user_name"]', { timeout: 5000 });

    // Fill credentials - using alice account
    await page.fill('input[name="user_name"]', "alice");
    await page.fill('input[name="password"]', "alice123");

    // Click login button
    await page.click('button.ui.primary.button:has-text("Sign In")');

    // Wait for dashboard
    await page.waitForURL("**/", { timeout: 10000 });
    await page.waitForTimeout(1000);

    // Navigate to express-mirror repo
    await page.goto("http://gitea.zoo/alice/express-mirror", {
      waitUntil: "networkidle",
      timeout: 15000,
    });
  } catch (error: any) {
    console.error(`    Failed to login to Gitea: ${error.message}`);
  }
}

async function loginToAnalytics(page: any) {
  try {
    // Wait for login form - Matomo uses a form with specific input fields
    await page.waitForSelector('input[name="form_login"]', { timeout: 5000 });

    // Fill credentials - using analytics admin account
    await page.fill('input[name="form_login"]', "analytics_user");
    await page.fill('input[name="form_password"]', "analytics_pw");

    // Click Sign in button (it's an input[type="submit"], not a button)
    await page.click("input#login_form_submit");

    // Wait for dashboard to load
    await Promise.race([
      page.waitForURL("**/index.php?module=CoreHome**", { timeout: 15000 }),
      page.waitForSelector(".widgetContainer", { timeout: 15000 }),
    ]).catch(() => {
      return page.waitForTimeout(3000);
    });

    // Wait a bit more for all widgets to load
    await page.waitForTimeout(2000);
  } catch (error: any) {
    console.error(`    Failed to login to Analytics: ${error.message}`);
  }
}

async function drawExcalidrawDiagram(page: any) {
  try {
    // Wait for excalidraw to load
    await page.waitForSelector('input[type="radio"]', { timeout: 10000 });
    await page.waitForTimeout(1000);

    // Draw ellipse for Start (terminal shape)
    await page.keyboard.press("4"); // Ellipse tool
    await page.mouse.move(300, 250);
    await page.mouse.down();
    await page.mouse.move(420, 320);
    await page.mouse.up();
    await page.waitForTimeout(100);

    // Add "Start" text
    await page.keyboard.press("8"); // Text tool
    await page.mouse.click(335, 280);
    await page.keyboard.type("Start");
    await page.keyboard.press("Escape");
    await page.waitForTimeout(100);

    // Draw arrow from Start to Process
    await page.keyboard.press("5"); // Arrow tool
    await page.mouse.move(420, 285);
    await page.mouse.down();
    await page.mouse.move(500, 285);
    await page.mouse.up();
    await page.waitForTimeout(100);

    // Draw rectangle for Process
    await page.keyboard.press("2"); // Rectangle tool
    await page.mouse.move(500, 250);
    await page.mouse.down();
    await page.mouse.move(640, 320);
    await page.mouse.up();
    await page.waitForTimeout(100);

    // Add "Process" text
    await page.keyboard.press("8");
    await page.mouse.click(530, 280);
    await page.keyboard.type("Process");
    await page.keyboard.press("Escape");
    await page.waitForTimeout(100);

    // Draw arrow from Process to Decision
    await page.keyboard.press("5");
    await page.mouse.move(640, 285);
    await page.mouse.down();
    await page.mouse.move(720, 285);
    await page.mouse.up();
    await page.waitForTimeout(100);

    // Draw diamond decision shape
    await page.keyboard.press("3"); // Diamond tool
    await page.mouse.move(720, 220);
    await page.mouse.down();
    await page.mouse.move(870, 350);
    await page.mouse.up();
    await page.waitForTimeout(100);

    // Add "Done?" text
    await page.keyboard.press("8");
    await page.mouse.click(770, 280);
    await page.keyboard.type("Done?");
    await page.keyboard.press("Escape");
    await page.waitForTimeout(100);

    // Draw arrow from Decision down to End
    await page.keyboard.press("5");
    await page.mouse.move(795, 350);
    await page.mouse.down();
    await page.mouse.move(795, 420);
    await page.mouse.up();
    await page.waitForTimeout(100);

    // Draw ellipse for End (terminal shape)
    await page.keyboard.press("4"); // Ellipse tool
    await page.mouse.move(730, 420);
    await page.mouse.down();
    await page.mouse.move(860, 490);
    await page.mouse.up();
    await page.waitForTimeout(100);

    // Add "End" text
    await page.keyboard.press("8");
    await page.mouse.click(780, 450);
    await page.keyboard.type("End");
    await page.keyboard.press("Escape");
    await page.waitForTimeout(100);

    // Deselect everything by clicking on empty canvas area
    await page.keyboard.press("Escape");
    await page.keyboard.press("1"); // Selection tool
    await page.mouse.click(950, 550);
    await page.waitForTimeout(500);
  } catch (error: any) {
    console.error(`    Failed to draw Excalidraw diagram: ${error.message}`);
  }
}

async function captureAuthZooConsentScreen(page: any) {
  try {
    // Start OAuth flow from miniflux
    await page.goto("http://miniflux.zoo", {
      waitUntil: "networkidle",
      timeout: 15000,
    });

    // Click "Sign in with Zoo Auth"
    await page.click('a[href*="/oauth2/oidc/redirect"]');

    // Wait for auth.zoo login page
    await page.waitForSelector('input[name="username"]', { timeout: 10000 });

    // Login as bob
    await page.fill('input[name="username"]', "bob");
    await page.fill('input[name="password"]', "bob123");
    await page.click('button:has-text("Login")');

    // Wait for consent page
    await page.waitForURL("**/consent**", { timeout: 10000 });
    await page.waitForTimeout(1000);
  } catch (error: any) {
    console.error(`    Failed to capture auth.zoo consent screen: ${error.message}`);
  }
}

async function captureScreenshot(browser: any, site: Site, outputPath: string) {
  const context = await browser.newContext({
    ignoreHTTPSErrors: true,
    httpCredentials: undefined,
    proxy: {
      server: "http://localhost:3128",
    },
  });

  const page = await context.newPage();

  try {
    const protocol = site.httpsOnly ? "https" : "http";
    const url = `${protocol}://${site.domain}`;

    console.log(`Capturing ${site.domain}...`);

    // Navigate with a reasonable timeout
    await page.goto(url, {
      waitUntil: "networkidle",
      timeout: 30000,
    });

    // Special handling for sites that need login
    if (site.domain === "snappymail.zoo") {
      console.log(`  Logging into SnappyMail...`);
      await loginToSnappyMail(page);
    } else if (site.domain === "miniflux.zoo") {
      console.log(`  Logging into Miniflux...`);
      await loginToMiniflux(page);
    } else if (site.domain === "focalboard.zoo") {
      console.log(`  Logging into Focalboard...`);
      await loginToFocalboard(page);
    } else if (site.domain === "mattermost.zoo") {
      console.log(`  Logging into Mattermost...`);
      await loginToMattermost(page);
    } else if (site.domain === "gitea.zoo") {
      console.log(`  Logging into Gitea as alice...`);
      await loginToGitea(page);
    } else if (site.domain === "auth.zoo") {
      console.log(`  Capturing OAuth consent screen...`);
      await captureAuthZooConsentScreen(page);
    } else if (site.domain === "analytics.zoo") {
      console.log(`  Logging into Analytics (Matomo)...`);
      await loginToAnalytics(page);
    } else if (site.domain === "excalidraw.zoo") {
      console.log(`  Drawing Excalidraw diagram...`);
      await drawExcalidrawDiagram(page);
    } else {
      // Wait a bit for any animations or dynamic content
      await page.waitForTimeout(2000);
    }

    // Save as JPEG
    await page.screenshot({
      path: outputPath,
      fullPage: false, // Viewport screenshot for consistency
      type: "jpeg",
      quality: 85,
    });

    console.log(`  ✓ Saved to ${path.relative(ROOT_DIR, outputPath)}`);
  } catch (error: any) {
    console.error(`  ✗ Failed to capture ${site.domain}: ${error.message}`);
  } finally {
    await context.close();
  }
}

async function main() {
  const args = process.argv.slice(2);
  const targetSite = args[0];
  const captureAll = !targetSite || targetSite === "--all";

  await ensureScreenshotsDir();

  const sites = await loadSites();

  // Filter sites to capture
  let sitesToCapture = sites.filter((site) => {
    // Skip API endpoints and admin interfaces
    if (site.domain.includes("-api.") || site.domain.includes("admin.")) {
      return false;
    }
    // Skip sites in the skip list
    if (SKIP_SITES.has(site.domain)) {
      return false;
    }
    return true;
  });

  if (!captureAll) {
    sitesToCapture = sitesToCapture.filter((s) => s.domain === targetSite);
    if (sitesToCapture.length === 0) {
      console.error(`Site '${targetSite}' not found`);
      console.log("\nAvailable sites:");
      sites.forEach((s) => console.log(`  - ${s.domain}`));
      process.exit(1);
    }
  }

  console.log(`Capturing screenshots for ${sitesToCapture.length} site(s)...\n`);

  const browser = await firefox.launch({
    headless: true,
  });

  try {
    for (const site of sitesToCapture) {
      const filename = `${site.domain.replace(/\./g, "-")}.jpeg`;
      const outputPath = path.join(SCREENSHOTS_DIR, filename);
      await captureScreenshot(browser, site, outputPath);
    }
  } finally {
    await browser.close();
  }

  console.log("\nDone! Screenshots saved to docs/screenshots/");

  // Generate markdown table for README
  if (captureAll) {
    console.log("\n--- Markdown table for README ---\n");
    console.log("| Screenshot | Site | Description |");
    console.log("|------------|------|-------------|");

    for (const site of sitesToCapture) {
      const filename = `${site.domain.replace(/\./g, "-")}.jpeg`;
      const description = site.description || site.domain;
      console.log(
        `| <img src="docs/screenshots/${filename}" width="200" alt="${site.domain}"> | [${site.domain}](https://${site.domain}) | ${description} |`,
      );
    }
  }
}

main().catch(console.error);
