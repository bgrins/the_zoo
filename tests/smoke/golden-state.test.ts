// Checks the committed golden state (docs/golden-state.md) without a running environment
import { createHash } from "node:crypto";
import { readdirSync, readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, test } from "vitest";
import { captures, DUMP_ENCODING, normalizeDump, tablePattern } from "../../scripts/golden-state";
import { gitea, mattermost, minifluxSubscriptions } from "../../scripts/seed-data/content";
import { personaId, personas } from "../../scripts/seed-data/personas";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "../..");
const readText = (path: string) => readFileSync(resolve(root, path), "utf8");
const dumps = Object.fromEntries(
  Object.entries(captures).map(([service, { file }]) => [
    service,
    readFileSync(resolve(root, file), DUMP_ENCODING),
  ]),
);

const usernames = personas.map((p) => p.username).sort();
const personaEmail = (username: string) => `${username}@snappymail.zoo`;
const sorted = (values: (string | null)[]) => [...values].sort();

type Row = Record<string, string | null>;

// Dumps are read as latin1; text columns hold UTF-8
const utf8 = (value: string | null) => Buffer.from(String(value), DUMP_ENCODING).toString("utf8");
const unix = (at: string) => Date.parse(at) / 1000;

// Rows of a COPY block; in COPY text format \N is NULL and backslash escapes the rest
function rows(service: string, table: string): Row[] {
  const lines = dumps[service].split("\n");
  const start = lines.findIndex((line) => line.startsWith(`COPY ${table} (`));
  if (start === -1) {
    throw new Error(`No COPY block for ${table} in ${captures[service].file}`);
  }
  const columns = lines[start].replace(/^COPY \S+ \((.*)\) FROM stdin;$/, "$1").split(", ");
  const escapes: Record<string, string> = { b: "\b", f: "\f", n: "\n", r: "\r", t: "\t", v: "\v" };
  return lines.slice(start + 1, lines.indexOf("\\.", start)).map((line) => {
    const values = line.split("\t");
    return Object.fromEntries(
      columns.map((column, i) => [
        column,
        values[i] === "\\N" ? null : values[i].replace(/\\(.)/g, (_, c) => escapes[c] ?? c),
      ]),
    );
  });
}

function match(text: string, pattern: RegExp): string {
  const found = text.match(pattern);
  if (!found) {
    throw new Error(`${pattern} not found`);
  }
  return found[1];
}

type Tree = Map<string, Buffer | Tree>;

function gitObject(type: string, body: Buffer): Buffer {
  return createHash("sha1").update(`${type} ${body.length}\0`).update(body).digest();
}

// Git orders tree entries by name, comparing a subtree's name as if it ended in "/"
function gitTree(tree: Tree): Buffer {
  const entries = [...tree].map(([name, node]) =>
    node instanceof Map
      ? { name, key: `${name}/`, mode: "40000", hash: gitTree(node) }
      : { name, key: name, mode: "100644", hash: gitObject("blob", node) },
  );
  entries.sort((a, b) => (a.key < b.key ? -1 : 1));
  return gitObject(
    "tree",
    Buffer.concat(entries.flatMap((e) => [Buffer.from(`${e.mode} ${e.name}\0`), e.hash])),
  );
}

