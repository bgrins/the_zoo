#!/usr/bin/env tsx

import chalk from "chalk";
import { program } from "commander";
import { benchmark } from "../lib/commands/benchmark";
import { clean } from "../lib/commands/clean";
import { compose } from "../lib/commands/compose";
import { create } from "../lib/commands/create";
import { pull } from "../lib/commands/pull";
import { restart } from "../lib/commands/restart";
import { shellRedis, shellPostgres, shellStalwart, shellMysql } from "../lib/commands/shell";
import { start } from "../lib/commands/start";
import { status } from "../lib/commands/status";
import { stop } from "../lib/commands/stop";
import { emailUsers, emailSend, emailSwaks, emailCheck } from "../lib/commands/email";
import {
  giteaUsers,
  giteaCreateUser,
  giteaCreateOrg,
  giteaCreateRepo,
  giteaCreateIssue,
  giteaAddFile,
} from "../lib/commands/gitea";
import { mcp } from "../lib/commands/mcp";
import { setVerbose } from "../lib/utils/verbose";
import packageJson from "../package.json" with { type: "json" };

program
  .name("the_zoo")
  .description("CLI for The Zoo browser automation evaluation environment")
  .version(packageJson.version)
  .option("--verbose", "enable verbose output for all commands");

program
  .command("start")
  .description("Start The Zoo environment")
  .option("--port <port>", "proxy port (default: 3128)", "3128")
  .option("--instance <id>", "Start a specific instance created with 'thezoo create'")
  .option(
    "--set-env <var>",
    "set environment variable (format: KEY=value)",
    (value: string, previous: string[]) => {
      return previous ? [...previous, value] : [value];
    },
    [],
  )
  .option("--dry-run", "show what would be executed without actually running")
  .action(start);

program
  .command("create")
  .description("Prepare a new Zoo instance without starting it")
  .option("--dry-run", "show what would be executed without actually running")
  .option("--ip-base <ip>", "specify base IP for services (e.g., 172.30.100.1)")
  .action(create);

program
  .command("pull")
  .description("Pull Zoo container images")
  .option("--instance <id>", "Pull images for a specific instance")
  .action(pull);

program
  .command("stop")
  .description("Stop The Zoo environment")
  .option("--all", "Stop all running Zoo CLI instances")
  .option("--instance <id>", "Stop a specific instance")
  .action(stop);

program
  .command("restart")
  .description("Restart The Zoo environment (stop + start)")
  .option("--port <port>", "proxy port (default: 3128)", "3128")
  .option("--instance <id>", "Restart a specific instance")
  .option(
    "--set-env <var>",
    "set environment variable (format: KEY=value)",
    (value: string, previous: string[]) => {
      return previous ? [...previous, value] : [value];
    },
    [],
  )
  .action(restart);

program
  .command("status")
  .description("Show status of running Zoo instances")
  .option("--instance <id>", "Show status for a specific instance")
  .action(status);

program
  .command("clean")
  .description("Clean up Zoo resources")
  .option("--instance <id>", "Clean a specific instance")
  .option("--force", "skip confirmation prompt")
  .action(clean);

program
  .command("benchmark")
  .description("Run performance benchmarks on Zoo sites")
  .option("--sites-only", "Skip startup/restart timing, only benchmark site response times")
  .option("--sites <list>", "Comma-separated list of sites to benchmark (partial match)")
  .option("--output <dir>", "Custom output directory for results")
  .option("--port <port>", "Override proxy port")
  .option("--instance <id>", "Benchmark a specific instance")
  .action(benchmark);

program
  .command("compose [args...]")
  .description("Run docker compose commands for a Zoo instance")
  .option("--instance <id>", "specify instance ID (for multiple running instances)")
  .allowUnknownOption(true)
  .helpOption(false)
  .action((args, options) => {
    compose(args || [], { instance: options.instance });
  });

// Shell commands
const shell = program
  .command("shell")
  .description("Run shell commands for Zoo services")
  .option("--instance <id>", "specify instance ID (for multiple running instances)");

