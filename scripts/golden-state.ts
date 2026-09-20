// What `npm run golden:capture` dumps and copies for each service, and the normalization it
// applies. tests/smoke/golden-state.test.ts checks the committed files against the same rules.

export interface Capture {
  engine: "postgres" | "mysql";
  db: string;
  file: string;
  // Tables whose rows logins and background jobs create; the tables stay, empty
  excludeTableData: string[];
  // Container paths copied into the repo alongside the dump: [service, container path, repo path]
  files?: [string, string, string][];
  // Images that bake the captured state in at build time
  rebuild: string[];
}

export const captures: Record<string, Capture> = {
  auth: {
    engine: "postgres",
    db: "auth_db",
    file: "core/postgres/seed/auth.sql",
    // Hydra's login sessions, consents and tokens. hydra_client stays: init-clients.sh leaves
    // clients that match core/hydra/clients/default-clients.json untouched.
    excludeTableData: ["public.hydra_oauth2_*"],
    rebuild: ["postgres"],
  },
  focalboard: {
    engine: "postgres",
    db: "focalboard_db",
    file: "core/postgres/seed/focalboard.sql",
    excludeTableData: ["public.sessions"],
    rebuild: ["postgres"],
  },
  gitea: {
    engine: "postgres",
    db: "gitea_db",
    file: "core/postgres/seed/gitea.sql",
    excludeTableData: ["public.auth_token", "public.session"],
    // Git repositories are baked by sites/apps/gitea.zoo/fetch-repos.sh instead
    files: [
      ["gitea-zoo", "/data/gitea/conf", "sites/apps/gitea.zoo/data-golden/gitea/conf"],
      ["gitea-zoo", "/data/gitea/jwt", "sites/apps/gitea.zoo/data-golden/gitea/jwt"],
      ["gitea-zoo", "/data/gitea/avatars", "sites/apps/gitea.zoo/data-golden/gitea/avatars"],
    ],
    rebuild: ["postgres", "gitea-zoo"],
  },
  mattermost: {
    engine: "postgres",
    db: "mattermost_db",
    file: "core/postgres/seed/mattermost.sql",
    excludeTableData: ["public.sessions", "public.audits"],
    rebuild: ["postgres"],
  },
  miniflux: {
    engine: "postgres",
    db: "miniflux_db",
    file: "core/postgres/seed/miniflux.zoo.sql",
    excludeTableData: ["public.sessions", "public.user_sessions"],
    rebuild: ["postgres"],
  },
  stalwart: {
    engine: "postgres",
    db: "stalwart_db",
    file: "core/postgres/seed/stalwart.sql",
    // Rate-limit counters are rows, not tables: see dropStalwartRateLimits
    excludeTableData: [],
    rebuild: ["postgres"],
  },
  analytics: {
    engine: "mysql",
    db: "analytics_db",
    file: "core/mysql/sql/analytics_seed.sql",
    excludeTableData: ["matomo_session", "matomo_brute_force_log"],
    files: [
      [
        "analytics-zoo",
        "/var/www/html/config/config.ini.php",
        "sites/apps/analytics.zoo/data-golden/config/config.ini.php",
      ],
    ],
    rebuild: ["mysql", "analytics-zoo"],
  },
};

// Read and write dumps byte for byte: the MySQL dump holds binary blobs that aren't UTF-8.
// Rows then sort by byte value.
export const DUMP_ENCODING = "latin1";

const COPY_START = /^COPY (\S+) \(.*\) FROM stdin;$/;

// Apply fn to the data rows of every COPY block in a pg_dump
function mapCopyRows(dump: string, fn: (table: string, rows: string[]) => string[]): string {
  const lines = dump.split("\n");
  const out: string[] = [];
  for (let i = 0; i < lines.length; i++) {
    out.push(lines[i]);
    const table = lines[i].match(COPY_START)?.[1];
    if (!table) {
      continue;
    }
    const end = lines.indexOf("\\.", i + 1);
    if (end === -1) {
      throw new Error(`Unterminated COPY block for ${table}`);
    }
    out.push(...fn(table, lines.slice(i + 1, end)));
    i = end - 1;
  }
  return out.join("\n");
}

const INTEGER = /^-?\d+$/;

// Field by field, integers numerically and before other values, which compare as strings
function compareRows(a: string, b: string): number {
  const fa = a.split("\t");
  const fb = b.split("\t");
  for (let i = 0; i < Math.min(fa.length, fb.length); i++) {
    const [x, y] = [fa[i], fb[i]];
    if (x === y) {
      continue;
    }
    const [xi, yi] = [INTEGER.test(x), INTEGER.test(y)];
    if (xi && yi && BigInt(x) !== BigInt(y)) {
      return BigInt(x) < BigInt(y) ? -1 : 1;
    }
    if (xi !== yi) {
      return xi ? -1 : 1;
    }
    if (!xi) {
      return x < y ? -1 : 1;
    }
  }
  return fa.length - fb.length || (a < b ? -1 : a > b ? 1 : 0);
}

// pg_dump writes rows in physical order, which changes whenever a row is updated
export function sortCopyRows(dump: string): string {
  return mapCopyRows(dump, (_table, rows) => [...rows].sort(compareRows));
}

// Stalwart's tables m and y mix expiring rate-limit counters with data that must stay; the
// first key byte names the kind. Drop RCPT (0x02), authentication (0x05), SMTP (0x06),
// authenticated HTTP (0x08) and anonymous HTTP (0x09) limits; keep the rest, such as Bayes
// (0x11) and trusted-reply (0x13) entries.
export function dropStalwartRateLimits(dump: string): string {
  return mapCopyRows(dump, (table, rows) =>
    table === "public.m" || table === "public.y"
      ? rows.filter((row) => !/^\\\\x0[25689]/.test(row))
      : rows,
  );
}

// mysqldump has no --ignore-table-data; drop the tables' INSERT lines instead
function dropMysqlTableData(dump: string, tables: string[]): string {
  return dump
    .split("\n")
    .filter((line) => !tables.some((table) => line.startsWith(`INSERT INTO \`${table}\` `)))
    .join("\n");
}

export function normalizeDump(service: string, dump: string): string {
  const capture = captures[service];
  if (capture.engine === "mysql") {
    return dropMysqlTableData(dump, capture.excludeTableData);
  }
  return sortCopyRows(service === "stalwart" ? dropStalwartRateLimits(dump) : dump);
}
