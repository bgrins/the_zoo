#!/usr/bin/env tsx

import { firefox } from "playwright";
import { promises as fs } from "node:fs";
import path from "node:path";
import os from "node:os";
import { fileURLToPath } from "node:url";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import * as yaml from "yaml";

const execFileAsync = promisify(execFile);

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT_DIR = path.resolve(__dirname, "..");
const SCREENSHOTS_DIR = path.join(ROOT_DIR, "docs", "screenshots");
const SITES_YAML = path.join(ROOT_DIR, "core", "SITES.yaml");

const SKIP_SITES = new Set(["status.zoo", "secure.gravatar.com"]);

const VIDEO_WIDTH = 1280;
const VIDEO_HEIGHT = 720;

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

async function checkFfmpeg(): Promise<boolean> {
  try {
    await execFileAsync("ffmpeg", ["-version"]);
    return true;
  } catch {
    return false;
  }
}

// Re-encode WebM with VP9 at high quality (Playwright records VP8 at low bitrate)
async function reencodeWebm(inputPath: string): Promise<void> {
  const tmpOut = inputPath.replace(".webm", "-hq.webm");
  await execFileAsync(
    "ffmpeg",
    ["-y", "-i", inputPath, "-c:v", "libvpx-vp9", "-b:v", "2M", "-crf", "20", "-an", tmpOut],
    { timeout: 60000 },
  );
  await fs.rename(tmpOut, inputPath);
}

// --- Login helpers (reused for both static and live captures) ---

async function loginToSnappyMail(page: any) {
  try {
    await page.waitForSelector('input[name="Email"]', { timeout: 5000 });
    await page.fill('input[name="Email"]', "alex.chen@snappymail.zoo");
    await page.fill('input[name="Password"]', "Password.123");
    await page.click(".buttonLogin");
    await Promise.race([
      page.waitForURL("**/?/**", { timeout: 10000 }),
      page.waitForSelector(".messageList, .folderList, .mailbox", {
        timeout: 10000,
      }),
    ]).catch(() => page.waitForTimeout(3000));
  } catch (error: any) {
    console.error(`    Failed to login to SnappyMail: ${error.message}`);
  }
}

