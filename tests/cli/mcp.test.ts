import { type ChildProcess, spawn } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, rmSync } from "node:fs";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import {
  CLI_PATH,
  createFakeDocker,
  type FakeDocker,
  type FakeDockerRule,
  makeTempDir,
  ROOT_DIR,
  runCLI,
} from "./helpers";

const TSX_PATH = path.join(ROOT_DIR, "node_modules", ".bin", "tsx");

interface MCPMessage {
  jsonrpc: string;
  id?: number;
  method?: string;
  params?: any;
  result?: any;
  error?: any;
}

const INITIALIZE: MCPMessage = {
  jsonrpc: "2.0",
  id: 1,
  method: "initialize",
  params: {
    protocolVersion: "2024-11-05",
    capabilities: { tools: {} },
    clientInfo: { name: "test", version: "1.0.0" },
  },
};

/**
 * Run the MCP server in stdio mode. Every stdout line must be a JSON-RPC message;
 * anything else is protocol corruption and fails the pending receive().
 */
function runMCPStdio(env: Record<string, string>) {
  const proc = spawn(TSX_PATH, [CLI_PATH, "mcp"], {
    cwd: ROOT_DIR,
    env: { ...process.env, ZOO_DEV: "1", ...env },
    stdio: ["pipe", "pipe", "pipe"],
  });

  const messages: MCPMessage[] = [];
  const nonProtocolLines: string[] = [];
  let waiting: { resolve: (msg: MCPMessage) => void; reject: (err: Error) => void } | null = null;
  let buffer = "";
  let stderr = "";

  proc.stderr.on("data", (data) => {
    stderr += data.toString();
  });

  proc.stdout.on("data", (data) => {
    buffer += data.toString();
    const lines = buffer.split("\n");
    buffer = lines.pop() || "";

    for (const line of lines) {
      let msg: MCPMessage;
      try {
        msg = JSON.parse(line);
      } catch {
        nonProtocolLines.push(line);
        waiting?.reject(new Error(`Non-JSON line on MCP stdout: ${line}`));
        waiting = null;
        continue;
      }
      if (waiting) {
        waiting.resolve(msg);
        waiting = null;
      } else {
        messages.push(msg);
      }
    }
  });

  proc.on("exit", (code) => {
    waiting?.reject(new Error(`MCP server exited with code ${code}. stderr:\n${stderr}`));
    waiting = null;
  });

  return {
    nonProtocolLines,
    send: (message: MCPMessage) => {
      proc.stdin.write(`${JSON.stringify(message)}\n`);
    },
    receive: (): Promise<MCPMessage> => {
      const next = messages.shift();
      if (next) {
        return Promise.resolve(next);
      }
      return new Promise((resolve, reject) => {
        waiting = { resolve, reject };
      });
    },
    close: () => {
      proc.kill();
    },
  };
}