shell
  .command("redis [args...]")
  .description("Run Redis CLI commands")
  .allowUnknownOption(true)
  .helpOption(false)
  .action((args, _options, command) => {
    // Get the parent command options (which includes --instance)
    const parentOptions = command.parent.opts();
    shellRedis(args || [], { instance: parentOptions.instance });
  });

shell
  .command("postgres [args...]")
  .description("Run PostgreSQL CLI commands")
  .allowUnknownOption(true)
  .helpOption(false)
  .action((args, _options, command) => {
    // Get the parent command options (which includes --instance)
    const parentOptions = command.parent.opts();
    shellPostgres(args || [], { instance: parentOptions.instance });
  });

shell
  .command("stalwart [args...]")
  .description("Run Stalwart Mail CLI commands")
  .allowUnknownOption(true)
  .helpOption(false)
  .action((args, _options, command) => {
    // Get the parent command options (which includes --instance)
    const parentOptions = command.parent.opts();
    shellStalwart(args || [], { instance: parentOptions.instance });
  });

shell
  .command("mysql [args...]")
  .description("Run MySQL CLI commands")
  .allowUnknownOption(true)
  .helpOption(false)
  .action((args, _options, command) => {
    // Get the parent command options (which includes --instance)
    const parentOptions = command.parent.opts();
    shellMysql(args || [], { instance: parentOptions.instance });
  });

// Email commands
const email = program
  .command("email")
  .description("Manage email accounts and send/receive emails")
  .option("--instance <id>", "specify instance ID (for multiple running instances)");

email
  .command("users")
  .description("List all email users")
  .option("--domain <domain>", "filter by domain")
  .action((_options, command) => {
    const parentOptions = command.parent.opts();
    emailUsers({
      instance: parentOptions.instance,
      domain: _options.domain,
    });
  });

email
  .command("send")
  .description("Send an email")
  .option("--from <email>", "sender email address")
  .option("--to <email>", "recipient email address")
  .option("--subject <text>", "email subject")
  .option("--body <text>", "email body")
  .option("--html", "send as HTML email")
  .option("--password <password>", "sender password")
  .action((_options, command) => {
    const parentOptions = command.parent.opts();

    if (!_options.from || !_options.to || !_options.subject || !_options.body) {
      console.error(chalk.red("❌ Required options: --from, --to, --subject, --body"));
      process.exit(1);
    }

    emailSend({
      instance: parentOptions.instance,
      from: _options.from,
      to: _options.to,
      subject: _options.subject,
      body: _options.body,
      html: _options.html,
      password: _options.password,
    });
  });

email
  .command("inbox")
  .description("Check email inbox using IMAP")
  .option("--user <email>", "email account to check")
  .option("--password <password>", "account password")
  .option("--folder <name>", "mailbox folder to check", "INBOX")
  .option("--limit <number>", "number of emails to show", "10")
  .action((_options, command) => {
    const parentOptions = command.parent.opts();

    if (!_options.user) {
      console.error(chalk.red("❌ Required option: --user"));
      process.exit(1);
    }

    emailCheck({
      instance: parentOptions.instance,
      user: _options.user,
      password: _options.password,
      folder: _options.folder,
      limit: parseInt(_options.limit),
    });
  });

email
  .command("swaks [args...]")
  .description("Send test emails using swaks (Swiss Army Knife for SMTP)")
  .allowUnknownOption(true)
  .helpOption(false)
  .action((args, _options, command) => {
    const parentOptions = command.parent.opts();
    emailSwaks(args || [], { instance: parentOptions.instance });
  });

// Gitea commands
const gitea = program
  .command("gitea")
  .description("Manage Gitea repositories, users, and organizations")
  .option("--instance <id>", "specify instance ID (for multiple running instances)");

gitea
  .command("users")
  .description("List all Gitea users")
  .action((_options, command) => {
    const parentOptions = command.parent.opts();
    giteaUsers({ instance: parentOptions.instance });
  });

