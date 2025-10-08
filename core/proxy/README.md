# Squid Proxy Authentication

Optional basic authentication for the proxy.

## Setup

Set `PROXY_USER` and `PROXY_PASS` environment variables:

```bash
export PROXY_USER=zoouser
export PROXY_PASS=zoopassword
docker compose up -d proxy --build
```

## Usage

```bash
curl -L -k --proxy http://zoouser:zoopassword@localhost:3128 http://example.zoo
```

## Notes

- No env vars set = no authentication required (default)
- Both PROXY_USER and PROXY_PASS must be set to enable auth