async function loginToMiniflux(page: any) {
  try {
    await page.waitForSelector('input[name="username"]', { timeout: 5000 });
    await page.fill('input[name="username"]', "alice");
    await page.fill('input[name="password"]', "alice123");
    await page.click('button[type="submit"]');
    await page.waitForURL("**/unread", { timeout: 10000 });

    await page.goto("http://miniflux.zoo/subscribe", {
      waitUntil: "networkidle",
      timeout: 15000,
    });
    await page.waitForSelector('input[name="url"]', { timeout: 5000 });
    await page.fill('input[name="url"]', "https://postmill.zoo/f/todayilearned/new.atom");
    await page.click('button:has-text("Find a feed")');

    try {
      await page.waitForURL("**/feed/*/entries", { timeout: 10000 });
    } catch {
      await page.goto("http://miniflux.zoo/feeds", {
        waitUntil: "networkidle",
        timeout: 15000,
      });
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
    await page.waitForSelector('input[id="input_loginId"]', { timeout: 5000 });
    await page.fill('input[id="input_loginId"]', "alice");
    await page.fill('input[id="input_password-input"]', "alice123");
    await page.click('button[id="saveSetting"]');

    await Promise.race([
      page.waitForURL("**/channels/**", { timeout: 15000 }),
      page.waitForSelector(".channel-header, .post-list", { timeout: 15000 }),
    ]).catch(() => page.waitForTimeout(3000));

    await page.waitForTimeout(2000);
  } catch (error: any) {
    console.error(`    Failed to login to Mattermost: ${error.message}`);
  }
}

async function loginToFocalboard(page: any) {
  try {
    await page.waitForSelector('input[placeholder="Enter username"]', {
      timeout: 5000,
    });
    await page.fill('input[placeholder="Enter username"]', "alex.lee@snappymail.zoo");
    await page.fill('input[placeholder="Enter password"]', "Password.123");
    await page.click('button:has-text("Log in")');

    await Promise.race([
      page.waitForURL("**/board/**", { timeout: 10000 }),
      page.waitForURL("**/workspace/**", { timeout: 10000 }),
      page.waitForSelector(".BoardComponent, .Workspace, .Board", {
        timeout: 10000,
      }),
    ]).catch(() => page.waitForTimeout(3000));
  } catch (error: any) {
    console.error(`    Failed to login to Focalboard: ${error.message}`);
  }
}

async function loginToGitea(page: any) {
  try {
    await page.click('a[href*="/user/login"]');
    await page.waitForSelector('input[name="user_name"]', { timeout: 5000 });
    await page.fill('input[name="user_name"]', "alice");
    await page.fill('input[name="password"]', "alice123");
    await page.click('button.ui.primary.button:has-text("Sign In")');

    await page.waitForURL("**/", { timeout: 10000 });
    await page.waitForTimeout(1000);

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
    await page.waitForSelector('input[name="form_login"]', { timeout: 5000 });
    await page.fill('input[name="form_login"]', "analytics_user");
    await page.fill('input[name="form_password"]', "analytics_pw");
    await page.click("input#login_form_submit");

    await Promise.race([
      page.waitForURL("**/index.php?module=CoreHome**", { timeout: 15000 }),
      page.waitForSelector(".widgetContainer", { timeout: 15000 }),
    ]).catch(() => page.waitForTimeout(3000));

    await page.waitForTimeout(2000);
  } catch (error: any) {
    console.error(`    Failed to login to Analytics: ${error.message}`);
  }
}

async function drawExcalidrawDiagram(page: any) {
  try {
    await page.waitForSelector('input[type="radio"]', { timeout: 10000 });
    await page.waitForTimeout(1000);

    await page.keyboard.press("4");
    await page.mouse.move(300, 250);
    await page.mouse.down();
    await page.mouse.move(420, 320);
    await page.mouse.up();
    await page.waitForTimeout(100);

    await page.keyboard.press("8");
    await page.mouse.click(335, 280);
    await page.keyboard.type("Start");
    await page.keyboard.press("Escape");
    await page.waitForTimeout(100);

    await page.keyboard.press("5");
    await page.mouse.move(420, 285);
    await page.mouse.down();
    await page.mouse.move(500, 285);
    await page.mouse.up();
    await page.waitForTimeout(100);

    await page.keyboard.press("2");
    await page.mouse.move(500, 250);
    await page.mouse.down();
    await page.mouse.move(640, 320);
    await page.mouse.up();
    await page.waitForTimeout(100);

    await page.keyboard.press("8");
    await page.mouse.click(530, 280);
    await page.keyboard.type("Process");
    await page.keyboard.press("Escape");
    await page.waitForTimeout(100);

    await page.keyboard.press("5");
    await page.mouse.move(640, 285);
    await page.mouse.down();
    await page.mouse.move(720, 285);
    await page.mouse.up();
    await page.waitForTimeout(100);

    await page.keyboard.press("3");
    await page.mouse.move(720, 220);
    await page.mouse.down();
    await page.mouse.move(870, 350);
    await page.mouse.up();
    await page.waitForTimeout(100);

    await page.keyboard.press("8");
    await page.mouse.click(770, 280);
    await page.keyboard.type("Done?");
    await page.keyboard.press("Escape");
    await page.waitForTimeout(100);

    await page.keyboard.press("5");
    await page.mouse.move(795, 350);
    await page.mouse.down();
    await page.mouse.move(795, 420);
    await page.mouse.up();
    await page.waitForTimeout(100);

    await page.keyboard.press("4");
    await page.mouse.move(730, 420);
    await page.mouse.down();
    await page.mouse.move(860, 490);
    await page.mouse.up();
    await page.waitForTimeout(100);

    await page.keyboard.press("8");
    await page.mouse.click(780, 450);
    await page.keyboard.type("End");
    await page.keyboard.press("Escape");
    await page.waitForTimeout(100);

    await page.keyboard.press("Escape");
    await page.keyboard.press("1");
    await page.mouse.click(950, 550);
    await page.waitForTimeout(500);
  } catch (error: any) {
    console.error(`    Failed to draw Excalidraw diagram: ${error.message}`);
  }
}

async function captureAuthZooConsentScreen(page: any) {
  try {
    await page.goto("http://miniflux.zoo", {
      waitUntil: "networkidle",
      timeout: 15000,
    });

    await page.click('a[href*="/oauth2/oidc/redirect"]');
    await page.waitForSelector('input[name="username"]', { timeout: 10000 });

    await page.fill('input[name="username"]', "bob");
    await page.fill('input[name="password"]', "bob123");
    await page.click('button:has-text("Login")');

    await page.waitForURL("**/consent**", { timeout: 10000 });
    await page.waitForTimeout(1000);
  } catch (error: any) {
    console.error(`    Failed to capture auth.zoo consent screen: ${error.message}`);
  }
}

// --- Setup helpers ---

function siteUrl(site: Site): string {
  const protocol = site.httpsOnly ? "https" : "http";
  return `${protocol}://${site.domain}`;
}

async function navigateToSite(page: any, site: Site): Promise<void> {
  await page.goto(siteUrl(site), {
    waitUntil: "networkidle",
    timeout: 30000,
  });
}

// Static screenshot setup: includes side effects like subscribing to feeds, drawing diagrams
async function setupForScreenshot(page: any, site: Site): Promise<void> {
  await navigateToSite(page, site);

  if (site.domain === "snappymail.zoo") {
    await loginToSnappyMail(page);
  } else if (site.domain === "miniflux.zoo") {
    await loginToMiniflux(page);
  } else if (site.domain === "focalboard.zoo") {
    await loginToFocalboard(page);
  } else if (site.domain === "mattermost.zoo") {
    await loginToMattermost(page);
  } else if (site.domain === "gitea.zoo") {
    await loginToGitea(page);
  } else if (site.domain === "auth.zoo") {
    await captureAuthZooConsentScreen(page);
  } else if (site.domain === "analytics.zoo") {
    await loginToAnalytics(page);
  } else if (site.domain === "excalidraw.zoo") {
    await drawExcalidrawDiagram(page);
  } else {
    await page.waitForTimeout(2000);
  }
}

// Lightweight login-only helpers for live captures (no side effects)

async function loginOnlyMiniflux(page: any) {
  try {
    await page.waitForSelector('input[name="username"]', { timeout: 5000 });
    await page.fill('input[name="username"]', "alice");
    await page.fill('input[name="password"]', "alice123");
    await page.click('button[type="submit"]');
    await page.waitForURL("**/unread", { timeout: 10000 });
    // Navigate to feeds to show subscribed content (no subscribing)
    await page.goto("http://miniflux.zoo/feeds", {
      waitUntil: "networkidle",
      timeout: 15000,
    });
    await page.click('a:has-text("todayilearned")').catch(() => {});
    await page.waitForSelector("article", { timeout: 5000 }).catch(() => {});
    await page.waitForTimeout(1000);
  } catch (error: any) {
    console.error(`    Failed to login to Miniflux (live): ${error.message}`);
  }
}

// --- Live interaction functions (3-5 seconds of interesting activity) ---

async function defaultLiveInteraction(page: any) {
  // Smooth scroll down and back up
  await page.evaluate(() => window.scrollTo({ top: 300, behavior: "smooth" }));
  await page.waitForTimeout(1500);
  await page.evaluate(() => window.scrollTo({ top: 0, behavior: "smooth" }));
  await page.waitForTimeout(1500);
}

async function liveSnappyMail(page: any) {
  try {
    // Open the first email to read it
    await page.waitForSelector(".messageListItem", { timeout: 5000 }).catch(() => {});
    const emails = await page.$$(".messageListItem");
    if (emails.length > 0) {
      await emails[0].click();
      await page.waitForTimeout(1500);
    }

    // Compose a new email
    const newMsg = await page.$(
      '[data-title="New message"], .buttonCompose, [title="New message"]',
    );
    if (newMsg) {
      await newMsg.click();
      await page.waitForTimeout(800);

      // Fill in recipient
      const toField = await page.$(
        '.emailaddresses input, [data-binding*="to"] input, dialog input[type="text"]',
      );
      if (toField) {
        await toField.click();
        await page.keyboard.type("blake.sullivan@snappymail.zoo");
        await page.keyboard.press("Tab");
        await page.waitForTimeout(300);
      }

      // Fill in subject
      const subjectField = await page.$(
        'dialog table input:not([type]), dialog input[placeholder=""]',
      );
      if (subjectField) {
        await subjectField.click();
        await page.keyboard.type("Sprint review notes");
        await page.waitForTimeout(300);
      }

      // Type in body — click the iframe or contenteditable area
      const bodyFrame = await page.$("dialog iframe");
      if (bodyFrame) {
        const frame = await bodyFrame.contentFrame();
        if (frame) {
          await frame.click("body");
          await frame.type(
            "body",
            "Hi Blake,\n\nHere are the notes from today's sprint review. Let me know if anything needs updating.\n\nBest,\nAlex",
          );
        }
      }
      await page.waitForTimeout(1500);
    }
  } catch {
    await defaultLiveInteraction(page);
  }
}

async function liveMiniflux(page: any) {
  try {
    // Navigate to unread and click through entries
    await page.goto("http://miniflux.zoo/unread", {
      waitUntil: "networkidle",
      timeout: 10000,
    });
    await page.waitForTimeout(500);
    const articles = await page.$$("article .item-title a");
    if (articles.length > 0) {
      await articles[0].click();
      await page.waitForTimeout(2000);
      // Go back
      await page.goBack({ waitUntil: "networkidle" });
      await page.waitForTimeout(1000);
    } else {
      await defaultLiveInteraction(page);
    }
  } catch {
    await defaultLiveInteraction(page);
  }
}

async function liveMattermost(page: any) {
  try {
    // Type a message in the current channel
    const messageInput = await page.$(
      'textarea[id="post_textbox"], #post_textbox, textarea[placeholder*="Write"]',
    );
    if (messageInput) {
      await messageInput.click();
      await page.waitForTimeout(300);
      await page.keyboard.type("Hey team, checking in on the project status!");
      await page.waitForTimeout(500);
      // Send the message
      await page.keyboard.press("Enter");
      await page.waitForTimeout(1000);
    }

    // Switch to a different channel via the sidebar
    const channels = await page.$$(".SidebarChannel a, .sidebar-item a, a[id^='sidebarItem']");
    if (channels.length > 1) {
      // Click the second channel (skip current)
      await channels[1].click();
      await page.waitForTimeout(1500);

      // Scroll through messages in the new channel
      const postList = await page.$(".post-list__content, #postListContent");
      if (postList) {
        await page.evaluate(
          (el: HTMLElement) => el.scrollTo({ top: el.scrollHeight, behavior: "smooth" }),
          postList,
        );
        await page.waitForTimeout(1000);
      }
    }
  } catch {
    await defaultLiveInteraction(page);
  }
}

async function liveGitea(page: any) {
  try {
    // Click into a source file from the repo
    const fileLinks = await page.$$(".repository-file-list a.name");
    if (fileLinks.length > 0) {
      // Find a code file to click
      for (const link of fileLinks) {
        const text = await link.textContent();
        if (text && (text.endsWith(".js") || text.endsWith(".json") || text.endsWith(".md"))) {
          await link.click();
          await page.waitForTimeout(2000);
          await page.goBack({ waitUntil: "networkidle" });
          await page.waitForTimeout(1000);
          return;
        }
      }
      // Fallback: click first file
      await fileLinks[0].click();
      await page.waitForTimeout(2000);
      await page.goBack({ waitUntil: "networkidle" });
      await page.waitForTimeout(1000);
    } else {
      await defaultLiveInteraction(page);
    }
  } catch {
    await defaultLiveInteraction(page);
  }
}

async function liveFocalboard(page: any) {
  try {
    // Click on a card to open it
    const cards = await page.$$(".KanbanCard, .TableRow, .BoardCard, .octo-board-card");
    if (cards.length > 0) {
      await cards[0].click();
      await page.waitForTimeout(1500);
      await page.keyboard.press("Escape");
      await page.waitForTimeout(500);
    }

    // Add a new card via "+ New" button in the first column
    const newButtons = await page.$$('button:has-text("+ New")');
    if (newButtons.length > 0) {
      await newButtons[0].click();
      await page.waitForTimeout(800);
      await page.keyboard.type("Set up CI/CD pipeline");
      await page.keyboard.press("Enter");
      await page.waitForTimeout(800);
    }

    // Switch to a different view (e.g. Project Priorities or Task Calendar)
    const viewLinks = await page.$$(".sidebar-view-item");
    if (viewLinks.length > 1) {
      // Click the second view (skip the currently active one)
      await viewLinks[1].click();
      await page.waitForTimeout(1500);

      // Switch to yet another view for variety
      if (viewLinks.length > 2) {
        await viewLinks[2].click();
        await page.waitForTimeout(1500);
      }
    }
  } catch {
    await defaultLiveInteraction(page);
  }
}

async function liveAnalytics(page: any) {
  try {
    // Hover over chart elements to trigger tooltips
    const charts = await page.$$("canvas, .widgetContainer .widget");
    if (charts.length > 0) {
      const box = await charts[0].boundingBox();
      if (box) {
        // Sweep mouse across the chart
        for (let x = box.x + 20; x < box.x + box.width - 20; x += 40) {
          await page.mouse.move(x, box.y + box.height / 2);
          await page.waitForTimeout(200);
        }
        await page.waitForTimeout(1000);
      }
    } else {
      await defaultLiveInteraction(page);
    }
  } catch {
    await defaultLiveInteraction(page);
  }
}

async function liveExcalidraw(page: any) {
  try {
    // Helper to animate a drag from point A to B
    const animateDrag = async (x1: number, y1: number, x2: number, y2: number, steps: number) => {
      await page.mouse.move(x1, y1);
      await page.mouse.down();
      for (let i = 1; i <= steps; i++) {
        const t = i / steps;
        await page.mouse.move(x1 + (x2 - x1) * t, y1 + (y2 - y1) * t);
        await page.waitForTimeout(30);
      }
      await page.mouse.up();
    };

    // Draw "User" rectangle
    await page.keyboard.press("2");
    await animateDrag(150, 280, 300, 360, 15);
    await page.waitForTimeout(200);

    // Label it
    await page.keyboard.press("8");
    await page.mouse.click(225, 315);
    await page.keyboard.type("User");
    await page.keyboard.press("Escape");
    await page.waitForTimeout(200);

    // Arrow: User -> API
    await page.keyboard.press("5");
    await animateDrag(300, 320, 400, 320, 12);
    await page.waitForTimeout(200);

    // Draw "API" rectangle
    await page.keyboard.press("2");
    await animateDrag(400, 280, 560, 360, 15);
    await page.waitForTimeout(200);

    // Label it
    await page.keyboard.press("8");
    await page.mouse.click(480, 315);
    await page.keyboard.type("API");
    await page.keyboard.press("Escape");
    await page.waitForTimeout(200);

    // Arrow: API -> Database
    await page.keyboard.press("5");
    await animateDrag(560, 320, 660, 320, 12);
    await page.waitForTimeout(200);

    // Draw "DB" ellipse
    await page.keyboard.press("4");
    await animateDrag(660, 280, 810, 360, 15);
    await page.waitForTimeout(200);

    // Label it
    await page.keyboard.press("8");
    await page.mouse.click(735, 315);
    await page.keyboard.type("Database");
    await page.keyboard.press("Escape");
    await page.waitForTimeout(200);

    // Arrow: API -> Cache (downward)
    await page.keyboard.press("5");
    await animateDrag(480, 360, 480, 440, 10);
    await page.waitForTimeout(200);

    // Draw "Cache" diamond
    await page.keyboard.press("3");
    await animateDrag(410, 440, 560, 530, 12);
    await page.waitForTimeout(200);

    // Label it
    await page.keyboard.press("8");
    await page.mouse.click(465, 480);
    await page.keyboard.type("Cache");
    await page.keyboard.press("Escape");
    await page.waitForTimeout(300);

    // Deselect
    await page.keyboard.press("Escape");
    await page.keyboard.press("1");
    await page.mouse.click(900, 550);
    await page.waitForTimeout(500);
  } catch {
    await defaultLiveInteraction(page);
  }
}

async function liveAuthZoo(page: any) {
  try {
    // Login with credentials
    await page.waitForSelector('input[name="username"]', { timeout: 5000 });
    await page.fill('input[name="username"]', "alice");
    await page.fill('input[name="password"]', "alice123");
    await page.click('button:has-text("Sign In")');

    // Wait for dashboard
    await page.waitForURL("**/dashboard", { timeout: 10000 });
    await page.waitForTimeout(800);

    // Navigate to Explore Apps page
    await page.click('a:has-text("Explore Apps")');
    await page.waitForURL("**/explore", { timeout: 10000 });
    await page.waitForTimeout(800);

    // Scroll through the app grid
    await page.evaluate(() => window.scrollTo({ top: 400, behavior: "smooth" }));
    await page.waitForTimeout(1500);
    await page.evaluate(() => window.scrollTo({ top: 0, behavior: "smooth" }));
    await page.waitForTimeout(1000);
  } catch {
    await defaultLiveInteraction(page);
  }
}

async function livePostmill(page: any) {
  try {
    // Browse a forum and interact
    const links = await page.$$(".submission-row__title a, .submission__link");
    if (links.length > 0) {
      await links[0].click();
      await page.waitForTimeout(2000);
      await page.evaluate(() => window.scrollTo({ top: 300, behavior: "smooth" }));
      await page.waitForTimeout(1500);
    } else {
      await defaultLiveInteraction(page);
    }
  } catch {
    await defaultLiveInteraction(page);
  }
}

async function liveWiki(page: any) {
  try {
    // Use the random page button to navigate to an article
    const randomBtn = await page.$('button:has-text("🎲")');
    if (randomBtn) {
      await randomBtn.click();
      await page.waitForTimeout(2000);
    }

    // Scroll down the article content inside the iframe
    const iframe = await page.$("iframe");
    if (iframe) {
      const frame = await iframe.contentFrame();
      if (frame) {
        await frame.evaluate(() => window.scrollTo({ top: 300, behavior: "smooth" }));
        await page.waitForTimeout(1000);

        // Click a link within the article to navigate deeper
        const articleLinks = await frame.$$("a[href]");
        for (const link of articleLinks) {
          const href = await link.getAttribute("href");
          if (href && !href.startsWith("http") && !href.startsWith("#")) {
            await link.click();
            await page.waitForTimeout(2000);
            break;
          }
        }
      }
    }
  } catch {
    await defaultLiveInteraction(page);
  }
}

async function liveClassifieds(page: any) {
  try {
    // Click into the Electronics category
    await page.click('a[href*="sCategory"]:has-text("Electronics")');
    await page.waitForTimeout(1500);

    // Click on the first listing in the results
    const listings = await page.$$(
      ".listing-card a, .item a[href*='page=item'], ul li a[href*='page=item']",
    );
    if (listings.length > 0) {
      await listings[0].click();
      await page.waitForTimeout(2000);

      // Scroll down to see listing details
      await page.evaluate(() => window.scrollTo({ top: 300, behavior: "smooth" }));
      await page.waitForTimeout(1000);
    } else {
      // Fallback: click a listing from the main page
      await page.goBack({ waitUntil: "networkidle" });
      const items = await page.$$('a[href*="page=item&id="]');
      if (items.length > 0) {
        await items[0].click();
        await page.waitForTimeout(2000);
      }
    }
  } catch {
    await defaultLiveInteraction(page);
  }
}

async function liveOnestopshop(page: any) {
  try {
    // Click a category from the nav bar
    await page.click('a:has-text("Electronics")');
    await page.waitForTimeout(1500);

    // Click into a product
    const productLinks = await page.$$("strong a[href]");
    if (productLinks.length > 0) {
      await productLinks[0].click();
      await page.waitForTimeout(1500);

      // Scroll down to see product details
      await page.evaluate(() => window.scrollTo({ top: 300, behavior: "smooth" }));
      await page.waitForTimeout(800);

      // Add to cart
      const addBtn = await page.$('button:has-text("Add to Cart"), #product-addtocart-button');
      if (addBtn) {
        await addBtn.click();
        await page.waitForTimeout(1500);
      }
    }
  } catch {
    await defaultLiveInteraction(page);
  }
}

async function livePaste(page: any) {
  try {
    // Type some code into the paste editor
    const editor = await page.$('textarea, .CodeMirror, [contenteditable="true"], .ace_editor');
    if (editor) {
      await editor.click();
      await page.waitForTimeout(300);
      const code = 'function hello() {\n  console.log("Hello, Zoo!");\n}';
      for (const char of code) {
        await page.keyboard.type(char);
        await page.waitForTimeout(50);
      }
      await page.waitForTimeout(1000);
    } else {
      await defaultLiveInteraction(page);
    }
  } catch {
    await defaultLiveInteraction(page);
  }
}

async function liveNorthwind(page: any) {
  try {
    // Navigate directly to the orders table (most interesting data)
    await page.goto(
      "http://northwind.zoo/index.php?route=/sql&db=northwind_db&table=orders&pos=0",
      { waitUntil: "networkidle", timeout: 15000 },
    );
    await page.waitForTimeout(1500);

    // Scroll through the order data
    await page.evaluate(() => window.scrollTo({ top: 300, behavior: "smooth" }));
    await page.waitForTimeout(1000);

    // Click on the products table via sidebar or direct navigation
    await page.goto(
      "http://northwind.zoo/index.php?route=/sql&db=northwind_db&table=products&pos=0",
      { waitUntil: "networkidle", timeout: 15000 },
    );
    await page.waitForTimeout(1500);

    // Scroll through products
    await page.evaluate(() => window.scrollTo({ top: 200, behavior: "smooth" }));
    await page.waitForTimeout(1000);
  } catch {
    await defaultLiveInteraction(page);
  }
}

// Per-site live capture config: setup prepares the page, interact does the recorded activity.
// If setup is omitted, the static screenshot setup (setupForScreenshot) is reused.
interface LiveConfig {
  setup?: (page: any, site: Site) => Promise<void>;
  interact: (page: any) => Promise<void>;
}

const LIVE_CONFIGS: Record<string, LiveConfig> = {
  "snappymail.zoo": {
    // Login before recording so the video starts in the mailbox
    setup: async (page, site) => {
      await navigateToSite(page, site);
      await loginToSnappyMail(page);
    },
    interact: liveSnappyMail,
  },
  "miniflux.zoo": {
    setup: async (page, site) => {
      await navigateToSite(page, site);
      await loginOnlyMiniflux(page);
    },
    interact: liveMiniflux,
  },
  "mattermost.zoo": { interact: liveMattermost },
  "gitea.zoo": { interact: liveGitea },
  "focalboard.zoo": { interact: liveFocalboard },
  "analytics.zoo": { interact: liveAnalytics },
  "excalidraw.zoo": {
    // Start from blank canvas — the drawing IS the live interaction
    setup: async (page, site) => {
      await navigateToSite(page, site);
      await page.waitForSelector('input[type="radio"]', { timeout: 10000 });
      await page.waitForTimeout(1000);
    },
    interact: liveExcalidraw,
  },
  "auth.zoo": {
    // Navigate directly to auth.zoo login — no OAuth flow side effects
    setup: async (page, site) => {
      await navigateToSite(page, site);
      await page.waitForTimeout(1000);
    },
    interact: liveAuthZoo,
  },
  "postmill.zoo": { interact: livePostmill },
  "wiki.zoo": { interact: liveWiki },
  "classifieds.zoo": { interact: liveClassifieds },
  "onestopshop.zoo": { interact: liveOnestopshop },
  "paste.zoo": { interact: livePaste },
  "northwind.zoo": { interact: liveNorthwind },
};

// --- Screenshot + live capture ---

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
    console.log(`Capturing ${site.domain}...`);
    await setupForScreenshot(page, site);

    await page.screenshot({
      path: outputPath,
      fullPage: false,
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

async function captureLive(browser: any, site: Site, hasFfmpeg: boolean): Promise<void> {
  const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), "zoo-live-"));
  const config = LIVE_CONFIGS[site.domain];

  // Phase 1: Set up the site in a non-recording context (login, navigate, etc.)
  // This keeps setup like login screens out of the final video.
  const setupContext = await browser.newContext({
    ignoreHTTPSErrors: true,
    httpCredentials: undefined,
    viewport: { width: VIDEO_WIDTH, height: VIDEO_HEIGHT },
    proxy: {
      server: "http://localhost:3128",
    },
  });
  const setupPage = await setupContext.newPage();

  let storageState: any;
  let startUrl: string;
  try {
    console.log(`  Recording live capture for ${site.domain}...`);
    if (config?.setup) {
      await config.setup(setupPage, site);
    } else {
      await setupForScreenshot(setupPage, site);
    }
    startUrl = setupPage.url();
    storageState = await setupContext.storageState();
  } finally {
    await setupContext.close();
  }

  // Phase 2: Create a recording context with the saved session state
  const context = await browser.newContext({
    ignoreHTTPSErrors: true,
    httpCredentials: undefined,
    viewport: { width: VIDEO_WIDTH, height: VIDEO_HEIGHT },
    proxy: {
      server: "http://localhost:3128",
    },
    storageState,
    recordVideo: {
      dir: tmpDir,
      size: { width: VIDEO_WIDTH, height: VIDEO_HEIGHT },
    },
  });

  const page = await context.newPage();

  try {
    // Navigate to where setup left off
    await page.goto(startUrl, { waitUntil: "networkidle", timeout: 15000 }).catch(() => {});
    await page.waitForTimeout(500);

    // Run the live interaction
    const interact = config?.interact || defaultLiveInteraction;
    await interact(page);

    // Save the video path before closing (Playwright assigns it at page creation)
    const video = page.video();
    await page.close();
    const videoPath = video ? await video.path() : null;
    await context.close();

    // Find the recorded video (either from video() API or by scanning tmpDir)
    let srcWebm = videoPath;
    if (!srcWebm) {
      const files = await fs.readdir(tmpDir);
      const webmFile = files.find((f) => f.endsWith(".webm"));
      if (webmFile) {
        srcWebm = path.join(tmpDir, webmFile);
      }
    }

    if (!srcWebm) {
      console.error(`  ✗ No video file found for ${site.domain}`);
      return;
    }

    const basename = site.domain.replace(/\./g, "-");
    const destWebm = path.join(SCREENSHOTS_DIR, `${basename}.webm`);
    await fs.copyFile(srcWebm, destWebm);

    if (hasFfmpeg) {
      // Re-encode with VP9 at higher quality
      await reencodeWebm(destWebm);
    }
    console.log(`  ✓ Live WebM saved to ${path.relative(ROOT_DIR, destWebm)}`);
  } catch (error: any) {
    console.error(`  ✗ Failed to capture live for ${site.domain}: ${error.message}`);
    await context.close().catch(() => {});
  } finally {
    // Clean up temp dir
    await fs.rm(tmpDir, { recursive: true, force: true }).catch(() => {});
  }
}

