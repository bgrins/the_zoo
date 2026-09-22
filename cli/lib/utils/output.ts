import { constants } from "node:os";
import chalk from "chalk";
import yoctoSpinner from "yocto-spinner";
import { CliError } from "./errors";

export function startSpinner(text: string): ReturnType<typeof yoctoSpinner> {
  return yoctoSpinner({ text }).start();
}

const HELD_SIGNALS = ["SIGINT", "SIGTERM"] as const;

/**
 * Start a spinner holding off SIGINT and SIGTERM, so that a `task` (e.g. "reset") cut short
 * still starts the services it stopped. `check` throws once one came. The spinner's listeners,
 * which exit, are set aside until `release`. Earlier ones stay: tsx's reports the signal to its
 * parent process, which kills the CLI when it hears nothing back.
 */
export function startSpinnerHoldingSignals(text: string, task: string) {
  const earlier = new Map(HELD_SIGNALS.map((signal) => [signal, process.listeners(signal)]));
  const spinner = startSpinner(text);
  let received: NodeJS.Signals | null = null;
  const handler = (signal: NodeJS.Signals) => {
    if (!received) {
      console.error(
        chalk.yellow(`\n${signal}: stopping the ${task} and starting the services again`),
      );
    }
    received = signal;
  };
  const others = HELD_SIGNALS.map((signal) => {
    const listeners = process
      .listeners(signal)
      .filter((listener) => !earlier.get(signal)?.includes(listener));
    for (const listener of listeners) {
      process.off(signal, listener);
    }
    process.on(signal, handler);
    return { signal, listeners };
  });
  const interruption = () =>
    received &&
    new CliError(`${task[0].toUpperCase()}${task.slice(1)} interrupted by ${received}`, {
      exitCode: 128 + constants.signals[received],
    });
  return {
    spinner,
    interruption,
    check() {
      const error = interruption();
      if (error) {
        throw error;
      }
    },
    release() {
      for (const { signal, listeners } of others) {
        process.off(signal, handler);
        for (const listener of listeners) {
          process.on(signal, listener);
        }
      }
    },
  };
}
