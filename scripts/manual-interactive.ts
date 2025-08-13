import { firefox } from "playwright";

const PROXY_HOST = "localhost";
const PROXY_PORT = process.env.ZOO_PROXY_PORT ? parseInt(process.env.ZOO_PROXY_PORT) : 3128;
const TEST_SITES = [{ url: "https://status.zoo" }];

console.log("🔍 Environment check:");
console.log(`   ZOO_PROXY_PORT from env: ${process.env.ZOO_PROXY_PORT}`);
console.log(`   Using PROXY_PORT: ${PROXY_PORT}`);

async function run() {
  // Skip in devcontainer (no headed browser support)
  if (process.env.DEVCONTAINER === "true") {
    console.log("ℹ️  Skipping browser launch in devcontainer (no headed browser)");
    return;
  }

  console.log("🦁 Opening Zoo sites for manual interaction...\n");

  // For some reason Firefox isn't working with ignoreHTTPSErrors, so use chromium instead
  const browser = await firefox.launch({
    headless: false,

    proxy: {
      server: `http://${PROXY_HOST}:${PROXY_PORT}`,
    },

    // Set Firefox preferences to recognize .zoo as a valid TLD
    firefoxUserPrefs: {
      // Allow .zoo domains
      "browser.fixup.domainsuffixwhitelist.zoo": true,
      // "browser.search.update": true,
      // "keyword.URL": "http://search.zoo?q=%s",
      // "browser.search.defaultenginename": "Custom Search",
    },
  });

  const context = await browser.newContext({
    ignoreHTTPSErrors: true,
    viewport: { width: 1280, height: 720 },
  });

  // Open all sites in separate tabs
  for (const site of TEST_SITES) {
    console.log(`📄 Opening ${site.url}...`);
    const page = await context.newPage();
    try {
      await page.goto(site.url, { timeout: 10000 });
      console.log(`✅ Successfully opened ${site.url}`);
    } catch (e) {
      console.error(`❌ Failed to open ${site.url}:`, (e as Error).message);
    }
  }

  console.log("\n✨ All sites opened! Browser will remain open for manual interaction.");
  console.log("Press Ctrl+C to close the browser and exit.\n");

  // Handle graceful shutdown
  process.on("SIGINT", async () => {
    console.log("\n🔄 Closing browser...");
    await browser.close();
    console.log("✅ Browser closed. Goodbye!");
    process.exit(0);
  });

  // Keep the browser open indefinitely for manual interaction
  await new Promise(() => {}); // This will run forever until interrupted
}

run().catch(console.error);
