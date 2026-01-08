import { exec } from "node:child_process";
import path from "node:path";
import { promisify } from "node:util";
import chalk from "chalk";
import { checkDocker, dockerComposeExecInteractive } from "../utils/docker";
import { getProjectName } from "../utils/project";
import { paths } from "../utils/config";

const execAsync = promisify(exec);

interface GiteaOptions {
  instance?: string;
}

interface GiteaCreateUserOptions extends GiteaOptions {
  username: string;
  email: string;
  password: string;
  admin?: boolean;
}

interface GiteaCreateOrgOptions extends GiteaOptions {
  name: string;
  fullName?: string;
  description?: string;
  website?: string;
}

interface GiteaCreateRepoOptions extends GiteaOptions {
  name: string;
  owner: string;
  description?: string;
  private?: boolean;
  autoInit?: boolean;
}

interface GiteaCreateIssueOptions extends GiteaOptions {
  owner: string;
  repo: string;
  title: string;
  body?: string;
}

interface GiteaAddFileOptions extends GiteaOptions {
  owner: string;
  repo: string;
  path: string;
  content: string;
  message?: string;
  branch?: string;
}

/**
 * Get the zoo source path for a running instance
 */
function getZooSourcePath(projectName: string): string {
  // Extract instance ID from project name
  const match = projectName.match(/^thezoo-cli-instance-(.+?)-v/);
  if (match) {
    const instanceId = match[1];
    // In development mode, the zoo sources are in runtime directory
    const instancePath = path.join(paths.runtime, instanceId, "zoo");
    return instancePath;
  }
  // Fallback to current directory for main development
  return process.cwd();
}