gitea
  .command("create-user")
  .description("Create a new Gitea user")
  .option("--username <name>", "username")
  .option("--email <email>", "email address")
  .option("--password <password>", "password")
  .option("--admin", "create as admin user")
  .action((_options, command) => {
    const parentOptions = command.parent.opts();

    if (!_options.username || !_options.email || !_options.password) {
      console.error(chalk.red("❌ Required options: --username, --email, --password"));
      process.exit(1);
    }

    giteaCreateUser({
      instance: parentOptions.instance,
      username: _options.username,
      email: _options.email,
      password: _options.password,
      admin: _options.admin,
    });
  });

gitea
  .command("create-org")
  .description("Create a new organization")
  .option("--name <name>", "organization name")
  .option("--full-name <name>", "full organization name")
  .option("--description <text>", "organization description")
  .option("--website <url>", "organization website")
  .action((_options, command) => {
    const parentOptions = command.parent.opts();

    if (!_options.name) {
      console.error(chalk.red("❌ Required option: --name"));
      process.exit(1);
    }

    giteaCreateOrg({
      instance: parentOptions.instance,
      name: _options.name,
      fullName: _options.fullName,
      description: _options.description,
      website: _options.website,
    });
  });

gitea
  .command("create-repo")
  .description("Create a new repository")
  .option("--name <name>", "repository name")
  .option("--owner <owner>", "repository owner (user or org)")
  .option("--description <text>", "repository description")
  .option("--private", "create as private repository")
  .option("--no-auto-init", "don't initialize with README")
  .action((_options, command) => {
    const parentOptions = command.parent.opts();

    if (!_options.name || !_options.owner) {
      console.error(chalk.red("❌ Required options: --name, --owner"));
      process.exit(1);
    }

    giteaCreateRepo({
      instance: parentOptions.instance,
      name: _options.name,
      owner: _options.owner,
      description: _options.description,
      private: _options.private,
      autoInit: _options.autoInit,
    });
  });

gitea
  .command("create-issue")
  .description("Create an issue in a repository")
  .option("--owner <owner>", "repository owner")
  .option("--repo <repo>", "repository name")
  .option("--title <title>", "issue title")
  .option("--body <text>", "issue body/description")
  .action((_options, command) => {
    const parentOptions = command.parent.opts();

    if (!_options.owner || !_options.repo || !_options.title) {
      console.error(chalk.red("❌ Required options: --owner, --repo, --title"));
      process.exit(1);
    }

    giteaCreateIssue({
      instance: parentOptions.instance,
      owner: _options.owner,
      repo: _options.repo,
      title: _options.title,
      body: _options.body,
    });
  });

gitea
  .command("add-file")
  .description("Add a file to a repository")
  .option("--owner <owner>", "repository owner")
  .option("--repo <repo>", "repository name")
  .option("--path <path>", "file path in repository")
  .option("--content <content>", "file content")
  .option("--message <message>", "commit message")
  .option("--branch <branch>", "branch name", "main")
  .action((_options, command) => {
    const parentOptions = command.parent.opts();

    if (!_options.owner || !_options.repo || !_options.path || !_options.content) {
      console.error(chalk.red("❌ Required options: --owner, --repo, --path, --content"));
      process.exit(1);
    }

    giteaAddFile({
      instance: parentOptions.instance,
      owner: _options.owner,
      repo: _options.repo,
      path: _options.path,
      content: _options.content,
      message: _options.message,
      branch: _options.branch,
    });
  });

// MCP Server command
program
  .command("mcp")
  .description("Start Model Context Protocol (MCP) server")
  .option("--port <port>", "run server on HTTP/SSE mode on specified port (default: stdio)")
  .action(mcp);

// Handle global verbose option
program.hook("preAction", (thisCommand, _actionCommand) => {
  const globalOptions = thisCommand.parent?.opts() || thisCommand.opts();
  if (globalOptions.verbose) {
    setVerbose(true);
  }
});

program.parse(process.argv);
