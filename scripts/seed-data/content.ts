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
      due: "2030-10-15",
    },
    {
      repo: "bob/zoo-api-client",
      title: "0.2.0",
      description: "Error handling and request options",
      due: "2030-10-01",
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
          body: "+1. Please include the response body too; misc.zoo says what went wrong in its errors.",
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

export interface MattermostPost {
  by: string;
  at: string;
  message: string;
  reactions?: { by: string; emoji: string; at: string }[];
  replies?: { by: string; at: string; message: string }[];
}

export const mattermost = {
  // Channels to create; every team member is already in town-square and off-topic
  channels: [
    {
      team: "zoo",
      name: "engineering",
      displayName: "Engineering",
      purpose: "Day-to-day engineering discussion",
      header: "Code lives at https://gitea.zoo/zoo-labs",
      by: "blake.sullivan",
      at: "2026-08-31T08:40:00Z",
      members: ["alice", "bob", "charlie", "eve", "frank", "grace", "alex.chen", "blake.sullivan"],
    },
    {
      team: "zoo",
      name: "design",
      displayName: "Design",
      purpose: "UI, UX and brand reviews",
      header: "",
      by: "diana",
      at: "2026-08-31T08:50:00Z",
      members: ["alice", "bob", "diana", "mallory"],
    },
    {
      team: "platform",
      name: "incidents",
      displayName: "Incidents",
      purpose: "Outages, their fixes and postmortems",
      header: "",
      by: "frank",
      at: "2026-08-31T09:30:00Z",
      members: ["alice", "frank", "grace", "alex.chen", "blake.sullivan", "eve"],
    },
  ],
  // team/channel -> root posts, oldest first
  posts: {
    "zoo/town-square": [
      {
        by: "blake.sullivan",
        at: "2026-08-31T09:00:00Z",
        message:
          "Welcome to the Zoo workspace! Engineering chat is in ~engineering and design reviews are in ~design. Please add your full name to your profile so people know who you are.",
        reactions: [
          { by: "alice", emoji: "+1", at: "2026-08-31T09:05:00Z" },
          { by: "diana", emoji: "wave", at: "2026-08-31T09:12:00Z" },
          { by: "bob", emoji: "+1", at: "2026-08-31T09:20:00Z" },
        ],
      },
      {
        by: "admin",
        at: "2026-09-01T07:30:00Z",
        message:
          "Heads-up: gitea.zoo will be read-only on Saturday, September 12 from 08:00 to 09:00 UTC for maintenance.",
        replies: [
          {
            by: "frank",
            at: "2026-09-01T07:45:00Z",
            message: "Thanks. I'll pause the nightly mirror sync during the window.",
          },
        ],
      },
      {
        by: "bob",
        at: "2026-09-11T16:00:00Z",
        message:
          "Demo day is Friday, September 18 at 15:00 UTC. Reply in this thread with what you'd like to show.",
        replies: [
          {
            by: "alice",
            at: "2026-09-11T16:20:00Z",
            message: "The new token handling in zoo-utilities.",
          },
          {
            by: "diana",
            at: "2026-09-11T17:05:00Z",
            message: "Mockups for the hello-zoo welcome page.",
          },
          {
            by: "charlie",
            at: "2026-09-12T09:10:00Z",
            message: "Traffic trends from analytics.zoo.",
          },
        ],
      },
    ],
    "zoo/engineering": [
      {
        by: "grace",
        at: "2026-09-01T09:20:00Z",
        message:
          "I filed zoo-labs/zoo-utilities#1: `generateToken` uses `Math.random`. Treat any token it has issued as guessable.",
        reactions: [
          { by: "alice", emoji: "eyes", at: "2026-09-01T09:25:00Z" },
          { by: "alex.chen", emoji: "+1", at: "2026-09-01T09:31:00Z" },
        ],
        replies: [
          {
            by: "alice",
            at: "2026-09-01T10:05:00Z",
            message: "I'll take it. PR by the end of the week.",
          },
          {
            by: "blake.sullivan",
            at: "2026-09-01T10:30:00Z",
            message: "Thanks both. This one blocks v1.3.0.",
          },
        ],
      },
      {
        by: "alex.chen",
        at: "2026-09-03T14:35:00Z",
        message:
          "Heads-up: `require('@zoo-labs/utilities')` throws on a clean install because `lib/db.js` is missing. Tracking it in zoo-labs/zoo-utilities#2.",
        replies: [
          {
            by: "bob",
            at: "2026-09-03T15:05:00Z",
            message: "Confirmed. Let's add minimal modules rather than change the exports.",
          },
        ],
      },
      {
        by: "alice",
        at: "2026-09-05T14:00:00Z",
        message:
          "The token fix is up for review: zoo-labs/zoo-utilities#4. @grace could you take a look?",
        reactions: [{ by: "grace", emoji: "+1", at: "2026-09-05T14:10:00Z" }],
        replies: [
          {
            by: "grace",
            at: "2026-09-07T09:10:00Z",
            message:
              "Left one comment about making the length configurable. Otherwise it looks good.",
          },
        ],
      },
      {
        by: "bob",
        at: "2026-09-08T12:10:00Z",
        message:
          "I closed the esbuild PR on zoo-api-client. We're staying on tsc, since we need the .d.ts files anyway.",
        reactions: [{ by: "alex.chen", emoji: "+1", at: "2026-09-08T12:15:00Z" }],
      },
      {
        by: "eve",
        at: "2026-09-09T11:30:00Z",
        message:
          'QA reminder: please put reproduction steps in bug reports. Issues that just say "it doesn\'t work" take much longer to triage.',
        reactions: [
          { by: "frank", emoji: "100", at: "2026-09-09T11:40:00Z" },
          { by: "grace", emoji: "+1", at: "2026-09-09T11:52:00Z" },
        ],
      },
      {
        by: "frank",
        at: "2026-09-14T08:15:00Z",
        message:
          "The CI runners move to the new build host on Wednesday. Builds may queue for a few minutes around 10:00 UTC.",
      },
    ],
    "zoo/design": [
      {
        by: "diana",
        at: "2026-09-02T13:00:00Z",
        message:
          "Starting on the hello-zoo welcome page (alice/hello-zoo#2). I'm using the green and slate palette from home.zoo.",
        replies: [
          {
            by: "mallory",
            at: "2026-09-02T13:40:00Z",
            message:
              "Nice. Please check the contrast against WCAG AA; the light green on white we used before failed.",
          },
          {
            by: "diana",
            at: "2026-09-02T14:05:00Z",
            message: "Good point, I'll check every pairing.",
          },
        ],
      },
      {
        by: "mallory",
        at: "2026-09-10T10:00:00Z",
        message:
          "Usability sessions for the Focalboard templates are booked for September 22 and 23. Notes will go on a board made from the User Research Sessions template.",
        reactions: [
          { by: "diana", emoji: "+1", at: "2026-09-10T10:04:00Z" },
          { by: "bob", emoji: "heart", at: "2026-09-10T10:30:00Z" },
        ],
      },
      {
        by: "bob",
        at: "2026-09-15T09:30:00Z",
        message: "Reminder: the design review of the demo day slides is Thursday at 14:00 UTC.",
      },
    ],
    "zoo/off-topic": [
      {
        by: "charlie",
        at: "2026-09-04T12:00:00Z",
        message: "Lunch poll for Friday: react with :taco: or :ramen:.",
        reactions: [
          { by: "alice", emoji: "taco", at: "2026-09-04T12:02:00Z" },
          { by: "frank", emoji: "ramen", at: "2026-09-04T12:05:00Z" },
          { by: "diana", emoji: "taco", at: "2026-09-04T12:09:00Z" },
          { by: "eve", emoji: "taco", at: "2026-09-04T12:15:00Z" },
        ],
      },
      {
        by: "demo",
        at: "2026-09-10T15:00:00Z",
        message: "Does anyone have a spare USB-C to HDMI adapter for the demo room?",
        replies: [
          {
            by: "frank",
            at: "2026-09-10T15:12:00Z",
            message: "There's one in the second drawer of the AV cart.",
          },
        ],
      },
    ],
    "platform/town-square": [
      {
        by: "blake.sullivan",
        at: "2026-09-01T08:00:00Z",
        message:
          "Platform team: quarterly planning is Monday at 10:00 UTC. Bring your top three items.",
        replies: [
          {
            by: "grace",
            at: "2026-09-01T08:40:00Z",
            message: "Mine: token security, disk alerts, faster CI.",
          },
        ],
      },
    ],
    "platform/incidents": [
      {
        by: "frank",
        at: "2026-09-06T02:14:00Z",
        message: ":rotating_light: Pushes to gitea.zoo are failing with 502s. Investigating.",
        reactions: [{ by: "grace", emoji: "eyes", at: "2026-09-06T02:20:00Z" }],
        replies: [
          {
            by: "frank",
            at: "2026-09-06T02:31:00Z",
            message:
              "Cause: old repository archives filled the disk on the git host. I cleared them and pushes work again.",
          },
          {
            by: "grace",
            at: "2026-09-06T08:05:00Z",
            message: "Thanks for jumping on it. Can we alert at 85% disk?",
          },
          {
            by: "frank",
            at: "2026-09-06T08:20:00Z",
            message: "Yes, I'll add the alert today and write up a postmortem.",
          },
        ],
      },
      {
        by: "frank",
        at: "2026-09-07T10:00:00Z",
        message:
          "Postmortem for the September 6 Gitea outage: pushes failed for 17 minutes (02:14 to 02:31 UTC) because repository archives filled the disk. Follow-ups: a disk alert at 85% (done) and a nightly archive cleanup (frank, due September 11).",
        reactions: [
          { by: "blake.sullivan", emoji: "+1", at: "2026-09-07T10:20:00Z" },
          { by: "alex.chen", emoji: "+1", at: "2026-09-07T10:45:00Z" },
        ],
      },
      {
        by: "eve",
        at: "2026-09-16T13:45:00Z",
        message:
          "Staging logins on auth.zoo took 8 to 10 seconds this morning. Is anyone else seeing that?",
        replies: [
          {
            by: "alex.chen",
            at: "2026-09-16T14:02:00Z",
            message: "Yes. The last deploy raised the password hashing cost; I'm rolling it back.",
          },
          {
            by: "alex.chen",
            at: "2026-09-16T14:20:00Z",
            message: "Rolled back. Logins take under a second again.",
          },
        ],
      },
    ],
  } as Record<string, MattermostPost[]>,
  directMessages: [
    {
      members: ["alice", "bob"],
      posts: [
        {
          by: "bob",
          at: "2026-09-08T17:00:00Z",
          message: "Do you have time tomorrow to pair on the ApiError class for zoo-api-client?",
        },
        { by: "alice", at: "2026-09-08T17:12:00Z", message: "Sure, 10:00 UTC works for me." },
        { by: "bob", at: "2026-09-08T17:14:00Z", message: "Great, I'll send an invite." },
      ],
    },
  ],
};

// Feeds each persona reads in Miniflux, by category, with the title the persona gave them
// where the feed's own is ambiguous. Miniflux fetched them once and doesn't poll: after a
// change to the Gitea content, refresh them (PUT /v1/feeds/refresh as each persona) before
// capturing.
export const minifluxSubscriptions: {
  username: string;
  category: string;
  // siteUrl replaces the link a feed gives when it doesn't open (Gitea's branch feeds)
  feeds: { url: string; title?: string; siteUrl?: string }[];
}[] = [
  {
    username: "alice",
    category: "Zoo Labs",
    feeds: [
      { url: "https://gitea.zoo/zoo-labs/zoo-utilities.rss" },
      { url: "https://gitea.zoo/zoo-labs.rss" },
    ],
  },
  {
    username: "alice",
    category: "My projects",
    feeds: [{ url: "https://gitea.zoo/alice/hello-zoo.rss" }],
  },
  {
    username: "bob",
    category: "Projects",
    feeds: [
      { url: "https://gitea.zoo/bob/zoo-api-client.rss" },
      { url: "https://gitea.zoo/zoo-labs.rss" },
    ],
  },
  {
    username: "charlie",
    category: "Community",
    feeds: [{ url: "https://gitea.zoo/community/awesome-zoo.rss" }],
  },
  {
    username: "frank",
    category: "Commits",
    feeds: [
      {
        url: "https://gitea.zoo/zoo-labs/zoo-utilities/rss/branch/master",
        title: "zoo-utilities commits",
        siteUrl: "https://gitea.zoo/zoo-labs/zoo-utilities/src/branch/master",
      },
      {
        url: "https://gitea.zoo/alice/hello-zoo/rss/branch/master",
        title: "hello-zoo commits",
        siteUrl: "https://gitea.zoo/alice/hello-zoo/src/branch/master",
      },
    ],
  },
];
