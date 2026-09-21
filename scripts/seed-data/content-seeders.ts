import { crc32 } from "node:zlib";
import { giteaApi, minifluxApi } from "./api";
import { type GiteaIssue, gitea, mattermost, minifluxSubscriptions } from "./content";
import { execDockerArgs, outputOf, psql } from "./exec";
import { personas } from "./personas";

const unix = (at: string) => Math.floor(Date.parse(at) / 1000);
const sqlString = (value: string) => `'${value.replace(/'/g, "''")}'`;
const sameSet = (a: string[], b: string[]) =>
  a.length === b.length && [...a].sort().join("\n") === [...b].sort().join("\n");

function persona(username: string) {
  const found = personas.find((p) => p.username === username);
  if (!found) {
    throw new Error(`No persona ${username}`);
  }
  return found;
}

// --- Gitea ---

const giteaSql = (sql: string) => psql("gitea_user", "gitea_db", sql);

// Timestamp columns of the rows content steps create or change
const GITEA_TIMESTAMPS: Record<string, string[]> = {
  action: ["created_unix"],
  branch: ["created_unix", "updated_unix"],
  comment: ["created_unix", "updated_unix"],
  issue: ["created_unix", "updated_unix", "closed_unix"],
  issue_watch: ["created_unix", "updated_unix"],
  label: ["created_unix", "updated_unix"],
  milestone: ["created_unix", "updated_unix", "closed_date_unix"],
  notification: ["created_unix", "updated_unix"],
  // Xorm's "updated" column, rewritten with the rest of the row until the merge
  pull_request: ["merged_unix"],
  reaction: ["created_unix"],
  repository: ["updated_unix"],
  review: ["created_unix", "updated_unix"],
  review_state: ["updated_unix"],
  watch: ["created_unix", "updated_unix"],
};

// Runs a step, waits for the work Gitea queues for it (notifications, push updates, pull
// request checks), then dates every timestamp it wrote at the content's time. Earlier steps
// have dated theirs in the past, so any timestamp from the last minute is this step's. A step
// that fails partway is dated too: a re-run skips what it already made.
async function giteaAt(at: string, step: () => Promise<void>) {
  const since = Math.floor(Date.now() / 1000) - 60;
  try {
    await step();
  } finally {
    execDockerArgs("gitea-zoo", ["gitea", "manager", "flush-queues"], { user: "git" });
    const time = unix(at);
    giteaSql(
      Object.entries(GITEA_TIMESTAMPS)
        .flatMap(([table, columns]) =>
          columns.map(
            (column) => `UPDATE ${table} SET ${column} = ${time} WHERE ${column} >= ${since};`,
          ),
        )
        .join(" "),
    );
  }
}

// Gitea mails the watchers of every issue, comment and review; the golden inboxes hold none
// of it. The preference is set in the database, which leaves the users' update times alone.
async function withoutGiteaMail(run: () => Promise<void>) {
  const preferences = giteaSql(
    `SELECT id, email_notifications_preference FROM public."user" WHERE email_notifications_preference <> 'disabled';`,
  )
    .split("\n")
    .filter(Boolean)
    .map((line) => line.split("|"));
  const ids = (list: string[][]) => list.map(([id]) => id).join(", ");
  if (preferences.length > 0) {
    giteaSql(
      `UPDATE public."user" SET email_notifications_preference = 'disabled' WHERE id IN (${ids(preferences)});`,
    );
  }
  try {
    await run();
  } finally {
    for (const preference of new Set(preferences.map(([, value]) => value))) {
      const users = preferences.filter(([, value]) => value === preference);
      giteaSql(
        `UPDATE public."user" SET email_notifications_preference = ${sqlString(preference)} WHERE id IN (${ids(users)});`,
      );
    }
  }
}

