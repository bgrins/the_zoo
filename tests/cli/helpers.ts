import { type ChildProcess, spawn } from "node:child_process";
import { chmodSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

export const ROOT_DIR = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..", "..");
export const CLI_PATH = path.join(ROOT_DIR, "cli", "bin", "thezoo.ts");
export const TSX_PATH = path.join(ROOT_DIR, "node_modules", ".bin", "tsx");

export interface CLIResult {
  code: number | null;
  stdout: string;
  stderr: string;
}

// What the CLI and tsx need from the developer's environment. Anything else, such as
// THE_ZOO_HOME, FORCE_COLOR or the .env values vitest loads, would change what tests see.
const INHERITED_ENV = [
  "PATH",
  "HOME",
  "TMPDIR",
  "TMP",
  "TEMP",
  "USER",
  "LOGNAME",
  "SHELL",
  "LANG",
  "SystemRoot",
  "ComSpec",
  "PATHEXT",
  "USERPROFILE",
  "APPDATA",
  "LOCALAPPDATA",
];

/**
 * Environment for a CLI process: the INHERITED_ENV variables, development mode and no
 * colors, then `overrides`, where undefined unsets a variable
 */
export function cliEnv(overrides: Record<string, string | undefined> = {}): NodeJS.ProcessEnv {
  const inherited = Object.fromEntries(INHERITED_ENV.map((key) => [key, process.env[key]]));
  return { ...inherited, ZOO_DEV: "1", FORCE_COLOR: "0", ...overrides };
}

/**
 * Run the CLI sources with tsx in development mode, or a built bundle (`bundle`) with node
 */
export function runCLI(
  args: string[],
  options: {
    env?: Record<string, string | undefined>;
    cwd?: string;
    bundle?: string;
    onSpawn?: (proc: ChildProcess) => void;
  } = {},
): Promise<CLIResult> {
  return new Promise((resolve, reject) => {
    const [command, entry] = options.bundle
      ? [process.execPath, options.bundle]
      : [TSX_PATH, CLI_PATH];
    const proc = spawn(command, [entry, ...args], {
      cwd: options.cwd ?? ROOT_DIR,
      env: cliEnv(options.env),
    });
    options.onSpawn?.(proc);

    let stdout = "";
    let stderr = "";
    proc.stdout.on("data", (data) => {
      stdout += data.toString();
    });
    proc.stderr.on("data", (data) => {
      stderr += data.toString();
    });
    proc.on("close", (code) => resolve({ code, stdout, stderr }));
    proc.on("error", reject);
  });
}

/**
 * The instance ID a successful `the_zoo create` (or `create --dry-run`) printed
 */
export function createdInstanceId(result: CLIResult): string {
  const id = result.stdout.match(/Instance ID: (\w+)/)?.[1];
  if (result.code !== 0 || id === undefined) {
    throw new Error(`create exited with ${result.code}:\n${result.stdout}${result.stderr}`);
  }
  return id;
}

export function makeTempDir(prefix: string): string {
  return mkdtempSync(path.join(os.tmpdir(), `${prefix}-`));
}

export interface FakeDockerRule {
  /** Regex tested against the space-joined docker arguments */
  match: string;
  stdout?: string;
  stderr?: string;
  exitCode?: number;
  /** Never answer, like a hung Docker Desktop */
  hang?: boolean;
  /** Answer after this long */
  delaySeconds?: number;
  /** Answer only the first matching call; later ones go to the next matching rule */
  once?: boolean;
}

export interface FakeDocker {
  /** Env vars that put the fake docker first on PATH and point it at its state */
  env: Record<string, string>;
  /** Every docker invocation so far, as argument arrays */
  calls: () => string[][];
  cleanup: () => void;
}

export interface FakeContainer {
  service: string;
  running?: boolean;
  labels?: Record<string, string>;
  // Defaults to sha256:<service>
  image?: string;
  // Volume name by mount destination
  volumes?: Record<string, string>;
  env?: string[];
}

/**
 * Rules answering the `docker ps` and `docker inspect` calls that list a project's containers.
 * Container IDs are id-<service>.
 */
export function projectContainerRules(
  project: string,
  containers: FakeContainer[],
): FakeDockerRule[] {
  const inspected = containers.map((c) => ({
    Id: `id-${c.service}`,
    Image: c.image ?? `sha256:${c.service}`,
    State: { Running: c.running ?? true },
    Config: { Labels: { "com.docker.compose.service": c.service, ...c.labels }, Env: c.env ?? [] },
    Mounts: Object.entries(c.volumes ?? {}).map(([Destination, Name]) => ({
      Type: "volume",
      Name,
      Destination,
    })),
  }));
  return [
    {
      match: `^ps -a -q --filter label=com.docker.compose.project=${project} `,
      stdout: containers.map((c) => `id-${c.service}\n`).join(""),
    },
    { match: "^inspect ", stdout: JSON.stringify(inspected) },
  ];
}

/**
 * A stand-in curl that records its arguments and always prints `response`.
 * Its `dir` must come before the fake docker's on PATH.
 */
export function createFakeCurl(response: string) {
  const dir = makeTempDir("thezoo-fake-curl");
  const logPath = path.join(dir, "calls.log");
  writeFileSync(path.join(dir, "response"), response);
  writeFileSync(logPath, "");
  writeFileSync(
    path.join(dir, "curl"),
    `#!/bin/sh\necho "$*" >> "${logPath}"\ncat "${path.join(dir, "response")}"\n`,
  );
  chmodSync(path.join(dir, "curl"), 0o755);

  return {
    dir,
    calls: () => readFileSync(logPath, "utf8").split("\n").filter(Boolean),
    cleanup: () => rmSync(dir, { recursive: true, force: true }),
  };
}

// Plain sh rather than node: node itself reacts to arguments like --env-file.
// Each call is logged as one line of \x1f-separated arguments, with newlines inside them
// (scripts for docker run) logged as \x1e. Rules live in numbered directories and the first
// whose regex matches a line of the joined arguments wins.
const FAKE_DOCKER_SCRIPT = `#!/bin/sh
printf '%s\\037' "$@" | tr '\\n' '\\036' >> "$FAKE_DOCKER_LOG"
printf '\\n' >> "$FAKE_DOCKER_LOG"
for rule in "$FAKE_DOCKER_RULES"/*; do
  [ -d "$rule" ] || continue
  if printf '%s' "$*" | grep -Eq -f "$rule/match"; then
    [ -f "$rule/hang" ] && exec sleep 60
    [ ! -f "$rule/delay" ] || sleep "$(cat "$rule/delay")"
    cat "$rule/stdout"
    cat "$rule/stderr" >&2
    code=$(cat "$rule/code")
    [ ! -f "$rule/once" ] || rm -rf "$rule"
    exit "$code"
  fi
done
exit 0
`;

/**
 * What the fake `docker compose config --format json` reports: core services, an
 * on-demand app and a heavy one
 */
export const FAKE_COMPOSE_SERVICES = {
  caddy: { image: "the_zoo-caddy", mem_limit: "1073741824" },
  redis: { image: "redis:7.4.7-alpine", mem_limit: "536870912" },
  miniflux: { image: "miniflux/miniflux:2.2.9", mem_limit: "536870912", profiles: ["on-demand"] },
  postmill: { image: "vwa-reddit:1", mem_limit: "536870912", profiles: ["on-demand", "heavy"] },
};

// The snapshots volume the fake config names, whatever the env file says
export const FAKE_SNAPSHOTS_VOLUME = "fake_zoo_snapshots";

const DAEMON_DOWN_ERROR =
  "Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?\n";

/**
 * Create a stand-in docker binary so CLI tests don't depend on (or disturb) the
 * real Docker daemon. `projects` is what `docker compose ls` reports as running.
 * `docker compose config` reports FAKE_COMPOSE_SERVICES. With `daemon` "down" every other
 * command after `rules` fails like Docker's when the daemon isn't running; with "hung"
 * none of them answers.
 */
export function createFakeDocker(
  options: { projects?: string[]; rules?: FakeDockerRule[]; daemon?: "down" | "hung" } = {},
): FakeDocker {
  const dir = makeTempDir("thezoo-fake-docker");
  const logPath = path.join(dir, "calls.log");
  const rulesDir = path.join(dir, "rules");
  const scriptPath = path.join(dir, "docker");

  const daemonRules: Record<string, FakeDockerRule[]> = {
    down: [{ match: ".", exitCode: 1, stderr: DAEMON_DOWN_ERROR }],
    hung: [{ match: ".", hang: true }],
  };
  const rules: FakeDockerRule[] = [
    ...(options.rules ?? []),
    // Client-side, so it works without the daemon
    {
      match: "^compose .*config --format json$",
      stdout: JSON.stringify({
        services: FAKE_COMPOSE_SERVICES,
        volumes: { zoo_snapshots: { name: FAKE_SNAPSHOTS_VOLUME, external: true } },
      }),
    },
    ...(options.daemon ? daemonRules[options.daemon] : []),
    {
      match: "^compose ls",
      stdout: JSON.stringify((options.projects ?? []).map((Name) => ({ Name }))),
    },
  ];

  rules.forEach((rule, index) => {
    const ruleDir = path.join(rulesDir, String(index).padStart(3, "0"));
    mkdirSync(ruleDir, { recursive: true });
    writeFileSync(path.join(ruleDir, "match"), `${rule.match}\n`);
    writeFileSync(path.join(ruleDir, "stdout"), rule.stdout ?? "");
    writeFileSync(path.join(ruleDir, "stderr"), rule.stderr ?? "");
    writeFileSync(path.join(ruleDir, "code"), String(rule.exitCode ?? 0));
    if (rule.hang) {
      writeFileSync(path.join(ruleDir, "hang"), "");
    }
    if (rule.delaySeconds !== undefined) {
      writeFileSync(path.join(ruleDir, "delay"), String(rule.delaySeconds));
    }
    if (rule.once) {
      writeFileSync(path.join(ruleDir, "once"), "");
    }
  });
  writeFileSync(logPath, "");
  writeFileSync(scriptPath, FAKE_DOCKER_SCRIPT);
  chmodSync(scriptPath, 0o755);

  return {
    env: {
      PATH: `${dir}${path.delimiter}${process.env.PATH}`,
      FAKE_DOCKER_LOG: logPath,
      FAKE_DOCKER_RULES: rulesDir,
    },
    calls: () =>
      readFileSync(logPath, "utf8")
        .split("\n")
        .filter(Boolean)
        .map((line) =>
          line
            .split("\x1f")
            .slice(0, -1)
            .map((arg) => arg.replaceAll("\x1e", "\n")),
        ),
    cleanup: () => rmSync(dir, { recursive: true, force: true }),
  };
}
