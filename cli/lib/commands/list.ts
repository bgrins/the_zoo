import { statSync } from "node:fs";
import chalk from "chalk";
import packageJson from "../../package.json" with { type: "json" };
import { paths } from "../utils/config";
import { getPublishedProxyPort, getRunningInstances } from "../utils/docker";
import { CliError } from "../utils/errors";
import { DEFAULT_PROXY_PORT, isDevMode, listInstanceDirs, locateInstance } from "../utils/instance";
import { compareVersions, parseVersion } from "../utils/version";

function formatTime(date: Date): string {
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

function createdTime(dir: string): string {
  const stat = statSync(dir);
  return formatTime(stat.birthtimeMs > 0 ? stat.birthtime : stat.mtime);
}

/**
 * Newest version first; directories that aren't versions last
 */
function byVersion(a: string, b: string): number {
  const [parsedA, parsedB] = [parseVersion(a), parseVersion(b)];
  if (parsedA && parsedB) {
    return compareVersions(parsedB, parsedA);
  }
  return Number(!parsedA) - Number(!parsedB) || a.localeCompare(b);
}

/**
 * List the instances of every CLI version with their state, proxy port and creation time
 */
export async function list(): Promise<void> {
  const instances = listInstanceDirs();
  if (instances.length === 0) {
    console.log(chalk.yellow("No Zoo CLI instances"));
    console.log(chalk.gray('Run "the_zoo start" to create one'));
    return;
  }

  // The running project of each instance directory, or null when Docker can't tell
  let running: Map<string, string> | null = new Map();
  try {
    for (const project of await getRunningInstances({ onlyCliInstances: true })) {
      const location = locateInstance(project);
      if (location) {
        running.set(location.dir, project);
      }
    }
  } catch (error) {
    if (!(error instanceof CliError)) {
      throw error;
    }
    console.log(chalk.yellow(`${error.message}; running state unknown\n`));
    running = null;
  }

  const current = `v${packageJson.version}`;
  const groups = new Map<string, typeof instances>();
  for (const instance of instances) {
    const group = instance.version ?? paths.runtime;
    groups.set(group, [...(groups.get(group) ?? []), instance]);
  }

  const rows: string[][] = [["ID", "STATE", "PORT", "CREATED"]];
  const headers = new Map<number, string>();
  for (const group of [...groups.keys()].sort(byVersion)) {
    headers.set(rows.length, group === current && !isDevMode() ? `${group} (this CLI)` : group);
    for (const instance of groups.get(group) ?? []) {
      const project = running?.get(instance.dir);
      const port =
        (project && (await getPublishedProxyPort(project))) ||
        instance.env.ZOO_PROXY_PORT ||
        DEFAULT_PROXY_PORT;
      const state = running === null ? "unknown" : project ? "running" : "stopped";
      rows.push([instance.instanceId, state, port, createdTime(instance.dir)]);
    }
  }

  const widths = rows[0].map((_, column) => Math.max(...rows.map((row) => row[column].length)));
  rows.forEach((row, index) => {
    const header = headers.get(index);
    if (header) {
      console.log(chalk.bold(`${index > 1 ? "\n" : ""}${header}`));
    }
    const line = `  ${row.map((cell, column) => cell.padEnd(widths[column])).join("  ")}`.trimEnd();
    console.log(index === 0 ? chalk.gray(line) : line);
  });
}