async function seedTeam({ org, name, permission, members }: (typeof gitea.teams)[number]) {
  const teams = await giteaApi("GET", `/orgs/${org}/teams`, { as: "admin" });
  const team = teams.find((t: { name: string }) => t.name === name);
  if (!team) {
    throw new Error(`Gitea has no team ${org}/${name}`);
  }
  // Gitea applies includes_all_repositories only along with a permission. Editing a team
  // recreates its units, so only when it lacks the repositories.
  if (!team.includes_all_repositories) {
    await giteaApi("PATCH", `/teams/${team.id}`, {
      as: "admin",
      body: { name, permission, includes_all_repositories: true },
    });
    console.log(`✓ Gave ${org}/${name} ${permission} access to all of ${org}'s repositories`);
  }
  const current = (await giteaApi("GET", `/teams/${team.id}/members`, { as: "admin" })).map(
    (u: { login: string }) => u.login,
  );
  for (const member of members.filter((m) => !current.includes(m))) {
    await giteaApi("PUT", `/teams/${team.id}/members/${member}`, { as: "admin" });
    console.log(`✓ Added ${member} to ${org}/${name}`);
  }
}

async function seedLabels(repo: string) {
  const existing = await giteaApi("GET", `/repos/${repo}/labels?limit=50`);
  for (const label of gitea.labels[repo]) {
    if (!existing.some((l: { name: string }) => l.name === label.name)) {
      await giteaApi("POST", `/repos/${repo}/labels`, {
        as: gitea.maintainers[repo],
        body: label,
      });
      console.log(`✓ Created label "${label.name}" in ${repo}`);
    }
  }
}

async function seedMilestone({ repo, title, description, due }: (typeof gitea.milestones)[number]) {
  const existing = await giteaApi("GET", `/repos/${repo}/milestones?state=all&limit=50`);
  if (!existing.some((m: { title: string }) => m.title === title)) {
    await giteaApi("POST", `/repos/${repo}/milestones`, {
      as: gitea.maintainers[repo],
      body: { title, description, due_on: `${due}T00:00:00Z` },
    });
    console.log(`✓ Created milestone ${title} in ${repo}`);
  }
}

async function pushBranch(issue: GiteaIssue) {
  const pull = issue.pull;
  if (!pull) {
    return;
  }
  const repo = `/repos/${issue.repo}`;
  if (await giteaApi("GET", `${repo}/branches/${pull.branch}`, { optional: true })) {
    return;
  }
  const files = [];
  for (const [path, content] of Object.entries(pull.commit.files)) {
    const current = await giteaApi("GET", `${repo}/contents/${path}?ref=${pull.base}`, {
      optional: true,
    });
    files.push({
      operation: current ? "update" : "create",
      path,
      sha: current?.sha,
      content: Buffer.from(content).toString("base64"),
    });
  }
  const identity = { name: persona(issue.by).fullName, email: `${issue.by}@snappymail.zoo` };
  await giteaApi("POST", `${repo}/contents`, {
    as: issue.by,
    body: {
      branch: pull.base,
      new_branch: pull.branch,
      message: pull.commit.message,
      author: identity,
      committer: identity,
      dates: { author: pull.commit.at, committer: pull.commit.at },
      files,
    },
  });
  console.log(`✓ Pushed ${pull.branch} to ${issue.repo}`);
}

