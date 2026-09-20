// Checks the committed golden state (docs/golden-state.md) without a running environment
import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, test } from "vitest";
import { captures, DUMP_ENCODING, normalizeDump } from "../../scripts/golden-state";
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
        const glob = new RegExp(`^${pattern.replace(/\./g, "\\.").replace(/\*/g, ".*")}$`);
        const tables = [...dump.matchAll(/^CREATE TABLE (\S+) \(/gm)]
          .map(([, table]) => table)
          .filter((table) => glob.test(table));
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
      "admin@status.zoo",
      "admin@zoo",
      "newuser@zoo",
      "test@zoo",
      "user@snappymail.zoo",
      "user@status.zoo",
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

  test("Gitea repositories match what fetch-repos.sh bakes", () => {
    const baked = bakedRepos();
    const owners = new Map(rows("gitea", 'public."user"').map((u) => [u.id, u.lower_name]));
    const repos = rows("gitea", "public.repository");
    expect(sorted(repos.map((r) => `${r.owner_name}/${r.lower_name}`))).toEqual(
      sorted([...baked.keys()]),
    );

    const branches = rows("gitea", "public.branch");
    const indexed = rows("gitea", "public.repo_indexer_status");
    const languages = rows("gitea", "public.language_stat");
    for (const repo of repos) {
      const name = `${repo.owner_name}/${repo.lower_name}`;
      const { branch, commit } = baked.get(name) ?? { branch: "", commit: "" };
      expect(owners.get(repo.owner_id), name).toBe(repo.owner_name);
      expect([repo.default_branch, repo.is_empty], name).toEqual([branch, "f"]);
      expect(
        branches
          .filter((b) => b.repo_id === repo.id)
          .map((b) => [b.name, b.commit_id, b.is_deleted]),
        name,
      ).toEqual([[branch, commit, "f"]]);
      for (const row of indexed.filter((r) => r.repo_id === repo.id)) {
        expect(row.commit_sha, `${name} repo_indexer_status`).toBe(commit);
      }
      for (const row of languages.filter((r) => r.repo_id === repo.id)) {
        expect(row.commit_id, `${name} language_stat`).toBe(commit);
      }
    }
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

  test("Stalwart's stored settings don't override config.toml's disabled rate limiters", () => {
    // Settings in the database win over config.toml, and these made mail between the same
    // personas fail after 25 messages an hour
    const keys = rows("stalwart", "public.s").map((row) =>
      Buffer.from(String(row.k).replace(/^\\x/, ""), "hex").toString(),
    );
    expect(keys.filter((key) => key.startsWith("queue.limiter."))).toEqual([]);
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
