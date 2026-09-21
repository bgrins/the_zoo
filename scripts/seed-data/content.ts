// Content the personas share across apps, seeded once they exist (see scripts/seed.ts).
// Times are UTC; each app gets them as its rows' timestamps.

export interface GiteaComment {
  by: string;
  at: string;
  body: string;
}

export interface GiteaIssue {
  // owner/name
  repo: string;
  // The number Gitea gives it: issues and pull requests count up together per repo, in the
  // order they're opened here
  number: number;
  by: string;
  at: string;
  title: string;
  body: string;
  // Applied by the repo's maintainer when the issue is opened
  labels?: string[];
  milestone?: string;
  assignees?: string[];
  comments?: GiteaComment[];
  closed?: { by: string; at: string };
  // A pull request from a branch with one commit by the author
  pull?: {
    branch: string;
    base: string;
    commit: { at: string; message: string; files: Record<string, string> };
    review?: {
      by: string;
      at: string;
      body: string;
      comments: { path: string; line: number; body: string }[];
    };
  };
}

export interface GiteaLabel {
  name: string;
  color: string;
  description: string;
}

const bug = { name: "bug", color: "#d73a4a", description: "Something isn't working" };
const enhancement = {
  name: "enhancement",
  color: "#a2eeef",
  description: "New feature or request",
};