async function openIssue(issue: GiteaIssue) {
  const repo = `/repos/${issue.repo}`;
  const ref = `${issue.repo}#${issue.number}`;
  let current = await giteaApi("GET", `${repo}/issues/${issue.number}`, { optional: true });
  if (!current) {
    const body = { title: issue.title, body: issue.body };
    const created = issue.pull
      ? await giteaApi("POST", `${repo}/pulls`, {
          as: issue.by,
          body: { ...body, head: issue.pull.branch, base: issue.pull.base },
        })
      : await giteaApi("POST", `${repo}/issues`, { as: issue.by, body });
    if (created.number !== issue.number) {
      throw new Error(`Opened ${issue.repo}#${created.number} instead of ${ref}`);
    }
    current = await giteaApi("GET", `${repo}/issues/${issue.number}`);
    console.log(`✓ Opened ${ref}`);
  } else if (current.title !== issue.title) {
    throw new Error(`${ref} is "${current.title}", not "${issue.title}"`);
  }

  const maintainer = gitea.maintainers[issue.repo];
  const labels = issue.labels ?? [];
  if (
    !sameSet(
      current.labels.map((l: { name: string }) => l.name),
      labels,
    )
  ) {
    const repoLabels = await giteaApi("GET", `${repo}/labels?limit=50`);
    const ids = labels.map((name) => {
      const label = repoLabels.find((l: { name: string }) => l.name === name);
      if (!label) {
        throw new Error(`${issue.repo} has no label "${name}"`);
      }
      return label.id;
    });
    await giteaApi("PUT", `${repo}/issues/${issue.number}/labels`, {
      as: maintainer,
      body: { labels: ids },
    });
  }

  const edit: Record<string, unknown> = {};
  if ((current.milestone?.title ?? undefined) !== issue.milestone) {
    const milestones = await giteaApi("GET", `${repo}/milestones?state=all&limit=50`);
    const milestone = milestones.find((m: { title: string }) => m.title === issue.milestone);
    if (!milestone) {
      throw new Error(`${issue.repo} has no milestone ${issue.milestone}`);
    }
    edit.milestone = milestone.id;
  }
  const assignees = issue.assignees ?? [];
  if (
    !sameSet(
      (current.assignees ?? []).map((u: { login: string }) => u.login),
      assignees,
    )
  ) {
    edit.assignees = assignees;
  }
  if (Object.keys(edit).length > 0) {
    await giteaApi("PATCH", `${repo}/issues/${issue.number}`, { as: maintainer, body: edit });
  }
}

async function addComment(issue: GiteaIssue, index: number) {
  const comment = issue.comments?.[index];
  if (!comment) {
    return;
  }
  const path = `/repos/${issue.repo}/issues/${issue.number}/comments`;
  const existing = await giteaApi("GET", path);
  if (index < existing.length) {
    if (existing[index].body !== comment.body || existing[index].user.login !== comment.by) {
      throw new Error(`Comment ${index + 1} on ${issue.repo}#${issue.number} differs`);
    }
    return;
  }
  if (index !== existing.length) {
    throw new Error(`${issue.repo}#${issue.number} is missing comments before ${index + 1}`);
  }
  await giteaApi("POST", path, { as: comment.by, body: { body: comment.body } });
  console.log(`✓ ${comment.by} commented on ${issue.repo}#${issue.number}`);
}

async function addReview(issue: GiteaIssue) {
  const review = issue.pull?.review;
  if (!review) {
    return;
  }
  const path = `/repos/${issue.repo}/pulls/${issue.number}/reviews`;
  const existing = await giteaApi("GET", path);
  if (existing.some((r: { user: { login: string } }) => r.user.login === review.by)) {
    return;
  }
  await giteaApi("POST", path, {
    as: review.by,
    body: {
      event: "COMMENT",
      body: review.body,
      comments: review.comments.map((c) => ({ path: c.path, new_position: c.line, body: c.body })),
    },
  });
  console.log(`✓ ${review.by} reviewed ${issue.repo}#${issue.number}`);
}

async function closeIssue(issue: GiteaIssue) {
  const closed = issue.closed;
  if (!closed) {
    return;
  }
  const kind = issue.pull ? "pulls" : "issues";
  const path = `/repos/${issue.repo}/${kind}/${issue.number}`;
  if ((await giteaApi("GET", path)).state === "open") {
    await giteaApi("PATCH", path, { as: closed.by, body: { state: "closed" } });
    console.log(`✓ ${closed.by} closed ${issue.repo}#${issue.number}`);
  }
}

export async function seedGiteaContent() {
  await withoutGiteaMail(seedGiteaContentMuted);
}

