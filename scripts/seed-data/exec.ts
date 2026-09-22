import { execFileSync, execSync } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");

// auth.zoo hashes the password and sends a welcome email before responding
export const SEED_REQUEST_TIMEOUT = 15000;

export class DockerExecError extends Error {
  constructor(
    message: string,
    readonly output: string,
  ) {
    super(message);
  }
}

function execError(label: string, error: unknown): DockerExecError {
  const { stdout = "", stderr = "" } = error as { stdout?: string; stderr?: string };
  const output = `${stdout}${stderr}`;
  return new DockerExecError(`${label}\n${output}`.trim(), output);
}

// Run a command in a service container. Throws a DockerExecError with the command's output
// on failure; match expected errors against `output`, since the message includes the command.
export function execDocker(container: string, command: string): string {
  try {
    return execSync(`docker compose exec -T ${container} ${command}`, {
      encoding: "utf8",
      stdio: "pipe",
      cwd: ROOT,
    });
  } catch (error) {
    throw execError(`${container}: ${command}`, error);
  }
}

// Like execDocker, without a shell in between, so arguments need no quoting
export function execDockerArgs(
  container: string,
  args: string[],
  options: { user?: string; input?: Buffer | string } = {},
): string {
  const user = options.user ? ["-u", options.user] : [];
  try {
    return execFileSync("docker", ["compose", "exec", "-T", ...user, container, ...args], {
      encoding: "utf8",
      stdio: "pipe",
      cwd: ROOT,
      input: options.input,
      maxBuffer: 64 * 1024 * 1024,
    });
  } catch (error) {
    throw execError(`${container}: ${args.join(" ")}`, error);
  }
}

export const outputOf = (error: unknown) => (error instanceof DockerExecError ? error.output : "");

export function psql(user: string, db: string, sql: string): string {
  return execDockerArgs("postgres", ["psql", "-U", user, "-d", db, "-t", "-A", "-c", sql]).trim();
}

// Run mmctl in local mode (MM_SERVICESETTINGS_ENABLELOCALMODE=true). Returns false instead of
// throwing when the output matches `alreadyDone`.
export function mmctl(args: string, alreadyDone?: RegExp): boolean {
  try {
    execDocker("mattermost", `mmctl ${args} --local`);
    return true;
  } catch (error) {
    if (alreadyDone?.test(outputOf(error))) {
      return false;
    }
    throw error;
  }
}
