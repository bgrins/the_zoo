# Universe CLI Reference

Complete reference for universe management CLI commands.

## Overview

The universe CLI provides commands to create and manage universes programmatically. All commands modify JSON files in the `universes/` directory.

**Important:** CLI commands only create/modify JSON files. No users or data are created until you run `npm run universe:load {name}`.

## Core Commands

### `universe create`

Create a new universe with metadata and directory structure.

**Usage:**

```bash
npm run cli -- universe create <universe-id> [options]
```

**Arguments:**

- `<universe-id>` - Unique identifier (required, becomes directory name)

**Options:**

- `--name <string>` - Human-readable name
- `--description <string>` - Description of the universe
- `--version <string>` - Semantic version (e.g., "1.0.0")
- `--personas <list>` - Comma-separated list of persona usernames (required)

**Example:**

```bash
npm run cli -- universe create my-universe \
  --name "My Test Universe" \
  --description "A universe for testing email workflows" \
  --version "1.0.0" \
  --personas alice,bob,charlie
```

**Creates:**

```
universes/my-universe/
  universe.json
  apps/
    snappymail.zoo/
    gitea.zoo/
```

**universe.json:**

```json
{
  "id": "my-universe",
  "name": "My Test Universe",
  "description": "A universe for testing email workflows",
  "version": "1.0.0",
  "personas": ["alice", "bob", "charlie"]
}
```

---

### `universe add-email`

Add an email to a universe's email data.

**Usage:**

```bash
npm run cli -- universe add-email <universe-id> [options]
```

**Arguments:**

- `<universe-id>` - Universe to add email to (required)

**Options:**

- `--from <email>` - Sender email address (required)
- `--to <email|list>` - Recipient(s), comma-separated for multiple (required)
- `--subject <string>` - Email subject (required)
- `--body <string>` - Email body (required)
- `--date <iso-date>` - ISO 8601 timestamp (optional)
- `--cc <email|list>` - CC recipients, comma-separated (optional)
- `--html` - Body contains HTML (optional, flag)

**Example:**

```bash
npm run cli -- universe add-email my-universe \
  --from alice@snappymail.zoo \
  --to bob@snappymail.zoo \
  --subject "Weekly Report" \
  --body "Here's the weekly report..." \
  --date "2025-01-20T14:00:00Z"
```

**Multiple recipients:**

```bash
npm run cli -- universe add-email my-universe \
  --from admin@snappymail.zoo \
  --to alice@snappymail.zoo,bob@snappymail.zoo,charlie@snappymail.zoo \
  --cc diana@snappymail.zoo \
  --subject "Team Meeting" \
  --body "Don't forget the meeting tomorrow"
```

**HTML email:**

```bash
npm run cli -- universe add-email my-universe \
  --from alice@snappymail.zoo \
  --to bob@snappymail.zoo \
  --subject "Report" \
  --body "<h1>Q1 Results</h1><p>Revenue up 25%</p>" \
  --html
```

**Updates:** `universes/my-universe/apps/snappymail.zoo/emails.json`

---

### `universe add-repo`

Add a Git repository to a universe.

**Usage:**

```bash
npm run cli -- universe add-repo <universe-id> [options]
```

**Arguments:**

- `<universe-id>` - Universe to add repository to (required)

**Options:**

- `--name <string>` - Repository name (required)
- `--owner <username>` - Owner username from personas (required)
- `--description <string>` - Repository description (optional)
- `--private` - Make repository private (optional, flag)
- `--default-branch <string>` - Default branch name (optional, default: "main")

**Example:**

```bash
npm run cli -- universe add-repo my-universe \
  --name awesome-project \
  --owner alice \
  --description "An awesome project" \
  --default-branch main
```

**Private repository:**

```bash
npm run cli -- universe add-repo my-universe \
  --name secret-project \
  --owner bob \
  --description "Top secret" \
  --private
```

**Updates:** `universes/my-universe/apps/gitea.zoo/repositories.json`

**Note:** File creation within repositories is not yet supported via CLI. Use manual JSON editing for initial files.

---

### `universe add-persona`

Add a persona to an existing universe.

**Usage:**

```bash
npm run cli -- universe add-persona <universe-id> <username>
```

**Arguments:**

- `<universe-id>` - Universe to add persona to (required)
- `<username>` - Persona username from `scripts/seed-data/personas.ts` (required)

**Example:**

```bash
npm run cli -- universe add-persona my-universe diana
```

**Updates:** `universes/my-universe/universe.json` personas array

**Effect:** When universe is loaded, diana will be created in all services alongside existing personas.

---

### `universe list`

List all available universes.

**Usage:**

```bash
npm run cli -- universe list
```

**Output:**

```
Available universes:
  • default
  • my-universe
  • team-project
```

---

### `universe info`

Display information about a universe.

**Usage:**

```bash
npm run cli -- universe info <universe-id>
```

**Example:**

```bash
npm run cli -- universe info my-universe
```

**Output:**

```
Universe: My Test Universe (my-universe)
Version: 1.0.0
Description: A universe for testing email workflows
Personas: alice, bob, charlie

Data:
  • 3 emails in snappymail.zoo
  • 2 repositories in gitea.zoo
```

---

## Loading Universes

After creating/modifying a universe, load it to populate The Zoo:

```bash
npm run universe:load <universe-id>
```

This command:

1. Reads JSON files from `universes/<universe-id>/`
2. Creates users for all personas across all services
3. Populates data (sends emails, creates repos, etc.)
4. Reports success/failures

### Idempotency

Loading the same universe multiple times is safe - existing users/data won't be duplicated (though some services may report "already exists").

## See Also

- [Creating Universes](./creating-universes.md) - Step-by-step tutorials
- [Universe Reference](./universe-reference.md) - JSON schema reference
- [Universes and Scenarios](./universes-and-scenarios.md) - Architecture overview
