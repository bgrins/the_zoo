import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { SSEServerTransport } from "@modelcontextprotocol/sdk/server/sse.js";
import {
  CallToolRequestSchema,
  ErrorCode,
  ListToolsRequestSchema,
  McpError,
} from "@modelcontextprotocol/sdk/types.js";
import chalk from "chalk";
import http from "node:http";
import { CliError, errorMessage } from "../utils/errors.js";
import { captureOutput, routeConsoleOutput } from "../utils/output.js";

// Import all command functions
import { clean } from "./clean.js";
import { create } from "./create.js";
import { shellRedis, shellPostgres, shellStalwart, shellMysql } from "./shell.js";
import { start } from "./start.js";
import { status } from "./status.js";
import { stop } from "./stop.js";
import { emailUsers, emailSend, emailSwaks, emailCheck } from "./email.js";

type ToolArgs = Record<string, any>;

const instanceProperty = {
  type: "string",
  description: "specify instance ID (for multiple running instances)",
};

// Command registry mapping tool names to functions and schemas
// We keep these in sync with the CLI command definitions manually
// to avoid circular dependencies
const COMMANDS: Record<
  string,
  { run: (args: ToolArgs) => Promise<void>; description: string; inputSchema: object }
> = {
  zoo_start: {
    run: (a) =>
      start({ port: a.proxy_port, instance: a.instance, setEnv: a.set_env, dryRun: a.dry_run }),
    description: "Start The Zoo environment",
    inputSchema: {
      type: "object",
      properties: {
        proxy_port: {
          type: "string",
          description: "proxy port (default: the instance's saved port, else 3128)",
        },
        instance: {
          type: "string",
          description: "Start a specific instance created with 'the_zoo create'",
        },
        set_env: {
          type: "array",
          items: { type: "string" },
          description: "set environment variable (format: KEY=value)",
        },
        dry_run: {
          type: "boolean",
          description: "show what would be executed without actually running",
        },
      },
    },
  },
  zoo_create: {
    run: (a) => create({ dryRun: a.dry_run, ipBase: a.ip_base }),
    description: "Prepare a new Zoo instance without starting it",
    inputSchema: {
      type: "object",
      properties: {
        dry_run: {
          type: "boolean",
          description: "show what would be executed without actually running",
        },
        ip_base: {
          type: "string",
          description: "specify base IP for services (e.g., 172.30.100.1)",
        },
      },
    },
  },
  zoo_stop: {
    run: (a) => stop({ all: a.all, instance: a.instance }),
    description: "Stop The Zoo environment",
    inputSchema: {
      type: "object",
      properties: {
        all: { type: "boolean", description: "Stop all running Zoo CLI instances" },
        instance: { type: "string", description: "Stop a specific instance" },
      },
    },
  },
  zoo_status: {
    run: (a) => status({ instance: a.instance }),
    description: "Show status of running Zoo instances",
    inputSchema: {
      type: "object",
      properties: {
        instance: { type: "string", description: "Show status for a specific instance" },
      },
    },
  },
  zoo_clean: {
    run: (a) => clean({ instance: a.instance, force: a.force }),
    description: "Clean up Zoo resources (requires force: true, since it cannot prompt)",
    inputSchema: {
      type: "object",
      properties: {
        instance: { type: "string", description: "Clean a specific instance" },
        force: { type: "boolean", description: "confirm the removal" },
      },
    },
  },
  zoo_shell_postgres: {
    run: (a) => shellPostgres(a.args ?? [], { instance: a.instance }),
    description: "Run PostgreSQL CLI commands",
    inputSchema: {
      type: "object",
      properties: {
        args: {
          type: "array",
          items: { type: "string" },
          description: "PostgreSQL command arguments",
        },
        instance: instanceProperty,
      },
    },
  },
  zoo_shell_redis: {
    run: (a) => shellRedis(a.args ?? [], { instance: a.instance }),
    description: "Run Redis CLI commands",
    inputSchema: {
      type: "object",
      properties: {
        args: { type: "array", items: { type: "string" }, description: "Redis command arguments" },
        instance: instanceProperty,
      },
    },
  },
  zoo_shell_stalwart: {
    run: (a) => shellStalwart(a.args ?? [], { instance: a.instance }),
    description: "Run Stalwart Mail CLI commands",
    inputSchema: {
      type: "object",
      properties: {
        args: {
          type: "array",
          items: { type: "string" },
          description: "Stalwart command arguments",
        },
        instance: instanceProperty,
      },
    },
  },
  zoo_shell_mysql: {
    run: (a) => shellMysql(a.args ?? [], { instance: a.instance }),
    description: "Run MySQL CLI commands",
    inputSchema: {
      type: "object",
      properties: {
        args: { type: "array", items: { type: "string" }, description: "MySQL command arguments" },
        instance: instanceProperty,
      },
    },
  },
  zoo_email_users: {
    run: (a) => emailUsers({ instance: a.instance, domain: a.domain }),
    description: "List all email users",
    inputSchema: {
      type: "object",
      properties: {
        instance: instanceProperty,
        domain: { type: "string", description: "filter by domain" },
      },
    },
  },
  zoo_email_send: {
    run: (a) =>
      emailSend({
        instance: a.instance,
        from: a.from,
        to: a.to,
        subject: a.subject,
        body: a.body,
        html: a.html,
        password: a.password,
      }),
    description: "Send an email",
    inputSchema: {
      type: "object",
      properties: {
        from: { type: "string", description: "sender email address" },
        to: { type: "string", description: "recipient email address" },
        subject: { type: "string", description: "email subject" },
        body: { type: "string", description: "email body" },
        html: { type: "boolean", description: "send as HTML email" },
        password: { type: "string", description: "sender password" },
        instance: instanceProperty,
      },
      required: ["from", "to", "subject", "body"],
    },
  },
  zoo_email_check: {
    run: (a) =>
      emailCheck({
        instance: a.instance,
        user: a.user,
        password: a.password,
        folder: a.folder,
        limit: a.limit,
      }),
    description: "Check email inbox using IMAP",
    inputSchema: {
      type: "object",
      properties: {
        user: { type: "string", description: "email account to check" },
        password: { type: "string", description: "account password" },
        folder: { type: "string", description: "mailbox folder to check" },
        limit: { type: "number", description: "number of emails to show" },
        instance: instanceProperty,
      },
      required: ["user"],
    },
  },
  zoo_email_swaks: {
    run: (a) => emailSwaks(a.args ?? [], { instance: a.instance }),
    description: "Send test emails using swaks (Swiss Army Knife for SMTP)",
    inputSchema: {
      type: "object",
      properties: {
        args: { type: "array", items: { type: "string" }, description: "Swaks command arguments" },
        instance: instanceProperty,
      },
    },
  },
};

