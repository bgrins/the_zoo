#!/usr/bin/env python3
"""
Browser-use integration example for The Zoo environment.

This demonstrates how to use browser-use with The Zoo's proxy setup
to automate interactions with .zoo domains.
"""

import asyncio
import os
from browser_use import Agent, Browser, ChatOpenAI
from browser_use.browser.profile import ProxySettings

# Zoo proxy configuration
ZOO_PROXY_PORT = os.environ.get("ZOO_PROXY_PORT", "3128")
ZOO_PROXY_URL = f"http://localhost:{ZOO_PROXY_PORT}"


async def main():
    # Configure browser to use Zoo proxy
    browser = Browser(
        headless=False,
        proxy=ProxySettings(server=ZOO_PROXY_URL),
        args=["--ignore-certificate-errors"],  # Zoo uses self-signed certs
    )

    # Initialize the LLM (uses OPENAI_API_KEY from environment)
    # You can also use ChatAnthropic, ChatGoogle, or ChatBrowserUse
    llm = ChatOpenAI(model="gpt-4o")

    # Create the agent
    agent = Agent(
        task="Go to https://home.zoo and tell me what services are available in The Zoo",
        llm=llm,
        browser=browser,
    )

    # Run the agent
    result = await agent.run()
    print("\n--- Agent Result ---")
    print(result)

    await browser.stop()


if __name__ == "__main__":
    asyncio.run(main())