describe("MCP Server - stdio mode", () => {
  let mcp: ReturnType<typeof runMCPStdio> | null = null;
  let home: string;
  let docker: FakeDocker;

  function startServer(rules: FakeDockerRule[] = [], projects: string[] = []) {
    docker = createFakeDocker({ projects, rules });
    mcp = runMCPStdio({ ...docker.env, THE_ZOO_HOME: home });
    return mcp;
  }

  async function initialize(server: ReturnType<typeof runMCPStdio>) {
    server.send(INITIALIZE);
    return server.receive();
  }

  async function callTool(
    server: ReturnType<typeof runMCPStdio>,
    id: number,
    name: string,
    args: Record<string, unknown> = {},
  ) {
    server.send({ jsonrpc: "2.0", id, method: "tools/call", params: { name, arguments: args } });
    const response = await server.receive();
    expect(response.id).toBe(id);
    return response.result;
  }

  beforeEach(() => {
    home = makeTempDir("thezoo-mcp-home");
  });

  afterEach(() => {
    const garbage = mcp?.nonProtocolLines ?? [];
    mcp?.close();
    mcp = null;
    docker?.cleanup();
    rmSync(home, { recursive: true, force: true });
    expect(garbage).toEqual([]);
  });

  test("should initialize successfully", async () => {
    const response = await initialize(startServer());

    expect(response.jsonrpc).toBe("2.0");
    expect(response.id).toBe(1);
    expect(response.result.protocolVersion).toBe("2024-11-05");
    expect(response.result.serverInfo).toEqual({ name: "the-zoo-cli", version: "1.0.0" });
    expect(response.result.capabilities).toEqual({ tools: {} });
  });

  test("should list tools with their schemas", async () => {
    const server = startServer();
    await initialize(server);

    server.send({ jsonrpc: "2.0", id: 2, method: "tools/list", params: {} });
    const response = await server.receive();
    const tools = response.result.tools;
    const toolNames = tools.map((t: any) => t.name);

    expect(toolNames).toEqual(
      expect.arrayContaining([
        "zoo_start",
        "zoo_stop",
        "zoo_status",
        "zoo_clean",
        "zoo_shell_postgres",
        "zoo_email_users",
        "zoo_email_send",
      ]),
    );
    const startTool = tools.find((t: any) => t.name === "zoo_start");
    expect(startTool.description).toBe("Start The Zoo environment");
    expect(Object.keys(startTool.inputSchema.properties)).toEqual([
      "proxy_port",
      "instance",
      "set_env",
      "dry_run",
    ]);
    const emailTool = tools.find((t: any) => t.name === "zoo_email_send");
    expect(emailTool.inputSchema.required).toEqual(["from", "to", "subject", "body"]);
  });

  test("should return command output as the tool result", async () => {
    const server = startServer();
    await initialize(server);

    const result = await callTool(server, 3, "zoo_status");

    expect(result.isError).toBeUndefined();
    expect(result.content).toHaveLength(1);
    expect(result.content[0].type).toBe("text");
    expect(result.content[0].text).toContain("Zoo Status");
    expect(result.content[0].text).toContain("No Zoo CLI instances are currently running");
  });

  test("should report command failures without exiting", async () => {
    const server = startServer();
    await initialize(server);

    const failed = await callTool(server, 3, "zoo_email_send", {
      from: "a@zoo",
      to: "b@zoo",
      subject: "s",
      body: "b",
    });
    expect(failed.isError).toBe(true);
    expect(failed.content[0].text).toContain("Password is required");

    const status = await callTool(server, 4, "zoo_status");
    expect(status.isError).toBeUndefined();
  });

  test("should refuse to clean without force instead of prompting", async () => {
    const instanceDir = path.join(home, "runtime", "abc");
    mkdirSync(instanceDir, { recursive: true });
    const server = startServer();
    await initialize(server);

    const result = await callTool(server, 3, "zoo_clean", { instance: "abc" });

    expect(result.isError).toBe(true);
    expect(result.content[0].text).toContain("Refusing to remove resources without confirmation");
    expect(existsSync(instanceDir)).toBe(true);
  });

  test("should pass proxy_port and dry_run through to start", async () => {
    const server = startServer();
    await initialize(server);
    const envPath = path.join(home, "runtime", "default", ".env");

    const dryRun = await callTool(server, 3, "zoo_start", { proxy_port: "3555", dry_run: true });

    expect(dryRun.isError).toBeUndefined();
    expect(dryRun.content[0].text).toContain("ZOO_PROXY_PORT=3555");
    expect(existsSync(envPath)).toBe(false);
    expect(docker.calls().some((args) => args.includes("up"))).toBe(false);

    const started = await callTool(server, 4, "zoo_start", { proxy_port: "3555" });

    expect(started.isError).toBeUndefined();
    expect(started.content[0].text).toContain("The Zoo is running!");
    expect(readFileSync(envPath, "utf-8")).toMatch(/^ZOO_PROXY_PORT=3555$/m);
    expect(docker.calls()).toContainEqual(expect.arrayContaining(["--env-file", envPath, "up"]));
  });

  test("should capture shell command output instead of inheriting stdout", async () => {
    const project = "thezoo-cli-instance-abc-v0-9-0";
    const server = startServer(
      [{ match: `-p ${project} exec -T redis redis-cli ping$`, stdout: "PONG\n" }],
      [project],
    );
    await initialize(server);

    const result = await callTool(server, 3, "zoo_shell_redis", { args: ["ping"] });

    expect(result.isError).toBeUndefined();
    expect(result.content[0].text).toContain("PONG");
  });

  test("should handle invalid tool requests", async () => {
    const server = startServer();
    await initialize(server);

    server.send({
      jsonrpc: "2.0",
      id: 4,
      method: "tools/call",
      params: { name: "zoo_nonexistent", arguments: {} },
    });

    const response = await server.receive();
    expect(response.id).toBe(4);
    expect(response.error.message).toContain('Tool "zoo_nonexistent" not found');
  });
});

