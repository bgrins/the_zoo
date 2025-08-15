import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import path from "node:path";
import { describe, expect, test, afterEach } from "vitest";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const cliPath = path.join(__dirname, "..", "..", "cli", "bin", "thezoo.ts");

interface MCPMessage {
  jsonrpc: string;
  id?: number;
  method?: string;
  params?: any;
  result?: any;
  error?: any;
}

/**
 * Helper to run MCP server in stdio mode and send/receive messages
 */
function runMCPStdio(): {
  send: (message: MCPMessage) => void;
  receive: () => Promise<MCPMessage>;
  close: () => void;
} {
  const proc = spawn("npx", ["tsx", cliPath, "mcp"], {
    env: { ...process.env },
    stdio: ["pipe", "pipe", "ignore"], // ignore stderr for cleaner tests
  });

  const messages: MCPMessage[] = [];
  const messageResolvers: Array<(msg: MCPMessage) => void> = [];
  let buffer = "";

  proc.stdout.on("data", (data) => {
    buffer += data.toString();
    const lines = buffer.split("\n");
    buffer = lines.pop() || "";

    for (const line of lines) {
      if (line.trim()) {
        try {
          const msg = JSON.parse(line);
          if (messageResolvers.length > 0) {
            const resolver = messageResolvers.shift();
            resolver?.(msg);
          } else {
            messages.push(msg);
          }
        } catch {
          // Not JSON, ignore
        }
      }
    }
  });

  return {
    send: (message: MCPMessage) => {
      proc.stdin.write(`${JSON.stringify(message)}\n`);
    },
    receive: () => {
      return new Promise((resolve) => {
        if (messages.length > 0) {
          const msg = messages.shift();
          if (msg) resolve(msg);
        } else {
          messageResolvers.push(resolve);
        }
      });
    },
    close: () => {
      proc.kill();
    },
  };
}

/**
 * Helper to start MCP server in HTTP mode
 */
async function startMCPHTTP(port: number): Promise<{ close: () => Promise<void> }> {
  const proc = spawn("npx", ["tsx", cliPath, "mcp", "--port", port.toString()], {
    env: { ...process.env },
    stdio: ["ignore", "ignore", "ignore"],
  });

  // Wait for server to start
  await new Promise((resolve) => setTimeout(resolve, 1000));

  // Verify server is running
  const maxAttempts = 10;
  for (let i = 0; i < maxAttempts; i++) {
    try {
      const response = await fetch(`http://localhost:${port}/health`);
      if (response.ok) {
        break;
      }
    } catch {
      if (i === maxAttempts - 1) {
        proc.kill();
        throw new Error("Failed to start HTTP server");
      }
      await new Promise((resolve) => setTimeout(resolve, 500));
    }
  }

  return {
    close: async () => {
      proc.kill();
      await new Promise((resolve) => setTimeout(resolve, 100));
    },
  };
}

