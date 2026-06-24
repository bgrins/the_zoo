#!/usr/bin/env python3
"""
Enron JMAP email importer for Stalwart.

Reads Enron maildir files, parses them, and imports via JMAP Email/set.
Called by enron-prepare.sh after users are created.

Usage:
    python3 enron-import-jmap.py --dataset ./enron/maildir \
        --target-domain enron.zoo --password EnronZoo.123 \
        --max-per-folder 50 --verbose
"""

import argparse
import json
import os
import random
import re
import sys
from email import policy
from email.parser import BytesParser
from email.utils import getaddresses, parseaddr
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import requests

PROXY_URL = os.environ.get("ZOO_PROXY_URL", "http://localhost:3128")
PUBLIC_HOSTNAME = "mail-api.zoo"
BASE_URL = f"http://{PUBLIC_HOSTNAME}"
DEFAULT_PASSWORD = "EnronZoo.123"
TARGET_DOMAIN_DEFAULT = "enron.zoo"

proxies = {"http": PROXY_URL, "https": PROXY_URL}

MAILDIR_FILE_RE = re.compile(r"^\d+(?:\.|\.eml)?$")

# The 20 curated Enron users: dir-name -> email-local-part
ENRON_USERS = {
    "allen-p": "phillip.allen",
    "bass-e": "eric.bass",
    "beck-s": "sally.beck",
    "blair-l": "lynn.blair",
    "campbell-l": "larry.campbell",
    "cash-m": "michelle.cash",
    "dasovich-j": "jeff.dasovich",
    "davis-d": "dana.davis",
    "delainey-d": "david.delainey",
    "derrick-j": "james.derrick",
    "farmer-d": "daren.farmer",
    "germany-c": "chris.germany",
    "griffith-j": "john.griffith",
    "haedicke-m": "mark.haedicke",
    "kaminski-v": "vince.kaminski",
    "kitchen-l": "louise.kitchen",
    "lavorato-j": "john.lavorato",
    "lay-k": "kenneth.lay",
    "shackleton-s": "sara.shackleton",
    "skilling-j": "jeff.skilling",
}

# Enron maildir folders -> JMAP mailbox roles
FOLDER_ROLE_MAP = {
    "inbox": "inbox",
    "sent": "sent",
    "sent_items": "sent",
    "deleted_items": "trash",
}


def log(msg: str, verbose: bool = True):
    if verbose:
        print(msg, flush=True)


def fix_url(original_url: str) -> str:
    """Rewrite Stalwart's internal hostname to PUBLIC_HOSTNAME."""
    parsed = requests.utils.urlparse(original_url)
    new_parsed = parsed._replace(netloc=PUBLIC_HOSTNAME)
    return requests.utils.urlunparse(new_parsed)


def fetch_session(username: str, password: str) -> Dict[str, str]:
    resp = requests.get(
        f"{BASE_URL}/.well-known/jmap",
        auth=(username, password),
        proxies=proxies,
    )
    resp.raise_for_status()
    data = resp.json()
    return {
        "api_url": fix_url(data["apiUrl"]),
        "account_id": data["primaryAccounts"]["urn:ietf:params:jmap:mail"],
    }


def fetch_mailbox_id(
    api_url: str, auth: Tuple[str, str], account_id: str, role: str
) -> Optional[str]:
    payload = {
        "using": ["urn:ietf:params:jmap:core", "urn:ietf:params:jmap:mail"],
        "methodCalls": [
            [
                "Mailbox/query",
                {"accountId": account_id, "filter": {"role": role}},
                f"find_{role}",
            ]
        ],
    }
    resp = requests.post(api_url, auth=auth, proxies=proxies, json=payload)
    resp.raise_for_status()
    ids = resp.json()["methodResponses"][0][1]["ids"]
    return ids[0] if ids else None


def extract_addresses(value: str) -> List[str]:
    if not value:
        return []
    return [addr for _, addr in getaddresses([value]) if addr]


def parse_message(path: Path) -> Optional[Dict]:
    try:
        with path.open("rb") as f:
            msg = BytesParser(policy=policy.default).parse(f)
    except Exception:
        return None
    from_addr = parseaddr(msg.get("From", ""))[1]
    to_addrs = extract_addresses(msg.get("To", ""))
    cc_addrs = extract_addresses(msg.get("Cc", ""))
    subject = (msg.get("Subject") or "").strip() or "(No Subject)"
    if msg.is_multipart():
        parts = []
        for part in msg.walk():
            if part.get_content_type() == "text/plain":
                try:
                    parts.append(part.get_content())
                except Exception:
                    pass
        body = "\n".join(parts).strip()
    else:
        try:
            body = msg.get_content().strip()
        except Exception:
            body = ""
    body = body or "(No Body)"
    return {
        "from": from_addr,
        "to": to_addrs,
        "cc": cc_addrs,
        "subject": subject,
        "body": body,
    }


def normalize_address(addr: str, target_domain: str) -> Optional[str]:
    if not addr or "@" not in addr:
        return None
    local = addr.split("@")[0].strip().lower()
    if not local:
        return None
    return f"{local}@{target_domain}"


def load_messages(subdir: Path, limit: int) -> List[Dict]:
    if not subdir.is_dir():
        return []
    files = [
        p for p in subdir.iterdir() if p.is_file() and MAILDIR_FILE_RE.match(p.name)
    ]
    random.shuffle(files)
    msgs: List[Dict] = []
    for p in files:
        if len(msgs) >= limit:
            break
        parsed = parse_message(p)
        if parsed:
            msgs.append(parsed)
    return msgs


