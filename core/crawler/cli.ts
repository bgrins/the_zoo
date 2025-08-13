#!/usr/bin/env tsx

import { createClient, type RedisClientType } from "redis";
import { RedisQueue } from "./redis-queue.js";
import { loadConfig } from "./config.js";
import { spawn } from "node:child_process";
import { promises as fs } from "node:fs";
import path from "node:path";

class SimpleCrawlerCLI {
  private redis: RedisClientType;
  private redisQueue: RedisQueue | null = null;
  private readonly config = loadConfig();
  private readonly pidFile = path.join(process.cwd(), "crawler.pid");

  constructor() {
    this.redis = createClient({ url: this.config.redisUrl });
  }

  async connect(): Promise<void> {
    await this.redis.connect();
    this.redisQueue = new RedisQueue(this.redis, "crawler");
  }

  async disconnect(): Promise<void> {
    await this.redis.disconnect();
  }

  async addUrl(url: string): Promise<void> {
    if (!this.redisQueue) {
      throw new Error("Redis queue not initialized");
    }

    await this.redisQueue.pushUrls([url]);
    console.log(`Added URL to queue: ${url}`);
  }

  async showQueue(): Promise<void> {
    if (!this.redisQueue) {
      throw new Error("Redis queue not initialized");
    }

    const sizes = await this.redisQueue.getQueueSizes();

    console.log("\nQueue Status:");
    console.log("=====================================");
    console.log(`Pending: ${sizes.pending}`);
    console.log(`Active: ${sizes.active}`);
    console.log(`Failed: ${sizes.failed}`);

    if (sizes.failed > 0) {
      console.log("\nRecent Errors:");
      // Show a few recent errors
      const errors = await this.redis.lRange("crawler:queue:failed", 0, 4);
      for (const error of errors) {
        try {
          const failedData = JSON.parse(error);
          console.log(`  - ${failedData.url}`);
          console.log(`    Error: ${failedData.error}`);
          console.log(`    Worker: ${failedData.workerId}`);
        } catch {
          console.log(`  - ${error}`);
        }
      }
    }
  }

  async showWorkers(): Promise<void> {
    if (!this.redisQueue) {
      throw new Error("Redis queue not initialized");
    }

    const workers = await this.redisQueue.getActiveWorkers();

    if (workers.length === 0) {
      console.log("No active workers");
      return;
    }

    console.log("\nActive Workers:");
    console.log("=====================================");
    for (const worker of workers) {
      console.log(`  ${worker.id}${worker.hostname ? ` (${worker.hostname})` : ""}`);
      if (worker.status) console.log(`    Status: ${worker.status}`);
      if (worker.urls_processed) console.log(`    URLs processed: ${worker.urls_processed}`);
      if (worker.heartbeat) {
        const lastSeen = Date.now() - parseInt(worker.heartbeat);
        console.log(`    Last seen: ${Math.round(lastSeen / 1000)}s ago`);
      }
    }
  }

  async recover(): Promise<void> {
    if (!this.redisQueue) {
      throw new Error("Redis queue not initialized");
    }

    const recovered = await this.redisQueue.recoverStaleUrls();

    if (recovered.length === 0) {
      console.log("No stale URLs found");
    } else {
      console.log(`Recovered ${recovered.length} stale URLs:`);
      for (const url of recovered) {
        console.log(`  - ${url}`);
      }
    }
  }

  async cleanup(): Promise<void> {
    if (!this.redisQueue) {
      throw new Error("Redis queue not initialized");
    }

    const cleaned = await this.redisQueue.cleanupDeadWorkers();

    if (cleaned.length === 0) {
      console.log("No dead workers found");
    } else {
      console.log(`Cleaned up ${cleaned.length} dead workers:`);
      for (const workerId of cleaned) {
        console.log(`  - ${workerId}`);
      }
    }
  }

  async reset(): Promise<void> {
    if (!this.redisQueue) {
      throw new Error("Redis queue not initialized");
    }

    // Clear all crawler-related data
    const namespace = "crawler";

    // Get all crawler keys
    const allCrawlerKeys = await this.redis.keys(`${namespace}*`);

    if (allCrawlerKeys.length > 0) {
      await this.redis.del(allCrawlerKeys);
    }

    console.log("Crawler queue reset");
  }