async function seedGiteaContentMuted() {
  const columns = new Set(
    giteaSql(
      "SELECT table_name || '.' || column_name FROM information_schema.columns WHERE table_schema = 'public';",
    ).split("\n"),
  );
  for (const [table, names] of Object.entries(GITEA_TIMESTAMPS)) {
    const missing = names.filter((column) => !columns.has(`${table}.${column}`));
    if (missing.length > 0) {
      throw new Error(`gitea_db has no ${missing.map((column) => `${table}.${column}`)}`);
    }
  }

  await giteaAt(gitea.setupAt, async () => {
    for (const team of gitea.teams) {
      await seedTeam(team);
    }
    for (const repo of Object.keys(gitea.labels)) {
      await seedLabels(repo);
    }
    for (const milestone of gitea.milestones) {
      await seedMilestone(milestone);
    }
  });

  // Every issue's events in time order, so IDs ascend with time as in a real history
  const events = gitea.issues.flatMap((issue) => [
    ...(issue.pull ? [{ at: issue.pull.commit.at, run: () => pushBranch(issue) }] : []),
    { at: issue.at, run: () => openIssue(issue) },
    ...(issue.comments ?? []).map((comment, i) => ({
      at: comment.at,
      run: () => addComment(issue, i),
    })),
    ...(issue.pull?.review ? [{ at: issue.pull.review.at, run: () => addReview(issue) }] : []),
    ...(issue.closed ? [{ at: issue.closed.at, run: () => closeIssue(issue) }] : []),
  ]);
  events.sort((a, b) => a.at.localeCompare(b.at));
  for (const event of events) {
    await giteaAt(event.at, event.run);
  }
}

// --- Mattermost ---

const mattermostSql = (sql: string) => psql("mattermost_user", "mattermost_db", sql);
const millis = (at: string) => Date.parse(at);

// A zip archive with one uncompressed file, the form mmctl import process takes
function zipFile(name: string, content: Buffer): Buffer {
  const nameBytes = Buffer.from(name);
  const crc = crc32(content);
  const local = Buffer.alloc(30);
  local.writeUInt32LE(0x04034b50, 0);
  local.writeUInt16LE(20, 4);
  local.writeUInt16LE(0x21, 12); // 1980-01-01
  local.writeUInt32LE(crc, 14);
  local.writeUInt32LE(content.length, 18);
  local.writeUInt32LE(content.length, 22);
  local.writeUInt16LE(nameBytes.length, 26);
  const central = Buffer.alloc(46);
  central.writeUInt32LE(0x02014b50, 0);
  central.writeUInt16LE(20, 4);
  central.writeUInt16LE(20, 6);
  central.writeUInt16LE(0x21, 14);
  central.writeUInt32LE(crc, 16);
  central.writeUInt32LE(content.length, 20);
  central.writeUInt32LE(content.length, 24);
  central.writeUInt16LE(nameBytes.length, 28);
  const localSize = local.length + nameBytes.length + content.length;
  const end = Buffer.alloc(22);
  end.writeUInt32LE(0x06054b50, 0);
  end.writeUInt16LE(1, 8);
  end.writeUInt16LE(1, 10);
  end.writeUInt32LE(central.length + nameBytes.length, 12);
  end.writeUInt32LE(localSize, 16);
  return Buffer.concat([local, nameBytes, content, central, nameBytes, end]);
}

// Mattermost's bulk import format, which keeps each post's, reply's and reaction's time
function mattermostImport(): string {
  const lines: unknown[] = [{ type: "version", version: 1 }];
  for (const [where, posts] of Object.entries(mattermost.posts)) {
    const [team, channel] = where.split("/");
    for (const post of posts) {
      lines.push({
        type: "post",
        post: {
          team,
          channel,
          user: post.by,
          message: post.message,
          create_at: millis(post.at),
          reactions: post.reactions?.map((r) => ({
            user: r.by,
            emoji_name: r.emoji,
            create_at: millis(r.at),
          })),
          replies: post.replies?.map((r) => ({
            user: r.by,
            message: r.message,
            create_at: millis(r.at),
          })),
        },
      });
    }
  }
  for (const dm of mattermost.directMessages) {
    lines.push({ type: "direct_channel", direct_channel: { members: dm.members } });
    for (const post of dm.posts) {
      lines.push({
        type: "direct_post",
        direct_post: {
          channel_members: dm.members,
          user: post.by,
          message: post.message,
          create_at: millis(post.at),
        },
      });
    }
  }
  return `${lines.map((line) => JSON.stringify(line)).join("\n")}\n`;
}

