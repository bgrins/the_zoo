# Enron Email Dataset Seeding

This document describes how to populate the Zoo's mail stack ([snappymail.zoo](https://snappymail.zoo) + Stalwart) with the [CMU Enron email corpus](https://www.cs.cmu.edu/~enron/) — roughly 500,000 real emails from ~150 Enron employees, curated down to 20 key accounts.

This is **opt-in**. The Zoo works normally without it. You only need this if you want pre-populated email inboxes.

---

## How it works

1. A preparation script downloads the dataset, creates user accounts in Stalwart, imports emails via JMAP, and dumps the resulting Stalwart PostgreSQL database.
2. That dump is placed in `core/postgres/seed/` so the postgres Docker image picks it up at build time.
3. Building postgres with `ENRON_SEED=true` bakes the Enron data into the golden state — every `npm run reset` or fresh start restores it instantly.

All Enron `@enron.com` addresses are rewritten to `@enron.zoo` so they route through the local Stalwart instance.

---

## Prerequisites

- The Zoo is running: `npm start`
- `python3` with `pip` available on the host
- `curl`, `xz`, `openssl` available on the host (standard on most Linux distros)
- At least **2 GB** free disk space for the download + extraction

---

## First-time setup (generating the dump)

This only needs to be done once. After the dump exists in `core/postgres/seed/`, anyone can build with `ENRON_SEED=true` without re-running this.

### 1. Start the Zoo

```bash
npm start
```

Wait until all core services are healthy.

### 2. Run the preparation script

```bash
cd scripts/uploads
./enron-prepare.sh
```

What it does, step by step:

| Step          | Description                                                               | Skipped if...            |
| ------------- | ------------------------------------------------------------------------- | ------------------------ |
| Download      | Fetches `enron_mail_20150507.tar.gz` (~423 MB) from CMU                   | Tarball already exists   |
| Extract       | Unpacks to `scripts/uploads/enron/maildir/`                               | Directory already exists |
| Rewrite       | Copies 20 user dirs to `processed/`, rewrites `@enron.com` → `@enron.zoo` | —                        |
| Create domain | POSTs `enron.zoo` domain to Stalwart API                                  | 409 = already exists     |
| Create users  | Creates 20 user accounts in Stalwart                                      | 409 = already exists     |
| Import emails | Imports via JMAP `Email/set` (inbox + sent + trash)                       | —                        |
| Dump          | `pg_dump stalwart_db` → `stalwart_enron.sql.xz`                           | —                        |
| Copy          | Copies the dump to `core/postgres/seed/`                                  | —                        |

Expected runtime: **20–40 minutes** depending on machine speed (mostly the JMAP import).

#### Optional: control how many emails are imported

```bash
# Default: 50 emails per folder per account
./enron-prepare.sh

# More emails (slower, larger dump)
MAX_EMAILS_PER_FOLDER=200 ./enron-prepare.sh

# All emails (very slow, large dump)
MAX_EMAILS_PER_FOLDER=0 ./enron-prepare.sh
```

### 3. Verify the dump was created

```bash
ls -lh core/postgres/seed/stalwart_enron.sql.xz
```

You should see a file in the range of a few hundred MB.

---

## Building with Enron data

Once the dump exists in `core/postgres/seed/`, rebuild postgres:

```bash
ENRON_SEED=true docker compose build postgres
docker compose up -d
```

Or set it persistently in your `.env`:

```bash
# .env
ENRON_SEED=true
```

Then just:

```bash
npm run reset   # or npm start
```

To go back to the default (no Enron data):

```bash
docker compose build postgres   # rebuilds without ENRON_SEED
docker compose up -d
```

---

## Logging in

