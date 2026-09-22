import chalk from "chalk";
import { instanceProjectName } from "../utils/config";
import { getInstanceDir, prepareInstance } from "../utils/instance";
import { parseIpBase } from "../utils/network-env";

interface CreateOptions {
  dryRun?: boolean;
  ipBase?: string;
}

export async function create(options: CreateOptions): Promise<void> {
  console.log(chalk.blue("📁 Creating new Zoo instance..."));

  // If dry-run, just show what would be created
  if (options.dryRun) {
    if (options.ipBase) {
      parseIpBase(options.ipBase);
    }
    const instanceId = Date.now().toString(36);
    console.log(chalk.yellow("\n🔍 Dry run mode - showing what would be created:\n"));
    console.log(chalk.cyan("Instance details:"));
    console.log(`  Instance ID: ${instanceId}`);
    console.log(`  Instance directory: ${getInstanceDir(instanceId)}`);
    console.log(`  Project name: ${instanceProjectName(instanceId)}`);

    if (options.ipBase) {
      console.log(`  Custom base IP: ${options.ipBase}`);
      console.log(`  Service IPs will be: ${options.ipBase} + 1, 2, 3`);
    } else {
      console.log(`  Network: <randomly generated with high-range IPs>`);
    }

    console.log("");
    console.log(chalk.gray(`To create this instance, run without --dry-run`));
    console.log(chalk.gray(`Then start it with: the_zoo start --instance ${instanceId}`));
    return;
  }

  const info = await prepareInstance({ ipBase: options.ipBase });

  console.log("");
  console.log(chalk.green("✓ New Zoo instance prepared!"));
  console.log("");
  console.log(`  ${chalk.bold("Instance ID:")} ${info.instanceId}`);
  console.log(`  ${chalk.bold("Project name:")} ${info.projectName}`);
  console.log(`  ${chalk.bold("Instance directory:")} ${getInstanceDir(info.instanceId)}`);
  console.log(`  ${chalk.bold("Network configuration:")}`);
  console.log(`    Subnet: ${info.env.ZOO_SUBNET}`);
  console.log(`    DNS IP: ${info.env.ZOO_DNS_IP}`);
  console.log(`    Caddy IP: ${info.env.ZOO_CADDY_IP}`);
  console.log(`    Proxy IP: ${info.env.ZOO_PROXY_IP}`);
  console.log("");
  console.log(chalk.cyan("To start this instance:"));
  console.log(chalk.gray(`  the_zoo start --instance ${info.instanceId}`));
  console.log("");
  console.log(chalk.cyan("To remove this instance:"));
  console.log(chalk.gray(`  the_zoo clean --instance ${info.instanceId}`));
}
