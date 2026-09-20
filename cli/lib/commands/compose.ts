import { spawn } from "node:child_process";
import { composeProjectArgs, existingDir } from "../utils/docker";
import { CliError } from "../utils/errors";
import { projectComposeOptions } from "../utils/instance";
import { findRunningProject } from "../utils/project";

interface ComposeOptions {
  instance?: string;
}

export async function compose(args: string[], options: ComposeOptions): Promise<void> {
  const projectName = await findRunningProject(options.instance);
  const composeOptions = await projectComposeOptions(projectName);

  const composeArgs = ["compose", ...composeProjectArgs(composeOptions), ...args];

  await new Promise<void>((resolve, reject) => {
    const proc = spawn("docker", composeArgs, {
      stdio: "inherit",
      cwd: existingDir(composeOptions.cwd),
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
