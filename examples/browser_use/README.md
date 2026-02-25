# Browser Use Integration

Use [browser-use](https://github.com/browser-use/browser-use) with The Zoo environment.

## Quick Start

```bash
cd examples/browser_use
cp .env.example .env # and update with API key
uv run example.py
```

## Notes

- Requires Python 3.11+
- The Zoo must be running (`npm start` from root)
- Proxy is at `localhost:3128` (or `ZOO_PROXY_PORT`)
