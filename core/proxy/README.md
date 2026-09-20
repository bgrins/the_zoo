# Squid Proxy Authentication

Optional basic authentication for the proxy.

## Setup

Set `PROXY_USER` and `PROXY_PASS` environment variables:

```bash
export PROXY_USER=zoouser
export PROXY_PASS=zoopassword
docker compose up -d proxy
```

## Usage

```bash
curl -L -k --proxy http://zoouser:zoopassword@localhost:3128 http://example.zoo
```

## Notes

- Without both variables the proxy needs no authentication (the default).
- It listens on 127.0.0.1 unless `ZOO_PROXY_BIND` is set (e.g. `0.0.0.0`).
