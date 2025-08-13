import { exec } from "node:child_process";
import { promisify } from "node:util";
import fs from "node:fs/promises";
import path from "node:path";
import chalk from "chalk";
import yoctoSpinner from "yocto-spinner";
import { confirm } from "@inquirer/prompts";
import { checkDocker, getRunningInstances } from "../utils/docker";
import { paths } from "../utils/config";

const execAsync = promisify(exec);

interface CleanOptions {
  force?: boolean;
  instance?: string;
}

/**
 * Clean up a specific instance
 */
async function cleanInstance(instanceId: string, options: CleanOptions): Promise<void> {
  const instanceDir = path.join(paths.runtime, instanceId);

  try {
    await fs.access(instanceDir);
  } catch {
    console.error(chalk.red(`Instance "${instanceId}" does not exist.`));
    process.exit(1);
  }

  if (!options.force) {
    console.log(chalk.yellow(`\nThis will remove instance "${instanceId}" and its files.`));

    const confirmed = await confirm({
      message: "Do you want to continue?",
      default: false,
    });

    if (!confirmed) {
      console.log("Operation cancelled");
      return;
    }
  }

  const spinner = yoctoSpinner({ text: `Removing instance ${instanceId}...` }).start();

  try {
    await fs.rm(instanceDir, { recursive: true, force: true });
    spinner.success(`Instance ${instanceId} removed`);
    console.log(chalk.green(`\n✓ Instance "${instanceId}" has been cleaned up`));
  } catch (error) {
    spinner.error("Failed to clean up instance");
    console.error(chalk.red((error as Error).message));
    process.exit(1);
  }
}

/**
 * Clean up all Zoo resources from Docker
 */
export async function clean(options: CleanOptions): Promise<void> {
  // If a specific instance is requested, clean only that
  if (options.instance) {
    return cleanInstance(options.instance, options);
  }

  console.log(chalk.blue("🧹 Cleaning up The Zoo CLI instances..."));

  // Check Docker
  const dockerRunning = await checkDocker();
  if (!dockerRunning) {
    console.error(chalk.red("Docker is not running"));
    process.exit(1);
  }

  // Get running instances for information
  const runningProjects = await getRunningInstances();

  if (!options.force && runningProjects.length > 0) {
    console.log(chalk.yellow("\nThe following Zoo instances are running:"));
    runningProjects.forEach((p) => console.log(`  - ${p}`));
    console.log(
      chalk.yellow(
        "\nThis command will stop and remove ALL Zoo CLI containers, networks, and volumes.",
      ),
    );

    const confirmed = await confirm({
      message: "Do you want to continue?",
      default: false,
    });

    if (!confirmed) {
      console.log("Operation cancelled");
      return;
    }
  }

  const spinner = yoctoSpinner({ text: "Cleaning up Docker resources..." }).start();

  try {
    // Step 1: Stop and remove all Zoo containers
    spinner.text = "Removing Zoo containers...";
    try {
      const { stdout: containers } = await execAsync('docker ps -aq --filter "name=thezoo-"');

      if (containers.trim()) {
        const containerList = containers
          .trim()
          .split("\n")
          .filter((c) => c)
          .join(" ");
        if (containerList) {
          await execAsync(`docker rm -f ${containerList}`);
        }
      }
    } catch (error) {
      console.warn(chalk.yellow(`Warning: ${(error as Error).message}`));
    }

    // Step 2: Remove all Zoo networks
    spinner.text = "Removing Zoo networks...";
    try {
      const { stdout: networks } = await execAsync(
        'docker network ls --filter "name=thezoo-" --format "{{.Name}}"',
      );

      if (networks.trim()) {
        for (const network of networks.trim().split("\n")) {
          if (network) {
            await execAsync(`docker network rm ${network}`).catch(() => {});
          }
        }
      }
    } catch (_error) {
      // No networks to remove
    }

    // Step 3: Remove all Zoo CLI volumes
    // Note: Only removes volumes with names like "thezoo-v1_*", "thezoo-test_*", etc.
    // Main Zoo project volumes (like "thezoo_caddy_data") are NOT removed
    spinner.text = "Removing Zoo CLI volumes...";
    try {
      const { stdout: volumes } = await execAsync(
        'docker volume ls --format "{{.Name}}" | grep -E "^thezoo-[^_]+_" || true',
      );

      if (volumes.trim()) {
        for (const volume of volumes.trim().split("\n")) {
          if (volume?.match(/^thezoo-[^_]+_/)) {
            await execAsync(`docker volume rm ${volume}`).catch(() => {});
          }
        }
      }
    } catch (_error) {
      // No volumes to remove
    }

    // Step 4: Prune any dangling images from Zoo builds
    spinner.text = "Pruning dangling images...";
    try {
      await execAsync('docker image prune -f --filter "label=com.docker.compose.project=thezoo-*"');
    } catch (_error) {
      // Ignore prune errors
    }

    spinner.success("Docker resources cleaned");

    console.log(chalk.green("\n✓ The Zoo CLI instances have been cleaned up"));
  } catch (error) {
    spinner.error("Failed to clean up");
    console.error(chalk.red((error as Error).message));
    process.exit(1);
  }
}