// "owner/name" -> branch and head commit, for the pinned mirrors and the sample repos the
// script commits itself (their commit IDs are computed from its heredocs)
function bakedRepos(): Map<string, { branch: string; commit: string }> {
  const script = readText("sites/apps/gitea.zoo/fetch-repos.sh");
  const repos = new Map<string, { branch: string; commit: string }>();
  const mirrors = JSON.parse(
    match(script, /cat > \/app\/git-data\/repos\.json << 'EOF'\n([\s\S]*?)\nEOF\n/),
  ).repositories;
  for (const { owner, name, branch, commit } of mirrors) {
    repos.set(`${owner}/${name}`, { branch, commit });
  }

  const branch = match(script, /git config --global init\.defaultBranch (\S+)/);
  const date = match(script, /GIT_AUTHOR_DATE="([^"]+)"/);
  expect(match(script, /GIT_COMMITTER_DATE="([^"]+)"/)).toBe(date);
  const time = Date.parse(date) / 1000;
  for (const section of script.split(/^git init /m).slice(1)) {
    const tree: Tree = new Map();
    for (const [, path, content] of section.matchAll(
      /^cat > ([^/\s]\S*) << 'EOF'\n([\s\S]*?)^EOF$/gm,
    )) {
      const parts = path.split("/");
      let dir = tree;
      for (const part of parts.slice(0, -1)) {
        if (!dir.has(part)) {
          dir.set(part, new Map());
        }
        dir = dir.get(part) as Tree;
      }
      dir.set(parts[parts.length - 1], Buffer.from(content));
    }
    const name = match(section, /git config user\.name "([^"]+)"/);
    const email = match(section, /git config user\.email "([^"]+)"/);
    const identity = `${name} <${email}> ${time} +0000`;
    const message = match(section, /git commit -m "([^"]+)"/);
    const commit = gitObject(
      "commit",
      Buffer.from(
        `tree ${gitTree(tree).toString("hex")}\nauthor ${identity}\ncommitter ${identity}\n\n${message}\n`,
      ),
    );
    repos.set(match(section, /git clone --bare \. \/app\/git-data\/(\S+)\.git/), {
      branch,
      commit: commit.toString("hex"),
    });
  }
  return repos;
}

// "owner/name" -> ref -> commit ID, from the fast-export streams export-refs.sh captured
function gitGoldenRefs(): Map<string, Map<string, string>> {
  const dir = resolve(root, "sites/apps/gitea.zoo/git-golden");
  const repos = new Map<string, Map<string, string>>();
  for (const owner of readdirSync(dir)) {
    for (const file of readdirSync(resolve(dir, owner))) {
      const stream = readFileSync(resolve(dir, owner, file));
      const refs = new Map<string, string>();
      const marks = new Map<string, string>();
      let ref: string | undefined;
      let mark: string | undefined;
      for (let pos = 0; pos < stream.length; ) {
        const end = stream.indexOf("\n", pos);
        const line = stream.toString("utf8", pos, end);
        pos = end + 1;
        const [command, arg] = [
          line.slice(0, line.indexOf(" ")),
          line.slice(line.indexOf(" ") + 1),
        ];
        if (command === "data") {
          pos += Number(arg);
        } else if (command === "blob") {
          ref = undefined;
        } else if (command === "commit" || command === "reset") {
          [ref, mark] = [arg, undefined];
        } else if (command === "mark") {
          mark = arg;
        } else if (command === "original-oid" && ref && mark) {
          marks.set(mark, arg);
          refs.set(ref, arg);
        } else if (command === "from" && ref && !mark) {
          refs.set(ref, marks.get(arg) ?? arg);
        }
      }
      repos.set(`${owner}/${file.replace(/\.fast-export$/, "")}`, refs);
    }
  }
  return repos;
}

interface Principal {
  type: number;
  fields: Record<number, (string | number)[]>;
}

// Stalwart's principal encoding: version, type, field count, then per field an ID byte (high
// bit set for numeric fields), a value count and the values, strings length-prefixed
function decodePrincipal(buf: Buffer): Principal {
  let pos = 3;
  const varint = () => {
    let value = 0;
    for (let shift = 0; ; shift += 7) {
      const byte = buf[pos++];
      value |= (byte & 0x7f) << shift;
      if (!(byte & 0x80)) {
        return value;
      }
    }
  };
  const fields: Principal["fields"] = {};
  for (let i = 0; i < buf[2]; i++) {
    const id = buf[pos++];
    const values: (string | number)[] = [];
    for (let count = varint(); count > 0; count--) {
      if (id & 0x80) {
        values.push(varint());
      } else {
        const length = varint();
        values.push(buf.toString("utf8", pos, pos + length));
        pos += length;
      }
    }
    fields[id & 0x7f] = values;
  }
  expect(pos).toBe(buf.length);
  return { type: buf[1], fields };
}

