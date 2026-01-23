import { exec } from "node:child_process";
import { existsSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { promisify } from "node:util";
import chalk from "chalk";
import { checkDocker } from "../utils/docker";
import { getProjectName } from "../utils/project";
import { paths } from "../utils/config";

const execAsync = promisify(exec);

interface KanbanOptions {
  instance?: string;
}

interface KanbanLoginOptions extends KanbanOptions {
  username: string;
  password: string;
}

interface KanbanCreateBoardOptions extends KanbanOptions {
  title: string;
  teamId?: string;
  template?: string;
}

interface KanbanCreateCardOptions extends KanbanOptions {
  boardId: string;
  title: string;
  description?: string;
}

interface KanbanCardsOptions extends KanbanOptions {
  boardId: string;
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

// Make authenticated request to Focalboard API using curl via proxy
async function focalboardRequest(
  endpoint: string,
  options: {
    method?: string;
    body?: any;
    token?: string;
  } = {},
): Promise<any> {
  const proxyPort = process.env.ZOO_PROXY_PORT || "3128";
  const proxyUrl = `http://localhost:${proxyPort}`;
  const url = `http://focalboard.zoo${endpoint}`;

  // Build curl command
  let curlCmd = `curl -s -k --proxy ${proxyUrl}`;

  // Add method
  if (options.method && options.method !== "GET") {
    curlCmd += ` -X ${options.method}`;
  }

  // Add auth token
  if (options.token) {
    curlCmd += ` -H "Authorization: Bearer ${options.token}"`;
  }

  // Add headers
  curlCmd += ` -H "Content-Type: application/json"`;
  curlCmd += ` -H "X-Requested-With: XMLHttpRequest"`;

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
      // If not JSON, return raw output
      return stdout;
    }
  } catch (error) {
    if (error instanceof Error) {
      throw new Error(`API request failed: ${error.message}`);
    }
    throw error;
  }
}

// Login and get auth token
async function getAuthToken(username: string, password: string): Promise<string> {
  const response = await focalboardRequest("/api/v2/login", {
    method: "POST",
    body: {
      type: "normal",
      username: username,
      password: password,
    },
  });

  if (response.token) {
    return response.token;
  }

  throw new Error(`Login failed: ${JSON.stringify(response)}`);
}

// Get signup token from database for registration
async function getSignupToken(projectName: string, zooSourcePath: string): Promise<string> {
  const cmd = `docker compose -p ${projectName} exec -T postgres psql -U focalboard_user -d focalboard_db -t -c "SELECT signup_token FROM teams WHERE id = '0';"`;
  const { stdout } = await execAsync(cmd, { cwd: zooSourcePath });
  return stdout.trim();
}

export async function kanbanUsers(options: KanbanOptions): Promise<void> {
  const dockerRunning = await checkDocker();
  if (!dockerRunning) {
    console.error(chalk.red("Docker is not running. Please start Docker first."));
    process.exit(1);
  }

  try {
    const projectName = await getProjectName(options.instance);
    console.log(chalk.gray(`Using project: ${projectName}`));

    // Login as admin to list users
    const token = await getAuthToken("admin", "admin123");

    // Get teams first (need team ID to list users)
    const teams = await focalboardRequest("/api/v2/teams", { token });

    if (!Array.isArray(teams) || teams.length === 0) {
      console.log(chalk.yellow("No teams found"));
      return;
    }

    const teamId = teams[0].id;

    // Get users in team
    const users = await focalboardRequest(`/api/v2/teams/${teamId}/users`, { token });

    console.log(chalk.bold("\n📋 Focalboard Users:"));
    if (!Array.isArray(users) || users.length === 0) {
      console.log(chalk.yellow("  No users found"));
    } else {
      users.forEach((user: any) => {
        const adminBadge = user.is_admin ? chalk.red(" [ADMIN]") : "";
        console.log(
          chalk.green(`  • ${user.username}${adminBadge}`),
          chalk.gray(`(${user.email || "no email"})`),
        );
      });
    }

    console.log(chalk.gray(`\nTotal: ${users?.length || 0} users`));
  } catch (error) {
    console.error(chalk.red("Failed to list users:"), error);
    process.exit(1);
  }
}

