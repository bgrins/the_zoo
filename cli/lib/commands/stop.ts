import chalk from "chalk";
import yoctoSpinner from "yocto-spinner";
import { dockerCompose, getRunningInstances } from "../utils/docker";
import { getProjectName } from "../utils/project";

interface StopOptions {
  all?: boolean;
  instance?: string;
}

export async function stop(options: StopOptions): Promise<void> {
  console.log(chalk.blue("🛑 Stopping The Zoo..."));

  // For stop command, we don't need the actual zoo source files
  // We just need any valid directory for docker compose to run from
  // The project name in docker compose will find the right containers
  const zooSourcePath = process.cwd(); // Use current directory

  // Check running instances
  const runningProjects = await getRunningInstances();

  if (runningProjects.length === 0) {
    console.log(chalk.yellow("No Zoo CLI instances are running"));
    return;
  }

  // Handle --instance option
  if (options.instance) {
    let projectName: string;
    try {
      projectName = await getProjectName(options.instance);
    } catch (error) {
      console.error(chalk.red(`❌ ${(error as Error).message}`));
      process.exit(1);
    }

    console.log(chalk.gray(`Stopping project: ${projectName}`));
    const spinner = yoctoSpinner({ text: "Stopping services..." }).start();

    try {
      await dockerCompose("down", {
        cwd: zooSourcePath,
        projectName,
        showCommand: false,
      });

      spinner.success("Services stopped");
      console.log(chalk.green("✓ The Zoo instance has been stopped"));
    } catch (error) {
      spinner.error("Failed to stop services");
      console.error(chalk.red((error as Error).message));
      process.exit(1);
    }
    return;
  }

  // Handle --all option
  if (options.all) {
    console.log(chalk.yellow(`Stopping all ${runningProjects.length} Zoo instance(s)...`));

    let failedStops = 0;
    for (const projectName of runningProjects) {
      console.log(chalk.gray(`\nStopping project: ${projectName}`));

      const spinner = yoctoSpinner({ text: "Stopping services..." }).start();

      try {
        await dockerCompose("down", {
          cwd: zooSourcePath,
          projectName,
          showCommand: false,
        });

        spinner.success("Services stopped");
      } catch (error) {
        spinner.error(`Failed to stop project ${projectName}`);
        console.error(chalk.red((error as Error).message));
        failedStops++;
      }
    }

    if (failedStops === 0) {
      console.log(chalk.green("\n✓ All Zoo instances have been stopped"));
    } else {
      console.log(
        chalk.yellow(
          `\n⚠️  Stopped ${runningProjects.length - failedStops} of ${runningProjects.length} instances`,
        ),
      );
      process.exit(1);
    }
    return;
  }

  // Stop the default instance (will error if multiple are running)
  let projectName: string;
  try {
    projectName = await getProjectName(undefined);
  } catch (error) {
    console.error(chalk.red(`❌ ${(error as Error).message}`));
    console.log("\nPlease use:");
    console.log("  thezoo stop --all              (to stop all instances)");
    console.log("  thezoo stop --instance <id>   (to stop a specific instance)");
    process.exit(1);
  }

  console.log(chalk.gray(`Stopping project: ${projectName}`));

  const spinner = yoctoSpinner({ text: "Stopping services..." }).start();

  try {
    await dockerCompose("down", {
      cwd: zooSourcePath,
      projectName,
      showCommand: false,
    });

    spinner.success("Services stopped");
    console.log(chalk.green("✓ The Zoo has been stopped"));
  } catch (error) {
    spinner.error("Failed to stop services");
    console.error(chalk.red((error as Error).message));
    process.exit(1);
  }
}
