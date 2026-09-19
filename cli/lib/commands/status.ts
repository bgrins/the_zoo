import chalk from "chalk";
import { getPublishedProxyPort, getRunningInstances } from "../utils/docker";
import { CliError } from "../utils/errors";
import { getInstanceSourcePath, parseProjectName } from "../utils/instance";
import { findInstanceProjects } from "../utils/project";

interface StatusOptions {
  instance?: string;
}

export async function status(options: StatusOptions): Promise<void> {
  console.log(chalk.blue("📊 Zoo Status\n"));

  // Get running instances
  const runningProjects = await getRunningInstances();

  if (runningProjects.length === 0) {
    console.log(chalk.yellow("No Zoo CLI instances are currently running"));
    console.log(chalk.gray('\nRun "the_zoo start" to start The Zoo'));
    return;
  }

  // Filter by instance if specified
  let projectsToShow = runningProjects;
  if (options.instance) {
    const instanceId = options.instance;
    projectsToShow = findInstanceProjects(runningProjects, instanceId);
    if (projectsToShow.length === 0) {
      throw new CliError(`No running instance found matching: ${instanceId}`, {
        hint: `Running instances:\n${runningProjects.map((p) => `  - ${p}`).join("\n")}`,
      });
    }
  }

  console.log(chalk.bold("Running instances:"));

  for (const projectName of projectsToShow) {
    console.log(`\n  ${chalk.green("●")} Project: ${chalk.bold(projectName)}`);

    const parsed = parseProjectName(projectName);
    if (parsed) {
      console.log(`    Instance ID: ${parsed.instanceId}`);
      console.log(`    Directory: ${getInstanceSourcePath(projectName)}`);
    } else {
      // Non-CLI instance (e.g., main development project)
      console.log(`    Directory: ${getInstanceSourcePath(projectName)}`);
    }

    const proxyPort = await getPublishedProxyPort(projectName);
    if (proxyPort) {
      console.log(`    Proxy: http://localhost:${proxyPort}`);
    }
  }

  console.log(`\n${chalk.gray("Configure your browser to use the proxy to access .zoo domains")}`);
  console.log(chalk.gray('Run "the_zoo stop" to stop instances'));
}
