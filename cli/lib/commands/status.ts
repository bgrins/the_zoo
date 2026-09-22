import { existsSync } from "node:fs";
import chalk from "chalk";
import {
  dockerProbe,
  getPublishedProxyPort,
  getRunningInstances,
  parseComposePs,
  publishedProxyPort,
} from "../utils/docker";
import { CliError } from "../utils/errors";
import { caCertPath, getProjectSource, parseProjectName } from "../utils/instance";
import { findInstanceProjects } from "../utils/project";
import { keptDataWarnings } from "../utils/stateful";

interface StatusOptions {
  instance?: string;
  json?: boolean;
}

/**
 * The running projects to show: all of them, or those matching --instance
 */
async function projectsToShow(options: StatusOptions): Promise<string[]> {
  const runningProjects = await getRunningInstances();
  if (!options.instance || runningProjects.length === 0) {
    return runningProjects;
  }
  const matches = findInstanceProjects(runningProjects, options.instance);
  if (matches.length === 0) {
    throw new CliError(`No running instance found matching: ${options.instance}`, {
      hint: `Running instances:\n${runningProjects.map((p) => `  - ${p}`).join("\n")}`,
    });
  }
  return matches;
}

/**
 * Warn, on stderr, about the databases of a project that kept their data after an unclean
 * shutdown instead of restoring their baseline
 */
export async function warnKeptData(projectName: string, indent = ""): Promise<void> {
  const warnings = await keptDataWarnings(projectName);
  if (warnings.length === 0) {
    return;
  }
  const instance = parseProjectName(projectName)?.instanceId ?? projectName;
  for (const warning of warnings) {
    console.error(chalk.yellow(`${indent}⚠ ${warning}`));
  }
  console.error(
    chalk.yellow(`${indent}  Run "the_zoo reset --instance ${instance}" to restore the baseline`),
  );
}

/**
 * The running instances for test harnesses: where to point a browser, and what is up
 */
async function printJson(projects: string[]): Promise<void> {
  const instances = [];
  for (const project of projects) {
    const { stdout } = await dockerProbe(["compose", "-p", project, "ps", "--format", "json"]);
    const containers = parseComposePs(stdout);
    const parsed = parseProjectName(project);
    const directory = (await getProjectSource(project)).dir;
    const proxyPort = publishedProxyPort(containers);
    const caCert = caCertPath(directory);
    instances.push({
      project,
      instanceId: parsed?.instanceId ?? null,
      version: parsed?.version ?? null,
      directory,
      proxyUrl: proxyPort ? `http://localhost:${proxyPort}` : null,
      caCert: existsSync(caCert) ? caCert : null,
      services: containers.map((container) => ({
        service: container.Service ?? null,
        state: container.State ?? null,
        health: container.Health || null,
      })),
    });
    await warnKeptData(project);
  }
  console.log(JSON.stringify({ instances }, null, 2));
}

export async function status(options: StatusOptions): Promise<void> {
  if (options.json) {
    return printJson(await projectsToShow(options));
  }

  console.log(chalk.blue("📊 Zoo Status\n"));

  const projects = await projectsToShow(options);
  if (projects.length === 0) {
    console.log(chalk.yellow("No Zoo CLI instances are currently running"));
    console.log(chalk.gray('\nRun "the_zoo start" to start The Zoo'));
    return;
  }

  console.log(chalk.bold("Running instances:"));

  for (const projectName of projects) {
    console.log(`\n  ${chalk.green("●")} Project: ${chalk.bold(projectName)}`);

    const parsed = parseProjectName(projectName);
    if (parsed) {
      console.log(`    Instance ID: ${parsed.instanceId}`);
    }
    console.log(`    Directory: ${(await getProjectSource(projectName)).dir}`);

    const proxyPort = await getPublishedProxyPort(projectName);
    if (proxyPort) {
      console.log(`    Proxy: http://localhost:${proxyPort}`);
    }
    await warnKeptData(projectName, "    ");
  }

  console.log(`\n${chalk.gray("Configure your browser to use the proxy to access .zoo domains")}`);
  console.log(chalk.gray('Run "the_zoo stop" to stop instances'));
}