function mmctlArgs(args: string[]): string {
  return execDockerArgs("mattermost", ["mmctl", ...args, "--local"]);
}

async function importMattermostPosts() {
  const file = "/tmp/zoo-content.zip";
  execDockerArgs("mattermost", ["sh", "-c", `cat > ${file}`], {
    input: zipFile("import.jsonl", Buffer.from(mattermostImport())),
  });
  const started = JSON.parse(mmctlArgs(["import", "process", "--bypass-upload", file, "--json"]));
  const { id } = [started].flat()[0];
  for (;;) {
    const [job] = [JSON.parse(mmctlArgs(["import", "job", "show", id, "--json"]))].flat();
    if (job.status === "success") {
      break;
    }
    if (job.status !== "pending" && job.status !== "in_progress") {
      throw new Error(`Mattermost import ${job.status}: ${JSON.stringify(job.data)}`);
    }
    await new Promise((resolve) => setTimeout(resolve, 1000));
  }
  execDockerArgs("mattermost", ["rm", file]);
}

const userId = (username: string) =>
  `(SELECT id FROM users WHERE username = ${sqlString(username)})`;

function channelId(team: string, name: string): string {
  const id = mattermostSql(
    `SELECT c.id FROM channels c JOIN teams t ON t.id = c.teamid WHERE t.name = ${sqlString(team)} AND c.name = ${sqlString(name)};`,
  );
  if (!id) {
    throw new Error(`mattermost.zoo has no channel ${team}/${name}`);
  }
  return id;
}

function directChannelId(members: string[]): string {
  const [a, b] = members.map(userId);
  const id = mattermostSql(
    `SELECT id FROM channels WHERE type = 'D' AND name = LEAST(${a}, ${b}) || '__' || GREATEST(${a}, ${b});`,
  );
  if (!id) {
    throw new Error(`mattermost.zoo has no direct channel for ${members.join(", ")}`);
  }
  return id;
}

// A member joined at `at` (ms): the "joined the channel" post, the membership and its history
const joinedAt = (channel: string, username: string, at: number) =>
  `UPDATE posts SET createat = ${at}, updateat = ${at} WHERE channelid = '${channel}' AND userid = ${userId(username)} AND type = 'system_join_channel';` +
  `UPDATE channelmembers SET lastupdateat = ${at} WHERE channelid = '${channel}' AND userid = ${userId(username)};` +
  `UPDATE channelmemberhistory SET jointime = ${at} WHERE channelid = '${channel}' AND userid = ${userId(username)};`;

