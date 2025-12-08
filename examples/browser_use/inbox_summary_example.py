#!/usr/bin/env python3
"""
Browser-use inbox summary example for The Zoo environment.

Logs in as a specified user and summarizes their email inbox.
"""

import argparse
import asyncio
import os
from browser_use import Agent, Browser, ChatOpenAI
from browser_use.browser.profile import ProxySettings

ZOO_PROXY_PORT = os.environ.get("ZOO_PROXY_PORT", "3128")
ZOO_PROXY_URL = f"http://localhost:{ZOO_PROXY_PORT}"

# Default test users from Zoo seed data
DEFAULT_USERS = {
    "alice": {"email": "alice@snappymail.zoo", "password": "alice123"},
    "bob": {"email": "bob@snappymail.zoo", "password": "bob123"},
    "charlie": {"email": "charlie@snappymail.zoo", "password": "charlie123"},
}


def create_browser(headless: bool = False):
    return Browser(
        headless=headless,
        proxy=ProxySettings(server=ZOO_PROXY_URL),
        args=["--ignore-certificate-errors"],
    )


async def check_inbox(user: dict, headless: bool = False, max_emails: int = 5):
    """Check and summarize inbox for a given user."""
    llm = ChatOpenAI(model="gpt-4o-mini")
    browser = create_browser(headless=headless)

    agent = Agent(
        task=f"""
        Go to https://snappymail.zoo and log in with:
        Email: {user["email"]} Password: {user["password"]}

        Once logged in, check the inbox and triage up to {max_emails} most recent emails.
        """,
        llm=llm,
        browser=browser,
    )

    result = await agent.run()
    await browser.stop()
    return result


def parse_args():
    parser = argparse.ArgumentParser(
        description="Check and summarize a user's email inbox in The Zoo"
    )
    parser.add_argument(
        "--user",
        "-u",
        choices=list(DEFAULT_USERS.keys()),
        default="alice",
        help="User to check inbox for (default: alice)",
    )
    parser.add_argument(
        "--email",
        "-e",
        help="Custom email address (overrides --user)",
    )
    parser.add_argument(
        "--password",
        "-p",
        help="Custom password (required if --email is used)",
    )
    parser.add_argument(
        "--headless",
        action="store_true",
        help="Run browser in headless mode",
    )
    parser.add_argument(
        "--max-emails",
        "-n",
        type=int,
        default=5,
        help="Maximum number of emails to summarize (default: 5)",
    )
    return parser.parse_args()


async def main():
    args = parse_args()

    if args.email:
        if not args.password:
            print("Error: --password is required when using --email")
            return
        user = {"email": args.email, "password": args.password}
    else:
        user = DEFAULT_USERS[args.user]

    print(f"=== Checking inbox for {user['email']} ===\n")

    result = await check_inbox(
        user=user,
        headless=args.headless,
        max_emails=args.max_emails,
    )

    print("\n=== Inbox Summary ===")
    print(result)


if __name__ == "__main__":
    asyncio.run(main())
