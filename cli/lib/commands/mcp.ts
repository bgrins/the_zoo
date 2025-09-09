import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { SSEServerTransport } from "@modelcontextprotocol/sdk/server/sse.js";
import { CallToolRequestSchema, ListToolsRequestSchema } from "@modelcontextprotocol/sdk/types.js";
import chalk from "chalk";
import http from "node:http";

// Import all command functions
import { clean } from "./clean.js";
import { create } from "./create.js";
import { shellRedis, shellPostgres, shellStalwart, shellMysql } from "./shell.js";
import { start } from "./start.js";
import { status } from "./status.js";
import { stop } from "./stop.js";
import { emailUsers, emailSend, emailSwaks, emailCheck } from "./email.js";

// Command registry mapping tool names to functions and schemas
// We keep these in sync with the CLI command definitions manually
// to avoid circular dependencies
const COMMANDS = {
  zoo_start: {
    fn: start,
    description: "Start The Zoo environment",
    inputSchema: {
      type: "object",
      properties: {
        proxy_port: { type: "string", description: "proxy port (default: 3128)" },
        instance: {
          type: "string",
          description: "Start a specific instance created with 'thezoo create'",
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
    fn: create,
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
    fn: stop,
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
    fn: status,
    description: "Show status of running Zoo instances",
    inputSchema: {
      type: "object",
      properties: {
        instance: { type: "string", description: "Show status for a specific instance" },
      },
    },
  },
  zoo_clean: {
    fn: clean,
    description: "Clean up Zoo resources",
    inputSchema: {
      type: "object",
      properties: {
        instance: { type: "string", description: "Clean a specific instance" },
        force: { type: "boolean", description: "skip confirmation prompt" },
      },
    },
  },
  zoo_shell_postgres: {
    fn: shellPostgres,
    description: "Run PostgreSQL CLI commands",
    inputSchema: {
      type: "object",
      properties: {
        args: {
          type: "array",
          items: { type: "string" },
          description: "PostgreSQL command arguments",
        },
        instance: {
          type: "string",
          description: "specify instance ID (for multiple running instances)",
        },
      },
    },
  },
  zoo_shell_redis: {
    fn: shellRedis,
    description: "Run Redis CLI commands",
    inputSchema: {
      type: "object",
      properties: {
        args: { type: "array", items: { type: "string" }, description: "Redis command arguments" },
        instance: {
          type: "string",
          description: "specify instance ID (for multiple running instances)",
        },
      },
    },
  },
  zoo_shell_stalwart: {
    fn: shellStalwart,
    description: "Run Stalwart Mail CLI commands",
    inputSchema: {
      type: "object",
      properties: {
        args: {
          type: "array",
          items: { type: "string" },
          description: "Stalwart command arguments",
        },
        instance: {
          type: "string",
          description: "specify instance ID (for multiple running instances)",
        },
      },
    },
  },
  zoo_shell_mysql: {
    fn: shellMysql,
    description: "Run MySQL CLI commands",
    inputSchema: {
      type: "object",
      properties: {
        args: { type: "array", items: { type: "string" }, description: "MySQL command arguments" },
        instance: {
          type: "string",
          description: "specify instance ID (for multiple running instances)",
        },
      },
    },
  },
  zoo_email_users: {
    fn: emailUsers,
    description: "List all email users",
    inputSchema: {
      type: "object",
      properties: {
        instance: {
          type: "string",
          description: "specify instance ID (for multiple running instances)",
        },
        domain: { type: "string", description: "filter by domain" },
      },
    },
  },
  zoo_email_send: {
    fn: emailSend,
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
        instance: {
          type: "string",
          description: "specify instance ID (for multiple running instances)",
        },
      },
      required: ["from", "to", "subject", "body"],
    },
  },
  zoo_email_check: {
    fn: emailCheck,
    description: "Check email inbox using IMAP",
    inputSchema: {
      type: "object",
      properties: {
        user: { type: "string", description: "email account to check" },
        password: { type: "string", description: "account password" },
        folder: { type: "string", description: "mailbox folder to check" },
        limit: { type: "number", description: "number of emails to show" },
        instance: {
          type: "string",
          description: "specify instance ID (for multiple running instances)",
        },
      },
      required: ["user"],
    },
  },
  zoo_email_swaks: {
    fn: emailSwaks,
    description: "Send test emails using swaks (Swiss Army Knife for SMTP)",
    inputSchema: {
      type: "object",
      properties: {
        args: { type: "array", items: { type: "string" }, description: "Swaks command arguments" },
        instance: {
          type: "string",
          description: "specify instance ID (for multiple running instances)",
        },
      },
    },
  },
};

// Initialize MCP server
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

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  const tools = Object.entries(COMMANDS).map(([name, config]) => ({
    name,
    description: config.description,
    inputSchema: config.inputSchema,
  }));

  return { tools };
});

