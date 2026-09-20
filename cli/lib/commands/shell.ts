import { dockerComposeExecInteractive } from "../utils/docker";
import { getInstanceEnvFile, getInstanceSourcePath } from "../utils/instance";
import { getProjectName } from "../utils/project";

interface ScriptOptions {
  instance?: string;
}

async function execInService(
  service: string,
  command: string[],
  options: ScriptOptions,
): Promise<void> {
  // Get the project name (handles instance validation, and checks Docker is running)
  const projectName = await getProjectName(options.instance);

  await dockerComposeExecInteractive(service, command, {
    cwd: getInstanceSourcePath(projectName),
    envFile: getInstanceEnvFile(projectName),
    projectName,
  });
}

export async function shellPostgres(args: string[], options: ScriptOptions): Promise<void> {
  await execInService("postgres", ["psql", "-U", "postgres", ...args], options);
}

export async function shellRedis(args: string[], options: ScriptOptions): Promise<void> {
  await execInService("redis", ["redis-cli", ...args], options);
}

export async function shellStalwart(args: string[], options: ScriptOptions): Promise<void> {
  // Add default credentials if not provided
  const stalwartArgs = [...args];
  if (!args.includes("-u") && !args.includes("--url")) {
    stalwartArgs.unshift("-u", "http://localhost:8080");
  }
  if (!args.includes("-c") && !args.includes("--credentials")) {
    stalwartArgs.unshift("-c", "admin:zoo-mail-admin-pw");
  }

  await execInService("stalwart", ["stalwart-cli", ...stalwartArgs], options);
}

export async function shellMysql(args: string[], options: ScriptOptions): Promise<void> {
  await execInService(
    "mysql",
    ["mysql", "-h", "127.0.0.1", "-uroot", "-ppassword", ...args],
    options,
  );
}
