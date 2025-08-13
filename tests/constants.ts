export const ON_DEMAND_TIMEOUT = 10000; // 10 seconds for on-demand container startup
export const EXTENDED_TEST_TIMEOUT = 30000; // 30 seconds for extended operations
export const EXTRA_EXTENDED_TEST_TIMEOUT = 60000; // 60 seconds for very long operations
export const PROXY_URL = `http://localhost:${process.env.ZOO_PROXY_PORT || "3128"}`;

// Playwright test configuration
export const PROXY_HOST = "localhost";
export const PROXY_PORT = parseInt(process.env.ZOO_PROXY_PORT || "3128");
export const PLAYWRIGHT_CONFIG = {
  headless: process.env.TEST_HEADLESS !== "false",
  takeScreenshots: process.env.TEST_TAKE_SCREENSHOTS !== "false",
};

// Playwright timeouts
export const PLAYWRIGHT_NAVIGATION_TIMEOUT = 10000; // 10 seconds for page navigation
export const PLAYWRIGHT_SELECTOR_TIMEOUT = 5000; // 5 seconds for element selection
export const PLAYWRIGHT_SCREENSHOT_BATCH_SIZE = 3; // Process screenshots in batches of 3
