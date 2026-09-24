import { execFileSync, spawn } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { selectBrowserProxy, type BrowserInstance } from "./lib/browser-proxy";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const status = execFileSync(
  process.execPath,
  ["--import", "tsx", path.join(root, "cli/bin/thezoo.ts"), "status", "--json"],
  { cwd: root, encoding: "utf8", env: { ...process.env, ZOO_DEV: "1" } },
);
const { instances } = JSON.parse(status) as { instances: BrowserInstance[] };
const proxy = selectBrowserProxy(instances, process.env.ZOO_BROWSER_INSTANCE);
const browser = spawn(
  "playwright-mcp",
  ["--ignore-https-errors", "--browser", "firefox", "--isolated", "--proxy-server", proxy],
  { stdio: "inherit" },
);
browser.on("error", (error) => {
  console.error(error);
  process.exitCode = 1;
});
browser.on("exit", (code, signal) => {
  if (signal) {
    process.kill(process.pid, signal);
  } else {
    process.exitCode = code ?? 1;
  }
});