const STALWART_INDIVIDUAL = 0;
const [NAME, DESCRIPTION, SECRETS, EMAILS] = [0, 3, 4, 5];

function stalwartMailboxes(): Principal[] {
  return rows("stalwart", "public.d")
    .filter((row) => row.k?.startsWith("\\x02"))
    .map((row) => decodePrincipal(Buffer.from(String(row.v).slice(2), "hex")))
    .filter((principal) => principal.type === STALWART_INDIVIDUAL);
}

describe("Golden state", () => {
  test("dumps are in the form golden:capture writes", () => {
    for (const [service, capture] of Object.entries(captures)) {
      const dump = dumps[service];
      expect(normalizeDump(service, dump) === dump, `${capture.file} is normalized`).toBe(true);
      expect(dump).not.toMatch(/Dump completed on/);
      if (capture.engine === "postgres") {
        expect(dump.match(/^\\(un)?restrict .*$/gm), capture.file).toEqual([
          "\\restrict zoo",
          "\\unrestrict zoo",
        ]);
      }
    }
  });

  test("tables whose data golden:capture leaves out have no rows", () => {
    for (const [service, capture] of Object.entries(captures)) {
      const dump = dumps[service];
      for (const pattern of capture.excludeTableData) {
        if (capture.engine === "mysql") {
          expect(dump).toContain(`CREATE TABLE \`${pattern}\` (`);
          expect(dump).not.toContain(`INSERT INTO \`${pattern}\` `);
          continue;
        }
        const tables = [...dump.matchAll(/^CREATE TABLE (\S+) \(/gm)]
          .map(([, table]) => table)
          .filter((table) => tablePattern(pattern).test(table));
        expect(tables.length, `${pattern} in ${capture.file}`).toBeGreaterThan(0);
        for (const table of tables) {
          expect(dump).not.toContain(`COPY ${table} (`);
        }
      }
    }
  });

  test("every app has exactly the personas, plus known extras", () => {
    expect(sorted(rows("auth", "public.users").map((u) => u.username))).toEqual(usernames);
    expect(sorted(rows("miniflux", "public.users").map((u) => u.username))).toEqual(usernames);

    const gitea = rows("gitea", 'public."user"');
    expect(sorted(gitea.filter((u) => u.type === "0").map((u) => u.lower_name))).toEqual(usernames);
    expect(sorted(gitea.filter((u) => u.type === "1").map((u) => u.lower_name))).toEqual([
      "community",
      "zoo-labs",
    ]);

    const mattermostBots = ["calls", "feedbackbot", "playbooks", "system-bot"];
    expect(sorted(rows("mattermost", "public.users").map((u) => u.username))).toEqual(
      sorted([...usernames, ...mattermostBots]),
    );
    // The account the docker-compose.yaml comment on focalboard-zoo documents
    const focalboardExtras = ["alex.lee@snappymail.zoo"];
    expect(sorted(rows("focalboard", "public.users").map((u) => u.username))).toEqual(
      sorted([...usernames, ...focalboardExtras]),
    );

    // core/stalwart/create-users.sh
    const stalwartExtras = [
      "admin@zoo",
      "newuser@zoo",
      "test@zoo",
      "user@snappymail.zoo",
      "user@zoo",
    ];
    expect(sorted(stalwartMailboxes().map((p) => String(p.fields[NAME])))).toEqual(
      sorted([...usernames.map(personaEmail), ...stalwartExtras]),
    );
  });

  test("persona accounts have the persona's snappymail.zoo address and role", () => {
    const admins = new Set(personas.filter((p) => p.role === "admin").map((p) => p.username));
    const isPersona = (user: Row, column = "username") => usernames.includes(String(user[column]));
    const flag = (username: string | null) => (admins.has(String(username)) ? "t" : "f");

    for (const user of rows("auth", "public.users")) {
      expect(user.email).toBe(personaEmail(String(user.username)));
    }
    for (const user of rows("miniflux", "public.users")) {
      expect(user.is_admin, String(user.username)).toBe(flag(user.username));
    }
    for (const user of rows("focalboard", "public.users").filter((u) => isPersona(u))) {
      expect(user.email).toBe(personaEmail(String(user.username)));
    }
    for (const user of rows("mattermost", "public.users").filter((u) => isPersona(u))) {
      expect(user.email).toBe(personaEmail(String(user.username)));
      expect(user.roles, String(user.username)).toBe(
        admins.has(String(user.username)) ? "system_user system_admin" : "system_user",
      );
    }

    const giteaEmails = rows("gitea", "public.email_address");
    for (const user of rows("gitea", 'public."user"').filter((u) => isPersona(u, "lower_name"))) {
      const email = personaEmail(String(user.lower_name));
      expect([user.email, user.avatar_email]).toEqual([email, email]);
      expect(user.is_admin, String(user.lower_name)).toBe(flag(user.lower_name));
      expect(
        giteaEmails
          .filter((e) => e.uid === user.id)
          .map((e) => [e.email, e.lower_email, e.is_primary]),
      ).toEqual([[email, email, "t"]]);
    }
  });

  test("auth.zoo IDs are the personas' UUIDv5s, and Gitea and Miniflux link to them", () => {
    for (const user of rows("auth", "public.users")) {
      expect(user.id, String(user.username)).toBe(personaId(String(user.username)));
    }
    for (const user of rows("miniflux", "public.users")) {
      expect(user.openid_connect_id, String(user.username)).toBe(personaId(String(user.username)));
    }

    const giteaUsers = new Map(rows("gitea", 'public."user"').map((u) => [u.id, u]));
    const links = rows("gitea", "public.external_login_user");
    expect(links).toHaveLength(personas.length);
    for (const link of links) {
      const username = String(giteaUsers.get(link.user_id)?.lower_name);
      const persona = personas.find((p) => p.username === username);
      expect(link.external_id, username).toBe(personaId(username));
      expect([link.login_source_id, link.provider, link.email, link.name]).toEqual([
        "1",
        "openidConnect",
        personaEmail(username),
        persona?.fullName,
      ]);
    }
  });

  test("Gitea repositories match what fetch-repos.sh bakes, plus the refs git-golden adds", () => {
    const baked = bakedRepos();
    const exported = gitGoldenRefs();
    const owners = new Map(rows("gitea", 'public."user"').map((u) => [u.id, u.lower_name]));
    const repos = rows("gitea", "public.repository");
    expect(sorted(repos.map((r) => `${r.owner_name}/${r.lower_name}`))).toEqual(
      sorted([...baked.keys()]),
    );
    for (const name of exported.keys()) {
      expect(baked.has(name), `git-golden/${name}`).toBe(true);
    }

    const branches = rows("gitea", "public.branch");
    const pulls = rows("gitea", "public.pull_request");
    const indexed = rows("gitea", "public.repo_indexer_status");
    const languages = rows("gitea", "public.language_stat");
    for (const repo of repos) {
      const name = `${repo.owner_name}/${repo.lower_name}`;
      const { branch, commit } = baked.get(name) ?? { branch: "", commit: "" };
      const refs = exported.get(name) ?? new Map<string, string>();
      expect(owners.get(repo.owner_id), name).toBe(repo.owner_name);
      expect([repo.default_branch, repo.is_empty], name).toEqual([branch, "f"]);
      const extra = [...refs]
        .filter(([ref]) => ref.startsWith("refs/heads/"))
        .map(([ref, id]) => [ref.slice("refs/heads/".length), id, "f"]);
      expect(
        sorted(
          branches
            .filter((b) => b.repo_id === repo.id)
            .map((b) => JSON.stringify([b.name, b.commit_id, b.is_deleted])),
        ),
        name,
      ).toEqual(sorted([[branch, commit, "f"], ...extra].map((b) => JSON.stringify(b))));
      // A pull request's page and diff read its head from refs/pull/N/head
      const pullRefs = pulls
        .filter((p) => p.base_repo_id === repo.id)
        .map((p) => {
          expect(p.head_repo_id, `${name}#${p.index}`).toBe(repo.id);
          const head = refs.get(`refs/heads/${p.head_branch}`);
          expect(head, `${name}#${p.index} head`).toBeDefined();
          return [`refs/pull/${p.index}/head`, head];
        });
      expect(
        [...refs].filter(([ref]) => !ref.startsWith("refs/heads/")),
        `${name} other refs`,
      ).toEqual(expect.arrayContaining(pullRefs));
      expect([...refs].length - extra.length, `${name} other refs`).toBe(pullRefs.length);
      for (const row of indexed.filter((r) => r.repo_id === repo.id)) {
        expect(row.commit_sha, `${name} repo_indexer_status`).toBe(commit);
      }
      for (const row of languages.filter((r) => r.repo_id === repo.id)) {
        expect(row.commit_id, `${name} language_stat`).toBe(commit);
      }
    }
  });

  test("persona accounts show the persona's full name", () => {
    const giteaNames = new Map(
      rows("gitea", 'public."user"').map((u) => [u.lower_name, utf8(u.full_name)]),
    );
    const mattermostNames = new Map(
      rows("mattermost", "public.users").map((u) => [u.username, [u.firstname, u.lastname]]),
    );
    for (const persona of personas) {
      expect(giteaNames.get(persona.username), persona.username).toBe(persona.fullName);
      const [first, last] = (mattermostNames.get(persona.username) ?? []).map(utf8);
      // The last word is the last name
      expect([`${first} ${last}`, last.includes(" ")], persona.username).toEqual([
        persona.fullName,
        false,
      ]);
    }
  });

  test("the dumps hold the Gitea, Mattermost and Miniflux content of content.ts", () => {
    const giteaUsers = new Map(rows("gitea", 'public."user"').map((u) => [u.id, u.lower_name]));
    const repoNames = new Map(
      rows("gitea", "public.repository").map((r) => [r.id, `${r.owner_name}/${r.lower_name}`]),
    );
    const issues = rows("gitea", "public.issue");
    const issueRefs = new Map(issues.map((i) => [i.id, `${repoNames.get(i.repo_id)}#${i.index}`]));
    expect(
      sorted(
        issues.map((i) =>
          JSON.stringify([
            issueRefs.get(i.id),
            giteaUsers.get(i.poster_id),
            utf8(i.name),
            Number(i.created_unix),
            i.is_pull === "t",
            i.is_closed === "t" ? Number(i.closed_unix) : null,
          ]),
        ),
      ),
    ).toEqual(
      sorted(
        gitea.issues.map((issue) =>
          JSON.stringify([
            `${issue.repo}#${issue.number}`,
            issue.by,
            issue.title,
            unix(issue.at),
            Boolean(issue.pull),
            issue.closed ? unix(issue.closed.at) : null,
          ]),
        ),
      ),
    );
    const plainComments = rows("gitea", "public.comment").filter((c) => c.type === "0");
    expect(
      sorted(
        plainComments.map((c) =>
          JSON.stringify([
            issueRefs.get(c.issue_id),
            giteaUsers.get(c.poster_id),
            utf8(c.content),
            Number(c.created_unix),
          ]),
        ),
      ),
    ).toEqual(
      sorted(
        gitea.issues.flatMap((issue) =>
          (issue.comments ?? []).map((c) =>
            JSON.stringify([`${issue.repo}#${issue.number}`, c.by, c.body, unix(c.at)]),
          ),
        ),
      ),
    );

    const mattermostUsers = new Map(
      rows("mattermost", "public.users").map((u) => [u.id, u.username]),
    );
    const expectedPosts = [
      ...Object.values(mattermost.posts)
        .flat()
        .flatMap((post) => [post, ...(post.replies ?? [])]),
      ...mattermost.directMessages.flatMap((dm) => dm.posts),
    ].map((post) => JSON.stringify([post.by, post.message, Date.parse(post.at)]));
    expect(
      sorted(
        rows("mattermost", "public.posts")
          .filter((p) => p.type === "")
          .map((p) =>
            JSON.stringify([mattermostUsers.get(p.userid), utf8(p.message), Number(p.createat)]),
          ),
      ),
    ).toEqual(sorted(expectedPosts));

    const minifluxUsers = new Map(rows("miniflux", "public.users").map((u) => [u.id, u.username]));
    expect(
      sorted(
        rows("miniflux", "public.feeds").map(
          (f) => `${minifluxUsers.get(f.user_id)} ${f.feed_url}`,
        ),
      ),
    ).toEqual(
      sorted(minifluxSubscriptions.flatMap((s) => s.feeds.map((f) => `${s.username} ${f.url}`))),
    );
  });

  test("Matomo starts with no visits, reports or traces of them", () => {
    const tables = [...dumps.analytics.matchAll(/^INSERT INTO `([^`]+)` /gm)].map(([, t]) => t);
    expect(tables.filter((table) => /^matomo_(log|archive)_/.test(table))).toEqual([]);
    expect(dumps.analytics).not.toMatch(/'(fingerprint_salt|SitesManagerHadTrafficInPast)_/);
  });

  test("Stalwart persona mailboxes match personas.ts", () => {
    const mailboxes = new Map(stalwartMailboxes().map((p) => [String(p.fields[NAME]), p.fields]));
    for (const persona of personas) {
      const email = personaEmail(persona.username);
      const fields = mailboxes.get(email);
      expect(fields?.[DESCRIPTION], email).toEqual([persona.fullName]);
      expect(fields?.[SECRETS], email).toEqual([persona.password]);
      expect(fields?.[EMAILS], email).toEqual([email]);
    }
  });

  test("Stalwart's stored inbound rate limiters are disabled", () => {
    // Stalwart writes its default limiters (sender 25/1h per recipient) into the database when
    // missing, and those win over config.toml; enabled, they fail mail between the same personas
    const settings = Object.fromEntries(
      rows("stalwart", "public.s").map((row) => [
        Buffer.from(String(row.k).replace(/^\\x/, ""), "hex").toString(),
        Buffer.from(String(row.v).replace(/^\\x/, ""), "hex").toString(),
      ]),
    );
    expect(
      Object.entries(settings).filter(([key]) =>
        /^queue\.limiter\.inbound\.[^.]+\.enable$/.test(key),
      ),
    ).toEqual([
      ["queue.limiter.inbound.ip.enable", "false"],
      ["queue.limiter.inbound.sender.enable", "false"],
    ]);
  });

  test("Hydra clients carry the hash init-clients.sh gives default-clients.json", () => {
    // jq -cS: compact, keys sorted
    const canonical = (value: unknown): string =>
      Array.isArray(value)
        ? `[${value.map(canonical).join(",")}]`
        : value && typeof value === "object"
          ? `{${Object.keys(value)
              .sort()
              .map(
                (key) =>
                  `${JSON.stringify(key)}:${canonical((value as Record<string, unknown>)[key])}`,
              )
              .join(",")}}`
          : JSON.stringify(value);
    const clients: { client_id: string }[] = JSON.parse(
      readText("core/hydra/clients/default-clients.json"),
    );
    const golden = new Map(rows("auth", "public.hydra_client").map((c) => [c.id, c.metadata]));
    expect(sorted([...golden.keys()])).toEqual(sorted(clients.map((c) => c.client_id)));
    for (const client of clients) {
      const hash = createHash("sha256")
        .update(`${canonical(client)}\n`)
        .digest("hex");
      expect(golden.get(client.client_id), client.client_id).toBe(`{"config_sha256":"${hash}"}`);
    }
  });
});