// Handle tool execution
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  const command = COMMANDS[name as keyof typeof COMMANDS];
  if (!command) {
    throw {
      code: -32601,
      message: `Tool "${name}" not found`,
    };
  }

  try {
    // Transform snake_case to camelCase for options
    const options: any = {};
    if (args) {
      for (const [key, value] of Object.entries(args)) {
        const camelKey = key.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase());
        options[camelKey] = value;
      }
    }

    // For shell commands, the first param is args array, second is options
    if (name.startsWith("zoo_shell_") || name === "zoo_email_swaks") {
      await (command.fn as any)(options.args || [], { instance: options.instance });
    } else {
      await (command.fn as any)(options || {});
    }

    return {
      content: [
        {
          type: "text",
          text: `Successfully executed: ${name}`,
        },
      ],
    };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    return {
      content: [
        {
          type: "text",
          text: `Error executing ${name}: ${errorMessage}`,
        },
      ],
    };
  }
});

// Export the main function as the command handler
export async function mcp(options: { port?: string }) {
  if (options.port) {
    // Run HTTP/SSE server
    const port = parseInt(options.port, 10);
    if (Number.isNaN(port) || port < 1 || port > 65535) {
      console.error(chalk.red("Invalid port number. Must be between 1 and 65535."));
      process.exit(1);
    }

    console.log(chalk.blue("🤖 Starting The Zoo MCP Server (HTTP/SSE mode)..."));
    console.log(chalk.gray(`Server will listen on http://localhost:${port}`));
    console.log(chalk.gray("Endpoints:"));
    console.log(chalk.gray(`  GET  /sse      - SSE connection for server events`));
    console.log(chalk.gray(`  POST /messages - Send messages to server`));
    console.log(chalk.gray(`  GET  /health   - Health check`));
    console.log(chalk.gray("\nPress Ctrl+C to stop the server\n"));

    const httpServer = http.createServer(async (req, res) => {
      const url = req.url || "";
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

      if (method === "GET" && url === "/sse") {
        console.log(chalk.gray("Client connected via SSE"));
        const transport = new SSEServerTransport("/messages", res);
        await transport.start();
        await server.connect(transport);

        // Handle client disconnect
        req.on("close", () => {
          console.log(chalk.gray("Client disconnected from SSE"));
        });
      } else if (method === "POST" && url === "/messages") {
        // SSEServerTransport handles this internally
        res.writeHead(404, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ error: "This endpoint is handled by SSE transport" }));
      } else if (method === "GET" && url === "/health") {
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
    });
  } else {
    // Run stdio server (default)
    // In stdio mode, we must not write to stdout as it's used for protocol communication
    // Only write to stderr for logging
    console.error(chalk.blue("🤖 Starting The Zoo MCP Server (stdio mode)..."));
    console.error(chalk.gray("The server will run on stdio for MCP client connections"));
    console.error(chalk.gray("Press Ctrl+C to stop the server\n"));

    try {
      const transport = new StdioServerTransport();
      await server.connect(transport);
      // Server is now running on stdio
    } catch (error) {
      console.error(chalk.red("Failed to start MCP server:"), error);
      process.exit(1);
    }
  }
}
