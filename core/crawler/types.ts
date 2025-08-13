export interface WorkerMetadata {
  hostname?: string;
  pid?: string;
  concurrency?: string;
  status?: string;
  heartbeat?: string;
  started_at?: string;
  urls_processed?: string;
  active_fetches?: string;
}

export interface Worker {
  id: string;
  hostname?: string;
  pid?: string;
  concurrency?: string;
  status?: string;
  heartbeat?: string;
  started_at?: string;
  urls_processed?: string;
  active_fetches?: string;
}

export interface QueueSizes {
  pending: number;
  active: number;
  failed: number;
}

export interface FailedUrl {
  url: string;
  error: string;
  timestamp: number;
  workerId: string;
}

export interface CrawlerState {
  status?: string;
  started_at?: string;
  urls_crawled?: string;
  urls_queued?: string;
  errors?: string;
  ignore_cache?: string;
}

export interface CrawlerProgress {
  crawl_rate?: string;
  avg_response_time?: string;
  total_bytes?: string;
}

export interface CrawledDocument {
  id: string;
  url: string;
  domain: string;
  title: string;
  content: string;
  timestamp: number;
  score: number;
  contentType: string;
  workerId: string;
}

export interface FetchResult {
  ok: boolean;
  status: number;
  headers: Record<string, string>;
  body: string;
  responseTime: number;
}

export interface CrawlerConfig {
  meilisearchHost: string;
  meilisearchApiKey: string;
  redisUrl: string;
  maxConcurrency: number;
  maxRequestsPerCrawl: number;
  maxDocsPerDomain: number;
  ignoreCrawlCache: boolean;
  seedUrl: string;
  batchSize: number;
  staleTimeout: number;
  heartbeatInterval: number;
  commandCheckInterval: number;
  deadWorkerCleanupInterval: number;
}
