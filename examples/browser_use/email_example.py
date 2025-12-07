#!/usr/bin/env python3
"""
Browser-use email example for The Zoo environment.

Demonstrates sending an email from one user and checking it with another user.
Uses two browser instances to simulate real multi-user interaction.
"""

import asyncio
import os
from browser_use import Agent, Browser, ChatOpenAI
from browser_use.browser.profile import ProxySettings

ZOO_PROXY_PORT = os.environ.get("ZOO_PROXY_PORT", "3128")
ZOO_PROXY_URL = f"http://localhost:{ZOO_PROXY_PORT}"

# Test users from Zoo seed data
SENDER = {"email": "alice@snappymail.zoo", "password": "alice123"}
RECIPIENT = {"email": "bob@snappymail.zoo", "password": "bob123"}


def create_browser():
    return Browser(
        headless=False,
        proxy=ProxySettings(server=ZOO_PROXY_URL),
        args=["--ignore-certificate-errors"],
    )


async def main():
    llm = ChatOpenAI(model="gpt-4o")

    print("=== Sending email as Alice ===")
    browser1 = create_browser()
    sender_agent = Agent(
        task=f"""
        Go to https://snappymail.zoo and log in with:
        Email: {SENDER['email']} Password: {SENDER['password']}

        Then compose and send a new email to {RECIPIENT['email']}.
        Come up with a realistic subject and message about scheduling a meeting.
        """,
        llm=llm,
        browser=browser1,
    )
    await sender_agent.run()
    await browser1.stop()

    print("\n=== Checking email as Bob ===")
    browser2 = create_browser()
    recipient_agent = Agent(
        task=f"""
        Go to https://snappymail.zoo and log in with:
        Email: {RECIPIENT['email']} Password: {RECIPIENT['password']}

        Check the inbox for a new email from Alice.
        Open it and summarize its contents.
        """,
        llm=llm,
        browser=browser2,
    )
    result = await recipient_agent.run()
    await browser2.stop()

    print("\n=== Email Summary ===")
    print(result)


if __name__ == "__main__":
    asyncio.run(main())
