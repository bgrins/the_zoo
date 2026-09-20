import chalk from "chalk";
import { dockerCompose, getRunningInstances } from "../utils/docker";
import { CliError, errorMessage } from "../utils/errors";
import { getInstanceEnvFile, getInstanceSourcePath } from "../utils/instance";
import { startSpinner } from "../utils/output";
import { getProjectName } from "../utils/project";

interface StopOptions {
  all?: boolean;
  instance?: string;
  quiet?: boolean;
}

// Without --profile '*' compose skips the on-demand services, whose containers would
// keep the instance network in use
async function stopProject(projectName: string, quiet?: boolean): Promise<void> {
  await dockerCompose(["--profile", "*", "down", "-v", "-t", "0", "--remove-orphans"], {
    cwd: getInstanceSourcePath(projectName),
    envFile: getInstanceEnvFile(projectName),
    projectName,
    showCommand: false,
    progress: quiet ? "quiet" : undefined,
  });
}

export async function stop(options: StopOptions): Promise<void> {
  console.log(chalk.blue("🛑 Stopping The Zoo..."));

  // `down -v` deletes the project's data, so only an explicit --instance may name a project
  // other than a CLI instance (in dev mode, the dev environment or a worktree)
  const runningProjects = await getRunningInstances({ onlyCliInstances: true });

  if (runningProjects.length === 0 && !options.instance) {
    console.log(chalk.yellow("No Zoo CLI instances are running"));
    return;
  }

  // Handle --all option
  if (options.all && !options.instance) {
    console.log(chalk.yellow(`Stopping all ${runningProjects.length} Zoo instance(s)...`));

    let failedStops = 0;
    for (const projectName of runningProjects) {
      console.log(chalk.gray(`\nStopping project: ${projectName}`));

      const spinner = startSpinner("Stopping services...");

      try {
        await stopProject(projectName, options.quiet);
        spinner.success("Services stopped");
      } catch (error) {
        spinner.error(`Failed to stop project ${projectName}`);
        console.error(chalk.red(errorMessage(error)));
        failedStops++;
      }
    }

    if (failedStops > 0) {
      throw new CliError(
        `Stopped ${runningProjects.length - failedStops} of ${runningProjects.length} instances`,
      );
    }
    console.log(chalk.green("\n✓ All Zoo instances have been stopped"));
    return;
  }

  // Stop the requested instance, or the only running one
  let projectName: string;
  try {
    if (!options.instance && runningProjects.length > 1) {
      throw new Error(
        `Multiple instances are running:\n${runningProjects.map((p) => `  - ${p}`).join("\n")}`,
      );
    }
    projectName = options.instance ? await getProjectName(options.instance) : runningProjects[0];
  } catch (error) {
    if (error instanceof CliError) {
      throw error;
    }
    throw new CliError(errorMessage(error), {
      hint: options.instance
        ? undefined
        : "Please use:\n" +
          "  the_zoo stop --all              (to stop all instances)\n" +
          "  the_zoo stop --instance <id>   (to stop a specific instance)",
    });
  }

  console.log(chalk.gray(`Stopping project: ${projectName}`));

  const spinner = startSpinner("Stopping services...");

  try {
    await stopProject(projectName, options.quiet);
    spinner.success("Services stopped");
    console.log(chalk.green("✓ The Zoo has been stopped"));
  } catch (error) {
    spinner.error("Failed to stop services");
    throw new CliError(errorMessage(error));
  }
}
