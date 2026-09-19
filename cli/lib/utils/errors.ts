/**
 * An expected command failure. Commands throw this instead of calling process.exit
 * so they can also run inside the MCP server; the CLI entry point prints it and exits.
 * An empty message exits silently (e.g. passing through a child process's exit code).
 */
export class CliError extends Error {
  constructor(
    message: string,
    readonly options: { hint?: string; exitCode?: number } = {},
  ) {
    super(message);
    this.name = "CliError";
  }

  get exitCode(): number {
    return this.options.exitCode ?? 1;
  }

  get hint(): string | undefined {
    return this.options.hint;
  }
}

export function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