export async function kanbanBoards(options: KanbanOptions): Promise<void> {
  const dockerRunning = await checkDocker();
  if (!dockerRunning) {
    console.error(chalk.red("Docker is not running. Please start Docker first."));
    process.exit(1);
  }

  try {
    const projectName = await getProjectName(options.instance);
    console.log(chalk.gray(`Using project: ${projectName}`));

    // Login as admin
    const token = await getAuthToken("admin", "admin123");

    // Get teams first
    const teams = await focalboardRequest("/api/v2/teams", { token });

    if (!Array.isArray(teams) || teams.length === 0) {
      console.log(chalk.yellow("No teams found"));
      return;
    }

    const teamId = teams[0].id;

    // Get boards
    const boards = await focalboardRequest(`/api/v2/teams/${teamId}/boards`, { token });

    console.log(chalk.bold("\n📋 Focalboard Boards:"));
    if (!Array.isArray(boards) || boards.length === 0) {
      console.log(chalk.yellow("  No boards found"));
    } else {
      boards.forEach((board: any) => {
        const icon = board.icon || "📋";
        const templateBadge = board.isTemplate ? chalk.cyan(" [TEMPLATE]") : "";
        console.log(
          chalk.green(`  ${icon} ${board.title}${templateBadge}`),
          chalk.gray(`(ID: ${board.id})`),
        );
        if (board.description) {
          console.log(chalk.gray(`      ${board.description}`));
        }
      });
    }

    console.log(chalk.gray(`\nTotal: ${boards?.length || 0} boards`));
  } catch (error) {
    console.error(chalk.red("Failed to list boards:"), error);
    process.exit(1);
  }
}

export async function kanbanCards(options: KanbanCardsOptions): Promise<void> {
  const dockerRunning = await checkDocker();
  if (!dockerRunning) {
    console.error(chalk.red("Docker is not running. Please start Docker first."));
    process.exit(1);
  }

  try {
    const projectName = await getProjectName(options.instance);
    console.log(chalk.gray(`Using project: ${projectName}`));

    // Login as admin
    const token = await getAuthToken("admin", "admin123");

    const limit = options.limit || 100;

    // Get cards for board
    const cards = await focalboardRequest(
      `/api/v2/boards/${options.boardId}/cards?per_page=${limit}`,
      { token },
    );

    console.log(chalk.bold(`\n🃏 Cards on board ${options.boardId}:`));
    if (!Array.isArray(cards) || cards.length === 0) {
      console.log(chalk.yellow("  No cards found"));
    } else {
      cards.forEach((card: any) => {
        const icon = card.icon || "🃏";
        console.log(chalk.green(`  ${icon} ${card.title}`), chalk.gray(`(ID: ${card.id})`));
      });
    }

    console.log(chalk.gray(`\nTotal: ${cards?.length || 0} cards`));
  } catch (error) {
    console.error(chalk.red("Failed to list cards:"), error);
    process.exit(1);
  }
}

export async function kanbanCreateBoard(options: KanbanCreateBoardOptions): Promise<void> {
  const dockerRunning = await checkDocker();
  if (!dockerRunning) {
    console.error(chalk.red("Docker is not running. Please start Docker first."));
    process.exit(1);
  }

  try {
    const projectName = await getProjectName(options.instance);
    console.log(chalk.gray(`Using project: ${projectName}`));

    // Login as admin
    const token = await getAuthToken("admin", "admin123");

    // Get default team if not specified
    let teamId = options.teamId;
    if (!teamId) {
      const teams = await focalboardRequest("/api/v2/teams", { token });
      if (!Array.isArray(teams) || teams.length === 0) {
        console.error(chalk.red("No teams found"));
        process.exit(1);
      }
      teamId = teams[0].id;
    }

    console.log(chalk.yellow(`📋 Creating board: ${options.title}...`));

    const response = await focalboardRequest("/api/v2/boards", {
      method: "POST",
      token,
      body: {
        title: options.title,
        teamId: teamId,
        type: "O", // Open board
        showDescription: true,
        isTemplate: false,
      },
    });

    if (response.id) {
      console.log(chalk.green(`Board created successfully!`));
      console.log(chalk.gray(`   ID: ${response.id}`));
      console.log(chalk.gray(`   URL: http://focalboard.zoo/board/${response.id}`));
    } else {
      console.error(chalk.red(`Failed to create board: ${JSON.stringify(response)}`));
      process.exit(1);
    }
  } catch (error) {
    console.error(chalk.red("Failed to create board:"), error);
    process.exit(1);
  }
}

