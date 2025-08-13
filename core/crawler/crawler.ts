import * as cheerio from "cheerio";
import { MeiliSearch } from "meilisearch";
import { createClient, type RedisClientType } from "redis";
import { RedisQueue } from "./redis-queue.js";
import { loadConfig } from "./config.js";
import os from "node:os";
import type { CrawlerConfig, CrawledDocument, FetchResult } from "./types.js";

export class SimpleCrawler {
  private readonly config: CrawlerConfig;
  private readonly meili: MeiliSearch;
  private readonly redis: RedisClientType;
  private readonly queue: RedisQueue;
  private readonly indexName = "zoo-pages";
  private readonly workerId: string;
  private readonly namespace: string;
  private readonly dryRun: boolean;

  private isRunning = false;
  private shouldStop = false;
  private urlsProcessed = 0;
  private documentBatch: CrawledDocument[] = [];
  private lastBatchTime = Date.now();

  constructor(options?: {
    namespace?: string;
    dryRun?: boolean;
    maxRequestsPerCrawl?: number;
  }) {
    this.config = loadConfig();

    // Override config with test options
    if (options?.maxRequestsPerCrawl) {
      this.config.maxRequestsPerCrawl = options.maxRequestsPerCrawl;
    }

    this.namespace = options?.namespace || "crawler";
    this.dryRun = options?.dryRun || false;
    this.workerId = `worker_${os.hostname()}_${process.pid}`;

    this.meili = new MeiliSearch({
      host: this.config.meilisearchHost,
      apiKey: this.config.meilisearchApiKey,
    });

    this.redis = createClient({ url: this.config.redisUrl });
    this.queue = new RedisQueue(this.redis, this.namespace);
  }

  async init(): Promise<void> {
    console.log(
      `Initializing simple crawler (${this.workerId})${this.dryRun ? " [DRY-RUN MODE]" : ""}...`,
    );
    await this.redis.connect();
    if (!this.dryRun) {
      await this.ensureIndex();
    }

    // Register this worker
    await this.queue.registerWorker(this.workerId, {
      hostname: os.hostname(),
      pid: process.pid.toString(),
    });

    console.log(`Connected to Redis${this.dryRun ? "" : " and Meilisearch"}`);
  }

  private async ensureIndex(): Promise<void> {
    try {
      await this.meili.getIndex(this.indexName);
    } catch {
      console.log(`Creating index: ${this.indexName}`);
      await this.meili.createIndex(this.indexName, { primaryKey: "id" });

      const index = this.meili.index(this.indexName);
      await index.updateSettings({
        searchableAttributes: ["title", "content", "url"],
        displayedAttributes: ["id", "url", "title", "content", "domain", "timestamp"],
        filterableAttributes: ["domain"],
        sortableAttributes: ["timestamp"],
      });
    }
  }

  async start(ignoreCache = false): Promise<void> {
    if (this.isRunning) {
      console.log("Crawler is already running");
      return;
    }

    console.log(`Starting crawler${ignoreCache ? " (ignoring cache)" : ""}...`);

    // Recover any stale URLs from previous runs
    const recovered = await this.queue.recoverStaleUrls();
    if (recovered.length > 0) {
      console.log(`Recovered ${recovered.length} stale URLs from previous run`);
    }

    // Check if we need to seed the queue
    const queueSizes = await this.queue.getQueueSizes();
    if (queueSizes.pending === 0 && queueSizes.active === 0) {
      console.log(`Seeding queue with: ${this.config.seedUrl}`);
      await this.queue.pushUrls([this.config.seedUrl]);
    }

    this.isRunning = true;
    this.shouldStop = false;

    await this.crawlLoop(ignoreCache);
  }

  async stop(): Promise<void> {
    console.log("Stopping crawler...");
    this.shouldStop = true;
  }

  private async crawlLoop(ignoreCache: boolean): Promise<void> {
    console.log(`[${this.workerId}] Starting crawl loop`);

    let consecutiveEmptyChecks = 0;
    const maxEmptyChecks = 12; // 2 minutes of empty checks (10s intervals)
    const workers = new Set<Promise<void>>();
    let lastHeartbeat = Date.now();

    while (!this.shouldStop && this.urlsProcessed < this.config.maxRequestsPerCrawl) {
      // Update heartbeat every 30 seconds
      if (Date.now() - lastHeartbeat > 30000) {
        await this.queue.updateWorkerStats(this.workerId, {
          heartbeat: Date.now().toString(),
          urls_processed: this.urlsProcessed.toString(),
          status: "active",
        });
        lastHeartbeat = Date.now();
      }

      const queueSizes = await this.queue.getQueueSizes();

      // If no work available, wait and check again
      if (queueSizes.pending === 0 && queueSizes.active === 0) {
        consecutiveEmptyChecks++;
        console.log(`No work available (check ${consecutiveEmptyChecks}/${maxEmptyChecks})`);

        if (consecutiveEmptyChecks >= maxEmptyChecks) {
          console.log("No new work found after waiting. Crawler finished.");
          break;
        }

        await new Promise((resolve) => setTimeout(resolve, 10000)); // Wait 10 seconds
        continue;
      }

      // Reset empty check counter when we find work
      consecutiveEmptyChecks = 0;

      // Process URLs with concurrency
      while (workers.size < this.config.maxConcurrency && !this.shouldStop) {
        const url = await this.queue.claimUrl(this.workerId, 5);

        if (url) {
          const worker = this.processUrl(url, ignoreCache).then(() => {
            workers.delete(worker);
          });
          workers.add(worker);
        } else {
          break; // No more URLs available right now
        }
      }

      // Wait for at least one worker to finish before continuing
      if (workers.size > 0) {
        await Promise.race(workers);
      }
    }

    // Wait for all remaining workers to finish
    console.log("Waiting for remaining workers to finish...");
    await Promise.allSettled(Array.from(workers));

    // Flush any remaining documents
    await this.flushDocumentBatch();

    console.log(`Crawling completed. Processed ${this.urlsProcessed} URLs.`);
    this.isRunning = false;
  }

