# Crawler Configuration

The Zoo includes a web crawler that can index sites within the environment. The crawler is designed for development and testing purposes.

## Configuration

The crawler can be configured via environment variables in docker-compose.yaml:

- `SEED_URL`: Initial URL to crawl (default: http://utils.zoo)
- `MAX_CONCURRENCY`: Number of concurrent requests per worker
- `MAX_REQUESTS_PER_CRAWL`: Total requests limit
- `MAX_DOCS_PER_DOMAIN`: Maximum documents per domain

## CLI Commands

Starting the container: `docker compose --profile tools up -d zoo-crawler`

Operate the crawler CLI with `npm run cli:crawler`. For example, `npm run cli:crawler -- start`.

Available crawler commands:

- `start` - Start the crawler
- `stop` - Stop the crawler
- `status` - Check crawler status
- `add --url <url>` - Add URL to crawl queue
- `queue` - Show queue status
- `workers` - List active workers

## Monitoring

- **Web UI**: Visit http://search.zoo/crawler for real-time status
- **API**: Check http://search.zoo/api/crawler/status for JSON status
- **Logs**: Use `docker compose logs -f zoo-crawler` to follow crawler logs
