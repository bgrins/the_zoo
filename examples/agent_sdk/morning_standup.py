#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "claude-agent-sdk>=0.1.39",
#   "python-dotenv>=1.0",
# ]
# ///
"""
Multi-agent morning standup demo for The Zoo.

Three AI agents coordinate across six interconnected zoo sites to simulate
a realistic developer team morning routine:

  Step 1: Alice (Developer) files a bug, creates a paste, posts to chat
  Step 2: Blake (Manager) triages — reviews issue, creates task, emails Eve
  Step 3: Eve (QA) reads Blake's email, comments on issue, subscribes to feed

Run:  uv run morning_standup.py
Requires: The Zoo running (npm start), ANTHROPIC_API_KEY set (or in .env)
"""

import asyncio
import atexit
import os
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

from claude_agent_sdk import ClaudeAgentOptions, query
from dotenv import load_dotenv

load_dotenv()

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

PROXY_PORT = os.environ.get("ZOO_PROXY_PORT", "3128")
MODEL = os.environ.get("ZOO_AGENT_MODEL", "sonnet")
REPO_ROOT = Path(__file__).resolve().parent.parent.parent
ZOO_ROOT_CERT = REPO_ROOT / "core" / "caddy" / "root.crt"


def _create_firefox_profile() -> str:
    """Create a Firefox profile with the Zoo root CA pre-trusted.

    Uses NSS certutil to import core/caddy/root.crt so Firefox trusts
    all *.zoo HTTPS certificates without --ignore-https-errors.
    Returns the profile directory path, or "" on failure.
    """
    certutil = shutil.which("certutil")
    if not certutil:
        print(
            "Warning: certutil (NSS tools) not found — install via 'brew install nss'"
        )
        print("         Falling back to --ignore-https-errors")
        return ""

    if not ZOO_ROOT_CERT.exists():
        print(f"Warning: Root cert not found at {ZOO_ROOT_CERT}")
        print("         Falling back to --ignore-https-errors")
        return ""

    profile_dir = tempfile.mkdtemp(prefix="zoo-firefox-")
    atexit.register(shutil.rmtree, profile_dir, ignore_errors=True)

    # Initialize empty NSS database
    subprocess.run(
        [certutil, "-N", "-d", f"sql:{profile_dir}", "--empty-password"],
        check=True,
        capture_output=True,
    )
    # Import the zoo root CA as trusted for SSL
    subprocess.run(
        [
            certutil,
            "-A",
            "-n",
            "Zoo Local CA",
            "-t",
            "C,C,C",
            "-d",
            f"sql:{profile_dir}",
            "-i",
            str(ZOO_ROOT_CERT),
        ],
        check=True,
        capture_output=True,
    )
    print(f"  Bootstrapped Firefox profile with Zoo root CA at {profile_dir}")
    return profile_dir


# Create a template profile once at startup — each agent gets a copy
_FIREFOX_PROFILE_TEMPLATE = _create_firefox_profile()


def _get_screen_size() -> tuple[int, int]:
    """Detect screen resolution (accounts for Retina scaling on macOS)."""
    try:
        out = subprocess.run(
            ["system_profiler", "SPDisplaysDataType"],
            capture_output=True,
            text=True,
        ).stdout
        for line in out.splitlines():
            if "Resolution" in line:
                # e.g. "Resolution: 3024 x 1964 Retina"
                parts = line.split()
                w, h = int(parts[1]), int(parts[3])
                if "Retina" in line:
                    w, h = w // 2, h // 2
                return w, h
    except Exception:
        pass
    return 1440, 900  # sensible default


SCREEN_W, SCREEN_H = _get_screen_size()
# Browser viewport: ~60% screen width, full height (minus ~80px for chrome/dock)
VIEWPORT_W = (SCREEN_W * 3) // 5
VIEWPORT_H = SCREEN_H - 80


def playwright_mcp_config():
    """Return a Playwright MCP server config with Firefox and the zoo proxy.

    Each call creates a fresh copy of the profile template so that
    concurrent agents don't hit Firefox profile-lock conflicts.
    """
    args = [
        "@playwright/mcp@latest",
        "--browser",
        "firefox",
        "--proxy-server",
        f"http://localhost:{PROXY_PORT}",
        "--viewport-size",
        f"{VIEWPORT_W}x{VIEWPORT_H}",
    ]
    if _FIREFOX_PROFILE_TEMPLATE:
        profile_copy = tempfile.mkdtemp(prefix="zoo-firefox-agent-")
        atexit.register(shutil.rmtree, profile_copy, ignore_errors=True)
        # Copy the NSS cert database files into the new profile
        for f in Path(_FIREFOX_PROFILE_TEMPLATE).iterdir():
            shutil.copy2(f, profile_copy)
        args += ["--user-data-dir", profile_copy]
    else:
        args += ["--ignore-https-errors"]
    return {"command": "npx", "args": args}


