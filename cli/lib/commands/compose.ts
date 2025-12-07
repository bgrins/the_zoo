import { spawn } from "node:child_process";
import { join } from "node:path";
import chalk from "chalk";
import { checkDocker } from "../utils/docker";
import { getInstanceSourcePath } from "../utils/instance";
import { getProjectName } from "../utils/project";

interface ComposeOptions {
  instance?: string;
}

export async function compose(args: string[], options: ComposeOptions): Promise<void> {
  const dockerRunning = await checkDocker();
  if (!dockerRunning) {
    console.error(chalk.red("❌ Docker is not running. Please start Docker first."));
    process.exit(1);
  }

  try {
    const projectName = await getProjectName(options.instance);
    const zooSourcePath = getInstanceSourcePath(projectName);

    const composeArgs = [
      "compose",
      "-f",
      join(zooSourcePath, "docker-compose.yaml"),
      "-p",
      projectName,
      ...args,
    ];

    const proc = spawn("docker", composeArgs, {
      stdio: "inherit",
      cwd: zooSourcePath,
    });

    proc.on("error", (err) => {
      console.error(chalk.red(`❌ Failed to run docker compose: ${err.message}`));
      process.exit(1);
    });

    proc.on("exit", (code) => {
      process.exit(code || 0);
    });
  } catch (error) {
    if (error instanceof Error) {
      console.error(chalk.red(`❌ ${error.message}`));
      process.exit(1);
    }
    throw error;
  }
}