export async function kanbanCreateCard(options: KanbanCreateCardOptions): Promise<void> {
  const dockerRunning = await checkDocker();
  if (!dockerRunning) {
    console.error(chalk.red("Docker is not running. Please start Docker first."));
    process.exit(1);
  }

  try {
    const projectName = await getProjectName(options.instance);
    console.log(chalk.gray(`Using project: ${projectName}`));

    // Login as admin
    const token = await getAuthToken("admin", "admin123");

    console.log(chalk.yellow(`🃏 Creating card: ${options.title}...`));

    const response = await focalboardRequest(`/api/v2/boards/${options.boardId}/cards`, {
      method: "POST",
      token,
      body: {
        title: options.title,
        contentOrder: [],
        properties: {},
      },
    });

    if (response.id) {
      console.log(chalk.green(`Card created successfully!`));
      console.log(chalk.gray(`   ID: ${response.id}`));
      console.log(chalk.gray(`   Board: ${options.boardId}`));
    } else {
      console.error(chalk.red(`Failed to create card: ${JSON.stringify(response)}`));
      process.exit(1);
    }
  } catch (error) {
    console.error(chalk.red("Failed to create card:"), error);
    process.exit(1);
  }
}

export async function kanbanCreateUser(options: KanbanLoginOptions): Promise<void> {
  const dockerRunning = await checkDocker();
  if (!dockerRunning) {
    console.error(chalk.red("Docker is not running. Please start Docker first."));
    process.exit(1);
  }

  try {
    const projectName = await getProjectName(options.instance);
    console.log(chalk.gray(`Using project: ${projectName}`));

    const zooSourcePath = getZooSourcePath(projectName);

    // Get signup token from database
    const signupToken = await getSignupToken(projectName, zooSourcePath);
    if (!signupToken) {
      console.error(chalk.red("Failed to get signup token from database"));
      process.exit(1);
    }

    console.log(chalk.yellow(`👤 Creating user: ${options.username}...`));

    const email = `${options.username}@snappymail.zoo`;
    const response = await focalboardRequest("/api/v2/register", {
      method: "POST",
      body: {
        username: options.username,
        email: email,
        password: options.password,
        token: signupToken,
      },
    });

    if (response.token || response === "") {
      console.log(chalk.green(`User ${options.username} created successfully!`));
      console.log(chalk.gray(`   Email: ${email}`));
    } else if (JSON.stringify(response).includes("already exists")) {
      console.log(chalk.yellow(`User ${options.username} already exists`));
    } else {
      console.error(chalk.red(`Failed to create user: ${JSON.stringify(response)}`));
      process.exit(1);
    }
  } catch (error) {
    console.error(chalk.red("Failed to create user:"), error);
    process.exit(1);
  }
}

export async function kanbanLogin(options: KanbanLoginOptions): Promise<void> {
  const dockerRunning = await checkDocker();
  if (!dockerRunning) {
    console.error(chalk.red("Docker is not running. Please start Docker first."));
    process.exit(1);
  }

  try {
    const projectName = await getProjectName(options.instance);
    console.log(chalk.gray(`Using project: ${projectName}`));

    console.log(chalk.yellow(`🔐 Logging in as ${options.username}...`));

    const token = await getAuthToken(options.username, options.password);

    console.log(chalk.green(`Login successful!`));
    console.log(chalk.gray(`   Token: ${token.substring(0, 20)}...`));
    console.log(chalk.gray(`\nUse this token with --token flag for authenticated requests`));
  } catch (error) {
    console.error(chalk.red("Login failed:"), error);
    process.exit(1);
  }
}
