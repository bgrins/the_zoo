import { describe, it, beforeAll, afterAll, expect } from "vitest";
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawn } from "node:child_process";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT_DIR = path.resolve(__dirname, "../..");
const BUILD_SCRIPT = path.join(ROOT_DIR, "scripts", "build-cli.ts");
const BUILD_DIR_NAME = `dist-test-${Date.now()}`;
const BUILD_DIR = path.join(ROOT_DIR, BUILD_DIR_NAME);

async function runBuild(): Promise<{ stdout: string; stderr: string }> {
  return new Promise((resolve, reject) => {
    const proc = spawn("npx", ["tsx", BUILD_SCRIPT, BUILD_DIR_NAME], {
      cwd: ROOT_DIR,
      stdio: "pipe",
      env: {
        ...process.env,
        SKIP_NPM_INSTALL: "true",
      },
    });

    let stdout = "";
    let stderr = "";

    proc.stdout.on("data", (data) => {
      stdout += data.toString();
    });

    proc.stderr.on("data", (data) => {
      stderr += data.toString();
    });

    proc.on("close", (code) => {
      if (code === 0) {
        resolve({ stdout, stderr });
      } else {
        reject(new Error(`Build failed with code ${code}: ${stderr}`));
      }
    });
  });
}

describe("CLI Build Process", () => {
  beforeAll(async () => {
    // Clean up any existing build directory
    await fs.rm(BUILD_DIR, { recursive: true, force: true });
  });

  afterAll(async () => {
    // Clean up after tests
    await fs.rm(BUILD_DIR, { recursive: true, force: true });
  });

  it("should run build script successfully", async () => {
    const { stdout } = await runBuild();
    expect(stdout).toContain("Building CLI package...");
    expect(stdout).toContain("Build complete!");
  });

  it("should create dist-test directory", async () => {
    const stats = await fs.stat(BUILD_DIR);
    expect(stats.isDirectory()).toBe(true);
  });

  it("should copy zoo sources to dist-test/zoo", async () => {
    const zooDir = path.join(BUILD_DIR, "zoo");
    const stats = await fs.stat(zooDir);
    expect(stats.isDirectory()).toBe(true);

    // Check key files were copied
    const expectedFiles = [
      "docker-compose.yaml",
      "core/caddy/Caddyfile",
      "core/coredns/Corefile",
      "sites",
    ];

    for (const file of expectedFiles) {
      const filePath = path.join(zooDir, file);
      await expect(fs.access(filePath)).resolves.not.toThrow();
    }
  });

  it("should bundle CLI into single JS file", async () => {
    const binDir = path.join(BUILD_DIR, "bin");

    const binStats = await fs.stat(binDir);
    expect(binStats.isDirectory()).toBe(true);

    // Check thezoo.js exists (bundled output)
    const thezooBin = path.join(binDir, "thezoo.js");
    await expect(fs.access(thezooBin)).resolves.not.toThrow();
  });

  it("should copy README.md", async () => {
    const readme = path.join(BUILD_DIR, "README.md");
    await expect(fs.access(readme)).resolves.not.toThrow();
  });

  it("should exclude node_modules and other ignored patterns", async () => {
    const zooDir = path.join(BUILD_DIR, "zoo");

    // These should NOT exist
    const excludedPaths = ["node_modules", ".git", "data", ".zoo"];

    for (const excluded of excludedPaths) {
      await expect(fs.access(path.join(zooDir, excluded))).rejects.toThrow();
    }
  });

  it("should exclude log files", async () => {
    const zooDir = path.join(BUILD_DIR, "zoo");

    // Walk through zoo directory and ensure no .log files
    async function checkForLogs(dir: string): Promise<void> {
      const entries = await fs.readdir(dir, { withFileTypes: true });

      for (const entry of entries) {
        if (entry.name.endsWith(".log")) {
          throw new Error(`Found log file: ${path.join(dir, entry.name)}`);
        }

        if (entry.isDirectory() && !["node_modules", ".git", "data"].includes(entry.name)) {
          await checkForLogs(path.join(dir, entry.name));
        }
      }
    }

    await expect(checkForLogs(zooDir)).resolves.not.toThrow();
  });

  it("should create valid package.json structure in dist-test", async () => {
    const distPackageJsonPath = path.join(BUILD_DIR, "package.json");
    const distPackageJson = JSON.parse(await fs.readFile(distPackageJsonPath, "utf-8"));

    expect(distPackageJson.name).toBe("the_zoo");
    expect(distPackageJson.bin).toEqual({ the_zoo: "./bin/thezoo.js" });
    expect(distPackageJson.files).toContain("bin/");
    expect(distPackageJson.files).toContain("zoo/");
    expect(distPackageJson.files).toContain("README.md");
    expect(distPackageJson.type).toBe("module");
    expect(distPackageJson.engines?.node).toBeDefined();
  });

  it("should create packable output with npm pack --dry-run", async () => {
    const proc = spawn("npm", ["pack", "--dry-run"], {
      cwd: BUILD_DIR,
      stdio: "pipe",
    });

    let stdout = "";
    let stderr = "";

    proc.stdout.on("data", (data) => {
      stdout += data.toString();
    });

    proc.stderr.on("data", (data) => {
      stderr += data.toString();
    });

    await new Promise((resolve, reject) => {
      proc.on("close", (code) => {
        if (code === 0) {
          resolve(undefined);
        } else {
          reject(new Error(`npm pack failed with code ${code}: ${stderr}`));
        }
      });
    });

    const packOutput = stdout + stderr;

    // Verify expected files are included
    expect(packOutput).toContain("bin/thezoo.js");
    expect(packOutput).toContain("README.md");
    expect(packOutput).toContain("zoo/docker-compose.yaml");
    expect(packOutput).toContain("zoo/core/caddy/Dockerfile");
    expect(packOutput).toContain("zoo/core/caddy/modules/dockerstatus/dockerstatus.go");
    expect(packOutput).toContain("zoo/core/caddy/modules/failinjector/failinjector.go");
    expect(packOutput).toContain("zoo/core/caddy/modules/ondemanddocker/ondemanddocker.go");

    // Verify package metadata
    expect(packOutput).toContain("the_zoo@");
    expect(packOutput).toContain("Tarball Contents");
    expect(packOutput).toContain("Tarball Details");

    // Ensure no source files are included
    // Check that no paths start with these directories
    const lines = packOutput.split("\n");
    const filePaths = lines.filter((line) => line.match(/^\s*\d+B\s+/)); // npm pack format shows size followed by path

    for (const line of filePaths) {
      const pathMatch = line.match(/^\s*\d+[KMG]?B\s+(.+)$/);
      if (pathMatch) {
        const filePath = pathMatch[1].trim();
        expect(filePath).not.toMatch(/^cli\/bin\//);
        expect(filePath).not.toMatch(/^tests\//);
        expect(filePath).not.toMatch(/^scripts\//);
        expect(filePath).not.toMatch(/^.git\//);
      }
    }

    // Also check for specific files that shouldn't be there
    expect(packOutput).not.toContain("scripts/build-cli.ts");

    // Verify package size is reasonable (less than 5MB)
    const sizeMatch = packOutput.match(/package size:\s+([\d.]+)\s*([KM]B)/);
    if (sizeMatch) {
      const size = parseFloat(sizeMatch[1]);
      const unit = sizeMatch[2];
      const sizeInKB = unit === "MB" ? size * 1024 : size;
      expect(sizeInKB).toBeLessThan(5 * 1024);
    }
  });
});
