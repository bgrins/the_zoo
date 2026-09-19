import chalk from "chalk";
import {
  checkDocker,
  dockerComposeExecCapture,
  dockerComposeExecInteractive,
  execCommand,
} from "../utils/docker";
import { CliError, errorMessage } from "../utils/errors";
import { getInstanceSourcePath, getProxyPort } from "../utils/instance";
import { getProjectName } from "../utils/project";

interface EmailOptions {
  instance?: string;
}

interface EmailSendOptions extends EmailOptions {
  from?: string;
  to?: string;
  subject?: string;
  body?: string;
  html?: boolean;
  password?: string;
}

interface EmailUsersOptions extends EmailOptions {
  domain?: string;
}

interface EmailCheckOptions extends EmailOptions {
  user?: string;
  password?: string;
  folder?: string;
  limit?: number;
}

async function ensureDocker(): Promise<void> {
  if (!(await checkDocker())) {
    throw new CliError("Docker is not running. Please start Docker first.");
  }
}

// Make authenticated request to Stalwart API using curl via the instance's proxy
async function stalwartRequest(
  endpoint: string,
  proxyPort: string,
  options: {
    method?: string;
    body?: any;
    auth?: { username: string; password: string };
  } = {},
): Promise<any> {
  const proxyUrl = `http://localhost:${proxyPort}`;
  const url = `https://mail-api.zoo${endpoint}`;

  // Build curl arguments as array (avoids shell spawning issues)
  const curlArgs = ["-s", "-k", "--proxy", proxyUrl];

  // Add method
  if (options.method && options.method !== "GET") {
    curlArgs.push("-X", options.method);
  }

  // Add auth
  if (options.auth) {
    curlArgs.push("-u", `${options.auth.username}:${options.auth.password}`);
  }

  // Add headers
  curlArgs.push("-H", "Content-Type: application/json");

  // Add body
  if (options.body) {
    curlArgs.push("-d", JSON.stringify(options.body));
  }

  curlArgs.push(url);

  try {
    const { stdout, stderr } = await execCommand("curl", curlArgs);

    if (stderr) {
      throw new Error(`curl error: ${stderr}`);
    }

    // Try to parse JSON response
    try {
      return JSON.parse(stdout);
    } catch (_e) {
      // If not JSON, throw error with response
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
  await ensureDocker();

  try {
    // Get the project name (handles instance validation)
    const projectName = await getProjectName(options.instance);
    console.log(chalk.gray(`Using project: ${projectName}`));

    // Get all principals (users and domains)
    const response = await stalwartRequest("/api/principal", await getProxyPort(projectName), {
      auth: { username: "admin", password: "zoo-mail-admin-pw" },
    });

    const users = response.data.items.filter((item: any) => item.type === "individual");
    const domains = response.data.items.filter((item: any) => item.type === "domain");

    // Filter by domain if specified
    let filteredUsers = users;
    if (options.domain) {
      filteredUsers = users.filter((user: any) => user.name.endsWith(`@${options.domain}`));
    }

    // Display domains
    console.log(chalk.bold("\n📧 Email Domains:"));
    domains.forEach((domain: any) => {
      console.log(chalk.cyan(`  • ${domain.name}`));
    });

    // Display users
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
    throw new CliError(`Failed to list email users: ${errorMessage(error)}`);
  }
}

export async function emailSend(options: EmailSendOptions): Promise<void> {
  const { from, to, subject, body, password } = options;
  if (!from || !to || !subject || !body) {
    throw new CliError("Required options: --from, --to, --subject, --body");
  }
  if (!password) {
    throw new CliError("Password is required. Use --password option.");
  }

  await ensureDocker();

  try {
    const projectName = await getProjectName(options.instance);
    console.log(chalk.gray(`Using project: ${projectName}`));

    console.log(chalk.yellow("📧 Sending email..."));
    console.log(chalk.gray(`From: ${from}`));
    console.log(chalk.gray(`To: ${to}`));
    console.log(chalk.gray(`Subject: ${subject}`));

    // Build swaks command arguments
    const swaksArgs = [
      "--to",
      to,
      "--from",
      from,
      "--server",
      "stalwart:587",
      "--auth-user",
      from,
      "--auth-password",
      password,
      "--header",
      `Subject: ${subject}`,
      "--tls",
    ];

    // Add body with proper content type
    if (options.html) {
      swaksArgs.push("--add-header", "Content-Type: text/html");
      swaksArgs.push("--body", body);
    } else {
      swaksArgs.push("--body", body);
    }

    // Execute swaks in the stalwart container
    await dockerComposeExecInteractive("stalwart", ["swaks", ...swaksArgs], {
      cwd: getInstanceSourcePath(projectName),
      projectName,
      interactive: false, // No interaction needed for sending
    });

    console.log(chalk.green("✅ Email sent successfully!"));
  } catch (error) {
    throw new CliError(`Failed to send email: ${errorMessage(error)}`);
  }
}

export async function emailSwaks(args: string[], options: EmailOptions): Promise<void> {
  await ensureDocker();

  const projectName = await getProjectName(options.instance);
  console.log(chalk.gray(`Using project: ${projectName}`));

  // If no arguments, show help
  if (args.length === 0) {
    console.log(chalk.yellow("📧 Swaks - Swiss Army Knife for SMTP"));
    console.log(chalk.gray("\nExamples:"));
    console.log(chalk.green("  # Send a simple test email"));
    console.log(
      `  the_zoo email swaks --to alex.chen@snappymail.zoo --from test@zoo --server stalwart:25`,
    );
    console.log(chalk.green("\n  # Send with subject and body"));
    console.log(
      `  the_zoo email swaks --to user@zoo --from admin@zoo --server stalwart:25 --header "Subject: Test" --body "Hello"`,
    );
    console.log(chalk.green("\n  # Send with authentication"));
    console.log(
      `  the_zoo email swaks --to user@zoo --from alex.chen@snappymail.zoo --server stalwart:587 --auth-user alex.chen@snappymail.zoo --auth-password Password.123`,
    );
    console.log(chalk.green("\n  # Show full swaks help"));
    console.log(`  the_zoo email swaks --help`);
    return;
  }

  console.log(chalk.gray(`Running: swaks ${args.join(" ")}`));
  console.log("");

  await dockerComposeExecInteractive("stalwart", ["swaks", ...args], {
    cwd: getInstanceSourcePath(projectName),
    projectName,
    interactive: process.stdout.isTTY,
  });
}

export async function emailCheck(options: EmailCheckOptions): Promise<void> {
  const { user, password } = options;
  if (!user) {
    throw new CliError("Required option: --user");
  }
  if (!password) {
    throw new CliError("Password is required. Use --password option.");
  }

  await ensureDocker();

  try {
    const projectName = await getProjectName(options.instance);
    console.log(chalk.gray(`Using project: ${projectName}`));

    const zooSourcePath = getInstanceSourcePath(projectName);
    const folder = options.folder || "INBOX";
    // URL-encode folder name for the URL, quote it for IMAP commands
    const folderUrlEncoded = encodeURIComponent(folder);
    const folderQuoted = folder.includes(" ") ? `"${folder}"` : folder;

    console.log(chalk.yellow(`📥 Checking ${folder} for ${user}...`));

    // First, check mailbox status using curl via IMAP
    let statusOut: string;
    try {
      const result = await dockerComposeExecCapture(
        "stalwart",
        [
          "curl",
          "-s",
          "-u",
          `${user}:${password}`,
          `imap://localhost/${folderUrlEncoded}`,
          "--request",
          `EXAMINE ${folderQuoted}`,
        ],
        { cwd: zooSourcePath, projectName },
      );
      statusOut = result.stdout;
    } catch (error) {
      // List available folders to help user
      let folders: string[] = [];
      try {
        const { stdout: foldersOut } = await dockerComposeExecCapture(
          "stalwart",
          ["curl", "-s", "-u", `${user}:${password}`, "imap://localhost"],
          { cwd: zooSourcePath, projectName },
        );
        // Parse folder names from IMAP LIST responses like: * LIST () "/" "Folder Name"
        folders = foldersOut
          .split("\n")
          .filter((line) => line.includes("* LIST"))
          .map((line) => {
            // Match the last quoted string in the line (the folder name)
            const match = line.match(/"([^"]+)"\s*$/);
            return match ? match[1] : null;
          })
          .filter((f): f is string => f !== null);
      } catch {
        // Folder listing also failed, just throw the original error
      }
      if (folders.length > 0) {
        throw new CliError(`Folder "${folder}" not found or access denied.`, {
          hint: `Available folders:\n${folders.map((f) => `  • ${f}`).join("\n")}`,
        });
      }
      throw error;
    }

    // Parse the status to get message count
    const existsMatch = statusOut.match(/\* (\d+) EXISTS/);
    const messageCount = existsMatch ? parseInt(existsMatch[1]) : 0;

    console.log(chalk.green(`\nMailbox: ${folder}`));
    console.log(chalk.gray(`Messages: ${messageCount}`));

    if (messageCount === 0) {
      console.log(chalk.yellow("\nNo messages in this mailbox."));
      return;
    }

    // Determine how many messages to fetch
    const limit = options.limit || 10;
    const fetchCount = Math.min(messageCount, limit);
    const startUID = Math.max(1, messageCount - fetchCount + 1);

    console.log(chalk.gray(`\nFetching last ${fetchCount} message(s)...\n`));

    // Fetch messages
    for (let i = messageCount; i >= startUID; i--) {
      const { stdout: messageOut } = await dockerComposeExecCapture(
        "stalwart",
        [
          "curl",
          "-s",
          "-u",
          `${user}:${password}`,
          `imap://localhost/${folderUrlEncoded};MAILINDEX=${i}`,
        ],
        { cwd: zooSourcePath, projectName },
      );

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
    if (error instanceof CliError) {
      throw error;
    }
    throw new CliError(`Failed to check email: ${errorMessage(error)}`);
  }
}