// The dates below set the same values every time, so they run on every seed: a seed that
// failed after the import is fixed by the next one
export async function seedMattermostContent() {
  const fixes: string[] = [];
  for (const channel of mattermost.channels) {
    try {
      mmctlArgs([
        "channel",
        "create",
        "--team",
        channel.team,
        "--name",
        channel.name,
        "--display-name",
        channel.displayName,
        "--purpose",
        channel.purpose,
        "--header",
        channel.header,
      ]);
      console.log(`✓ Created channel ${channel.team}/${channel.name} in mattermost.zoo`);
    } catch (error) {
      if (!/A channel with that name already exists/.test(outputOf(error))) {
        throw error;
      }
    }
    // The creator joins first, the others a second apart
    const members = [channel.by, ...channel.members.filter((m) => m !== channel.by)];
    mmctlArgs(["channel", "users", "add", `${channel.team}:${channel.name}`, ...members]);
    const id = channelId(channel.team, channel.name);
    const at = millis(channel.at);
    fixes.push(
      `UPDATE channels SET creatorid = ${userId(channel.by)}, createat = ${at}, updateat = ${at} WHERE id = '${id}';`,
      ...members.map((member, i) => joinedAt(id, member, at + i * 1000)),
    );
  }

  const [first] = Object.values(mattermost.posts)
    .flat()
    .sort((a, b) => a.at.localeCompare(b.at));
  if (
    mattermostSql(
      `SELECT count(*) FROM posts WHERE createat = ${millis(first.at)} AND message = ${sqlString(first.message)};`,
    ) === "0"
  ) {
    await importMattermostPosts();
    console.log("✓ Imported mattermost.zoo posts");
  } else {
    // Importing again would rewrite the posts' update times
    console.log("✓ mattermost.zoo already has its posts");
  }

  const channels = [
    ...Object.keys(mattermost.posts).map((where) =>
      channelId(...(where.split("/") as [string, string])),
    ),
    ...mattermost.directMessages.map((dm) => {
      const id = directChannelId(dm.members);
      const at = millis(dm.posts[0].at);
      fixes.push(
        `UPDATE channels SET createat = ${at}, updateat = ${at} WHERE id = '${id}';`,
        ...dm.members.map((member) => joinedAt(id, member, at)),
        // The sidebar hides a direct message without it once it's read
        ...dm.members.map((member) => {
          const [other] = dm.members.filter((m) => m !== member);
          return `INSERT INTO preferences (userid, category, name, value) SELECT ${userId(member)}, 'direct_channel_show', ${userId(other)}, 'true' ON CONFLICT DO NOTHING;`;
        }),
      );
      return id;
    }),
  ];
  const inChannels = `IN (${channels.map((id) => `'${id}'`).join(", ")})`;
  mattermostSql(
    [
      ...fixes,
      // Reacting and replying bump a post's update time
      `UPDATE reactions SET updateat = createat WHERE channelid ${inChannels};`,
      `UPDATE posts p SET updateat = GREATEST(p.createat, ` +
        `COALESCE((SELECT max(r.createat) FROM posts r WHERE r.rootid = p.id), 0), ` +
        `COALESCE((SELECT max(x.createat) FROM reactions x WHERE x.postid = p.id), 0)) ` +
        `WHERE p.channelid ${inChannels} AND p.type = '';`,
      `UPDATE channels c SET lastpostat = (SELECT max(createat) FROM posts WHERE channelid = c.id), ` +
        `lastrootpostat = (SELECT max(createat) FROM posts WHERE channelid = c.id AND rootid = '') ` +
        `WHERE c.id ${inChannels};`,
    ].join(" "),
  );
}

// --- Miniflux ---

// Creating a feed fetches it once; with the scheduler off (docker-compose.yaml), its entries
// stay as fetched here
export async function seedMinifluxContent() {
  for (const { username, category, feeds } of minifluxSubscriptions) {
    const categories = await minifluxApi("GET", "/categories", { as: username });
    const { id: categoryId } =
      categories.find((c: { title: string }) => c.title === category) ??
      (await minifluxApi("POST", "/categories", { as: username, body: { title: category } }));
    const existing = await minifluxApi("GET", "/feeds", { as: username });
    for (const { url, title, siteUrl } of feeds) {
      let feed = existing.find((f: { feed_url: string }) => f.feed_url === url);
      if (!feed) {
        const { feed_id } = await minifluxApi("POST", "/feeds", {
          as: username,
          body: { feed_url: url, category_id: categoryId },
        });
        feed = { id: feed_id };
        console.log(`✓ Subscribed ${username} to ${url}`);
      }
      const changes = {
        ...(title && feed.title !== title ? { title } : {}),
        ...(siteUrl && feed.site_url !== siteUrl ? { site_url: siteUrl } : {}),
      };
      if (Object.keys(changes).length > 0) {
        await minifluxApi("PUT", `/feeds/${feed.id}`, { as: username, body: changes });
      }
    }
  }
}
