import chalk from "chalk";
import {
  prepareInstance,
  showDryRunInfo,
  startServices,
  getDefaultInstanceId,
  instanceExists,
} from "../utils/instance";

interface StartOptions {
  proxyPort: string;
  setEnv?: string[];
  dryRun?: boolean;
  instance?: string;
}

export async function start(options: StartOptions): Promise<void> {
  console.log(chalk.blue("🚀 Starting The Zoo..."));

  // Determine instance ID to use
  let instanceId: string;
  if (options.instance) {
    // Use specified instance
    instanceId = options.instance;
    const exists = await instanceExists(instanceId);
    if (!exists) {
      console.error(chalk.red(`Instance "${instanceId}" does not exist.`));
      console.log(chalk.gray(`Run "thezoo create" to create a new instance.`));
      process.exit(1);
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

  const info = await prepareInstance({ ...options, instanceId });

  // If dry-run, show what would be executed
  if (options.dryRun) {
    showDryRunInfo(info);
    return;
  }

  await startServices(info);

  console.log("");
  console.log(chalk.green("✓ The Zoo is running!"));
  console.log("");
  console.log(`  ${chalk.bold("Instance:")} ${instanceId}`);
  console.log(`  ${chalk.bold("Proxy:")} http://localhost:${options.proxyPort}`);
  console.log(`  ${chalk.bold("Status:")} http://status.zoo (configure proxy in browser)`);
  console.log("");

  if (options.instance) {
    console.log(chalk.gray(`Run "thezoo stop --instance ${instanceId}" to stop this instance`));
  } else {
    console.log(chalk.gray('Run "thezoo stop" to stop all services'));
  }
}
