import { spawn } from "node:child_process";
import { composeFileArgs, existingDir } from "../utils/docker";
import { CliError } from "../utils/errors";
import { getInstanceEnvFile, getInstanceSourcePath } from "../utils/instance";
import { findRunningProject } from "../utils/project";

interface ComposeOptions {
  instance?: string;
}

export async function compose(args: string[], options: ComposeOptions): Promise<void> {
  const projectName = await findRunningProject(options.instance);
  const zooSourcePath = getInstanceSourcePath(projectName);
  const envFile = getInstanceEnvFile(projectName);

  const composeArgs = [
    "compose",
    ...composeFileArgs(zooSourcePath),
    ...(envFile ? ["--env-file", envFile] : []),
    "-p",
    projectName,
    ...args,
  ];

  await new Promise<void>((resolve, reject) => {
    const proc = spawn("docker", composeArgs, {
      stdio: "inherit",
      cwd: existingDir(zooSourcePath),
    });

    proc.on("error", (err) => {
      reject(new CliError(`Failed to run docker compose: ${err.message}`));
    });

    proc.on("exit", (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new CliError("", { exitCode: code || 1 }));
      }
    });
  });
}
