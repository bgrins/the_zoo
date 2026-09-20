import { spawn } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, rmSync } from "node:fs";
import http from "node:http";
import net from "node:net";
import os from "node:os";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import cliPackageJson from "../../cli/package.json" with { type: "json" };
import {
  CLI_PATH,
  cliEnv,
  createFakeDocker,
  type FakeDocker,
  type FakeDockerRule,
  makeTempDir,
  ROOT_DIR,
  runCLI,
  TSX_PATH,
} from "./helpers";

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
    env: cliEnv(env),
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
    expect(response.result.serverInfo).toEqual({
      name: "the-zoo-cli",
      version: cliPackageJson.version,
    });
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
  const response = await fetch(`http://127.0.0.1:${port}/sse`, {
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
    endpoint: endpoint.data,
    post: (message: MCPMessage) =>
      fetch(`http://127.0.0.1:${port}${endpoint.data}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(message),
      }),
    nextMessage: async (): Promise<MCPMessage> => JSON.parse((await nextEvent()).data),
    close: () => controller.abort(),
  };
}

/**
 * An HTTP request with headers fetch won't let a caller set, such as Host
 */
function rawRequest(
  port: number,
  options: { method: string; path: string; headers: Record<string, string>; body?: string },
): Promise<{ status: number; headers: http.IncomingHttpHeaders }> {
  return new Promise((resolve, reject) => {
    const req = http.request(
      {
        host: "127.0.0.1",
        port,
        method: options.method,
        path: options.path,
        headers: options.headers,
      },
      (res) => {
        res.resume();
        res.on("end", () => resolve({ status: res.statusCode ?? 0, headers: res.headers }));
      },
    );
    req.on("error", reject);
    req.end(options.body);
  });
}

async function freePort(): Promise<number> {
  const server = net.createServer();
  await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
  const { port } = server.address() as net.AddressInfo;
  await new Promise((resolve) => server.close(resolve));
  return port;
}

/**
 * Run `body` against an MCP server in HTTP/SSE mode on a free port, then stop the server
 */
async function withMCPHTTP(body: (port: number) => Promise<void>): Promise<void> {
  const port = await freePort();
  const proc = spawn(TSX_PATH, [CLI_PATH, "mcp", "--port", String(port)], {
    cwd: ROOT_DIR,
    env: cliEnv(),
    stdio: ["ignore", "pipe", "pipe"],
  });
  let output = "";
  proc.stdout.on("data", (data) => {
    output += data.toString();
  });
  proc.stderr.on("data", (data) => {
    output += data.toString();
  });
  const exited = new Promise((resolve) => proc.once("exit", resolve));

  try {
    for (let attempt = 0; ; attempt++) {
      if (proc.exitCode !== null || proc.signalCode !== null) {
        throw new Error(`MCP HTTP server exited (${proc.exitCode ?? proc.signalCode}):\n${output}`);
      }
      const healthy = await fetch(`http://127.0.0.1:${port}/health`).then(
        (response) => response.ok,
        () => false,
      );
      if (healthy) {
        break;
      }
      if (attempt >= 60) {
        throw new Error(`MCP HTTP server did not start on port ${port}:\n${output}`);
      }
      await new Promise((resolve) => setTimeout(resolve, 250));
    }
    await body(port);
  } finally {
    proc.kill();
    await exited;
  }
}

/**
 * An IPv4 address of this machine other hosts could reach it on, if it has one
 */
function externalIPv4(): string | undefined {
  return Object.values(os.networkInterfaces())
    .flat()
    .find((address) => address?.family === "IPv4" && !address.internal)?.address;
}

describe("MCP Server - HTTP/SSE mode", () => {
  test("should respond to health check", () =>
    withMCPHTTP(async (port) => {
      const response = await fetch(`http://127.0.0.1:${port}/health`);
      expect(response.ok).toBe(true);
      expect(await response.json()).toEqual({ status: "ok", server: "the-zoo-mcp" });
    }));

  test("should route messages to each SSE session", () =>
    withMCPHTTP(async (port) => {
      const first = await connectSSE(port);
      const second = await connectSSE(port);
      try {
        for (const client of [first, second]) {
          const accepted = await client.post(INITIALIZE);
          expect(accepted.status).toBe(202);

          const response = await client.nextMessage();
          expect(response.id).toBe(1);
          expect(response.result.serverInfo).toEqual({
            name: "the-zoo-cli",
            version: cliPackageJson.version,
          });
        }

        const listed = await first.post({
          jsonrpc: "2.0",
          id: 2,
          method: "tools/list",
          params: {},
        });
        expect(listed.status).toBe(202);
        const tools = await first.nextMessage();
        expect(tools.id).toBe(2);
        expect(tools.result.tools.length).toBeGreaterThan(0);
      } finally {
        first.close();
        second.close();
      }
    }));

  test("should reject messages for unknown sessions", () =>
    withMCPHTTP(async (port) => {
      const response = await fetch(`http://127.0.0.1:${port}/messages?sessionId=nope`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(INITIALIZE),
      });
      expect(response.status).toBe(404);
    }));

  test("should send no CORS headers, so other sites' pages can't call it", () =>
    withMCPHTTP(async (port) => {
      const origin = "https://attacker.example";
      const preflight = await rawRequest(port, {
        method: "OPTIONS",
        path: "/messages?sessionId=x",
        headers: {
          Origin: origin,
          "Access-Control-Request-Method": "POST",
          "Access-Control-Request-Headers": "content-type",
        },
      });
      const health = await rawRequest(port, {
        method: "GET",
        path: "/health",
        headers: { Origin: origin },
      });

      for (const response of [preflight, health]) {
        expect(response.headers["access-control-allow-origin"]).toBeUndefined();
        expect(response.headers["access-control-allow-methods"]).toBeUndefined();
      }
    }));

  test("should refuse messages addressed to another host name (DNS rebinding)", () =>
    withMCPHTTP(async (port) => {
      const client = await connectSSE(port);
      try {
        const rebound = await rawRequest(port, {
          method: "POST",
          path: client.endpoint,
          headers: { Host: `attacker.example:${port}`, "Content-Type": "application/json" },
          body: JSON.stringify({ ...INITIALIZE, id: 7 }),
        });
        expect(rebound.status).toBe(403);

        // Only the local client's message gets an answer
        expect((await client.post(INITIALIZE)).status).toBe(202);
        expect((await client.nextMessage()).id).toBe(1);
      } finally {
        client.close();
      }
    }));

  test.skipIf(!externalIPv4())("should not accept connections from other hosts", () =>
    withMCPHTTP(async (port) => {
      const error = await new Promise<NodeJS.ErrnoException | null>((resolve) => {
        const socket = net.connect({ host: externalIPv4(), port, timeout: 5000 });
        socket.once("connect", () => {
          socket.destroy();
          resolve(null);
        });
        socket.once("timeout", () => {
          socket.destroy();
          resolve(Object.assign(new Error("connect timed out"), { code: "ETIMEDOUT" }));
        });
        socket.once("error", resolve);
      });
      expect(error?.code).toBe("ECONNREFUSED");
    }),
  );
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
