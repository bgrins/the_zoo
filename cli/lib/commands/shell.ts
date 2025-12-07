import chalk from "chalk";
import { checkDocker, dockerComposeExecInteractive } from "../utils/docker";
import { getInstanceSourcePath } from "../utils/instance";
import { getProjectName } from "../utils/project";

interface ScriptOptions {
  instance?: string;
}

export async function shellPostgres(args: string[], options: ScriptOptions): Promise<void> {
  // Check if Docker is running
  const dockerRunning = await checkDocker();
  if (!dockerRunning) {
    console.error(chalk.red("❌ Docker is not running. Please start Docker first."));
    process.exit(1);
  }

  try {
    // Get the project name (handles instance validation)
    const projectName = await getProjectName(options.instance);
    const zooSourcePath = getInstanceSourcePath(projectName);

    await dockerComposeExecInteractive("postgres", ["psql", "-U", "postgres", ...args], {
      cwd: zooSourcePath,
      projectName,
    });
  } catch (error) {
    if (error instanceof Error) {
      console.error(chalk.red(`❌ ${error.message}`));
      process.exit(1);
    }
    throw error;
  }
}

export async function shellRedis(args: string[], options: ScriptOptions): Promise<void> {
  // Check if Docker is running
  const dockerRunning = await checkDocker();
  if (!dockerRunning) {
    console.error(chalk.red("❌ Docker is not running. Please start Docker first."));
    process.exit(1);
  }

  try {
    // Get the project name (handles instance validation)
    const projectName = await getProjectName(options.instance);
    const zooSourcePath = getInstanceSourcePath(projectName);

    await dockerComposeExecInteractive("redis", ["redis-cli", ...args], {
      cwd: zooSourcePath,
      projectName,
    });
  } catch (error) {
    if (error instanceof Error) {
      console.error(chalk.red(`❌ ${error.message}`));
      process.exit(1);
    }
    throw error;
  }
}

export async function shellStalwart(args: string[], options: ScriptOptions): Promise<void> {
  // Check if Docker is running
  const dockerRunning = await checkDocker();
  if (!dockerRunning) {
    console.error(chalk.red("❌ Docker is not running. Please start Docker first."));
    process.exit(1);
  }

  try {
    // Get the project name (handles instance validation)
    const projectName = await getProjectName(options.instance);
    const zooSourcePath = getInstanceSourcePath(projectName);

    // Add default credentials if not provided
    const stalwartArgs = [...args];
    if (!args.includes("-u") && !args.includes("--url")) {
      stalwartArgs.unshift("-u", "http://localhost:8080");
    }
    if (!args.includes("-c") && !args.includes("--credentials")) {
      stalwartArgs.unshift("-c", "admin:zoo-mail-admin-pw");
    }

    await dockerComposeExecInteractive("stalwart", ["stalwart-cli", ...stalwartArgs], {
      cwd: zooSourcePath,
      projectName,
    });
  } catch (error) {
    if (error instanceof Error) {
      console.error(chalk.red(`❌ ${error.message}`));
      process.exit(1);
    }
    throw error;
  }
}

export async function shellMysql(args: string[], options: ScriptOptions): Promise<void> {
  // Check if Docker is running
  const dockerRunning = await checkDocker();
  if (!dockerRunning) {
    console.error(chalk.red("❌ Docker is not running. Please start Docker first."));
    process.exit(1);
  }

  try {
    // Get the project name (handles instance validation)
    const projectName = await getProjectName(options.instance);
    const zooSourcePath = getInstanceSourcePath(projectName);

    await dockerComposeExecInteractive(
      "mysql",
      ["mysql", "-h", "127.0.0.1", "-uroot", "-ppassword", ...args],
      {
        cwd: zooSourcePath,
        projectName,
      },
    );
  } catch (error) {
    if (error instanceof Error) {
      console.error(chalk.red(`❌ ${error.message}`));
      process.exit(1);
    }
    throw error;
  }
}
