import { execFileSync } from "node:child_process";
import { chmodSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import path from "node:path";
import { expect, test } from "vitest";
import { cliEnv, createFakeDocker, makeTempDir, ROOT_DIR } from "./helpers";

test("MCP browser launches with the selected instance's published proxy port", () => {
  const project = "thezoo-cli-instance-sandbox-v0-9-0";
  const docker = createFakeDocker({
    projects: [project],
    rules: [
      {
        match: `^compose -p ${project} ps --format json$`,
        stdout: '{"Service":"proxy","Publishers":[{"PublishedPort":3190}]}\n',
      },
    ],
  });
  const dir = makeTempDir("thezoo-browser-mcp");
  const log = path.join(dir, "args");
  const binary = path.join(dir, "playwright-mcp");
  writeFileSync(binary, '#!/bin/sh\nprintf "%s\\n" "$@" > "$MOCK_MCP_LOG"\n');
  chmodSync(binary, 0o755);

  try {
    execFileSync(process.execPath, ["--import", "tsx", "scripts/browse-mcp.ts"], {
      cwd: ROOT_DIR,
      env: cliEnv({
        ...docker.env,
        PATH: `${dir}${path.delimiter}${docker.env.PATH}`,
        ZOO_BROWSER_INSTANCE: "sandbox",
        MOCK_MCP_LOG: log,
      }),
    });
    expect(readFileSync(log, "utf8").trim().split("\n")).toEqual([
      "--ignore-https-errors",
      "--browser",
      "firefox",
      "--isolated",
      "--proxy-server",
      "http://localhost:3190",
    ]);
  } finally {
    docker.cleanup();
    rmSync(dir, { recursive: true, force: true });
  }
});
