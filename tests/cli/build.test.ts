import { describe, it, beforeAll, afterAll, expect } from "vitest";
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execFileSync, spawn } from "node:child_process";
import { createdInstanceId, createFakeDocker, makeTempDir, runCLI } from "./helpers";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT_DIR = path.resolve(__dirname, "../..");
const UNTRACKED_FILE = path.join("core", `untracked-build-test-${Date.now()}`, "big.bin");
const COPIED_SOURCES = ["core", "sites", "docs/credentials"];

/**
 * Build into `outputDir`, running the script from `checkout` (ROOT_DIR or a path to it)
 * as the working directory
 */
async function runBuild(
  outputDir: string,
  options: { checkout?: string; env?: Record<string, string> } = {},
): Promise<{ stdout: string; stderr: string }> {
  const checkout = options.checkout ?? ROOT_DIR;
  return new Promise((resolve, reject) => {
    const proc = spawn("npx", ["tsx", path.join(checkout, "scripts", "build-cli.ts"), outputDir], {
      cwd: checkout,
      stdio: "pipe",
      env: {
        ...process.env,
        PWD: checkout,
        SKIP_NPM_INSTALL: "true",
        ...options.env,
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
  let tempDir: string;
  let buildDir: string;
  let buildOutput: string;

  beforeAll(async () => {
    tempDir = makeTempDir("thezoo-build");
    buildDir = path.join(tempDir, "dist");
    // The build copies tracked files only, so this one must not ship. It lives in the
    // checkout only while the build runs.
    const untracked = path.join(ROOT_DIR, UNTRACKED_FILE);
    await fs.mkdir(path.dirname(untracked), { recursive: true });
    await fs.writeFile(untracked, "untracked");
    try {
      ({ stdout: buildOutput } = await runBuild(buildDir));
    } finally {
      await fs.rm(path.dirname(untracked), { recursive: true, force: true });
    }
  }, 60_000);

  afterAll(async () => {
    await fs.rm(tempDir, { recursive: true, force: true });
  });

  it("should run build script successfully", () => {
    expect(buildOutput).toContain("Building CLI package...");
    expect(buildOutput).toContain("Build complete!");
  });

  it("should not ship untracked files", async () => {
    await expect(fs.access(path.join(buildDir, "zoo", UNTRACKED_FILE))).rejects.toThrow();
    await expect(
      fs.access(path.join(buildDir, "zoo", path.dirname(UNTRACKED_FILE))),
    ).rejects.toThrow();
  });

  it("should copy zoo sources to the package's zoo directory", async () => {
    const zooDir = path.join(buildDir, "zoo");
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
    const binDir = path.join(buildDir, "bin");

    const binStats = await fs.stat(binDir);
    expect(binStats.isDirectory()).toBe(true);

    // Check thezoo.js exists (bundled output)
    const thezooBin = path.join(binDir, "thezoo.js");
    await expect(fs.access(thezooBin)).resolves.not.toThrow();
  });

  it(
    "should run from the package with its own copy of the sources",
    { timeout: 60_000 },
    async () => {
      const home = makeTempDir("thezoo-bundle-home");
      const docker = createFakeDocker();
      // The bundle leaves its dependencies external, for the package install to provide
      const nodeModules = path.join(buildDir, "node_modules");
      await fs.symlink(path.join(ROOT_DIR, "node_modules"), nodeModules, "junction");
      const run = (args: string[]) =>
        runCLI(args, {
          bundle: path.join(buildDir, "bin", "thezoo.js"),
          cwd: home,
          env: { ...docker.env, THE_ZOO_HOME: home, ZOO_DEV: undefined },
        });

      try {
        const instanceId = createdInstanceId(await run(["create"]));
        const version = JSON.parse(await fs.readFile(path.join(buildDir, "package.json"), "utf-8"))
          .version as string;
        const instanceDir = path.join(home, "instances", `v${version}`, instanceId);
        const composeFile = path.join(instanceDir, "docker-compose.yaml");

        expect(await fs.readFile(composeFile, "utf-8")).toBe(
          await fs.readFile(path.join(buildDir, "zoo", "docker-compose.yaml"), "utf-8"),
        );
        await expect(fs.access(path.join(instanceDir, "core", "caddy", "Caddyfile"))).resolves.toBe(
          undefined,
        );
        const project = `thezoo-cli-instance-${instanceId}-v${version.replace(/\./g, "-")}`;

        // docker compose run by hand in the instance directory targets the instance, whose
        // networks and volumes are its own rather than the dev environment's
        const { COMPOSE_PROJECT_NAME: _projectName, ...shellEnv } = process.env;
        const config = JSON.parse(
          execFileSync("docker", ["compose", "config", "--format", "json"], {
            cwd: instanceDir,
            env: { ...shellEnv, PWD: instanceDir },
            encoding: "utf-8",
          }),
        );
        expect(config.name).toBe(project);
        expect(config.networks.public.name).toBe(`${project}_public`);
        expect(config.networks["zoo-network"].name).toBe(`${project}_zoo-network`);
        expect(config.volumes.caddy_data.name).toBe(`${project}_caddy_data`);
        expect(config.services.caddy.volumes).toContainEqual(
          expect.objectContaining({ source: path.join(instanceDir, "core", "caddy", "Caddyfile") }),
        );

        const started = await run(["start", "--instance", instanceId]);
        expect(started.code, started.stderr).toBe(0);
        expect(docker.calls()).toContainEqual([
          "compose",
          "-f",
          composeFile,
          "--env-file",
          path.join(instanceDir, ".env"),
          "-p",
          project,
          "up",
          "-d",
        ]);
      } finally {
        docker.cleanup();
        await fs.unlink(nodeModules);
        await fs.rm(home, { recursive: true, force: true });
      }
    },
  );

  it("should copy README.md", async () => {
    const readme = path.join(buildDir, "README.md");
    await expect(fs.access(readme)).resolves.not.toThrow();
  });

  it("should ship the repository's license", async () => {
    expect(await fs.readFile(path.join(buildDir, "LICENSE"), "utf-8")).toBe(
      await fs.readFile(path.join(ROOT_DIR, "LICENSE"), "utf-8"),
    );
    const distPackageJson = JSON.parse(
      await fs.readFile(path.join(buildDir, "package.json"), "utf-8"),
    );
    expect(distPackageJson.license).toBe("Apache-2.0");
  });

  it("should exclude node_modules and other ignored patterns", async () => {
    const zooDir = path.join(buildDir, "zoo");

    // These should NOT exist
    const excludedPaths = ["node_modules", ".git", "data", ".the_zoo"];

    for (const excluded of excludedPaths) {
      await expect(fs.access(path.join(zooDir, excluded))).rejects.toThrow();
    }
  });

  it("should exclude log files", async () => {
    const zooDir = path.join(buildDir, "zoo");

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

  it("should create valid package.json structure", async () => {
    const distPackageJsonPath = path.join(buildDir, "package.json");
    const distPackageJson = JSON.parse(await fs.readFile(distPackageJsonPath, "utf-8"));

    expect(distPackageJson.name).toBe("the_zoo");
    expect(distPackageJson.bin).toEqual({ the_zoo: "./bin/thezoo.js" });
    expect(distPackageJson.files).toContain("bin/");
    expect(distPackageJson.files).toContain("zoo/");
    expect(distPackageJson.files).toContain("README.md");
    expect(distPackageJson.type).toBe("module");
    expect(distPackageJson.engines?.node).toBeDefined();
  });

  it("should stamp CLI version and merge docker-compose files", async () => {
    // Read CLI version
    const cliPackageJsonPath = path.join(ROOT_DIR, "cli", "package.json");
    const cliPackageJson = JSON.parse(await fs.readFile(cliPackageJsonPath, "utf-8"));
    const expectedVersion = cliPackageJson.version;

    // Read the built docker-compose.yaml (merged from main + packages)
    const composeYamlPath = path.join(buildDir, "zoo", "docker-compose.yaml");
    const composeYaml = await fs.readFile(composeYamlPath, "utf-8");

    // Should contain the version as default in ZOO_IMAGE_TAG variable
    // Format: ${ZOO_IMAGE_TAG:-0.2.0} - allows runtime override while defaulting to CLI version
    const imageTagPattern = `\${ZOO_IMAGE_TAG:-${expectedVersion}}`;
    expect(composeYaml).toContain(`ghcr.io/bgrins/the_zoo/caddy:${imageTagPattern}`);
    expect(composeYaml).toContain(`ghcr.io/bgrins/the_zoo/postgres:${imageTagPattern}`);

    // docker-compose.packages.yaml should NOT exist (merged into main file)
    const packagesYamlPath = path.join(buildDir, "zoo", "docker-compose.packages.yaml");
    await expect(fs.access(packagesYamlPath)).rejects.toThrow();
  });

  it("should preserve environment variables for runtime substitution", async () => {
    // Read CLI version
    const cliPackageJsonPath = path.join(ROOT_DIR, "cli", "package.json");
    const cliPackageJson = JSON.parse(await fs.readFile(cliPackageJsonPath, "utf-8"));
    const expectedVersion = cliPackageJson.version;

    // Read the built docker-compose.yaml
    const composeYamlPath = path.join(buildDir, "zoo", "docker-compose.yaml");
    const composeYaml = await fs.readFile(composeYamlPath, "utf-8");

    // These env vars must be preserved (not interpolated) so CLI instances
    // can use different subnets/IPs to run alongside the dev environment
    const envVarPattern = (name: string, defaultVal: string) => `\${${name}:-${defaultVal}}`;

    expect(composeYaml).toContain(envVarPattern("ZOO_SUBNET", "172.20.0.0/16"));
    expect(composeYaml).toContain(envVarPattern("ZOO_PUBLIC_SUBNET", "172.21.0.0/30"));
    expect(composeYaml).toContain(envVarPattern("ZOO_DNS_IP", "172.20.250.2"));
    expect(composeYaml).toContain(envVarPattern("ZOO_CADDY_IP", "172.20.250.3"));
    expect(composeYaml).toContain(envVarPattern("ZOO_PROXY_IP", "172.20.250.4"));
    expect(composeYaml).toContain(envVarPattern("ZOO_PROXY_PORT", "3128"));

    // ZOO_IMAGE_TAG should be preserved but with the CLI version as default
    expect(composeYaml).toContain(envVarPattern("ZOO_IMAGE_TAG", expectedVersion));
  });

  it("should create packable output with npm pack --dry-run", async () => {
    const proc = spawn("npm", ["pack", "--dry-run"], {
      cwd: buildDir,
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

    // Verify package metadata
    expect(packOutput).toContain("the_zoo@");
    expect(packOutput).toContain("Tarball Contents");
    expect(packOutput).toContain("Tarball Details");

    // Each packed file is listed as e.g. "npm notice 3.0kB bin/thezoo.js"
    const files = packOutput
      .split("\n")
      .map((line) => line.match(/^npm notice [\d.]+[kMG]?B\s+(.+)$/)?.[1])
      .filter((file): file is string => file !== undefined);
    expect(files).toEqual(
      expect.arrayContaining([
        "bin/thezoo.js",
        "README.md",
        "LICENSE",
        "package.json",
        "zoo/docker-compose.yaml",
        "zoo/core/caddy/Dockerfile",
        "zoo/core/caddy/modules/dockerstatus/dockerstatus.go",
        "zoo/core/caddy/modules/failinjector/failinjector.go",
        "zoo/core/caddy/modules/ondemanddocker/ondemanddocker.go",
      ]),
    );
    for (const file of files) {
      expect(file).toMatch(/^(bin\/|zoo\/|README\.md$|LICENSE$|package\.json$)/);
    }

    // e.g. "npm notice package size: 261 B" or "1.2 MB"
    const sizeMatch = packOutput.match(/^npm notice package size:\s+([\d.]+)\s*([kMG]?B)$/m);
    if (!sizeMatch) {
      throw new Error(`No package size in npm pack output:\n${packOutput}`);
    }
    const unitKB = { B: 1 / 1000, kB: 1, MB: 1000, GB: 1000 ** 2 }[sizeMatch[2]] ?? Number.NaN;
    expect(parseFloat(sizeMatch[1]) * unitKB).toBeLessThan(5 * 1000);
  });
});

describe("CLI build from other checkouts", () => {
  let tempDir: string;

  beforeAll(() => {
    tempDir = makeTempDir("thezoo-build-checkouts");
  });

  afterAll(async () => {
    await fs.rm(tempDir, { recursive: true, force: true });
  });

  it(
    "should copy every source file from a source export",
    { timeout: 60_000, retry: 0 },
    async () => {
      // Stands in for a ZIP or `git archive` export: git finds no repository
      const notARepository = path.join(tempDir, "no-git");
      await fs.mkdir(notARepository);
      const outputDir = path.join(tempDir, "export");

      const { stdout } = await runBuild(outputDir, { env: { GIT_DIR: notARepository } });

      expect(stdout).toContain("not a git checkout");
      const tracked = execFileSync("git", ["ls-files", "-z", "--", ...COPIED_SOURCES], {
        cwd: ROOT_DIR,
        encoding: "utf-8",
      })
        .split("\0")
        .filter(Boolean);
      for (const file of tracked) {
        await expect(fs.access(path.join(outputDir, "zoo", file)), file).resolves.toBe(undefined);
      }
    },
  );

  it(
    "should keep compose paths relative when built through a symlinked path",
    { timeout: 60_000, retry: 0 },
    async () => {
      const linkDir = path.join(tempDir, "link");
      await fs.mkdir(linkDir);
      const checkout = path.join(linkDir, "the_zoo");
      await fs.symlink(ROOT_DIR, checkout);
      const outputDir = path.join(tempDir, "symlink");

      await runBuild(outputDir, { checkout });

      const composeYaml = await fs.readFile(
        path.join(outputDir, "zoo", "docker-compose.yaml"),
        "utf-8",
      );
      expect(composeYaml).not.toContain(linkDir);
      expect(composeYaml).not.toContain(ROOT_DIR);
      expect(composeYaml).toContain("source: ./core/caddy/Caddyfile");
    },
  );
});