// Make authenticated request to Gitea API using curl via proxy
async function giteaRequest(
  endpoint: string,
  options: {
    method?: string;
    body?: any;
    auth?: { username: string; password: string };
  } = {},
): Promise<any> {
  const proxyPort = process.env.ZOO_PROXY_PORT || "3128";
  const proxyUrl = `http://localhost:${proxyPort}`;
  const url = `https://gitea.zoo${endpoint}`;

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

export async function giteaUsers(options: GiteaOptions): Promise<void> {
  // Check if Docker is running
  const dockerRunning = await checkDocker();
  if (!dockerRunning) {
    console.error(chalk.red("❌ Docker is not running. Please start Docker first."));
    process.exit(1);
  }

  try {
    // Get the project name (handles instance validation)
    const projectName = await getProjectName(options.instance);
    console.log(chalk.gray(`Using project: ${projectName}`));

    // Use admin credentials to list users
    const response = await giteaRequest("/api/v1/admin/users", {
      auth: { username: "admin", password: "admin123" },
    });

    console.log(chalk.bold("\n👥 Gitea Users:"));
    if (!Array.isArray(response) || response.length === 0) {
      console.log(chalk.yellow("  No users found"));
    } else {
      response.forEach((user: any) => {
        const adminBadge = user.is_admin ? chalk.red(" [ADMIN]") : "";
        console.log(
          chalk.green(`  • ${user.login}${adminBadge}`),
          chalk.gray(`(${user.email})`),
        );
      });
    }

    console.log(chalk.gray(`\nTotal: ${response.length || 0} users`));
  } catch (error) {
    console.error(chalk.red("❌ Failed to list users:"), error);
    process.exit(1);
  }
}

export async function giteaCreateUser(options: GiteaCreateUserOptions): Promise<void> {
  // Check if Docker is running
  const dockerRunning = await checkDocker();
  if (!dockerRunning) {
    console.error(chalk.red("❌ Docker is not running. Please start Docker first."));
    process.exit(1);
  }

  try {
    const projectName = await getProjectName(options.instance);
    console.log(chalk.gray(`Using project: ${projectName}`));

    console.log(chalk.yellow(`👤 Creating user: ${options.username}...`));

    // Use gitea CLI command via docker exec
    const zooSourcePath = getZooSourcePath(projectName);
    const adminFlag = options.admin ? "--admin" : "";

    const createCmd = `su git -c "gitea admin user create --username '${options.username}' --password '${options.password}' --email '${options.email}' ${adminFlag} --must-change-password=false"`;

    await dockerComposeExecInteractive("gitea-zoo", ["sh", "-c", createCmd], {
      cwd: zooSourcePath,
      projectName,
      interactive: false,
    });

    console.log(chalk.green(`✅ User ${options.username} created successfully!`));
  } catch (error) {
    console.error(chalk.red("❌ Failed to create user:"), error);
    process.exit(1);
  }
}

export async function giteaCreateOrg(options: GiteaCreateOrgOptions): Promise<void> {
  // Check if Docker is running
  const dockerRunning = await checkDocker();
  if (!dockerRunning) {
    console.error(chalk.red("❌ Docker is not running. Please start Docker first."));
    process.exit(1);
  }

  try {
    const projectName = await getProjectName(options.instance);
    console.log(chalk.gray(`Using project: ${projectName}`));

    console.log(chalk.yellow(`🏢 Creating organization: ${options.name}...`));

    const response = await giteaRequest("/api/v1/orgs", {
      method: "POST",
      auth: { username: "admin", password: "admin123" },
      body: {
        username: options.name,
        full_name: options.fullName || options.name,
        description: options.description || "",
        website: options.website || "",
        visibility: "public",
      },
    });

    if (response.id) {
      console.log(chalk.green(`✅ Organization ${options.name} created successfully!`));
    } else {
      console.error(chalk.red(`❌ Failed to create organization: ${JSON.stringify(response)}`));
      process.exit(1);
    }
  } catch (error) {
    console.error(chalk.red("❌ Failed to create organization:"), error);
    process.exit(1);
  }
}

export async function giteaCreateRepo(options: GiteaCreateRepoOptions): Promise<void> {
  // Check if Docker is running
  const dockerRunning = await checkDocker();
  if (!dockerRunning) {
    console.error(chalk.red("❌ Docker is not running. Please start Docker first."));
    process.exit(1);
  }

  try {
    const projectName = await getProjectName(options.instance);
    console.log(chalk.gray(`Using project: ${projectName}`));

    console.log(chalk.yellow(`📦 Creating repository: ${options.owner}/${options.name}...`));

    // Determine if owner is an org or user by checking if it exists as org
    let endpoint = "/api/v1/user/repos";
    let auth = { username: options.owner, password: `${options.owner}123` };

    try {
      // Try to get org info
      const orgCheck = await giteaRequest(`/api/v1/orgs/${options.owner}`, {
        auth: { username: "admin", password: "admin123" },
      });

      if (orgCheck.id) {
        // It's an organization
        endpoint = `/api/v1/orgs/${options.owner}/repos`;
        auth = { username: "admin", password: "admin123" };
      }
    } catch (_e) {
      // Not an org, use user endpoint
    }

    const response = await giteaRequest(endpoint, {
      method: "POST",
      auth: auth,
      body: {
        name: options.name,
        description: options.description || "",
        private: options.private || false,
        auto_init: options.autoInit !== false, // default true
      },
    });

    if (response.id) {
      console.log(chalk.green(`✅ Repository ${options.owner}/${options.name} created successfully!`));
      console.log(chalk.gray(`   URL: https://gitea.zoo/${options.owner}/${options.name}`));
    } else {
      console.error(chalk.red(`❌ Failed to create repository: ${JSON.stringify(response)}`));
      process.exit(1);
    }
  } catch (error) {
    console.error(chalk.red("❌ Failed to create repository:"), error);
    process.exit(1);
  }
}

export async function giteaCreateIssue(options: GiteaCreateIssueOptions): Promise<void> {
  // Check if Docker is running
  const dockerRunning = await checkDocker();
  if (!dockerRunning) {
    console.error(chalk.red("❌ Docker is not running. Please start Docker first."));
    process.exit(1);
  }

  try {
    const projectName = await getProjectName(options.instance);
    console.log(chalk.gray(`Using project: ${projectName}`));

    console.log(chalk.yellow(`🐛 Creating issue in ${options.owner}/${options.repo}...`));

    const response = await giteaRequest(`/api/v1/repos/${options.owner}/${options.repo}/issues`, {
      method: "POST",
      auth: { username: options.owner, password: `${options.owner}123` },
      body: {
        title: options.title,
        body: options.body || "",
      },
    });

    if (response.number) {
      console.log(chalk.green(`✅ Issue #${response.number} created successfully!`));
      console.log(chalk.gray(`   Title: ${options.title}`));
      console.log(chalk.gray(`   URL: https://gitea.zoo/${options.owner}/${options.repo}/issues/${response.number}`));
    } else {
      console.error(chalk.red(`❌ Failed to create issue: ${JSON.stringify(response)}`));
      process.exit(1);
    }
  } catch (error) {
    console.error(chalk.red("❌ Failed to create issue:"), error);
    process.exit(1);
  }
}

export async function giteaAddFile(options: GiteaAddFileOptions): Promise<void> {
  // Check if Docker is running
  const dockerRunning = await checkDocker();
  if (!dockerRunning) {
    console.error(chalk.red("❌ Docker is not running. Please start Docker first."));
    process.exit(1);
  }

  try {
    const projectName = await getProjectName(options.instance);
    console.log(chalk.gray(`Using project: ${projectName}`));

    console.log(chalk.yellow(`📝 Adding file ${options.path} to ${options.owner}/${options.repo}...`));

    // Encode content as base64
    const content = Buffer.from(options.content).toString("base64");

    const response = await giteaRequest(
      `/api/v1/repos/${options.owner}/${options.repo}/contents/${options.path}`,
      {
        method: "POST",
        auth: { username: options.owner, password: `${options.owner}123` },
        body: {
          content: content,
          message: options.message || `Add ${options.path}`,
          branch: options.branch || "main",
        },
      },
    );

    if (response.content) {
      console.log(chalk.green(`✅ File ${options.path} added successfully!`));
      console.log(chalk.gray(`   Commit: ${options.message || `Add ${options.path}`}`));
    } else {
      console.error(chalk.red(`❌ Failed to add file: ${JSON.stringify(response)}`));
      process.exit(1);
    }
  } catch (error) {
    console.error(chalk.red("❌ Failed to add file:"), error);
    process.exit(1);
  }
}
