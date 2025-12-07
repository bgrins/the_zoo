# Browser Use Integration

Use [browser-use](https://github.com/browser-use/browser-use) with The Zoo environment.

## Quick Start

```bash
cd examples/browser_use
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env # and update with API key
python example.py
```

## Notes

- Requires Python 3.11+
- The Zoo must be running (`npm start` from root)
- Proxy is at `localhost:3128` (or `ZOO_PROXY_PORT`)