/**
 * A server bound to one transport. SSE mode creates one per client connection.
 */
function createServer(): Server {
  const server = new Server(
    {
      name: "the-zoo-cli",
      version: "1.0.0",
    },
    {
      capabilities: {
        tools: {},
      },
    },
  );

  server.setRequestHandler(ListToolsRequestSchema, async () => {
    const tools = Object.entries(COMMANDS).map(([name, config]) => ({
      name,
      description: config.description,
      inputSchema: config.inputSchema,
    }));

    return { tools };
  });

  server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args } = request.params;

    const command = COMMANDS[name];
    if (!command) {
      throw new McpError(ErrorCode.MethodNotFound, `Tool "${name}" not found`);
    }

    // Commands print progress and results; return that output as the tool result
    const { output, error } = await captureOutput(() => command.run(args ?? {}));

    const parts = [output.trim()];
    if (error) {
      parts.push(`Error: ${errorMessage(error)}`);
      if (error instanceof CliError && error.hint) {
        parts.push(error.hint);
      }
    }
    const text = parts.filter(Boolean).join("\n\n") || `${name} completed`;

    return {
      content: [{ type: "text", text }],
      ...(error ? { isError: true } : {}),
    };
  });

  return server;
}

// Export the main function as the command handler
export async function mcp(options: { port?: string }) {
  if (options.port) {
    // Run HTTP/SSE server
    const port = parseInt(options.port, 10);
    if (Number.isNaN(port) || port < 1 || port > 65535) {
      throw new CliError("Invalid port number. Must be between 1 and 65535.");
    }

    routeConsoleOutput({ stdoutReserved: false });

    console.log(chalk.blue("🤖 Starting The Zoo MCP Server (HTTP/SSE mode)..."));
    console.log(chalk.gray(`Server will listen on http://localhost:${port}`));
    console.log(chalk.gray("Endpoints:"));
    console.log(chalk.gray(`  GET  /sse      - SSE connection for server events`));
    console.log(chalk.gray(`  POST /messages - Send messages to server`));
    console.log(chalk.gray(`  GET  /health   - Health check`));
    console.log(chalk.gray("\nPress Ctrl+C to stop the server\n"));

    // One transport and server per SSE connection, keyed by the session ID
    // the client sends back on each POST /messages?sessionId=...
    const transports = new Map<string, SSEServerTransport>();

    const httpServer = http.createServer(async (req, res) => {
      const url = new URL(req.url || "/", "http://localhost");
      const method = req.method || "";

      // CORS headers for browser-based clients
      res.setHeader("Access-Control-Allow-Origin", "*");
      res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
      res.setHeader("Access-Control-Allow-Headers", "Content-Type");

      if (method === "OPTIONS") {
        res.writeHead(204);
        res.end();
        return;
      }

      if (method === "GET" && url.pathname === "/sse") {
        const transport = new SSEServerTransport("/messages", res);
        const server = createServer();
        transports.set(transport.sessionId, transport);
        console.log(chalk.gray(`Client connected via SSE (session ${transport.sessionId})`));

        res.on("close", () => {
          transports.delete(transport.sessionId);
          server.close().catch(() => {});
          console.log(chalk.gray(`Client disconnected from SSE (session ${transport.sessionId})`));
        });

        // connect() starts the transport, which sends the endpoint event
        await server.connect(transport);
      } else if (method === "POST" && url.pathname === "/messages") {
        const sessionId = url.searchParams.get("sessionId");
        const transport = sessionId ? transports.get(sessionId) : undefined;
        if (!transport) {
          res.writeHead(sessionId ? 404 : 400, { "Content-Type": "application/json" });
          res.end(JSON.stringify({ error: sessionId ? "Unknown sessionId" : "Missing sessionId" }));
          return;
        }
        await transport.handlePostMessage(req, res);
      } else if (method === "GET" && url.pathname === "/health") {
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ status: "ok", server: "the-zoo-mcp" }));
      } else {
        res.writeHead(404, { "Content-Type": "text/plain" });
        res.end("Not Found");
      }
    });

    httpServer.listen(port, () => {
      console.log(chalk.green(`✓ MCP Server listening on port ${port}`));
    });

    // Graceful shutdown
    process.on("SIGINT", () => {
      console.log(chalk.yellow("\n\nShutting down MCP server..."));
      httpServer.close(() => {
        console.log(chalk.green("Server closed"));
        process.exit(0);
      });
      // Open SSE streams would otherwise keep close() waiting forever
      httpServer.closeAllConnections();
    });
  } else {
    // Run stdio server (default)
    // stdout carries the protocol, so all other output goes to stderr or tool results
    routeConsoleOutput({ stdoutReserved: true });

    console.error(chalk.blue("🤖 Starting The Zoo MCP Server (stdio mode)..."));
    console.error(chalk.gray("The server will run on stdio for MCP client connections"));
    console.error(chalk.gray("Press Ctrl+C to stop the server\n"));

    await createServer().connect(new StdioServerTransport());
  }
}