  private async processUrl(url: string, ignoreCache: boolean): Promise<void> {
    try {
      console.log(`[${this.workerId}] Processing: ${url}`);

      // Check if already crawled (unless ignoring cache)
      if (!ignoreCache && (await this.queue.isUrlCompleted(url))) {
        console.log(`[${this.workerId}] Skipping cached URL: ${url}`);
        await this.queue.completeUrl(this.workerId, url);
        return;
      }

      // Fetch the URL
      const result = await this.fetchUrl(url);
      if (!result.ok) {
        throw new Error(`HTTP ${result.status}: ${result.body}`);
      }

      // Parse and extract content
      const $ = cheerio.load(result.body);
      const title = $("title").text().trim() || new URL(url).pathname;
      const content = this.extractContent($);

      if (content.length < 50) {
        throw new Error("Content too short, likely not a content page");
      }

      // Create document for indexing
      const doc: CrawledDocument = {
        id: Buffer.from(url).toString("base64"),
        url,
        domain: new URL(url).hostname,
        title,
        content,
        timestamp: Date.now(),
        score: 1,
        contentType: result.headers["content-type"] || "text/html",
        workerId: this.workerId,
      };

      // Add to batch for indexing
      this.documentBatch.push(doc);

      // Extract and queue new URLs
      const newUrls = this.extractUrls($, url);
      if (newUrls.length > 0) {
        await this.queue.pushUrls(newUrls);
        console.log(`[${this.workerId}] Found ${newUrls.length} new URLs`);
      }

      // Complete the URL
      await this.queue.completeUrl(this.workerId, url);
      this.urlsProcessed++;

      // Flush batch if it's getting large or enough time has passed
      const batchAge = Date.now() - this.lastBatchTime;
      if (this.documentBatch.length >= this.config.batchSize || batchAge > 30000) {
        await this.flushDocumentBatch();
      }
    } catch (error) {
      console.error(`[${this.workerId}] Failed to process ${url}:`, error);
      await this.queue.failUrl(this.workerId, url, error as Error);
    }
  }

  private async fetchUrl(url: string): Promise<FetchResult> {
    const startTime = Date.now();

    try {
      const response = await fetch(url, {
        headers: {
          "User-Agent": "Zoo-Crawler/1.0 (+http://search.zoo)",
        },
        redirect: "follow",
      });

      const body = await response.text();
      const responseTime = Date.now() - startTime;

      return {
        ok: response.ok,
        status: response.status,
        headers: Object.fromEntries(response.headers.entries()),
        body,
        responseTime,
      };
    } catch (error) {
      throw new Error(`Fetch failed: ${error instanceof Error ? error.message : "unknown error"}`);
    }
  }

  private extractContent($: cheerio.CheerioAPI): string {
    // Remove script and style elements
    $("script, style, nav, header, footer").remove();

    // Try to find main content
    const contentSelectors = ["main", "article", ".content", "#content", ".main-content", "body"];

    for (const selector of contentSelectors) {
      const element = $(selector);
      if (element.length > 0) {
        return element.text().replace(/\s+/g, " ").trim();
      }
    }

    return $("body").text().replace(/\s+/g, " ").trim();
  }

  private extractUrls($: cheerio.CheerioAPI, baseUrl: string): string[] {
    const urls: string[] = [];
    const base = new URL(baseUrl);

    $("a[href]").each((_, element) => {
      const href = $(element).attr("href");
      if (!href) return;

      try {
        const url = new URL(href, baseUrl);

        // Only crawl HTTP/HTTPS URLs from the same domain
        if (url.protocol !== "http:" && url.protocol !== "https:") return;
        if (url.hostname !== base.hostname) return;

        // Skip common non-content URLs
        if (url.pathname.match(/\.(css|js|json|xml|ico|png|jpg|jpeg|gif|svg|pdf)$/i)) return;
        if (url.pathname.includes("/api/") || url.pathname.includes("/_/")) return;

        // Remove fragment for indexing purposes
        url.hash = "";

        urls.push(url.toString());
      } catch {
        // Skip invalid URLs
      }
    });

    return [...new Set(urls)]; // Remove duplicates
  }

  private async flushDocumentBatch(): Promise<void> {
    if (this.documentBatch.length === 0) return;

    console.log(
      `[${this.workerId}] ${this.dryRun ? "[DRY-RUN] Would index" : "Indexing"} batch of ${this.documentBatch.length} documents`,
    );

    if (!this.dryRun) {
      try {
        const index = this.meili.index(this.indexName);
        await index.addDocuments(this.documentBatch);
      } catch (error) {
        console.error(`[${this.workerId}] Failed to index documents:`, error);
      }
    }

    this.documentBatch = [];
    this.lastBatchTime = Date.now();
  }

  async getStatus(): Promise<{
    isRunning: boolean;
    urlsProcessed: number;
    queueSizes: { pending: number; active: number; failed: number };
  }> {
    const queueSizes = await this.queue.getQueueSizes();

    return {
      isRunning: this.isRunning,
      urlsProcessed: this.urlsProcessed,
      queueSizes,
    };
  }

  async shutdown(): Promise<void> {
    console.log(`[${this.workerId}] Shutting down...`);

    this.shouldStop = true;
    await this.flushDocumentBatch();

    // Deregister worker
    await this.queue.deregisterWorker(this.workerId);

    await this.redis.disconnect();
  }
}