Go to [snappymail.zoo](https://snappymail.zoo) and log in with any of the 20 Enron accounts:

| Name              | Email                       | Password       |
| ----------------- | --------------------------- | -------------- |
| Phillip Allen     | `phillip.allen@enron.zoo`   | `EnronZoo.123` |
| Eric Bass         | `eric.bass@enron.zoo`       | `EnronZoo.123` |
| Sally Beck        | `sally.beck@enron.zoo`      | `EnronZoo.123` |
| Lynn Blair        | `lynn.blair@enron.zoo`      | `EnronZoo.123` |
| Larry Campbell    | `larry.campbell@enron.zoo`  | `EnronZoo.123` |
| Michelle Cash     | `michelle.cash@enron.zoo`   | `EnronZoo.123` |
| Jeff Dasovich     | `jeff.dasovich@enron.zoo`   | `EnronZoo.123` |
| Dana Davis        | `dana.davis@enron.zoo`      | `EnronZoo.123` |
| David Delainey    | `david.delainey@enron.zoo`  | `EnronZoo.123` |
| James Derrick Jr. | `james.derrick@enron.zoo`   | `EnronZoo.123` |
| Daren Farmer      | `daren.farmer@enron.zoo`    | `EnronZoo.123` |
| Chris Germany     | `chris.germany@enron.zoo`   | `EnronZoo.123` |
| John Griffith     | `john.griffith@enron.zoo`   | `EnronZoo.123` |
| Mark Haedicke     | `mark.haedicke@enron.zoo`   | `EnronZoo.123` |
| Vince Kaminski    | `vince.kaminski@enron.zoo`  | `EnronZoo.123` |
| Louise Kitchen    | `louise.kitchen@enron.zoo`  | `EnronZoo.123` |
| John Lavorato     | `john.lavorato@enron.zoo`   | `EnronZoo.123` |
| Kenneth Lay       | `kenneth.lay@enron.zoo`     | `EnronZoo.123` |
| Sara Shackleton   | `sara.shackleton@enron.zoo` | `EnronZoo.123` |
| Jeff Skilling     | `jeff.skilling@enron.zoo`   | `EnronZoo.123` |

Each account has emails in **Inbox**, **Sent**, and **Trash** (where source data existed).

---

## Sharing the dump via R2 (optional)

If you want other machines or CI to use the dump without re-running the preparation script, upload it to R2:

```bash
# Install rclone (no sudo needed)
mkdir -p ~/.local/bin
curl -fsSL https://downloads.rclone.org/rclone-current-linux-amd64.zip -o /tmp/rclone.zip
unzip -q /tmp/rclone.zip -d /tmp/rclone-tmp
cp /tmp/rclone-tmp/*/rclone ~/.local/bin/
export PATH="$HOME/.local/bin:$PATH"

# Configure R2 remote (one-time)
rclone config  # create remote named 'r2', provider Cloudflare R2

# Upload
rclone copy scripts/uploads/enron/stalwart_enron.sql.xz r2:the-zoo/enron/ -v --progress
```

Once uploaded, the postgres Dockerfile will automatically download it from R2 on machines that don't have the local seed file.

---

## Resuming a failed/interrupted run

All steps are idempotent or skip-if-exists:

- **Download**: resumes with `-C -` (curl continue)
- **Extract**: skips if `maildir/` already exists
- **Rewrite**: re-processes from scratch each run
- **Domain/User creation**: 409 responses are treated as success
- **JMAP import**: re-runs (emails may be duplicated if run twice — restart the Zoo first if needed)
- **Dump**: overwrites previous dump

To start completely fresh:

```bash
rm -rf scripts/uploads/enron/
npm run reset
./scripts/uploads/enron-prepare.sh
```

---

## Files

| File                                                       | Description                         |
| ---------------------------------------------------------- | ----------------------------------- |
| `scripts/uploads/enron-prepare.sh`                         | Main preparation script             |
| `scripts/uploads/enron-import-jmap.py`                     | Python JMAP email importer          |
| `scripts/seed-data/enron.ts`                               | User list (shared with seed script) |
| `core/postgres/seed/stalwart_enron.sql.xz`                 | Generated dump (gitignored)         |
| `sites/apps/snappymail.zoo/data-golden/.../enron.zoo.json` | SnappyMail domain config            |
