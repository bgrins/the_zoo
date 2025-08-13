# Zoo Crawler

A simplified web crawler service that indexes content from .zoo domains into MeiliSearch. Features a single-worker design with Redis-based queue management for resumability.

## Features

- **Simple single-worker architecture** with Redis queue for resumability
- **Full resumability** - stop/start anytime without losing progress
- **Automatic recovery** from stale URLs and worker failures
- **Redis-based queue** for reliable URL persistence
- **Real-time CLI management** of crawler operations
- Crawls .zoo domains starting from configurable seed URL
- Indexes content into Meilisearch with batching
- Deduplicates URLs to avoid re-crawling
- Respects same-domain crawling restrictions

## Quick Start

```bash
# Start the crawler container
docker compose --profile tools up -d zoo-crawler

# Add initial URL to queue
docker compose exec zoo-crawler npm run cli add --url http://utils.zoo

# Start crawling
docker compose exec zoo-crawler npm run start

# Check queue status
docker compose exec zoo-crawler npm run cli queue
```

## CLI Commands

### Queue Management

```bash
# Add URL to crawl queue
docker compose exec zoo-crawler npm run cli add --url <URL>

# Show queue status (pending/active/failed counts)
docker compose exec zoo-crawler npm run cli queue

# Reset all crawler data (clears queue and cache)
docker compose exec zoo-crawler npm run cli reset
```

### Worker Management

```bash
# List active workers with processing status
docker compose exec zoo-crawler npm run cli workers

# Recover stale URLs from dead/stuck workers
docker compose exec zoo-crawler npm run cli recover

# Clean up dead worker records
docker compose exec zoo-crawler npm run cli cleanup
```

### Starting the Crawler

```bash
# Start crawler (automatically seeds if queue is empty)
docker compose exec zoo-crawler npm run start

# Or run in development mode with auto-restart
docker compose exec zoo-crawler npm run dev
```

## Architecture

### Simplified Design

The crawler uses a simplified single-worker architecture with:

- **Single worker instance** for reliable, predictable crawling
- **Redis queue** for URL persistence and resumability
- **Automatic seeding** when queue is empty
- **Stale URL recovery** for robustness

### Components

- **Node.js + TypeScript**: Modern runtime with type safety
- **Redis**: URL queue and crawler state persistence
- **Meilisearch**: Full-text search indexing
- **Cheerio**: HTML parsing and content extraction

### Redis Data Structures

```
crawler:queue:pending       # List: URLs waiting to be crawled
crawler:queue:activeSet     # Sorted set: URLs being processed with timestamps
crawler:queue:failed        # List: Failed URLs with error information
crawler:queue:completed:*   # Keys: Cache of successfully crawled URLs
```

## Configuration

Environment variables (configured in docker-compose.yaml):

- `REDIS_URL`: Redis connection URL (default: redis://redis:6379)
- `MEILI_HOST`: Meilisearch host (default: http://search-api.zoo)
- `MEILI_MASTER_KEY`: Meilisearch API key (default: zooMasterKey123456789)
- `SEED_URL`: Initial URL to crawl (default: http://utils.zoo)
- `MAX_CONCURRENCY`: Concurrent requests (default: 3)
- `MAX_REQUESTS_PER_CRAWL`: Total URLs per crawl session (default: 500)
- `BATCH_SIZE`: Documents per Meilisearch batch (default: 10)

## Monitoring

### CLI Status

```bash
# Quick queue overview
docker compose exec zoo-crawler npm run cli queue

# Worker status
docker compose exec zoo-crawler npm run cli workers
```

### Web Interface

View crawler status at: `http://search.zoo/distributed-crawler`

Shows:

- Queue distribution (pending/active/failed)
- Active worker information
- Recent crawling activity

### Container Logs

```bash
# Follow crawler logs
docker compose logs -f zoo-crawler

# View recent logs
docker compose logs --tail=50 zoo-crawler
```

## Testing

### Internal Tests

```bash
# Run comprehensive test suite inside container
docker compose exec zoo-crawler npm run test

# Run container-specific CLI tests
docker compose exec zoo-crawler npm run test:container
```

### Integration Tests

```bash
# Run from host - tests crawler via Docker
npm run test tests/tools/crawler.test.ts

# Run smoke tests
npm run test:smoke -- tests/smoke/crawler.test.ts
```

## Development

### Running Locally

```bash
# Development mode with auto-restart
docker compose exec zoo-crawler npm run dev

# One-time execution
docker compose exec zoo-crawler npm run start
```

### Project Structure

```
/core/crawler/
├── crawler.ts      # Main SimpleCrawler class
├── cli.ts          # Command-line interface
├── redis-queue.ts  # Redis queue management
├── config.ts       # Configuration loading
├── types.ts        # TypeScript type definitions
├── index.ts        # Entry point
├── test-crawler.ts # Test suite
└── package.json    # Dependencies and scripts
```

### Key Classes

- **`SimpleCrawler`**: Main crawler engine with queue processing
- **`RedisQueue`**: URL queue operations and worker coordination
- **`SimpleCrawlerCLI`**: Command-line interface for management

## Backup & Restore

The crawler integrates with Meilisearch backup scripts:

```bash
# Backup search index
./scripts/meili-backup.sh

# Restore search index
./scripts/meili-restore.sh <backup-file>
```

## Troubleshooting

### Common Issues

**Empty queue after restart:**

- The crawler auto-seeds from `SEED_URL` when queue is empty
- Manually add URLs: `npm run cli add --url <URL>`

**Stale URLs in active queue:**

- Run recovery: `npm run cli recover`
- Reset if needed: `npm run cli reset`

**Container connection issues:**

- Ensure Redis and Meilisearch containers are running
- Check container logs: `docker compose logs zoo-crawler`

### Debug Commands

```bash
# Check Redis connectivity
docker compose exec zoo-crawler sh -c "nc -zv redis 6379"

# Check Meilisearch connectivity  
docker compose exec zoo-crawler sh -c "wget -qO- http://search-api.zoo/health"

# View all Redis keys
docker compose exec redis redis-cli keys "*crawler*"
```

## Production Considerations

This crawler is designed for the development Zoo environment. For production use, consider:

- **Rate limiting**: Add delays between requests to respect target servers
- **Robots.txt compliance**: Parse and respect robots.txt files
- **Error classification**: Implement retry logic for different error types
- **Monitoring**: Add metrics collection and alerting
- **Security**: Validate URLs and implement access controls

## Location

The crawler is located in `/core/crawler/` as a core Zoo service.
