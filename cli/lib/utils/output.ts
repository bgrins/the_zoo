import { AsyncLocalStorage } from "node:async_hooks";
import { format, stripVTControlCharacters } from "node:util";
import yoctoSpinner from "yocto-spinner";

interface OutputCapture {
  chunks: string[];
}

const captureStorage = new AsyncLocalStorage<OutputCapture>();

/**
 * The active capture while a command runs inside the MCP server. Output then goes
 * into the tool result instead of the terminal, and nothing may prompt or read stdin.
 */
export function getOutputCapture(): OutputCapture | undefined {
  return captureStorage.getStore();
}

/**
 * Run fn, collecting everything it prints via console, spinners and child processes
 */
export async function captureOutput(
  fn: () => Promise<void>,
): Promise<{ output: string; error?: unknown }> {
  const capture: OutputCapture = { chunks: [] };
  let error: unknown;
  await captureStorage.run(capture, async () => {
    try {
      await fn();
    } catch (e) {
      error = e;
    }
  });
  return { output: stripVTControlCharacters(capture.chunks.join("")), error };
}

/**
 * Send console output to the active capture when there is one. Outside a capture,
 * write to stderr when stdout is reserved (MCP stdio), else keep the normal behavior.
 */
export function routeConsoleOutput({ stdoutReserved }: { stdoutReserved: boolean }): void {
  for (const method of ["log", "info", "warn", "error", "debug"] as const) {
    const original = console[method].bind(console);
    console[method] = (...args: unknown[]) => {
      const capture = captureStorage.getStore();
      if (capture) {
        capture.chunks.push(`${format(...args)}\n`);
      } else if (stdoutReserved) {
        process.stderr.write(`${format(...args)}\n`);
      } else {
        original(...args);
      }
    };
  }
}

export function startSpinner(text: string): ReturnType<typeof yoctoSpinner> {
  const capture = getOutputCapture();
  const stream = capture && {
    isTTY: false,
    write: (chunk: string) => {
      capture.chunks.push(chunk);
      return true;
    },
  };
  return yoctoSpinner({ text, stream: stream as NodeJS.WriteStream | undefined }).start();
}
