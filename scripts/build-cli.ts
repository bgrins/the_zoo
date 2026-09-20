#!/usr/bin/env -S npx tsx

/**
 * Build script to prepare the CLI package for npm publishing
 * Copies necessary zoo sources into the CLI package
 */

import { exec, execFile } from "node:child_process";
import fs from "node:fs/promises";
import path from "node:path";
import { promisify } from "node:util";
import { fileURLToPath } from "node:url";

const execAsync = promisify(exec);
const execFileAsync = promisify(execFile);

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const ROOT_DIR = path.resolve(__dirname, "..");
const CLI_DIR = path.join(ROOT_DIR, "cli");

// Allow output directory to be passed as command line argument, absolute or relative to ROOT_DIR
const outputDir = process.argv[2] || "dist";
const BUILD_DIR = path.resolve(ROOT_DIR, outputDir);
const ZOO_BUILD_DIR = path.join(BUILD_DIR, "zoo");

// Files and directories to copy from the root
const COPY_LIST = ["core", "sites", "docs/credentials"] as const;

/**
 * Whether ROOT_DIR is the top of a git work tree. A source export (a ZIP or
 * `git archive`) is not, and has no untracked files to leave out.
 */
async function isGitCheckout(): Promise<boolean> {
  try {
    const { stdout } = await execFileAsync("git", ["rev-parse", "--show-toplevel"], {
      cwd: ROOT_DIR,
    });
    return (await fs.realpath(stdout.trim())) === (await fs.realpath(ROOT_DIR));
  } catch (error) {
    // Any other git failure (git missing, "dubious ownership") would silently ship untracked files
    if (String((error as { stderr?: string }).stderr).includes("not a git repository")) {
      return false;
    }
    throw error;
  }
}

/**
 * Paths, relative to ROOT_DIR, of the files under `item` to ship: the git-tracked ones in
 * a checkout, so untracked local files never ship, otherwise all of them.
 */
async function listSourceFiles(item: string, gitCheckout: boolean): Promise<string[]> {
  if (!gitCheckout) {
    const entries = await fs.readdir(path.join(ROOT_DIR, item), {
      recursive: true,
      withFileTypes: true,
    });
    return entries
      .filter((entry) => entry.isFile())
      .map((entry) => path.relative(ROOT_DIR, path.join(entry.parentPath, entry.name)));
  }
  const { stdout } = await execFileAsync("git", ["ls-files", "-z", "--", item], {
    cwd: ROOT_DIR,
    maxBuffer: 64 * 1024 * 1024,
  });
  return stdout.split("\0").filter(Boolean);
}

async function copySources(item: string, gitCheckout: boolean): Promise<number> {
  const files = await listSourceFiles(item, gitCheckout);
  if (files.length === 0) {
    throw new Error("no files found");
  }

  let copied = 0;
  for (const file of files) {
    const src = path.join(ROOT_DIR, file);
    // Tracked files deleted in the working tree are left out of the build
    const exists = await fs
      .access(src)
      .then(() => true)
      .catch(() => false);
    if (!exists) continue;

    const dest = path.join(ZOO_BUILD_DIR, file);
    await fs.mkdir(path.dirname(dest), { recursive: true });
    await fs.copyFile(src, dest);
    copied++;
  }
  return copied;
}

interface PackageJson {
  [key: string]: any;
  bin?: Record<string, string>;
  files?: string[];
}

