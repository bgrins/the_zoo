import { exec } from "node:child_process";
import { promisify } from "node:util";
import chalk from "chalk";
import { getRunningInstances } from "../utils/docker";

const execAsync = promisify(exec);

interface StatusOptions {
  instance?: string;
}

export async function status(options: StatusOptions): Promise<void> {
  console.log(chalk.blue("📊 Zoo Status\n"));

  // Get running instances
  const runningProjects = await getRunningInstances();

  if (runningProjects.length === 0) {
    console.log(chalk.yellow("No Zoo CLI instances are currently running"));
    console.log(chalk.gray('\nRun "thezoo start" to start The Zoo'));
    return;
  }

  // Filter by instance if specified
  let projectsToShow = runningProjects;
  if (options.instance) {
    const instanceId = options.instance;
    projectsToShow = runningProjects.filter((p) => p.includes(instanceId));
    if (projectsToShow.length === 0) {
      console.error(chalk.red(`No running instance found matching: ${instanceId}`));
      console.log("\nRunning instances:");
      runningProjects.forEach((p) => console.log(`  - ${p}`));
      return;
    }
  }

  console.log(chalk.bold("Running instances:"));

  for (const projectName of projectsToShow) {
    console.log(`\n  ${chalk.green("●")} Project: ${chalk.bold(projectName)}`);

    // Extract instance ID and subnet from project name
    const match = projectName.match(/^thezoo-cli-instance-(.+?)(?:-subnet(\d+))?$/);
    const instanceId = match?.[1] || projectName;
    const subnetOctet = match?.[2];

    console.log(`    Instance ID: ${instanceId}`);
    if (subnetOctet) {
      console.log(`    Subnet: 172.${subnetOctet}.0.0/16`);
    }

    // Try to find proxy port using docker compose ps
    try {
      const { stdout } = await execAsync(`docker compose -p ${projectName} ps proxy --format json`);

      if (stdout.trim()) {
        const containerInfo = JSON.parse(stdout.trim());
        // Extract port from Publishers array
        const proxyPublisher = containerInfo.Publishers?.find((p: any) => p.PublishedPort);
        if (proxyPublisher?.PublishedPort) {
          console.log(`    Proxy: http://localhost:${proxyPublisher.PublishedPort}`);
        }
      }
    } catch {
      // Ignore errors
    }
  }

  console.log(`\n${chalk.gray("Configure your browser to use the proxy to access .zoo domains")}`);
  console.log(chalk.gray('Run "thezoo stop" to stop instances'));
}