export const gitea = {
  // When the teams, labels and milestones were set up
  setupAt: "2026-08-20T09:00:00Z",
  // Each team gets all of its org's repositories
  teams: [
    {
      org: "zoo-labs",
      name: "developers",
      permission: "write",
      members: ["alice", "bob", "grace", "alex.chen"],
    },
    { org: "community", name: "maintainers", permission: "admin", members: ["charlie"] },
  ],
  // Who triages each repo's issues
  maintainers: {
    "zoo-labs/zoo-utilities": "alice",
    "alice/hello-zoo": "alice",
    "bob/zoo-api-client": "bob",
    "community/awesome-zoo": "charlie",
  } as Record<string, string>,
  labels: {
    "zoo-labs/zoo-utilities": [
      bug,
      {
        name: "documentation",
        color: "#0075ca",
        description: "Improvements or additions to documentation",
      },
      enhancement,
      { name: "security", color: "#b60205", description: "Security vulnerabilities and hardening" },
    ],
    "alice/hello-zoo": [
      bug,
      enhancement,
      { name: "good first issue", color: "#7057ff", description: "Good for newcomers" },
      { name: "question", color: "#d876e3", description: "Further information is requested" },
    ],
    "bob/zoo-api-client": [bug, enhancement],
    "community/awesome-zoo": [
      { name: "new entry", color: "#0e8a16", description: "Suggests a resource to add" },
      { name: "broken link", color: "#fbca04", description: "A link or section that goes nowhere" },
    ],
  } as Record<string, GiteaLabel[]>,
  milestones: [
    {
      repo: "zoo-labs/zoo-utilities",
      title: "v1.3.0",
      description: "Token and module fixes for the next release",
      due: "2026-10-15",
    },
    {
      repo: "bob/zoo-api-client",
      title: "0.2.0",
      description: "Error handling and request options",
      due: "2026-10-01",
    },
  ],
  issues: [
    {
      repo: "alice/hello-zoo",
      number: 1,
      by: "frank",
      at: "2026-08-24T10:15:00Z",
      title: "Read the port from the PORT environment variable",
      body: "`index.js` hard-codes port 3000, which clashes with other services when we run it in a container. Could it use `process.env.PORT` and fall back to 3000?",
      labels: ["enhancement", "good first issue"],
      comments: [
        {
          by: "alice",
          at: "2026-08-24T12:40:00Z",
          body: "Makes sense. Happy to take a PR for this one.",
        },
      ],
    },
    {
      repo: "alice/hello-zoo",
      number: 2,
      by: "diana",
      at: "2026-08-28T15:30:00Z",
      title: "The welcome page has no styling or title",
      body: "The README promises a zoo-themed welcome page, but `/` returns a bare `<h1>` with no `<title>`. I can put together a simple layout with the zoo colors if that's welcome.",
      labels: ["enhancement"],
      comments: [
        {
          by: "alice",
          at: "2026-08-28T17:05:00Z",
          body: "Yes please! Keep it to a single HTML string in `index.js` for now.",
        },
      ],
    },
    {
      repo: "community/awesome-zoo",
      number: 1,
      by: "mallory",
      at: "2026-08-31T18:45:00Z",
      title: "Add Zoo Docker Templates to Community Projects",
      body: "https://gitea.zoo/charlie/zoo-docker-templates has ready-to-use Docker setups for zoo services and isn't on the list yet.",
      labels: ["new entry"],
      comments: [
        {
          by: "charlie",
          at: "2026-09-01T08:20:00Z",
          body: "Good idea, I'll add it. PRs welcome too!",
        },
      ],
    },
    {
      repo: "zoo-labs/zoo-utilities",
      number: 1,
      by: "grace",
      at: "2026-09-01T09:12:00Z",
      title: "generateToken uses Math.random, which is not secure",
      body: "`lib/auth.js` builds tokens from `Math.random().toString(36)`. The output is predictable and only about 11 characters long, so it shouldn't be used for session or password reset tokens.\n\nWe should use `crypto.randomBytes` instead.",
      labels: ["bug", "security"],
      milestone: "v1.3.0",
      assignees: ["alice"],
      comments: [
        {
          by: "alice",
          at: "2026-09-01T10:03:00Z",
          body: "Agreed. I'll open a PR that switches to `crypto.randomBytes(32)` and hex-encodes the result.",
        },
        {
          by: "blake.sullivan",
          at: "2026-09-02T08:30:00Z",
          body: "Thanks both. This one blocks v1.3.0.",
        },
      ],
    },
    {
      repo: "bob/zoo-api-client",
      number: 1,
      by: "charlie",
      at: "2026-09-02T13:05:00Z",
      title: "getAnimals() doesn't check the response status",
      body: "When misc.zoo answers with a 500, `getAnimals()` calls `response.json()` on the error page and throws a `SyntaxError`, which hides the real problem. It should check `response.ok` and throw an error that includes the status.",
      labels: ["bug"],
      milestone: "0.2.0",
      assignees: ["bob"],
      comments: [
        {
          by: "bob",
          at: "2026-09-02T16:10:00Z",
          body: "Good catch. I'll add an `ApiError` class with `status` and `url`.",
        },
        {
          by: "alex.chen",
          at: "2026-09-03T09:00:00Z",
          body: "+1. Please include the response body too; misc.zoo returns its errors as JSON.",
        },
      ],
    },
    {
      repo: "zoo-labs/zoo-utilities",
      number: 2,
      by: "alex.chen",
      at: "2026-09-03T14:20:00Z",
      title: "require('@zoo-labs/utilities') fails: lib/db.js is missing",
      body: "`index.js` requires `./lib/db` and `./lib/validators`, but neither file is in the repo, so importing the package throws:\n\n```\nError: Cannot find module './lib/db'\n```\n\nEither add the modules or drop them from `index.js`.",
      labels: ["bug"],
      milestone: "v1.3.0",
      assignees: ["alex.chen"],
      comments: [
        {
          by: "bob",
          at: "2026-09-03T15:02:00Z",
          body: "Confirmed on a clean install. I'd rather add minimal modules than change the exports.",
        },
      ],
    },
    {
      repo: "bob/zoo-api-client",
      number: 2,
      by: "alex.chen",
      at: "2026-09-04T10:30:00Z",
      title: "Add a request timeout option",
      body: "Requests to a stopped service hang until the OS gives up. A `timeout` option in the `ZooClient` config, passed to an `AbortController`, would let callers fail fast.",
      labels: ["enhancement"],
      milestone: "0.2.0",
    },
    {
      repo: "zoo-labs/zoo-utilities",
      number: 3,
      by: "eve",
      at: "2026-09-04T16:40:00Z",
      title: "validateToken accepts any non-empty string",
      body: "`validateToken('x')` returns `true`. I expected it to reject strings that `generateToken` could never produce.",
      labels: ["bug"],
      comments: [
        {
          by: "alice",
          at: "2026-09-05T14:05:00Z",
          body: "Same root cause as #1: tokens have no fixed format yet. #4 makes them 64 hex characters and checks for exactly that, so I'm closing this as a duplicate.",
        },
      ],
      closed: { by: "alice", at: "2026-09-05T14:06:00Z" },
    },
    {
      repo: "zoo-labs/zoo-utilities",
      number: 4,
      by: "alice",
      at: "2026-09-05T13:52:00Z",
      title: "Generate auth tokens with crypto.randomBytes",
      body: "Fixes #1.\n\n- `generateToken` returns 32 random bytes, hex-encoded\n- `validateToken` accepts only 64 hex characters",
      labels: ["security"],
      milestone: "v1.3.0",
      assignees: ["alice"],
      comments: [
        {
          by: "alice",
          at: "2026-09-07T11:30:00Z",
          body: "Good idea. I'll add an optional `bytes` argument that defaults to 32.",
        },
      ],
      pull: {
        branch: "alice/secure-tokens",
        base: "master",
        commit: {
          at: "2026-09-05T13:40:00Z",
          message: "Generate auth tokens with crypto.randomBytes",
          files: {
            "lib/auth.js": `// Authentication utilities
const crypto = require('crypto');

module.exports = {
  generateToken: () => {
    return crypto.randomBytes(32).toString('hex');
  },
  validateToken: (token) => {
    return typeof token === 'string' && /^[0-9a-f]{64}$/.test(token);
  }
};
`,
          },
        },
        review: {
          by: "grace",
          at: "2026-09-07T09:05:00Z",
          body: "Looks good to me, one question inline.",
          comments: [
            {
              path: "lib/auth.js",
              line: 6,
              body: "Could the byte count be an argument? The invite links in zoo-api-client want shorter tokens.",
            },
          ],
        },
      },
    },
    {
      repo: "community/awesome-zoo",
      number: 2,
      by: "diana",
      at: "2026-09-06T12:10:00Z",
      title: "The Tools and Tutorials sections are empty",
      body: "The table of contents links to Tools and Tutorials, but the README has no such sections, so both links go nowhere.",
      labels: ["broken link"],
      assignees: ["charlie"],
    },
    {
      repo: "bob/zoo-api-client",
      number: 3,
      by: "bob",
      at: "2026-09-08T10:00:00Z",
      title: "Build with esbuild instead of tsc",
      body: "Cuts the build from about 3 seconds to under 100 ms.",
      comments: [
        {
          by: "alex.chen",
          at: "2026-09-08T11:30:00Z",
          body: "esbuild doesn't emit `.d.ts` files, and `types` points at `dist/index.d.ts`. We'd still need `tsc --emitDeclarationOnly`, so the build wouldn't get simpler.",
        },
        {
          by: "bob",
          at: "2026-09-08T12:02:00Z",
          body: "Fair point, and the build is fast enough. Closing.",
        },
      ],
      closed: { by: "bob", at: "2026-09-08T12:03:00Z" },
      pull: {
        branch: "esbuild",
        base: "master",
        commit: {
          at: "2026-09-08T09:40:00Z",
          message: "Build with esbuild",
          files: {
            "package.json": `{
  "name": "zoo-api-client",
  "version": "0.1.0",
  "description": "API client for Zoo services",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "scripts": {
    "build": "esbuild src/index.ts --bundle --platform=node --outfile=dist/index.js",
    "test": "jest"
  },
  "devDependencies": {
    "@types/node": "^18.0.0",
    "esbuild": "^0.23.0",
    "typescript": "^5.0.0"
  }
}
`,
          },
        },
      },
    },
    {
      repo: "alice/hello-zoo",
      number: 3,
      by: "user1",
      at: "2026-09-11T11:20:00Z",
      title: "How do I run this on a different port?",
      body: "Port 3000 is taken on my machine. Is there a flag for the port?",
      labels: ["question"],
      comments: [
        {
          by: "alice",
          at: "2026-09-11T13:00:00Z",
          body: "Not yet: change `port` in `index.js` for now. #1 tracks reading it from `PORT`, so I'm closing this one.",
        },
      ],
      closed: { by: "alice", at: "2026-09-11T13:01:00Z" },
    },
  ] as GiteaIssue[],
};