async function build(): Promise<void> {
  console.log("Building CLI package...");

  // Clean build directory
  console.log("Cleaning build directory...");
  await fs.rm(BUILD_DIR, { recursive: true, force: true });
  await fs.mkdir(ZOO_BUILD_DIR, { recursive: true });

  // Read CLI version for stamping into docker-compose.packages.yaml
  const cliPackageJsonRaw = await fs.readFile(path.join(CLI_DIR, "package.json"), "utf-8");
  const cliVersion = JSON.parse(cliPackageJsonRaw).version;
  console.log(`CLI version: ${cliVersion}`);

  // Copy necessary files
  const gitCheckout = await isGitCheckout();
  console.log(
    gitCheckout
      ? "Copying zoo sources..."
      : "Copying zoo sources (not a git checkout, so including untracked files)...",
  );
  for (const item of COPY_LIST) {
    try {
      const count = await copySources(item, gitCheckout);
      console.log(`  ✓ ${item} (${count} files)`);
    } catch (error) {
      console.error(`  ✗ Failed to copy ${item}: ${(error as Error).message}`);
      process.exit(1);
    }
  }

  // Merge docker-compose.yaml with packages override into a single file
  // Use --no-interpolate to preserve env var syntax (e.g., ${ZOO_SUBNET:-...})
  // Then post-process to update ZOO_IMAGE_TAG default from "latest" to the CLI version
  console.log("\nMerging docker-compose files...");
  try {
    // Without --no-path-resolution compose makes paths absolute under the build checkout
    // (as $PWD spells it, which can be a symlink). Without --no-normalize it names the
    // project, networks and volumes after the checkout (the_zoo, the dev project), and an
    // explicit network or volume name would be shared by every instance. The compose file
    // lives in zoo/ alongside core/, sites/ and docs/, so relative paths stay valid.
    const { stdout } = await execFileAsync(
      "docker",
      [
        "compose",
        "-f",
        "docker-compose.yaml",
        "-f",
        "docker-compose.packages.yaml",
        "config",
        "--no-interpolate",
        "--no-path-resolution",
        "--no-normalize",
      ],
      { cwd: ROOT_DIR, maxBuffer: 64 * 1024 * 1024 },
    );
    // Update the default value for ZOO_IMAGE_TAG from "latest" to the CLI version
    // This preserves the ability to override at runtime while setting a sensible default
    const processedOutput = stdout.replace(
      /\$\{ZOO_IMAGE_TAG:-latest\}/g,
      `\${ZOO_IMAGE_TAG:-${cliVersion}}`,
    );
    await fs.writeFile(path.join(ZOO_BUILD_DIR, "docker-compose.yaml"), processedOutput);
    console.log(`  ✓ Merged docker-compose.yaml with default image tag ${cliVersion}`);
  } catch (error) {
    console.error("Failed to merge docker-compose files:", error);
    process.exit(1);
  }

  // Bundle CLI into a single file using esbuild
  console.log("\nBundling CLI...");

  try {
    // Use esbuild to bundle everything into a single file
    // Use --packages=external to mark all packages as external (not bundled)
    // This avoids issues with Node.js built-ins and CJS/ESM incompatibilities
    await execFileAsync("npx", [
      "esbuild",
      path.join(CLI_DIR, "bin", "thezoo.ts"),
      "--bundle",
      "--platform=node",
      "--target=node20",
      "--format=esm",
      `--outfile=${path.join(BUILD_DIR, "bin", "thezoo.js")}`,
      "--packages=external",
    ]);
    console.log("  ✓ CLI bundled successfully");
  } catch (error) {
    console.error("Bundling failed:", error);
    process.exit(1);
  }

  // Copy main README
  await fs.copyFile(path.join(ROOT_DIR, "README.md"), path.join(BUILD_DIR, "README.md"));
  console.log("  ✓ README.md");

  // Copy CLI package.json and update it for publishing
  const cliPackageJson: PackageJson = JSON.parse(
    await fs.readFile(path.join(CLI_DIR, "package.json"), "utf-8"),
  );
  cliPackageJson.bin = { the_zoo: "./bin/thezoo.js" };
  cliPackageJson.files = ["bin/", "zoo/", "README.md"];
  await fs.writeFile(path.join(BUILD_DIR, "package.json"), JSON.stringify(cliPackageJson, null, 2));
  console.log("  ✓ package.json");

  // Install dependencies in the build directory
  // Skip npm install if SKIP_NPM_INSTALL env var is set (useful for tests)
  if (process.env.SKIP_NPM_INSTALL !== "true") {
    console.log("\nInstalling dependencies...");
    try {
      await execAsync("npm install --omit=dev", { cwd: BUILD_DIR });
      console.log("  ✓ Dependencies installed");
    } catch (error) {
      console.error("Failed to install dependencies:", error);
      process.exit(1);
    }
  }

  // Fix the shebang in the compiled thezoo.js
  const thezooBinPath = path.join(BUILD_DIR, "bin", "thezoo.js");
  let content = await fs.readFile(thezooBinPath, "utf-8");
  content = content.replace("#!/usr/bin/env tsx", "#!/usr/bin/env node");
  await fs.writeFile(thezooBinPath, content);
  console.log("  ✓ Updated shebang in thezoo.js");

  console.log("\nBuild complete! Package ready at:", BUILD_DIR);
}

// Run build
build().catch((error) => {
  console.error("Build failed:", error);
  process.exit(1);
});