# ---------------------------------------------------------------------------
# Agent prompts
# ---------------------------------------------------------------------------

AGENT_PREAMBLE = """\
IMPORTANT: Never use browser_take_screenshot — it produces images too large for the \
message buffer. Always use browser_snapshot instead to inspect page state.\
"""

ALICE_PROMPT = (
    AGENT_PREAMBLE
    + """
You are Alice, a developer on the Zoo platform team. Complete these tasks in order,
using the Playwright browser tools. All sites use HTTPS.

1. **File a bug on Gitea**
   - Navigate to https://gitea.zoo and click "Sign in with auth.zoo"
   - On the auth.zoo login page, log in (username: alice, password: alice123)
   - If a consent/authorize screen appears, click Allow/Accept
   - Go to the alice/hello-zoo repository
   - Create a new issue:
     Title: "Bug: login redirect fails on Safari 17"
     Body: "When logging in from Safari 17.x on macOS, the OAuth redirect
     lands on a blank page instead of the dashboard. This started after the
     latest auth.zoo update. Priority: high."
   - Note the issue URL

2. **Create a paste with reproduction steps**
   - Navigate to https://paste.zoo
   - Create a new paste with this content:
     "## Reproduction Steps - Safari Login Bug

     1. Open Safari 17.x on macOS Sonoma
     2. Navigate to https://home.zoo
     3. Click 'Sign in with auth.zoo'
     4. Enter valid credentials
     5. After OAuth callback, page shows blank white screen
     6. Console shows: 'TypeError: Cannot read property redirect of undefined'

     Expected: User lands on dashboard
     Actual: Blank page after OAuth redirect"
   - Note the paste URL

3. **Post standup update to Mattermost**
   - Navigate to https://mattermost.zoo and log in (username: alice, password: alice123)
   - In the Town Square channel of the "zoo" team, type and send a message.
   - CRITICAL: The message MUST contain the full literal URLs (copy-paste them exactly).
     Include: (a) a greeting, (b) the exact Gitea issue URL from step 1,
     (c) the exact paste URL from step 2, (d) a request for QA to take a look.
     Example format: "Morning! Filed a Safari login bug: https://gitea.zoo/alice/hello-zoo/issues/3 — Repro steps: https://paste.zoo/xxx — Could use eyes from QA."
   - Do NOT paraphrase or omit the URLs. Both URLs must appear in the message.

When done, report back a summary including the Gitea issue URL and paste URL.
"""
)

BLAKE_PROMPT = (
    AGENT_PREAMBLE
    + """
You are Blake Sullivan, engineering manager for the Zoo platform team. Complete these
tasks in order using the Playwright browser tools. All sites use HTTPS.

Context from Alice's standup: {context}

1. **Check Mattermost for Alice's update and reply**
   - Navigate to https://mattermost.zoo and log in
     (username: blake.sullivan, password: Password.123)
   - Go to the "zoo" team, Town Square channel
   - Read Alice's latest message about the Safari bug
   - Reply in the channel: "Thanks Alice, I'll triage this now. Looping in Eve for QA."

2. **Review the Gitea issue**
   - Navigate to https://gitea.zoo and log in
     (username: blake.sullivan, password: Password.123)
   - Find and read Alice's issue on the alice/hello-zoo repository about the Safari login bug

3. **Create a task on Focalboard**
   - Navigate to https://focalboard.zoo and log in
     (username: alex.lee@snappymail.zoo, password: Password.123)
   - If there's a "Create a board" prompt, use the "Project Tasks" template
   - Add a new card titled "Review: Safari login redirect bug" in the first column
   - Close any dialogs that appear

4. **Email Eve about the bug**
   - Navigate to https://snappymail.zoo and log in
     (email: blake.sullivan@snappymail.zoo, password: Password.123)
   - Compose a new email:
     To: eve@snappymail.zoo
     Subject: "Action needed: Safari login bug triage"
     Body: "Hi Eve, Alice filed a Safari 17 login redirect bug on hello-zoo.
     Can you take a look and run through the repro steps? I've added it to
     the Focalboard sprint board. Thanks, Blake"
   - Send the email

When done, report back a summary of all actions taken.
"""
)

