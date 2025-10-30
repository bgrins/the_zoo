# Universe Reference

Complete reference for universe JSON schemas.

## About This Document

This document describes the JSON schema for universe files. These JSON files define what data should exist in a universe.

**CLI commands** - Use `npm run cli -- universe ...` to build JSON programmatically (see [Universe CLI Reference](./universe-cli-reference.md))

## universe.json

The main metadata file for a universe.

### Schema

```typescript
{
  id: string;              // Required: Unique identifier, must match directory name
  name?: string;           // Optional: Human-readable name
  description?: string;    // Optional: Description of this universe
  version?: string;        // Optional: Semantic version (e.g., "1.0.0")
  personas: string[];      // Required: Array of persona usernames
}
```

### Example

```json
{
  "id": "default",
  "name": "Default Universe",
  "description": "Basic populated environment with common test data",
  "version": "1.0.0",
  "personas": ["alice", "bob", "charlie"]
}
```

### Field Details

#### `id` (required)

- Type: `string`
- Must match the universe directory name
- Use lowercase with hyphens: `my-universe`, not `My Universe` or `my_universe`
- Must be unique across all universes

#### `name` (optional)

- Type: `string`
- Human-readable display name
- Can include spaces and capitalization

#### `description` (optional)

- Type: `string`
- Describe the purpose and use case for this universe
- Helpful for documentation and sharing

#### `version` (optional)

- Type: `string`
- Semantic versioning recommended: `MAJOR.MINOR.PATCH`
- Useful for tracking universe iterations

#### `personas` (required)

- Type: `string[]`
- Array of persona usernames from `scripts/seed-data/personas.ts`
- Valid values: `admin`, `alice`, `bob`, `charlie`, `diana`, `eve`, `frank`, `grace`, `demo`, `user1`, `alex.chen`, `blake.sullivan`, `mallory`
- Personas are automatically created in all apps

## apps/snappymail.zoo/emails.json

Email messages to populate across user inboxes.

**Note:** This section covers the JSON schema for defining emails in universes. For operational email usage (sending/receiving emails, accessing inboxes, SMTP configuration), see [Email API](./email-api.md).

### Schema

```typescript
{
  from: string;                    // Required: Sender email
  to: string | string[];           // Required: Recipient(s)
  subject: string;                 // Required: Email subject
  body: string;                    // Required: Email body (plain text or HTML)
  date?: string;                   // Optional: ISO 8601 timestamp
  cc?: string | string[];          // Optional: CC recipients
  html?: boolean;                  // Optional: true if body is HTML
}[]
```

### Example

```json
[
  {
    "from": "bob@snappymail.zoo",
    "to": "alice@snappymail.zoo",
    "subject": "Quarterly report",
    "body": "Please review the attached Q4 report.",
    "date": "2025-01-20T14:30:00Z"
  },
  {
    "from": "alice@snappymail.zoo",
    "to": ["bob@snappymail.zoo", "charlie@snappymail.zoo"],
    "subject": "Team meeting",
    "body": "<h1>Agenda</h1><ul><li>Project updates</li></ul>",
    "html": true,
    "cc": "diana@snappymail.zoo"
  }
]
```

### Field Details

#### `from` (required)

- Type: `string`
- Must be valid email address
- Should use `@snappymail.zoo` domain
- User must exist in universe personas (email accounts created automatically)
- See [Email API](./email-api.md#email-accounts) for account management

#### `to` (required)

- Type: `string | string[]`
- Single recipient: `"alice@snappymail.zoo"`
- Multiple recipients: `["alice@snappymail.zoo", "bob@snappymail.zoo"]`
- All recipients should exist in universe personas

#### `subject` (required)

- Type: `string`
- Email subject line
- Can be empty string but must be present

#### `body` (required)

- Type: `string`
- Email content
- Plain text by default
- HTML if `html: true` is set

#### `date` (optional)

- Type: `string`
- ISO 8601 format: `YYYY-MM-DDTHH:mm:ssZ`
- Defaults to current timestamp if not specified
- Useful for creating realistic timelines

#### `cc` (optional)

- Type: `string | string[]`
- Carbon copy recipients
- Same format as `to` field

#### `html` (optional)

- Type: `boolean`
- Set to `true` if `body` contains HTML
- Defaults to `false` (plain text)

## apps/gitea.zoo/repositories.json

Git repositories to create in Gitea.

### Schema

```typescript
{
  name: string;                    // Required: Repository name
  owner: string;                   // Required: Owner username
  description?: string;            // Optional: Repository description
  private?: boolean;               // Optional: Private repository
  defaultBranch?: string;          // Optional: Default branch name
  files?: {                        // Optional: Initial files
    path: string;                  // Required: File path
    content: string;               // Required: File content
    branch?: string;               // Optional: Branch name
    message?: string;              // Optional: Commit message
  }[];
}[]
```

### Example

```json
[
  {
    "name": "my-project",
    "owner": "alice",
    "description": "A sample project",
    "private": false,
    "defaultBranch": "main",
    "files": [
      {
        "path": "README.md",
        "content": "# My Project\n\nWelcome!",
        "message": "Initial commit"
      },
      {
        "path": "src/index.js",
        "content": "console.log('Hello World');",
        "message": "Add main file"
      }
    ]
  }
]
```

### Field Details

#### `name` (required)

- Type: `string`
- Repository name
- Will appear as `gitea.zoo/{owner}/{name}`
- Use lowercase with hyphens for consistency

#### `owner` (required)

- Type: `string`
- Username from universe personas
- Must be a valid persona in the universe

#### `description` (optional)

- Type: `string`
- Repository description
- Shown on repository page

#### `private` (optional)

- Type: `boolean`
- Default: `false`
- If `true`, only owner can access

#### `defaultBranch` (optional)

- Type: `string`
- Default: `"main"`
- Name of the default branch

#### `files` (optional)

- Type: `array`
- Initial files to commit to repository
- Each file creates a separate commit

#### `files[].path` (required if files present)

- Type: `string`
- Relative path from repository root
- Can include directories: `src/components/App.tsx`

#### `files[].content` (required if files present)

- Type: `string`
- File content
- Use `\n` for newlines in JSON strings

#### `files[].branch` (optional)

- Type: `string`
- Default: `defaultBranch` value
- Branch to commit to

#### `files[].message` (optional)

- Type: `string`
- Default: `"Add {path}"`
- Commit message for this file

## See Also

- [Creating Universes](./creating-universes.md) - Step-by-step tutorials for creating universes
- [Universe CLI Reference](./universe-cli-reference.md) - CLI commands for building universes programmatically
- [Universes and Scenarios](./universes-and-scenarios.md) - Architecture and concepts overview
- [Email API](./email-api.md) - Email operations and SMTP guide
