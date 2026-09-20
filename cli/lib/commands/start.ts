import path from "node:path";
import chalk from "chalk";
import { instanceProjectName } from "../utils/config";
import { getRunningInstances } from "../utils/docker";
import { CliError } from "../utils/errors";
import {
  caCertPath,
  prepareInstance,
  showDryRunInfo,
  startServices,
  getDefaultInstanceId,
  instanceExists,
  parseWaitTimeout,
} from "../utils/instance";
import { findInstanceProjects } from "../utils/project";
import { warnKeptData } from "./status";

interface StartOptions {
  port?: string;
  setEnv?: string[];
  dryRun?: boolean;
  instance?: string;
  quiet?: boolean;
  withHeavy?: boolean;
  wait?: boolean;
  waitTimeout?: string;
  // Set by restart, which has already stopped the instance under other CLI versions
  otherVersionsStopped?: boolean;
}

export async function start(options: StartOptions): Promise<void> {
  console.log(chalk.blue("🚀 Starting The Zoo..."));
  const waitTimeout = parseWaitTimeout(options);

  // Determine instance ID to use
  let instanceId: string;
  if (options.instance) {
    // Use specified instance
    instanceId = options.instance;
    const exists = await instanceExists(instanceId);
    if (!exists) {
      throw new CliError(`Instance "${instanceId}" does not exist.`, {
        hint: 'Run "the_zoo create" to create a new instance.',
      });
    }
    console.log(chalk.gray(`Using instance: ${instanceId}`));
  } else {
    // Use default instance ID for the current version
    instanceId = getDefaultInstanceId();
    const exists = await instanceExists(instanceId);

    if (exists) {
      console.log(chalk.gray(`Using existing default instance: ${instanceId}`));
    } else {
      console.log(chalk.gray(`Creating new default instance: ${instanceId}`));
    }
  }

  // Another CLI version's project for this instance holds the proxy port it would reuse
  if (!options.dryRun && !options.otherVersionsStopped) {
    const others = findInstanceProjects(await getRunningInstances(), instanceId).filter(
      (project) => project !== instanceProjectName(instanceId),
    );
    if (others.length > 0) {
      throw new CliError(
        `Instance "${instanceId}" is running under another CLI version (${others.join(", ")})`,
        {
          hint: `Run "the_zoo restart${options.instance ? ` --instance ${instanceId}` : ""}" to move it to this version`,
        },
      );
    }
  }

  const info = await prepareInstance({
    port: options.port,
    setEnv: options.setEnv,
    instanceId,
    dryRun: options.dryRun,
    withHeavy: options.withHeavy,
  });

  // If dry-run, show what would be executed
  if (options.dryRun) {
    showDryRunInfo(info);
    return;
  }

  const { heavyLeftOut } = await startServices(info, { quiet: options.quiet, waitTimeout });

  console.log("");
  console.log(
    chalk.green(waitTimeout ? "✓ The Zoo is running and healthy!" : "✓ The Zoo is running!"),
  );
  console.log("");
  console.log(`  ${chalk.bold("Instance:")} ${instanceId}`);
  console.log(`  ${chalk.bold("Proxy:")} http://localhost:${info.env.ZOO_PROXY_PORT}`);
  console.log(`  ${chalk.bold("Status:")} http://status.zoo (configure proxy in browser)`);
  console.log(`  ${chalk.bold("CA cert:")} ${caCertPath(info.packagePath)}`);
  console.log(
    `  ${chalk.bold("Credentials:")} ${path.join(info.packagePath, "docs", "credentials")}`,
  );
  console.log("");

  await warnKeptData(info.projectName);

  const instanceFlag = options.instance ? ` --instance ${instanceId}` : "";
  if (heavyLeftOut.length > 0) {
    console.log(
      chalk.gray(
        `Heavy apps not created: ${heavyLeftOut.join(", ")}. Add them with "the_zoo start${instanceFlag} --with-heavy"`,
      ),
    );
  }

  if (options.instance) {
    console.log(chalk.gray(`Run "the_zoo stop --instance ${instanceId}" to stop this instance`));
  } else {
    console.log(chalk.gray('Run "the_zoo stop" to stop all services'));
  }
}
