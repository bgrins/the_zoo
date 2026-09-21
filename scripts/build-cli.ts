#!/usr/bin/env -S npx tsx

/**
 * Build script to prepare the CLI package for npm publishing
 * Copies necessary zoo sources into the CLI package
 */

import { execFile } from "node:child_process";
import { createHash } from "node:crypto";
import fs from "node:fs/promises";
import path from "node:path";
import { promisify } from "node:util";
import { fileURLToPath } from "node:url";
import { build as esbuild, type Metafile } from "esbuild";

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

/**
 * A hash of the paths and contents of every file under `dir`
 */
async function hashDirectory(dir: string): Promise<string> {
  const files = (await fs.readdir(dir, { recursive: true, withFileTypes: true }))
    .filter((entry) => entry.isFile())
    .map((entry) => path.relative(dir, path.join(entry.parentPath, entry.name)))
    .sort();
  const hash = createHash("sha256");
  for (const file of files) {
    const content = await fs.readFile(path.join(dir, file));
    hash.update(`${file}\0${content.length}\0`).update(content);
  }
  return hash.digest("hex");
}

interface PackageJson {
  [key: string]: any;
  bin?: Record<string, string>;
  files?: string[];
  dependencies?: Record<string, string>;
}

const THIRD_PARTY_LICENSES = "THIRD_PARTY_LICENSES";

/**
 * The name, version and license text of every package the bundle includes code from
 */
async function bundledLicenses(metafile: Metafile): Promise<{ text: string; count: number }> {
  const packageDirs = new Set<string>();
  for (const output of Object.values(metafile.outputs)) {
    for (const [input, { bytesInOutput }] of Object.entries(output.inputs)) {
      const match = input.match(/^(.*node_modules\/(?:@[^/]+\/)?[^/]+)\//);
      if (match && bytesInOutput > 0) {
        packageDirs.add(path.resolve(ROOT_DIR, match[1]));
      }
    }
  }

  const sections: string[] = [];
  for (const dir of [...packageDirs].sort()) {
    const manifest: PackageJson = JSON.parse(
      await fs.readFile(path.join(dir, "package.json"), "utf-8"),
    );
    const licenseFile = (await fs.readdir(dir)).find((file) => /^licen[cs]e/i.test(file));
    const text = licenseFile
      ? (await fs.readFile(path.join(dir, licenseFile), "utf-8")).trim()
      : `License: ${manifest.license}`;
    sections.push(`${manifest.name}@${manifest.version} (${manifest.license})\n\n${text}`);
  }
  return {
    text: `The Zoo CLI bundles the following packages.\n\n${sections.join(`\n\n${"-".repeat(72)}\n\n`)}\n`,
    count: sections.length,
  };
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

  // Bundle the CLI and its dependencies into one file. The package ships no lockfile, so
  // dependencies installed with it would resolve their version ranges at install time.
  console.log("\nBundling CLI...");
  // An instance copies the sources again when they differ from the ones it has
  const sourcesId = await hashDirectory(ZOO_BUILD_DIR);

  let metafile: Metafile;
  try {
    ({ metafile } = await esbuild({
      absWorkingDir: ROOT_DIR,
      entryPoints: [path.join(CLI_DIR, "bin", "thezoo.ts")],
      bundle: true,
      platform: "node",
      target: "node20",
      format: "esm",
      outfile: path.join(BUILD_DIR, "bin", "thezoo.js"),
      metafile: true,
      logLevel: "warning",
      define: { __ZOO_SOURCES_ID__: JSON.stringify(sourcesId) },
      // CommonJS dependencies (commander) require Node's built-in modules
      banner: {
        js: 'import { createRequire } from "node:module"; const require = createRequire(import.meta.url);',
      },
    }));
    console.log("  ✓ CLI bundled successfully");
  } catch (error) {
    console.error("Bundling failed:", error);
    process.exit(1);
  }

  const licenses = await bundledLicenses(metafile);
  await fs.writeFile(path.join(BUILD_DIR, THIRD_PARTY_LICENSES), licenses.text);
  console.log(`  ✓ ${THIRD_PARTY_LICENSES} (${licenses.count} packages)`);

  for (const file of ["README.md", "LICENSE"]) {
    await fs.copyFile(path.join(ROOT_DIR, file), path.join(BUILD_DIR, file));
    console.log(`  ✓ ${file}`);
  }

  // Copy CLI package.json and update it for publishing
  const cliPackageJson: PackageJson = JSON.parse(
    await fs.readFile(path.join(CLI_DIR, "package.json"), "utf-8"),
  );
  cliPackageJson.bin = { the_zoo: "./bin/thezoo.js" };
  cliPackageJson.files = ["bin/", "zoo/", "README.md", "LICENSE", THIRD_PARTY_LICENSES];
  // Bundled into bin/thezoo.js
  delete cliPackageJson.dependencies;
  await fs.writeFile(path.join(BUILD_DIR, "package.json"), JSON.stringify(cliPackageJson, null, 2));
  console.log("  ✓ package.json");

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
