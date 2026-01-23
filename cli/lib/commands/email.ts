import { exec } from "node:child_process";
import { existsSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { promisify } from "node:util";
import chalk from "chalk";
import { checkDocker, dockerComposeExecInteractive } from "../utils/docker";
import { getProjectName } from "../utils/project";
import { paths } from "../utils/config";

const execAsync = promisify(exec);

interface EmailOptions {
  instance?: string;
}

interface EmailSendOptions extends EmailOptions {
  from: string;
  to: string;
  subject: string;
  body: string;
  html?: boolean;
  password?: string;
}

interface EmailUsersOptions extends EmailOptions {
  domain?: string;
}

interface EmailCheckOptions extends EmailOptions {
  user: string;
  password?: string;
  folder?: string;
  limit?: number;
}

/**
 * Try to find the Zoo repo root by walking up from this source file location.
 * This makes dev-mode CLI robust even when invoked from other directories.
 */
function findZooRepoRoot(): string | null {
  // Allow explicit override (recommended)
  const explicit = process.env.ZOO_REPO_ROOT || process.env.ZOO_ROOT || process.env.THE_ZOO_ROOT;
  if (explicit && existsSync(path.join(explicit, "docker-compose.yaml"))) {
    return explicit;
  }

  // Start from this file's directory
  const here = path.dirname(fileURLToPath(import.meta.url));

  // Walk up a few levels looking for docker-compose.yaml
  let cur = here;
  for (let i = 0; i < 8; i++) {
    const candidate = path.join(cur, "docker-compose.yaml");
    if (existsSync(candidate)) return cur;

    const parent = path.dirname(cur);
    if (parent === cur) break;
    cur = parent;
  }

  return null;
}

/**
 * Get the zoo source path for a running instance.
 *
 * IMPORTANT CHANGE:
 * - In dev mode (ZOO_DEV=1), always prefer the real repo root as cwd.
 * - Only use the runtime instance path if it exists; otherwise fallback to repo root.
 */
function getZooSourcePath(projectName: string): string {
  const repoRoot = findZooRepoRoot();

  // If dev mode, always run compose from the repo root so cwd is valid.
  if (process.env.ZOO_DEV === "1" && repoRoot) {
    return repoRoot;
  }

  // Extract instance ID from project name
  const match = projectName.match(/^thezoo-cli-instance-(.+?)-v/);
  if (match) {
    const instanceId = match[1];
    // In development mode, the zoo sources are in runtime directory
    const instancePath = path.join(paths.runtime, instanceId, "zoo");
    if (existsSync(instancePath)) return instancePath;
    // If the runtime path doesn't exist, fall back to repo root
    if (repoRoot) return repoRoot;
  }

  // Fallbacks
  if (repoRoot) return repoRoot;
  return process.cwd();
}

// Make authenticated request to Stalwart API using curl via proxy
async function stalwartRequest(
  endpoint: string,
  options: {
    method?: string;
    body?: any;
    auth?: { username: string; password: string };
  } = {},
): Promise<any> {
  const proxyPort = process.env.ZOO_PROXY_PORT || "3128";
  const proxyUrl = `http://localhost:${proxyPort}`;
  const url = `https://mail-api.zoo${endpoint}`;

  // Build curl command
  let curlCmd = `curl -s -k --proxy ${proxyUrl}`;

  // Add method
  if (options.method && options.method !== "GET") {
    curlCmd += ` -X ${options.method}`;
  }

  // Add auth
  if (options.auth) {
    curlCmd += ` -u "${options.auth.username}:${options.auth.password}"`;
  }

  // Add headers
  curlCmd += ` -H "Content-Type: application/json"`;

  // Add body
  if (options.body) {
    const bodyStr = JSON.stringify(options.body).replace(/"/g, '\\"');
    curlCmd += ` -d "${bodyStr}"`;
  }

  curlCmd += ` "${url}"`;

  try {
    const { stdout, stderr } = await execAsync(curlCmd);

    if (stderr) {
      throw new Error(`curl error: ${stderr}`);
    }

    // Try to parse JSON response
    try {
      return JSON.parse(stdout);
    } catch (_e) {
      throw new Error(`Invalid JSON response: ${stdout}`);
    }
  } catch (error) {
    if (error instanceof Error) {
      throw new Error(`API request failed: ${error.message}`);
    }
    throw error;
  }
}

export async function emailUsers(options: EmailUsersOptions): Promise<void> {
  const dockerRunning = await checkDocker();
  if (!dockerRunning) {
    console.error(chalk.red("❌ Docker is not running. Please start Docker first."));
    process.exit(1);
  }

  try {
    const projectName = await getProjectName(options.instance);
    console.log(chalk.gray(`Using project: ${projectName}`));

    const response = await stalwartRequest("/api/principal", {
      auth: { username: "admin", password: "zoo-mail-admin-pw" },
    });

    const users = response.data.items.filter((item: any) => item.type === "individual");
    const domains = response.data.items.filter((item: any) => item.type === "domain");

    let filteredUsers = users;
    if (options.domain) {
      filteredUsers = users.filter((user: any) => user.name.endsWith(`@${options.domain}`));
    }

    console.log(chalk.bold("\n📧 Email Domains:"));
    domains.forEach((domain: any) => {
      console.log(chalk.cyan(`  • ${domain.name}`));
    });

    console.log(chalk.bold("\n👥 Email Users:"));
    if (filteredUsers.length === 0) {
      console.log(chalk.yellow("  No users found"));
    } else {
      filteredUsers.forEach((user: any) => {
        console.log(
          chalk.green(`  • ${user.name}`),
          chalk.gray(`(${user.description || "No description"})`),
        );
      });
    }

    console.log(chalk.gray(`\nTotal: ${filteredUsers.length} users`));
  } catch (error) {
    console.error(chalk.red("❌ Failed to list email users:"), error);
    process.exit(1);
  }
}

export async function emailSend(options: EmailSendOptions): Promise<void> {
  if (!options.password) {
    console.error(chalk.red("❌ Password is required. Use --password option."));
    process.exit(1);
  }

  const dockerRunning = await checkDocker();
  if (!dockerRunning) {
    console.error(chalk.red("❌ Docker is not running. Please start Docker first."));
    process.exit(1);
  }

  try {
    const projectName = await getProjectName(options.instance);
    console.log(chalk.gray(`Using project: ${projectName}`));

    console.log(chalk.yellow("📧 Sending email..."));
    console.log(chalk.gray(`From: ${options.from}`));
    console.log(chalk.gray(`To: ${options.to}`));
    console.log(chalk.gray(`Subject: ${options.subject}`));

    const swaksArgs = [
      "--to",
      options.to,
      "--from",
      options.from,
      "--server",
      "stalwart:587",
      "--auth-user",
      options.from,
      "--auth-password",
      options.password,
      "--header",
      `Subject: ${options.subject}`,
      "--tls",
    ];

    if (options.html) {
      swaksArgs.push("--add-header", "Content-Type: text/html");
      swaksArgs.push("--body", options.body);
    } else {
      swaksArgs.push("--body", options.body);
    }

    const zooSourcePath = getZooSourcePath(projectName);

    await dockerComposeExecInteractive("stalwart", ["swaks", ...swaksArgs], {
      cwd: zooSourcePath,
      projectName,
      interactive: false,
    });

    console.log(chalk.green("✅ Email sent successfully!"));
  } catch (error) {
    console.error(chalk.red("❌ Failed to send email:"), error);
    process.exit(1);
  }
}

export async function emailSwaks(args: string[], options: EmailOptions): Promise<void> {
  const dockerRunning = await checkDocker();
  if (!dockerRunning) {
    console.error(chalk.red("❌ Docker is not running. Please start Docker first."));
    process.exit(1);
  }

  try {
    const projectName = await getProjectName(options.instance);
    console.log(chalk.gray(`Using project: ${projectName}`));

    if (args.length === 0) {
      console.log(chalk.yellow("📧 Swaks - Swiss Army Knife for SMTP"));
      console.log(chalk.gray("\nExamples:"));
      console.log(chalk.green("  # Send a simple test email"));
      console.log(
        `  npm run cli email swaks -- --to alex.chen@snappymail.zoo --from test@zoo --server stalwart:25`,
      );
      console.log(chalk.green("\n  # Send with subject and body"));
      console.log(
        `  npm run cli email swaks -- --to user@zoo --from admin@zoo --server stalwart:25 --header "Subject: Test" --body "Hello"`,
      );
      console.log(chalk.green("\n  # Send with authentication"));
      console.log(
        `  npm run cli email swaks -- --to user@zoo --from alex.chen@snappymail.zoo --server stalwart:587 --auth-user alex.chen@snappymail.zoo --auth-password Password.123`,
      );
      console.log(chalk.green("\n  # Show full swaks help"));
      console.log(`  npm run cli email swaks -- --help`);
      return;
    }

    const swaksCmd = `swaks ${args.join(" ")}`;
    const zooSourcePath = getZooSourcePath(projectName);

    console.log(chalk.gray(`Running: ${swaksCmd}`));
    console.log("");

    await dockerComposeExecInteractive("stalwart", ["swaks", ...args], {
      cwd: zooSourcePath,
      projectName,
      interactive: process.stdout.isTTY,
    });
  } catch (error) {
    console.error(chalk.red("❌ Failed to run swaks:"), error);
    process.exit(1);
  }
}

export async function emailCheck(options: EmailCheckOptions): Promise<void> {
  if (!options.password) {
    console.error(chalk.red("❌ Password is required. Use --password option."));
    process.exit(1);
  }

  const dockerRunning = await checkDocker();
  if (!dockerRunning) {
    console.error(chalk.red("❌ Docker is not running. Please start Docker first."));
    process.exit(1);
  }

  try {
    const projectName = await getProjectName(options.instance);
    console.log(chalk.gray(`Using project: ${projectName}`));

    const zooSourcePath = getZooSourcePath(projectName);
    const folder = options.folder || "INBOX";

    console.log(chalk.yellow(`📥 Checking ${folder} for ${options.user}...`));

    const statusCmd = `docker compose -p ${projectName} exec -T stalwart curl -s -u "${options.user}:${options.password}" "imap://localhost/${folder}" --request "EXAMINE ${folder}"`;
    const { stdout: statusOut } = await execAsync(statusCmd, { cwd: zooSourcePath });

    const existsMatch = statusOut.match(/\* (\d+) EXISTS/);
    const messageCount = existsMatch ? parseInt(existsMatch[1]) : 0;

    console.log(chalk.green(`\nMailbox: ${folder}`));
    console.log(chalk.gray(`Messages: ${messageCount}`));

    if (messageCount === 0) {
      console.log(chalk.yellow("\nNo messages in this mailbox."));
      return;
    }

    const limit = options.limit || 10;
    const fetchCount = Math.min(messageCount, limit);
    const startUID = Math.max(1, messageCount - fetchCount + 1);

    console.log(chalk.gray(`\nFetching last ${fetchCount} message(s)...\n`));

    for (let i = messageCount; i >= startUID; i--) {
      const fetchCmd = `docker compose -p ${projectName} exec -T stalwart curl -s -u "${options.user}:${options.password}" "imap://localhost/${folder};MAILINDEX=${i}"`;

      const { stdout: messageOut } = await execAsync(fetchCmd, { cwd: zooSourcePath });

      console.log(chalk.blue(`━━━ Message ${i} ━━━`));
      console.log(messageOut);
      console.log("");
    }

    if (messageCount > fetchCount) {
      console.log(
        chalk.gray(`\nShowing ${fetchCount} of ${messageCount} messages. Use --limit to see more.`),
      );
    }
  } catch (error) {
    console.error(chalk.red("❌ Failed to check email:"), error);
    process.exit(1);
  }
}
