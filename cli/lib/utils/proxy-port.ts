import net from "node:net";
import { dockerProbe } from "./docker";

const PORT_CHECK_TIMEOUT_MS = 5000;

export interface PortCheck {
  level: "ok" | "fail";
  detail: string;
  hint?: string;
}

/**
 * Whether something listens on the port, trying to listen on it the way the proxy would
 */
function portInUse(port: number, host: string): Promise<NodeJS.ErrnoException | null> {
  return new Promise((resolve) => {
    const server = net.createServer();
    const timer = setTimeout(() => {
      server.close();
      resolve(Object.assign(new Error("timed out"), { code: "ETIMEDOUT" }));
    }, PORT_CHECK_TIMEOUT_MS);
    server.once("error", (error: NodeJS.ErrnoException) => {
      clearTimeout(timer);
      resolve(error);
    });
    server.listen(port, host, () => {
      clearTimeout(timer);
      server.close(() => resolve(null));
    });
  });
}

/**
 * Whether an instance can publish its proxy on the port at `host`: it is free, or the proxy of
 * one of the `own` projects holds it
 */
export async function checkProxyPort(
  port: string,
  host: string,
  dockerRunning: boolean,
  own: string[],
): Promise<PortCheck> {
  const error = await portInUse(Number(port), host);
  if (!error) {
    return { level: "ok", detail: "free" };
  }
  const hint = 'Pick another with "the_zoo start --port <port>"';
  if (error.code !== "EADDRINUSE") {
    return { level: "fail", detail: `unusable: ${error.message}`, hint };
  }

  const { stdout } = dockerRunning
    ? await dockerProbe([
        "ps",
        "--filter",
        `publish=${port}`,
        "--format",
        '{{.Names}}\t{{.Label "com.docker.compose.project"}}',
      ])
    : { stdout: "" };
  const [name, project] = stdout.split("\n")[0].split("\t");
  if (project && own.includes(project)) {
    return { level: "ok", detail: `the proxy of ${project}` };
  }
  if (project) {
    return {
      level: "fail",
      detail: `in use by ${name} of ${project}`,
      hint: `Stop ${project}, or pick another port with "the_zoo start --port <port>"`,
    };
  }
  return {
    level: "fail",
    detail: name ? `in use by container ${name}` : "in use by another program",
    hint,
  };
}