def build_creations(
    account_email: str,
    msgs: List[Dict],
    mailbox_id: str,
    target_domain: str,
    prefix: str,
    mark_seen: bool = False,
) -> Dict[str, Dict]:
    creations: Dict[str, Dict] = {}
    for idx, m in enumerate(msgs):
        if prefix == "s":
            # Sent: account is sender
            to_norm = [normalize_address(a, target_domain) for a in (m["to"] + m["cc"])]
            to_norm = [a for a in to_norm if a and a != account_email]
            to_norm = list(dict.fromkeys(to_norm))
            from_list = [{"name": account_email.split("@")[0], "email": account_email}]
            to_list = [{"name": t.split("@")[0], "email": t} for t in to_norm] or [
                {"name": account_email.split("@")[0], "email": account_email}
            ]
        else:
            # Inbox/Trash: someone else sent it
            sender = normalize_address(m["from"], target_domain) or account_email
            from_list = [{"name": sender.split("@")[0], "email": sender}]
            to_list = [{"name": account_email.split("@")[0], "email": account_email}]

        cid = f"{prefix}-{idx}"
        creations[cid] = {
            "mailboxIds": {mailbox_id: True},
            "keywords": {"$seen": True} if mark_seen else {},
            "from": from_list,
            "to": to_list,
            "subject": m["subject"],
            "textBody": [{"partId": "p", "type": "text/plain"}],
            "bodyValues": {"p": {"value": m["body"], "isTruncated": False}},
        }
    return creations


def submit_creations(
    api_url: str,
    auth: Tuple[str, str],
    account_id: str,
    creations: Dict[str, Dict],
    label: str,
    verbose: bool,
):
    if not creations:
        return 0
    # Submit in batches of 50 to avoid oversized requests
    batch_size = 50
    items = list(creations.items())
    total_created = 0
    for i in range(0, len(items), batch_size):
        batch = dict(items[i : i + batch_size])
        payload = {
            "using": ["urn:ietf:params:jmap:core", "urn:ietf:params:jmap:mail"],
            "methodCalls": [
                [
                    "Email/set",
                    {"accountId": account_id, "create": batch},
                    f"seed_{label}_{i}",
                ]
            ],
        }
        resp = requests.post(api_url, auth=auth, proxies=proxies, json=payload)
        if resp.status_code != 200:
            log(f"  [ERR] JMAP Email/set HTTP {resp.status_code}: {resp.text[:200]}")
            continue
        try:
            data = resp.json()["methodResponses"][0][1]
            created = len(data.get("created", {}))
            failed = data.get("notCreated", {})
            total_created += created
            if failed:
                log(f"  [WARN] {len(failed)} failures in batch")
        except Exception as e:
            log(f"  [ERR] Parse response: {e}")
    return total_created


def process_account(
    acct_dir: Path,
    email_local: str,
    target_domain: str,
    password: str,
    max_per_folder: int,
    verbose: bool,
) -> int:
    account_email = f"{email_local}@{target_domain}"
    log(f"  [{acct_dir.name}] -> {account_email}", verbose)

    # JMAP session
    try:
        sess = fetch_session(account_email, password)
    except Exception as e:
        log(f"  [ERR] JMAP session failed for {account_email}: {e}")
        return 0

    auth = (account_email, password)
    api_url = sess["api_url"]
    account_id = sess["account_id"]

    # Look up mailbox IDs
    mailboxes: Dict[str, Optional[str]] = {}
    for role in ("inbox", "sent", "trash"):
        try:
            mailboxes[role] = fetch_mailbox_id(api_url, auth, account_id, role)
        except Exception:
            mailboxes[role] = None
        log(f"    mailbox {role} = {mailboxes[role]}", verbose)

    total = 0

    for folder_name, jmap_role in FOLDER_ROLE_MAP.items():
        mbox_id = mailboxes.get(jmap_role)
        if not mbox_id:
            continue

        msgs = load_messages(acct_dir / folder_name, max_per_folder)
        if not msgs:
            continue

        prefix = folder_name[0]  # i, s, d
        mark_seen = jmap_role == "sent"

        creations = build_creations(
            account_email, msgs, mbox_id, target_domain, prefix, mark_seen
        )
        created = submit_creations(
            api_url,
            auth,
            account_id,
            creations,
            f"{email_local}_{folder_name}",
            verbose,
        )
        total += created
        log(f"    {folder_name}: {created}/{len(msgs)} imported", verbose)

    return total


def main():
    ap = argparse.ArgumentParser(description="Import Enron emails via JMAP")
    ap.add_argument(
        "--dataset", required=True, help="Root maildir directory (contains user dirs)"
    )
    ap.add_argument("--target-domain", default=TARGET_DOMAIN_DEFAULT)
    ap.add_argument("--password", default=DEFAULT_PASSWORD)
    ap.add_argument("--max-per-folder", type=int, default=50)
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()

    root = Path(args.dataset)
    if not root.is_dir():
        print(f"Dataset path {root} not found", file=sys.stderr)
        sys.exit(1)

    grand_total = 0
    processed = 0

    for dir_name, email_local in ENRON_USERS.items():
        # Processed dir uses email-local name (e.g. phillip.allen);
        # raw extracted dir uses the original Enron name (e.g. allen-p)
        acct_dir = root / email_local
        if not acct_dir.is_dir():
            acct_dir = root / dir_name
        if not acct_dir.is_dir():
            log(f"  [SKIP] {dir_name}: directory not found", args.verbose)
            continue

        log(f"=== {dir_name} ===")
        count = process_account(
            acct_dir,
            email_local,
            args.target_domain,
            args.password,
            args.max_per_folder,
            args.verbose,
        )
        grand_total += count
        processed += 1
        log(f"  Total for {email_local}: {count} emails")

    log(f"\n=== Done: {processed} accounts, {grand_total} emails imported ===")


if __name__ == "__main__":
    main()
