# Playwright Python Example

Use [Playwright for Python](https://playwright.dev/python/) with The Zoo environment.

## Quick Start

```bash
cd examples/playwright_python
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
playwright install firefox
python example.py
```

## Notes

- Requires Python 3.8+
- The Zoo must be running (`npm start` from root)
- Proxy is at `localhost:3128` (or `ZOO_PROXY_PORT`)
