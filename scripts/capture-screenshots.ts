#!/usr/bin/env tsx

import { firefox } from "playwright";
import { promises as fs } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import * as yaml from "yaml";
import { execSync } from "node:child_process";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT_DIR = path.resolve(__dirname, "..");
const SCREENSHOTS_DIR = path.join(ROOT_DIR, "docs", "screenshots");
const SITES_YAML = path.join(ROOT_DIR, "core", "SITES.yaml");

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

async function convertToAvif(pngPath: string, avifPath: string) {
  try {
    // Use vips to convert PNG to highly optimized AVIF
    execSync(`vips copy "${pngPath}" "${avifPath}"[Q=50,effort=4]`, { stdio: "pipe" });

    // Remove the PNG after successful conversion
    await fs.unlink(pngPath);

    return true;
  } catch (error: any) {
    console.error(`  ✗ Failed to convert to AVIF: ${error.message}`);
    console.error(`    Make sure vips is installed: brew install vips`);
    return false;
  }
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

    // Wait for navigation to feed page
    await Promise.race([
      page.waitForURL("**/unread", { timeout: 10000 }),
      page.waitForURL("**/feeds", { timeout: 10000 }),
      page.waitForSelector("article, .item, .entry-item", { timeout: 10000 }),
    ]).catch(() => {
      return page.waitForTimeout(3000);
    });
  } catch (error: any) {
    console.error(`    Failed to login to Miniflux: ${error.message}`);
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
    } else {
      // Wait a bit for any animations or dynamic content
      await page.waitForTimeout(2000);
    }

    // First save as PNG
    const pngPath = outputPath.replace(".avif", ".png");
    await page.screenshot({
      path: pngPath,
      fullPage: false, // Viewport screenshot for consistency
    });

    // Convert to AVIF
    const converted = await convertToAvif(pngPath, outputPath);

    if (converted) {
      console.log(`  ✓ Saved to ${path.relative(ROOT_DIR, outputPath)}`);
    } else {
      console.log(`  ⚠ PNG saved to ${path.relative(ROOT_DIR, pngPath)} (AVIF conversion failed)`);
    }
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
    // Skip status page (it's just a list)
    if (site.domain === "status.zoo") {
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
      const filename = `${site.domain.replace(/\./g, "-")}.avif`;
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
    console.log("| Site | Description | Screenshot |");
    console.log("|------|-------------|------------|");

    for (const site of sitesToCapture) {
      const filename = `${site.domain.replace(/\./g, "-")}.avif`;
      const description = site.description || site.domain;
      console.log(
        `| [${site.domain}](https://${site.domain}) | ${description} | ![${site.domain}](docs/screenshots/${filename}) |`,
      );
    }
  }
}

main().catch(console.error);