describe("MCP Server - stdio mode", () => {
  let mcp: ReturnType<typeof runMCPStdio> | null = null;

  afterEach(() => {
    if (mcp) {
      mcp.close();
      mcp = null;
    }
  });

  test("should initialize successfully", async () => {
    mcp = runMCPStdio();

    mcp.send({
      jsonrpc: "2.0",
      id: 1,
      method: "initialize",
      params: {
        protocolVersion: "2024-11-05",
        capabilities: { tools: {} },
        clientInfo: { name: "test", version: "1.0.0" },
      },
    });

    const response = await mcp.receive();
    expect(response.jsonrpc).toBe("2.0");
    expect(response.id).toBe(1);
    expect(response.result).toBeDefined();
    expect(response.result.protocolVersion).toBe("2024-11-05");
    expect(response.result.serverInfo).toEqual({
      name: "the-zoo-cli",
      version: "1.0.0",
    });
    expect(response.result.capabilities).toEqual({ tools: {} });
  });

  test("should list available tools", async () => {
    mcp = runMCPStdio();

    // Initialize first
    mcp.send({
      jsonrpc: "2.0",
      id: 1,
      method: "initialize",
      params: {
        protocolVersion: "2024-11-05",
        capabilities: { tools: {} },
        clientInfo: { name: "test", version: "1.0.0" },
      },
    });
    await mcp.receive(); // consume initialize response

    // List tools
    mcp.send({
      jsonrpc: "2.0",
      id: 2,
      method: "tools/list",
      params: {},
    });

    const response = await mcp.receive();
    expect(response.jsonrpc).toBe("2.0");
    expect(response.id).toBe(2);
    expect(response.result).toBeDefined();
    expect(response.result.tools).toBeDefined();
    expect(Array.isArray(response.result.tools)).toBe(true);
    expect(response.result.tools.length).toBeGreaterThan(0);

    // Check some expected tools exist
    const toolNames = response.result.tools.map((t: any) => t.name);
    expect(toolNames).toContain("zoo_start");
    expect(toolNames).toContain("zoo_stop");
    expect(toolNames).toContain("zoo_status");
    expect(toolNames).toContain("zoo_shell_postgres");
    expect(toolNames).toContain("zoo_email_users");
  });

  test("should have proper tool schemas", async () => {
    mcp = runMCPStdio();

    // Initialize
    mcp.send({
      jsonrpc: "2.0",
      id: 1,
      method: "initialize",
      params: {
        protocolVersion: "2024-11-05",
        capabilities: { tools: {} },
        clientInfo: { name: "test", version: "1.0.0" },
      },
    });
    await mcp.receive();

    // List tools
    mcp.send({
      jsonrpc: "2.0",
      id: 2,
      method: "tools/list",
      params: {},
    });

    const response = await mcp.receive();
    const tools = response.result.tools;

    // Find zoo_start tool
    const startTool = tools.find((t: any) => t.name === "zoo_start");
    expect(startTool).toBeDefined();
    expect(startTool.description).toBe("Start The Zoo environment");
    expect(startTool.inputSchema).toBeDefined();
    expect(startTool.inputSchema.type).toBe("object");
    expect(startTool.inputSchema.properties).toBeDefined();
    expect(startTool.inputSchema.properties.proxy_port).toBeDefined();
    expect(startTool.inputSchema.properties.instance).toBeDefined();

    // Find zoo_email_send tool
    const emailTool = tools.find((t: any) => t.name === "zoo_email_send");
    expect(emailTool).toBeDefined();
    expect(emailTool.inputSchema.required).toEqual(["from", "to", "subject", "body"]);
  });

  test("should handle tool execution requests", async () => {
    mcp = runMCPStdio();

    // Initialize
    mcp.send({
      jsonrpc: "2.0",
      id: 1,
      method: "initialize",
      params: {
        protocolVersion: "2024-11-05",
        capabilities: { tools: {} },
        clientInfo: { name: "test", version: "1.0.0" },
      },
    });
    await mcp.receive();

    // Call a tool that will fail gracefully (status with no running instances)
    mcp.send({
      jsonrpc: "2.0",
      id: 3,
      method: "tools/call",
      params: {
        name: "zoo_status",
        arguments: {},
      },
    });

    const response = await mcp.receive();
    expect(response.jsonrpc).toBe("2.0");
    expect(response.id).toBe(3);
    expect(response.result).toBeDefined();
    expect(response.result.content).toBeDefined();
    expect(Array.isArray(response.result.content)).toBe(true);
    expect(response.result.content[0].type).toBe("text");
  });

  test("should handle invalid tool requests", async () => {
    mcp = runMCPStdio();

    // Initialize
    mcp.send({
      jsonrpc: "2.0",
      id: 1,
      method: "initialize",
      params: {
        protocolVersion: "2024-11-05",
        capabilities: { tools: {} },
        clientInfo: { name: "test", version: "1.0.0" },
      },
    });
    await mcp.receive();

    // Call non-existent tool
    mcp.send({
      jsonrpc: "2.0",
      id: 4,
      method: "tools/call",
      params: {
        name: "zoo_nonexistent",
        arguments: {},
      },
    });

    const response = await mcp.receive();
    expect(response.jsonrpc).toBe("2.0");
    expect(response.id).toBe(4);
    expect(response.error).toBeDefined();
    expect(response.error.message).toContain('Tool "zoo_nonexistent" not found');
  });
});

describe("MCP Server - HTTP/SSE mode", () => {
  const port = 33333;
  let server: { close: () => Promise<void> } | null = null;

  afterEach(async () => {
    if (server) {
      await server.close();
      server = null;
    }
  });

  test("should start HTTP server and respond to health check", async () => {
    server = await startMCPHTTP(port);

    const response = await fetch(`http://localhost:${port}/health`);
    expect(response.ok).toBe(true);

    const data = await response.json();
    expect(data.status).toBe("ok");
    expect(data.server).toBe("the-zoo-mcp");
  });

  test("should provide SSE endpoint", async () => {
    server = await startMCPHTTP(port);

    // Check that SSE endpoint exists (won't fully connect without proper client)
    const response = await fetch(`http://localhost:${port}/sse`, {
      method: "GET",
      headers: {
        Accept: "text/event-stream",
      },
      signal: AbortSignal.timeout(1000),
    }).catch(() => {
      // Expected to timeout or error since we're not properly handling SSE
      return { ok: false, status: 0 };
    });

    // The endpoint should exist even if we can't properly connect
    expect(response.status).not.toBe(404);
  });

  test("should handle multiple ports", async () => {
    const port1 = 33334;
    const port2 = 33335;

    const server1 = await startMCPHTTP(port1);
    const server2 = await startMCPHTTP(port2);

    try {
      const response1 = await fetch(`http://localhost:${port1}/health`);
      const response2 = await fetch(`http://localhost:${port2}/health`);

      expect(response1.ok).toBe(true);
      expect(response2.ok).toBe(true);

      const data1 = await response1.json();
      const data2 = await response2.json();

      expect(data1.server).toBe("the-zoo-mcp");
      expect(data2.server).toBe("the-zoo-mcp");
    } finally {
      await server1.close();
      await server2.close();
    }
  });
});

describe("MCP Server - Help and Options", () => {
  test("should show help for mcp command", async () => {
    const proc = spawn("npx", ["tsx", cliPath, "mcp", "--help"], {
      env: { ...process.env },
    });

    const output = await new Promise<string>((resolve) => {
      let stdout = "";
      proc.stdout.on("data", (data) => {
        stdout += data.toString();
      });
      proc.on("close", () => {
        resolve(stdout);
      });
    });

    expect(output).toContain("Start Model Context Protocol (MCP) server");
    expect(output).toContain("--port");
    expect(output).toContain("run server on HTTP/SSE mode");
    expect(output).toContain("default: stdio");
  });
});
