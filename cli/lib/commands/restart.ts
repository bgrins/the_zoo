import { stop } from "./stop";
import { start } from "./start";

interface RestartOptions {
  port: string;
  setEnv?: string[];
  instance?: string;
}

export async function restart(options: RestartOptions): Promise<void> {
  await stop({ instance: options.instance });
  await start(options);
}
