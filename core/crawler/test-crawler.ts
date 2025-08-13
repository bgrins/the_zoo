#!/usr/bin/env tsx

import { SimpleCrawler } from "./crawler.js";
import { createClient, type RedisClientType } from "redis";
import { RedisQueue } from "./redis-queue.js";
import { loadConfig } from "./config.js";

const TEST_NAMESPACE = "test-crawler";
const TEST_SEED_URL = "http://utils.zoo";

class TestCrawler {
  private crawler: SimpleCrawler | null = null;
  private redis: RedisClientType;
  private queue: RedisQueue;
  private config = loadConfig();

  constructor() {
    this.redis = createClient({ url: this.config.redisUrl });
    this.queue = new RedisQueue(this.redis, TEST_NAMESPACE);
  }

  async setup(): Promise<void> {
    console.log("Setting up test environment...");
    await this.redis.connect();

    // Clear any existing test data
    await this.cleanupTestData();

    // Create crawler with test namespace and dry-run mode
    this.crawler = new SimpleCrawler({
      namespace: TEST_NAMESPACE,
      dryRun: true, // Don't write to Meilisearch
      maxRequestsPerCrawl: 10, // Limit for testing
    });

    await this.crawler.init();
    console.log("Test environment ready");
  }

  async cleanupTestData(): Promise<void> {
    const keys = await this.redis.keys(`${TEST_NAMESPACE}:*`);
    if (keys.length > 0) {
      await this.redis.del(keys);
    }
  }

  async runTests(): Promise<void> {
    console.log("\n=== Running Crawler Tests ===\n");

    // Test 1: Queue operations
    console.log("Test 1: Queue operations");
    await this.queue.pushUrls([TEST_SEED_URL, "http://utils.zoo/whoami"]);
    const sizes = await this.queue.getQueueSizes();
    console.log(`✓ Added URLs to queue - Pending: ${sizes.pending}`);

    // Test 2: URL claiming
    console.log("\nTest 2: URL claiming");
    const claimedUrl = await this.queue.claimUrl("test-worker", 1);
    console.log(`✓ Claimed URL: ${claimedUrl}`);

    // Test 3: URL completion
    console.log("\nTest 3: URL completion");
    if (claimedUrl) {
      await this.queue.completeUrl("test-worker", claimedUrl);
      const isCompleted = await this.queue.isUrlCompleted(claimedUrl);
      console.log(`✓ URL marked as completed: ${isCompleted}`);
    }

    // Test 4: Failed URL handling
    console.log("\nTest 4: Failed URL handling");
    const failUrl = "http://test.invalid";
    await this.queue.failUrl("test-worker", failUrl, new Error("Test error"));
    const failedSizes = await this.queue.getQueueSizes();
    console.log(`✓ Failed URL recorded - Failed count: ${failedSizes.failed}`);

    // Test 5: Stale URL recovery
    console.log("\nTest 5: Stale URL recovery");
    // Claim a URL but don't complete it
    const staleUrl = await this.queue.claimUrl("test-worker", 1);
    if (staleUrl) {
      // Simulate stale by setting old timestamp
      await this.redis.zAdd(`${TEST_NAMESPACE}:queue:activeSet`, {
        score: Date.now() - 3600000, // 1 hour ago
        value: `test-worker:${staleUrl}`,
      });

      const recovered = await this.queue.recoverStaleUrls();
      console.log(`✓ Recovered ${recovered.length} stale URLs`);
    }

    // Test 6: Crawler start/stop
    console.log("\nTest 6: Crawler start/stop");
    if (this.crawler) {
      // Start crawler in background
      const crawlerPromise = this.crawler.start(true);

      // Wait a moment
      await new Promise((resolve) => setTimeout(resolve, 2000));

      // Get status
      const status = await this.crawler.getStatus();
      console.log(
        `✓ Crawler status - Running: ${status.isRunning}, Processed: ${status.urlsProcessed}`,
      );

      // Stop crawler
      await this.crawler.stop();
      await crawlerPromise;

      const finalStatus = await this.crawler.getStatus();
      console.log(`✓ Crawler stopped - Running: ${finalStatus.isRunning}`);
    }

    console.log("\n=== All tests completed ===");
  }

  async cleanup(): Promise<void> {
    console.log("\nCleaning up test environment...");
    await this.cleanupTestData();
    if (this.crawler) {
      await this.crawler.shutdown();
    }
    await this.redis.disconnect();
    console.log("Cleanup complete");
  }
}

// Run tests
async function main() {
  // Check if running inside container (by checking for Docker environment)
  if (!process.env.HOSTNAME || !process.env.REDIS_URL) {
    console.error("ERROR: Tests must be run inside the crawler container!");
    console.error("Make sure to run: docker compose exec zoo-crawler npm test");
    process.exit(1);
  }

  const tester = new TestCrawler();

  try {
    await tester.setup();
    await tester.runTests();
  } catch (error) {
    console.error("Test failed:", error);
    process.exit(1);
  } finally {
    await tester.cleanup();
  }
}

main();