  async start(): Promise<void> {
    // Check if already running
    if (await this.isRunning()) {
      console.log("Crawler is already running");
      return;
    }

    console.log("Starting crawler...");

    const child = spawn("tsx", ["index.ts"], {
      detached: true,
      stdio: "ignore",
      cwd: process.cwd(),
    });

    child.unref();

    // Save PID
    if (child.pid) {
      await fs.writeFile(this.pidFile, child.pid.toString());
    }
    console.log(`Crawler started with PID ${child.pid}`);
  }

  async stop(): Promise<void> {
    if (!(await this.isRunning())) {
      console.log("Crawler is not running");
      return;
    }

    try {
      const pidStr = await fs.readFile(this.pidFile, "utf8");
      const pid = parseInt(pidStr.trim());

      process.kill(pid, "SIGTERM");

      // Wait a bit for graceful shutdown
      await new Promise((resolve) => setTimeout(resolve, 2000));

      // Check if still running and force kill if needed
      try {
        process.kill(pid, 0); // Check if process exists
        console.log("Forcing crawler shutdown...");
        process.kill(pid, "SIGKILL");
      } catch {
        // Process already dead, that's fine
      }

      await fs.unlink(this.pidFile).catch(() => {}); // Ignore errors
      console.log("Crawler stopped");
    } catch (error) {
      console.error("Error stopping crawler:", error);
      // Clean up PID file anyway
      await fs.unlink(this.pidFile).catch(() => {});
    }
  }

  async status(): Promise<void> {
    const running = await this.isRunning();
    console.log(`Crawler status: ${running ? "running" : "stopped"}`);

    if (running) {
      try {
        const pidStr = await fs.readFile(this.pidFile, "utf8");
        console.log(`PID: ${pidStr.trim()}`);
      } catch {
        console.log("PID file not found (may be running externally)");
      }
    }
  }

  private async isRunning(): Promise<boolean> {
    try {
      const pidStr = await fs.readFile(this.pidFile, "utf8");
      const pid = parseInt(pidStr.trim());

      // Check if process exists
      process.kill(pid, 0);
      return true;
    } catch {
      // Either file doesn't exist or process doesn't exist
      await fs.unlink(this.pidFile).catch(() => {}); // Clean up stale PID file
      return false;
    }
  }
}

interface ParsedArgs {
  command: string;
  url: string | null;
}

function parseArgs(): ParsedArgs {
  const args = process.argv.slice(2);
  const command = args[0] ?? "";

  let url: string | null = null;
  const urlIndex = args.indexOf("--url");
  if (urlIndex !== -1 && args[urlIndex + 1]) {
    url = args[urlIndex + 1];
  }

  return { command, url };
}

function printUsage(): void {
  console.log("Usage: crawler <command> [options]");
  console.log("\nCommands:");
  console.log("  start                   - Start the crawler");
  console.log("  stop                    - Stop the crawler");
  console.log("  status                  - Check crawler status");
  console.log("  add --url <url>         - Add URL to crawl queue");
  console.log("  queue                   - Show queue status");
  console.log("  workers                 - List active workers");
  console.log("  recover                 - Recover stale URLs");
  console.log("  cleanup                 - Clean up dead workers");
  console.log("  reset                   - Reset all crawler data");
}

async function main(): Promise<void> {
  const { command, url } = parseArgs();
  const cli = new SimpleCrawlerCLI();

  // Only connect for commands that need Redis
  const needsRedis = ["add", "queue", "workers", "recover", "cleanup", "reset"];

  try {
    if (needsRedis.includes(command)) {
      await cli.connect();
    }

    switch (command) {
      case "start":
        await cli.start();
        break;
      case "stop":
        await cli.stop();
        break;
      case "status":
        await cli.status();
        break;
      case "add":
        if (!url) {
          console.error("Error: --url <url> is required for add command");
          process.exit(1);
        }
        await cli.addUrl(url);
        break;
      case "queue":
        await cli.showQueue();
        break;
      case "workers":
        await cli.showWorkers();
        break;
      case "recover":
        await cli.recover();
        break;
      case "cleanup":
        await cli.cleanup();
        break;
      case "reset":
        await cli.reset();
        break;
      default:
        printUsage();
        process.exit(1);
    }
  } catch (error) {
    console.error("Error:", error instanceof Error ? error.message : String(error));
    process.exit(1);
  } finally {
    if (needsRedis.includes(command)) {
      await cli.disconnect();
    }
  }
}

main();
