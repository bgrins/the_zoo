#!/usr/bin/env -S npx tsx

/**
 * Build script to prepare the CLI package for npm publishing
 * Copies necessary zoo sources into the CLI package
 */

import { exec } from "node:child_process";
import fs from "node:fs/promises";
import path from "node:path";
import { promisify } from "node:util";
import { fileURLToPath } from "node:url";

const execAsync = promisify(exec);

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const ROOT_DIR = path.resolve(__dirname, "..");
const CLI_DIR = path.join(ROOT_DIR, "cli");

// Allow output directory to be passed as command line argument
const outputDir = process.argv[2] || "dist";
const BUILD_DIR = path.join(ROOT_DIR, outputDir);
const ZOO_BUILD_DIR = path.join(BUILD_DIR, "zoo");

// Files and directories to copy from the root
const COPY_LIST = ["docker-compose.yaml", "core", "sites"] as const;

// Additional patterns to exclude (beyond gitignore)
const ADDITIONAL_EXCLUDE_PATTERNS: string[] = [
  // Add any patterns here that should be excluded from the package
  // but might not be in .gitignore
];

async function shouldExclude(filePath: string): Promise<boolean> {
  // First check if git would ignore this file
  try {
    // Get relative path from ROOT_DIR for git check-ignore
    const relativePath = path.relative(ROOT_DIR, filePath);
    await execAsync(`git check-ignore "${relativePath}"`, { cwd: ROOT_DIR });
    // If command succeeds, the file is ignored by git
    return true;
  } catch {
    // If command fails, the file is not ignored by git
    // Check additional patterns
    const basename = path.basename(filePath);
    return ADDITIONAL_EXCLUDE_PATTERNS.some((pattern) => {
      if (pattern.includes("*")) {
        const regex = new RegExp(`^${pattern.replace("*", ".*")}$`);
        return regex.test(basename);
      }
      return basename === pattern;
    });
  }
}

async function copyRecursive(src: string, dest: string): Promise<void> {
  const stats = await fs.stat(src);

  if (await shouldExclude(src)) {
    return;
  }

  if (stats.isDirectory()) {
    await fs.mkdir(dest, { recursive: true });
    const entries = await fs.readdir(src);

    for (const entry of entries) {
      const srcPath = path.join(src, entry);
      const destPath = path.join(dest, entry);
      await copyRecursive(srcPath, destPath);
    }
  } else {
    await fs.mkdir(path.dirname(dest), { recursive: true });
    await fs.copyFile(src, dest);
  }
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

  // Copy necessary files
  console.log("Copying zoo sources...");
  for (const item of COPY_LIST) {
    const src = path.join(ROOT_DIR, item);
    const dest = path.join(ZOO_BUILD_DIR, item);

    try {
      await copyRecursive(src, dest);
      console.log(`  ✓ ${item}`);
    } catch (error) {
      console.error(`  ✗ Failed to copy ${item}: ${(error as Error).message}`);
      process.exit(1);
    }
  }

  // Bundle CLI into a single file using esbuild
  console.log("\nBundling CLI...");

  try {
    // Use esbuild to bundle everything into a single file
    // Use --packages=external to mark all packages as external (not bundled)
    // This avoids issues with Node.js built-ins and CJS/ESM incompatibilities
    await execAsync(
      `npx esbuild ${CLI_DIR}/bin/thezoo.ts --bundle --platform=node --target=node18 --format=esm --outfile=${BUILD_DIR}/bin/thezoo.js --packages=external`,
    );
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
  cliPackageJson.bin = { thezoo: "./bin/thezoo.js" };
  cliPackageJson.files = ["bin/", "zoo/", "README.md"];
  await fs.writeFile(path.join(BUILD_DIR, "package.json"), JSON.stringify(cliPackageJson, null, 2));
  console.log("  ✓ package.json");

  // Install dependencies in the build directory
  // Skip npm install if SKIP_NPM_INSTALL env var is set (useful for tests)
  if (process.env.SKIP_NPM_INSTALL !== "true") {
    console.log("\nInstalling dependencies...");
    try {
      await execAsync("npm install --production", { cwd: BUILD_DIR });
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
