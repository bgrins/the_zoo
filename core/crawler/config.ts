import type { CrawlerConfig } from "./types.js";

function getEnvString(key: string, defaultValue: string): string {
  return process.env[key] ?? defaultValue;
}

function getEnvNumber(key: string, defaultValue: number): number {
  const value = process.env[key];
  if (value === undefined) return defaultValue;
  const parsed = parseInt(value, 10);
  return Number.isNaN(parsed) ? defaultValue : parsed;
}

function getEnvBoolean(key: string, defaultValue: boolean): boolean {
  const value = process.env[key];
  if (value === undefined) return defaultValue;
  return value.toLowerCase() === "true";
}

export function loadConfig(): CrawlerConfig {
  return {
    meilisearchHost: getEnvString("MEILI_HOST", "http://meilisearch:7700"),
    meilisearchApiKey: getEnvString("MEILI_MASTER_KEY", "zooMasterKey123456789"),
    redisUrl: getEnvString("REDIS_URL", "redis://redis:6379"),
    maxConcurrency: getEnvNumber("MAX_CONCURRENCY", 5),
    maxRequestsPerCrawl: getEnvNumber("MAX_REQUESTS_PER_CRAWL", 1000),
    maxDocsPerDomain: getEnvNumber("MAX_DOCS_PER_DOMAIN", 5),
    ignoreCrawlCache: getEnvBoolean("IGNORE_CRAWL_CACHE", false),
    seedUrl: getEnvString("SEED_URL", "http://utils.zoo"),
    batchSize: getEnvNumber("BATCH_SIZE", 100),
    staleTimeout: getEnvNumber("STALE_TIMEOUT", 300000), // 5 minutes
    heartbeatInterval: getEnvNumber("HEARTBEAT_INTERVAL", 10000), // 10 seconds
    commandCheckInterval: getEnvNumber("COMMAND_CHECK_INTERVAL", 1000), // 1 second
    deadWorkerCleanupInterval: getEnvNumber("DEAD_WORKER_CLEANUP_INTERVAL", 30000), // 30 seconds
  };
}
