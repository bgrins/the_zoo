#!/usr/bin/env python3
"""
Playwright Python example for The Zoo environment.
"""

import os
from playwright.sync_api import sync_playwright

PROXY_PORT = os.environ.get("ZOO_PROXY_PORT", "3128")


def main():
    with sync_playwright() as p:
        browser = p.firefox.launch(
            headless=False,
            proxy={"server": f"http://localhost:{PROXY_PORT}"},
        )
        context = browser.new_context(ignore_https_errors=True)
        page = context.new_page()

        # Navigate to home page
        page.goto("https://home.zoo")
        print(f"Title: {page.title()}")

        # List services
        cards = page.locator(".app-card").all()
        print(f"Found {len(cards)} services")

        # Go to paste service
        page.goto("https://paste.zoo")
        page.wait_for_load_state("networkidle")
        print(f"Navigated to: {page.url}")

        # Create a paste
        page.fill("#content-input", "Hello from Playwright Python!")
        page.click("#submit-button")
        page.wait_for_url("**/upload/**")
        print(f"Created paste at: {page.url}")

        page.wait_for_timeout(3000)
        browser.close()


if __name__ == "__main__":
    main()