async function main() {
  const args = process.argv.slice(2);
  const liveMode = args.includes("--live");
  const filteredArgs = args.filter((a) => a !== "--live");
  const targetSite = filteredArgs[0];
  const captureAll = !targetSite || targetSite === "--all";

  await ensureScreenshotsDir();

  let hasFfmpeg = false;
  if (liveMode) {
    hasFfmpeg = await checkFfmpeg();
    if (!hasFfmpeg) {
      console.warn(
        "⚠ ffmpeg not found - WebM will be saved as-is (VP8). Install ffmpeg for VP9 re-encoding: brew install ffmpeg\n",
      );
    }
  }

  const sites = await loadSites();

  let sitesToCapture = sites.filter((site) => {
    if (site.domain.includes("-api.") || site.domain.includes("admin.")) {
      return false;
    }
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

  const modeLabel = liveMode ? "screenshots + live captures" : "screenshots";
  console.log(`Capturing ${modeLabel} for ${sitesToCapture.length} site(s)...\n`);

  const browser = await firefox.launch({
    headless: true,
  });

  try {
    for (const site of sitesToCapture) {
      const filename = `${site.domain.replace(/\./g, "-")}.jpeg`;
      const outputPath = path.join(SCREENSHOTS_DIR, filename);
      await captureScreenshot(browser, site, outputPath);

      if (liveMode) {
        await captureLive(browser, site, hasFfmpeg);
      }
    }
  } finally {
    await browser.close();
  }

  console.log("\nDone! Screenshots saved to docs/screenshots/");
}

main().catch(console.error);
