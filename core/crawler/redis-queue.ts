import type { RedisClientType } from "redis";
import type {
  Worker,
  WorkerMetadata,
  QueueSizes,
  FailedUrl,
  CrawlerState,
  CrawlerProgress,
} from "./types.js";

interface QueueKeys {
  pending: string;
  active: string;
  activeSet: string;
  failed: string;
  completed: string;
  domains: string;
  workers: string;
  state: string;
  progress: string;
  recent: string;
  errors: string;
}

export class RedisQueue {
  private readonly redis: RedisClientType;
  private readonly prefix: string;
  private readonly keys: QueueKeys;

  constructor(redis: RedisClientType, prefix = "crawler:queue") {
    this.redis = redis;
    this.prefix = prefix;

    this.keys = {
      pending: `${prefix}:pending`,
      active: `${prefix}:active`,
      activeSet: `${prefix}:active:set`,
      failed: `${prefix}:failed`,
      completed: `${prefix}:completed`,
      domains: `${prefix}:domains`,
      workers: `${prefix}:workers`,
      state: `${prefix}:state`,
      progress: `${prefix}:progress`,
      recent: `${prefix}:recent`,
      errors: `${prefix}:errors`,
    };
  }

  async pushUrl(url: string): Promise<number> {
    return await this.redis.lPush(this.keys.pending, url);
  }

  async pushUrls(urls: string[]): Promise<number> {
    if (urls.length === 0) return 0;
    return await this.redis.lPush(this.keys.pending, urls);
  }

  async claimUrl(workerId: string, timeout = 1): Promise<string | null> {
    const result = await this.redis.blPop(this.keys.pending, timeout);

    if (result) {
      const url = result.element;

      await this.redis.zAdd(this.keys.activeSet, {
        score: Date.now(),
        value: `${workerId}:${url}`,
      });

      return url;
    }

    return null;
  }

  async completeUrl(workerId: string, url: string): Promise<void> {
    await this.redis.zRem(this.keys.activeSet, `${workerId}:${url}`);

    const key = `${this.keys.completed}:${url}`;
    await this.redis.set(key, "1", { EX: 86400 });

    await this.redis.hIncrBy(this.keys.state, "urls_crawled", 1);

    // Track recent URLs
    await this.addRecentUrl(url);
  }

  async isUrlCompleted(url: string): Promise<boolean> {
    const key = `${this.keys.completed}:${url}`;
    const exists = await this.redis.exists(key);
    return exists === 1;
  }

  async failUrl(workerId: string, url: string, error: Error): Promise<void> {
    await this.redis.zRem(this.keys.activeSet, `${workerId}:${url}`);

    const failedData: FailedUrl = {
      url,
      error: error.message,
      timestamp: Date.now(),
      workerId,
    };

    const failedDataStr = JSON.stringify(failedData);
    await this.redis.lPush(this.keys.failed, failedDataStr);
    await this.redis.hIncrBy(this.keys.state, "errors", 1);
    await this.redis.lPush(this.keys.errors, failedDataStr);
    await this.redis.lTrim(this.keys.errors, 0, 49);
  }

  async isUrlCrawled(url: string): Promise<boolean> {
    const key = `${this.keys.completed}:${url}`;
    return (await this.redis.exists(key)) === 1;
  }

  async getQueueSizes(): Promise<QueueSizes> {
    const [pending, active, failed] = await Promise.all([
      this.redis.lLen(this.keys.pending),
      this.redis.zCard(this.keys.activeSet),
      this.redis.lLen(this.keys.failed),
    ]);

    return { pending, active, failed };
  }

  async incrementDomainCount(domain: string): Promise<number> {
    return await this.redis.hIncrBy(this.keys.domains, domain, 1);
  }

  async getDomainCount(domain: string): Promise<number> {
    const count = await this.redis.hGet(this.keys.domains, domain);
    return parseInt(count ?? "0", 10);
  }

  async registerWorker(workerId: string, metadata: WorkerMetadata = {}): Promise<void> {
    await this.redis.sAdd(this.keys.workers, workerId);
    await this.redis.hSet(`${this.keys.workers}:${workerId}`, {
      status: "running",
      heartbeat: Date.now().toString(),
      started_at: Date.now().toString(),
      urls_processed: "0",
      ...metadata,
    });
  }

  async updateWorkerHeartbeat(workerId: string): Promise<void> {
    await this.redis.hSet(`${this.keys.workers}:${workerId}`, {
      heartbeat: Date.now().toString(),
    });
  }