/**
 * Minimal SSE client: resolves the endpoint event, then yields JSON-RPC messages
 */
async function connectSSE(port: number) {
  const controller = new AbortController();
  const response = await fetch(`http://localhost:${port}/sse`, {
    headers: { Accept: "text/event-stream" },
    signal: controller.signal,
  });
  expect(response.status).toBe(200);
  expect(response.headers.get("content-type")).toBe("text/event-stream");

  if (!response.body) {
    throw new Error("SSE response has no body");
  }
  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let buffer = "";

  async function nextEvent(): Promise<{ event: string; data: string }> {
    while (!buffer.includes("\n\n")) {
      const { value, done } = await reader.read();
      if (done) {
        throw new Error("SSE stream ended");
      }
      buffer += decoder.decode(value, { stream: true });
    }
    const end = buffer.indexOf("\n\n");
    const raw = buffer.slice(0, end);
    buffer = buffer.slice(end + 2);
    const event = raw.match(/^event: (.*)$/m)?.[1] ?? "message";
    const data = raw.match(/^data: (.*)$/m)?.[1] ?? "";
    return { event, data };
  }

  const endpoint = await nextEvent();
  expect(endpoint.event).toBe("endpoint");
  expect(endpoint.data).toMatch(/^\/messages\?sessionId=[\w-]+$/);

  return {
    post: (message: MCPMessage) =>
      fetch(`http://localhost:${port}${endpoint.data}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(message),
      }),
    nextMessage: async (): Promise<MCPMessage> => JSON.parse((await nextEvent()).data),
    close: () => controller.abort(),
  };
}

async function startMCPHTTP(port: number): Promise<{ close: () => Promise<void> }> {
  const proc: ChildProcess = spawn(TSX_PATH, [CLI_PATH, "mcp", "--port", port.toString()], {
    cwd: ROOT_DIR,
    env: { ...process.env, ZOO_DEV: "1" },
    stdio: ["ignore", "ignore", "ignore"],
  });

  for (let attempt = 0; ; attempt++) {
    try {
      const response = await fetch(`http://localhost:${port}/health`);
      if (response.ok) {
        break;
      }
    } catch {
      if (attempt >= 40) {
        proc.kill();
        throw new Error(`MCP HTTP server did not start on port ${port}`);
      }
    }
    await new Promise((resolve) => setTimeout(resolve, 250));
  }

  return {
    close: async () => {
      proc.kill();
      await new Promise((resolve) => proc.once("exit", resolve));
    },
  };
}

describe("MCP Server - HTTP/SSE mode", () => {
  const port = 33333;
  let server: { close: () => Promise<void> } | null = null;

  afterEach(async () => {
    await server?.close();
    server = null;
  });

  test("should respond to health check", async () => {
    server = await startMCPHTTP(port);

    const response = await fetch(`http://localhost:${port}/health`);
    expect(response.ok).toBe(true);
    expect(await response.json()).toEqual({ status: "ok", server: "the-zoo-mcp" });
  });

  test("should route messages to each SSE session", async () => {
    server = await startMCPHTTP(port);

    const first = await connectSSE(port);
    const second = await connectSSE(port);
    try {
      for (const client of [first, second]) {
        const accepted = await client.post(INITIALIZE);
        expect(accepted.status).toBe(202);

        const response = await client.nextMessage();
        expect(response.id).toBe(1);
        expect(response.result.serverInfo.name).toBe("the-zoo-cli");
      }

      const listed = await first.post({ jsonrpc: "2.0", id: 2, method: "tools/list", params: {} });
      expect(listed.status).toBe(202);
      const tools = await first.nextMessage();
      expect(tools.id).toBe(2);
      expect(tools.result.tools.length).toBeGreaterThan(0);
    } finally {
      first.close();
      second.close();
    }
  });

  test("should reject messages for unknown sessions", async () => {
    server = await startMCPHTTP(port);

    const response = await fetch(`http://localhost:${port}/messages?sessionId=nope`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(INITIALIZE),
    });
    expect(response.status).toBe(404);
  });
});

describe("MCP Server - Help and Options", () => {
  test("should show help for mcp command", async () => {
    const { stdout } = await runCLI(["mcp", "--help"]);

    expect(stdout).toContain("Start Model Context Protocol (MCP) server");
    expect(stdout).toContain("--port");
    expect(stdout).toContain("run server on HTTP/SSE mode");
    expect(stdout).toContain("default: stdio");
  });
});
