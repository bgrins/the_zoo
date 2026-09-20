import { spawn } from "node:child_process";
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
  options: { env?: Record<string, string | undefined>; cwd?: string; bundle?: string } = {},
): Promise<CLIResult> {
  return new Promise((resolve, reject) => {
    const [command, entry] = options.bundle
      ? [process.execPath, options.bundle]
      : [TSX_PATH, CLI_PATH];
    const proc = spawn(command, [entry, ...args], {
      cwd: options.cwd ?? ROOT_DIR,
      env: cliEnv(options.env),
    });

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
  exitCode?: number;
}

export interface FakeDocker {
  /** Env vars that put the fake docker first on PATH and point it at its state */
  env: Record<string, string>;
  /** Every docker invocation so far, as argument arrays */
  calls: () => string[][];
  cleanup: () => void;
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
// Each call is logged as one line of \x1f-separated arguments. Rules live in
// numbered directories and the first whose regex matches the joined arguments wins.
const FAKE_DOCKER_SCRIPT = `#!/bin/sh
printf '%s\\037' "$@" >> "$FAKE_DOCKER_LOG"
printf '\\n' >> "$FAKE_DOCKER_LOG"
for rule in "$FAKE_DOCKER_RULES"/*; do
  [ -d "$rule" ] || continue
  if printf '%s' "$*" | grep -Eq -f "$rule/match"; then
    cat "$rule/stdout"
    exit "$(cat "$rule/code")"
  fi
done
exit 0
`;

/**
 * Create a stand-in docker binary so CLI tests don't depend on (or disturb) the
 * real Docker daemon. `projects` is what `docker compose ls` reports as running.
 */
export function createFakeDocker(
  options: { projects?: string[]; rules?: FakeDockerRule[] } = {},
): FakeDocker {
  const dir = makeTempDir("thezoo-fake-docker");
  const logPath = path.join(dir, "calls.log");
  const rulesDir = path.join(dir, "rules");
  const scriptPath = path.join(dir, "docker");

  const rules: FakeDockerRule[] = [
    ...(options.rules ?? []),
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
    writeFileSync(path.join(ruleDir, "code"), String(rule.exitCode ?? 0));
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
        .map((line) => line.split("\x1f").slice(0, -1)),
    cleanup: () => rmSync(dir, { recursive: true, force: true }),
  };
}
