import { giteaApi } from "./api";
import { type GiteaIssue, gitea } from "./content";
import { execDockerArgs, psql } from "./exec";
import { personas } from "./personas";

const unix = (at: string) => Math.floor(Date.parse(at) / 1000);
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
// have dated theirs in the past, so any timestamp from the last minute is this step's.
async function giteaAt(at: string, step: () => Promise<void>) {
  const since = Math.floor(Date.now() / 1000) - 60;
  await step();
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
