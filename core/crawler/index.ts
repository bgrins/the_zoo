#!/usr/bin/env tsx

import { SimpleCrawler } from "./crawler.js";

const crawler = new SimpleCrawler();

// Graceful shutdown handling
process.on("SIGTERM", async () => {
  console.log("Received SIGTERM, shutting down gracefully...");
  await crawler.shutdown();
  process.exit(0);
});

process.on("SIGINT", async () => {
  console.log("Received SIGINT, shutting down gracefully...");
  await crawler.shutdown();
  process.exit(0);
});

async function main() {
  try {
    await crawler.init();

    // Check command line arguments
    const args = process.argv.slice(2);
    const ignoreCache = args.includes("--ignore-cache");

    console.log("Simple crawler starting...");
    await crawler.start(ignoreCache);
  } catch (error) {
    console.error("Crawler error:", error);
    process.exit(1);
  }
}

main();
