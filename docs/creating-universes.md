# Creating Your First Universe

This tutorial will guide you through creating a custom universe for The Zoo.

## Prerequisites

- The Zoo is installed and running (`npm start`)
- All Docker containers are running

## Creating Universes

**CLI Commands**

- Use `npm run cli -- universe ...` commands
- Build JSON files programmatically
- Easier for complex or dynamic universes
- See [Universe CLI Reference](./universe-cli-reference.md) for complete command documentation

---

## Tutorial: CLI-Based Creation (Programmatic)

In this example we create the "Team Project" universe using CLI commands.

### Step 1: Create Universe Structure

```bash
npm run cli -- universe create team-project \
  --name "Team Project" \
  --description "Alice and Bob collaborating on a project" \
  --personas alice,bob
```

This creates:

- `universes/team-project/universe.json`
- `universes/team-project/apps/` directory structure

### Step 2: Add Email Data

```bash
npm run cli -- universe add-email team-project \
  --from bob@snappymail.zoo \
  --to alice@snappymail.zoo \
  --subject "Project kickoff" \
  --body "Hey Alice, excited to start working on this project with you!" \
  --date "2025-01-15T09:00:00Z"

npm run cli -- universe add-email team-project \
  --from alice@snappymail.zoo \
  --to bob@snappymail.zoo \
  --subject "Re: Project kickoff" \
  --body "Me too! Let's set up a repo on Gitea." \
  --date "2025-01-15T10:30:00Z"
```

### Step 3: Add Repository Data

```bash
npm run cli -- universe add-repo team-project \
  --name project-alpha \
  --owner alice \
  --description "Our awesome project" \
  --default-branch main
```

### Step 4: Load the Universe

```bash
npm run universe:load team-project
```

This reads the JSON files created by the CLI commands and:

1. Creates alice and bob in all services (auth.zoo, gitea.zoo, snappymail.zoo)
2. Sends the 2 emails
3. Creates the project-alpha repository

### Step 5: Verify

Same as Tutorial 1 - check SnappyMail and Gitea to see the data.
