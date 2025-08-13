import chalk from "chalk";

let isVerbose = false;

/**
 * Set verbose mode for the CLI
 */
export function setVerbose(verbose: boolean): void {
  isVerbose = verbose;
}

/**
 * Get current verbose mode status
 */
export function getVerbose(): boolean {
  return isVerbose;
}

/**
 * Log a verbose message (only shown when verbose mode is enabled)
 */
export function logVerbose(message: string, ...args: any[]): void {
  if (isVerbose) {
    console.log(chalk.gray(`[VERBOSE] ${message}`), ...args);
  }
}

/**
 * Log verbose command information
 */
export function logVerboseCommand(command: string, cwd?: string): void {
  if (isVerbose) {
    const location = cwd ? ` (in ${cwd})` : "";
    console.log(chalk.gray(`[VERBOSE] Running command: ${command}${location}`));
  }
}

/**
 * Log verbose step information
 */
export function logVerboseStep(step: string): void {
  if (isVerbose) {
    console.log(chalk.gray(`[VERBOSE] Step: ${step}`));
  }
}

/**
 * Log verbose environment information
 */
export function logVerboseEnv(env: Record<string, string>): void {
  if (isVerbose) {
    console.log(chalk.gray(`[VERBOSE] Environment variables:`));
    for (const [key, value] of Object.entries(env)) {
      console.log(chalk.gray(`[VERBOSE]   ${key}=${value}`));
    }
  }
}

/**
 * Log verbose timing information
 */
export function logVerboseTiming(operation: string, duration: number): void {
  if (isVerbose) {
    console.log(chalk.gray(`[VERBOSE] ${operation} took ${duration}ms`));
  }
}
