#!/usr/bin/env tsx

import chalk from "chalk";
import { program } from "commander";
import { benchmark } from "../lib/commands/benchmark";
import { clean } from "../lib/commands/clean";
import { compose } from "../lib/commands/compose";
import { create } from "../lib/commands/create";
import { doctor } from "../lib/commands/doctor";
import { list } from "../lib/commands/list";
import { pull } from "../lib/commands/pull";
import { reset, state } from "../lib/commands/reset";
import { restart } from "../lib/commands/restart";
import {
  snapshotList,
  snapshotRemove,
  snapshotRestore,
  snapshotSave,
} from "../lib/commands/snapshot";
import { shellRedis, shellPostgres, shellStalwart, shellMysql } from "../lib/commands/shell";
import { start } from "../lib/commands/start";
import { status } from "../lib/commands/status";
import { stop } from "../lib/commands/stop";
import { emailUsers, emailSend, emailSwaks, emailCheck } from "../lib/commands/email";
import { CliError, errorMessage } from "../lib/utils/errors";
import { getVerbose, setVerbose } from "../lib/utils/verbose";
import packageJson from "../package.json" with { type: "json" };

program
  .name("the_zoo")
  .description("CLI for The Zoo browser automation evaluation environment")
  .version(packageJson.version)
  .option("--verbose", "enable verbose output for all commands");

program
  .command("start")
  .description("Start The Zoo environment")
  .option("--port <port>", "proxy port (default: the instance's saved port, else 3128)")
  .option("--instance <id>", "Start a specific instance created with 'the_zoo create'")
  .option(
    "--set-env <var>",
    "set environment variable (format: KEY=value)",
    (value: string, previous: string[]) => {
      return previous ? [...previous, value] : [value];
    },
    [],
  )
  .option("--with-heavy", "also create the heavy apps (~20 GB of images); saved for the instance")
  .option("--wait", "wait until the core services are healthy")
  .option("--wait-timeout <seconds>", "how long --wait waits (default: 300)")
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
  .option("--port <port>", "proxy port (default: the instance's saved port, else 3128)")
  .option("--instance <id>", "Restart a specific instance")
  .option(
    "--set-env <var>",
    "set environment variable (format: KEY=value)",
    (value: string, previous: string[]) => {
      return previous ? [...previous, value] : [value];
    },
    [],
  )
  .option("--with-heavy", "also create the heavy apps (~20 GB of images); saved for the instance")
  .option("--wait", "wait until the core services are healthy")
  .option("--wait-timeout <seconds>", "how long --wait waits (default: 300)")
  .action(restart);

program
  .command("status")
  .description("Show status of running Zoo instances")
  .option("--instance <id>", "Show status for a specific instance")
  .option("--json", "print the running instances as JSON")
  .action(status);

program
  .command("reset [app]")
  .description(
    "Restore the databases and their files to the baseline, and recreate every app and the services that use them; with an app, recreate it and restore only its database, if it has one",
  )
  .option("--instance <id>", "Reset a specific instance")
  .action(reset);

program
  .command("state")
  .description("Show when each database was last restored, and from which baseline")
  .option("--instance <id>", "Show a specific instance")
  .option("--json", "print JSON")
  .action(state);

const snapshot = program
  .command("snapshot")
  .description("Save the databases and app files as a baseline that resets restore")
  .option("--instance <id>", "specify instance ID (for multiple running instances)");

snapshot
  .command("save <name>")
  .description("Stop the stateful services, archive their data as <name> and start them again")
  .action((name, _options, command) => snapshotSave(name, command.parent.opts()));

snapshot
  .command("restore <name>")
  .description('Make <name> the baseline ("golden" for the state built into the images) and reset')
  .action((name, _options, command) => snapshotRestore(name, command.parent.opts()));

snapshot
  .command("list")
  .description("List snapshots")
  .action((_options, command) => snapshotList(command.parent.opts()));

snapshot
  .command("rm <name>")
  .description("Remove a snapshot")
  .action((name, _options, command) => snapshotRemove(name, command.parent.opts()));

program
  .command("clean")
  .description("Clean up Zoo resources")
  .option("--instance <id>", "Clean a specific instance")
  .option("--old-versions", "remove older CLI versions' instances and images, unless running")
  .option("--force", "skip confirmation prompt")
  .action(clean);

program.command("list").description("List the instances of every CLI version").action(list);

program
  .command("doctor")
  .description("Check that Docker and this machine can run The Zoo")
  .option("--port <port>", "proxy port to check (default: the default instance's, else 3128)")
  .action(doctor);

program
  .command("benchmark")
  .description("Run performance benchmarks on Zoo sites")
  .option("--sites-only", "Skip startup/restart timing, only benchmark site response times")
  .option("--sites <list>", "Comma-separated list of sites to benchmark (partial match)")
  .option("--output <dir>", "Custom output directory for results")
  .option("--port <port>", "Override proxy port")
  .option("--instance <id>", "Benchmark a specific instance")
  .option("--force", "stop a running instance to time its startup without asking")
  .action(benchmark);

program
  .command("compose [args...]")
  .description("Run docker compose commands for a Zoo instance")
  .option("--instance <id>", "specify instance ID (for multiple running instances)")
  .allowUnknownOption(true)
  .helpOption(false)
  .action((args, options) => {
    return compose(args || [], { instance: options.instance });
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
    return shellRedis(args || [], { instance: parentOptions.instance });
  });

shell
  .command("postgres [args...]")
  .description("Run PostgreSQL CLI commands")
  .allowUnknownOption(true)
  .helpOption(false)
  .action((args, _options, command) => {
    // Get the parent command options (which includes --instance)
    const parentOptions = command.parent.opts();
    return shellPostgres(args || [], { instance: parentOptions.instance });
  });

shell
  .command("stalwart [args...]")
  .description("Run Stalwart Mail CLI commands")
  .allowUnknownOption(true)
  .helpOption(false)
  .action((args, _options, command) => {
    // Get the parent command options (which includes --instance)
    const parentOptions = command.parent.opts();
    return shellStalwart(args || [], { instance: parentOptions.instance });
  });

shell
  .command("mysql [args...]")
  .description("Run MySQL CLI commands")
  .allowUnknownOption(true)
  .helpOption(false)
  .action((args, _options, command) => {
    // Get the parent command options (which includes --instance)
    const parentOptions = command.parent.opts();
    return shellMysql(args || [], { instance: parentOptions.instance });
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
    return emailUsers({
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
    return emailSend({
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
    return emailCheck({
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
    return emailSwaks(args || [], { instance: parentOptions.instance });
  });

// Handle global verbose option
program.hook("preAction", (thisCommand, _actionCommand) => {
  const globalOptions = thisCommand.parent?.opts() || thisCommand.opts();
  if (globalOptions.verbose) {
    setVerbose(true);
  }
});

program.parseAsync(process.argv).catch((error: unknown) => {
  if (error instanceof CliError) {
    if (error.message) {
      console.error(chalk.red(`❌ ${error.message}`));
    }
    if (error.hint) {
      console.error(chalk.gray(error.hint));
    }
    process.exit(error.exitCode);
  }
  console.error(chalk.red(`❌ ${errorMessage(error)}`));
  if (getVerbose() && error instanceof Error) {
    console.error(error.stack);
  }
  process.exit(1);
});
