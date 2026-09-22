export const ON_DEMAND_TIMEOUT = 12500; // 12.5 seconds for on-demand container startup
// Fetches in on-demand tests give up before the test does, so a slow start reports its URL
export const ON_DEMAND_FETCH_TIMEOUT = ON_DEMAND_TIMEOUT - 1000;
export const EXTENDED_TEST_TIMEOUT = 30000; // 30 seconds for extended operations
// Hook timeout for warming an on-demand app; heavy ones (Magento, Postmill, Mattermost) can take
// over ON_DEMAND_TIMEOUT to start cold, and every app slows down when many start at once
export const COLD_START_TIMEOUT = 60000;
export const EXTRA_EXTENDED_TEST_TIMEOUT = 60000; // 60 seconds for very long operations

// Playwright test configuration
export const PLAYWRIGHT_CONFIG = {
  headless: process.env.TEST_HEADLESS !== "false",
};

// Playwright timeouts
export const PLAYWRIGHT_NAVIGATION_TIMEOUT = 10000; // 10 seconds for page navigation
export const PLAYWRIGHT_SELECTOR_TIMEOUT = 5000; // 5 seconds for element selection
export const PLAYWRIGHT_SCREENSHOT_BATCH_SIZE = 3; // Process screenshots in batches of 3