  async updateWorkerStats(workerId: string, stats: Partial<WorkerMetadata>): Promise<void> {
    const statsToUpdate: Record<string, string> = {};
    for (const [key, value] of Object.entries(stats)) {
      if (value !== undefined) {
        statsToUpdate[key] = value;
      }
    }
    if (Object.keys(statsToUpdate).length > 0) {
      await this.redis.hSet(`${this.keys.workers}:${workerId}`, statsToUpdate);
    }
  }

  async deregisterWorker(workerId: string): Promise<void> {
    await this.redis.sRem(this.keys.workers, workerId);
    await this.redis.del(`${this.keys.workers}:${workerId}`);
  }

  async getActiveWorkers(): Promise<Worker[]> {
    const workerIds = await this.redis.sMembers(this.keys.workers);
    const workers: Worker[] = [];

    for (const id of workerIds) {
      const data = await this.redis.hGetAll(`${this.keys.workers}:${id}`);
      workers.push({ id, ...data });
    }

    return workers;
  }

  async recoverStaleUrls(staleTimeout = 300000): Promise<string[]> {
    const now = Date.now();
    const staleThreshold = now - staleTimeout;

    const staleEntries = await this.redis.zRangeByScore(this.keys.activeSet, 0, staleThreshold);

    const recovered: string[] = [];
    for (const entry of staleEntries) {
      const parts = entry.split(":", 2);
      const url = parts[1];
      if (url) {
        await this.redis.lPush(this.keys.pending, url);
        await this.redis.zRem(this.keys.activeSet, entry);
        recovered.push(url);
      }
    }

    return recovered;
  }

  async cleanupDeadWorkers(timeout = 60000): Promise<string[]> {
    const workers = await this.getActiveWorkers();
    const now = Date.now();
    const cleaned: string[] = [];

    for (const worker of workers) {
      const heartbeat = parseInt(worker.heartbeat ?? "0", 10);
      if (now - heartbeat > timeout) {
        const activeUrls = await this.redis.zRange(this.keys.activeSet, 0, -1);
        for (const entry of activeUrls) {
          if (entry.startsWith(`${worker.id}:`)) {
            const parts = entry.split(":", 2);
            const url = parts[1];
            if (url) {
              await this.redis.lPush(this.keys.pending, url);
              await this.redis.zRem(this.keys.activeSet, entry);
            }
          }
        }

        await this.deregisterWorker(worker.id);
        cleaned.push(worker.id);
      }
    }

    return cleaned;
  }

  async updateProgress(updates: Partial<CrawlerProgress>): Promise<void> {
    const progressToUpdate: Record<string, string> = {};
    for (const [key, value] of Object.entries(updates)) {
      if (value !== undefined) {
        progressToUpdate[key] = value;
      }
    }
    if (Object.keys(progressToUpdate).length > 0) {
      await this.redis.hSet(this.keys.progress, progressToUpdate);
    }
  }

  async getProgress(): Promise<CrawlerProgress> {
    return await this.redis.hGetAll(this.keys.progress);
  }

  async addRecentUrl(url: string): Promise<void> {
    await this.redis.lPush(this.keys.recent, url);
    await this.redis.lTrim(this.keys.recent, 0, 99);
  }

  async getRecentUrls(count = 10): Promise<string[]> {
    return await this.redis.lRange(this.keys.recent, 0, count - 1);
  }

  async updateState(updates: Partial<CrawlerState>): Promise<void> {
    const stateToUpdate: Record<string, string> = {};
    for (const [key, value] of Object.entries(updates)) {
      if (value !== undefined) {
        stateToUpdate[key] = value;
      }
    }
    if (Object.keys(stateToUpdate).length > 0) {
      await this.redis.hSet(this.keys.state, stateToUpdate);
    }
  }

  async getState(): Promise<CrawlerState> {
    return await this.redis.hGetAll(this.keys.state);
  }

  async clear(): Promise<void> {
    const keys = await this.redis.keys(`${this.prefix}:*`);
    if (keys.length > 0) {
      await this.redis.del(keys);
    }
  }

  async getRecentErrors(count = 10): Promise<FailedUrl[]> {
    const errors = await this.redis.lRange(this.keys.errors, 0, count - 1);
    return errors.map((errorStr) => JSON.parse(errorStr) as FailedUrl);
  }
}