EVE_PROMPT = (
    AGENT_PREAMBLE
    + """
You are Eve, QA engineer on the Zoo platform team. Complete these tasks
in order using the Playwright browser tools. All sites use HTTPS.

Context from Alice's standup: {context}

1. **Check email**
   - Navigate to https://snappymail.zoo and log in
     (email: eve@snappymail.zoo, password: eve123)
   - Check your inbox for an email from Blake about the Safari bug and read it.

2. **Review the reproduction steps**
   - Navigate to the paste URL from Alice's context (on https://paste.zoo)
   - Read through the repro steps

3. **Comment on the Gitea issue**
   - Navigate to https://gitea.zoo and log in (username: eve, password: eve123)
   - Go to the alice/hello-zoo repository
   - Find the issue about the Safari login bug
   - Add a comment: "I'll take a look at this today. Reviewed the repro steps on
     paste.zoo. Will test on Safari 17.2 and 17.4 on both macOS Sonoma and
     Ventura. I'll update the issue with my findings by EOD."

4. **Subscribe to Alice's activity feed in Miniflux**
   - Navigate to https://miniflux.zoo and log in (username: eve, password: eve123)
   - Go to add a new feed subscription
   - Add the feed URL: http://gitea.zoo/alice.atom
   - Choose any available category or the default

5. **Post update to Mattermost**
   - Navigate to https://mattermost.zoo and log in (username: eve, password: eve123!!)
   - Go to the "zoo" team, Town Square channel
   - Post a message: "Picked up the Safari login bug. Reviewed the repro steps
     and commented on the issue. Will have results by EOD."

When done, report back a summary of all actions taken.
"""
)


# ---------------------------------------------------------------------------
# Agent runner
# ---------------------------------------------------------------------------


async def run_agent(name: str, prompt: str) -> str:
    """Run a single agent with its own Playwright browser and return the result."""
    tag = f"[{name}]"
    start = time.time()
    result = ""

    async for message in query(
        prompt=prompt,
        options=ClaudeAgentOptions(
            model=MODEL,
            permission_mode="bypassPermissions",
            max_turns=50,
            mcp_servers={"playwright": playwright_mcp_config()},
        ),
    ):
        if hasattr(message, "content") and isinstance(message.content, list):
            for block in message.content:
                if hasattr(block, "text"):
                    print(f"  {tag} {block.text}")
                elif hasattr(block, "name") and hasattr(block, "input"):
                    # Tool use block
                    summary = str(block.input)
                    if len(summary) > 120:
                        summary = summary[:120] + "…"
                    print(f"  {tag} ▶ {block.name}({summary})")
        if hasattr(message, "result"):
            result = message.result or ""

    elapsed = time.time() - start
    print(f"  {tag} Finished in {elapsed:.0f}s")
    return result


# ---------------------------------------------------------------------------
# Orchestrator
# ---------------------------------------------------------------------------


async def main():
    if not os.environ.get("ANTHROPIC_API_KEY"):
        print("Error: ANTHROPIC_API_KEY environment variable is required")
        sys.exit(1)

    print("=" * 60)
    print("  Multi-Agent Morning Standup Demo")
    print("  3 agents x 6 sites x 1 sequential workflow")
    print("=" * 60)
    total_start = time.time()

    # Step 1: Alice files bug, creates paste, posts standup
    print("\n--- Step 1: Alice (Developer) ---")
    print("  Sites: gitea.zoo -> paste.zoo -> mattermost.zoo")
    alice_result = await run_agent("Alice", ALICE_PROMPT)
    print(f"\n  Alice's report:\n  {alice_result[:300]}...")

    # Step 2: Blake triages — reads Alice's message, reviews issue, emails Eve
    print("\n--- Step 2: Blake (Manager) ---")
    print("  Sites: mattermost.zoo -> gitea.zoo -> focalboard.zoo -> snappymail.zoo")
    blake_result = await run_agent("Blake", BLAKE_PROMPT.format(context=alice_result))
    print(f"\n  Blake's report:\n  {blake_result[:300]}...")

    # Step 3: Eve responds — reads Bob's email, comments on issue, subscribes to feed
    print("\n--- Step 3: Eve (QA) ---")
    print(
        "  Sites: snappymail.zoo -> paste.zoo -> gitea.zoo -> miniflux.zoo -> mattermost.zoo"
    )
    eve_result = await run_agent("Eve", EVE_PROMPT.format(context=alice_result))
    print(f"\n  Eve's report:\n  {eve_result[:300]}...")

    total_elapsed = time.time() - total_start
    print("\n" + "=" * 60)
    print(f"  Standup complete! Total time: {total_elapsed:.0f}s")
    print("=" * 60)

    # Print full results
    print("\n\n--- Full Agent Reports ---\n")
    for name, result in [
        ("Alice", alice_result),
        ("Blake", blake_result),
        ("Eve", eve_result),
    ]:
        print(f"=== {name} ===")
        print(result)
        print()


if __name__ == "__main__":
    asyncio.run(main())
