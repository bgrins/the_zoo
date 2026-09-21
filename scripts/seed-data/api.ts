import { fetchWithProxy } from "../lib/http-client";
import { execDockerArgs, SEED_REQUEST_TIMEOUT } from "./exec";
import { personas } from "./personas";

function basicAuth(username: string): string {
  const persona = personas.find((p) => p.username === username);
  if (!persona) {
    throw new Error(`No persona ${username}`);
  }
  return `Basic ${Buffer.from(`${username}:${persona.password}`).toString("base64")}`;
}

interface ApiOptions {
  // The persona to sign in as, with basic auth; anonymous without
  as?: string;
  body?: unknown;
  // Return null for a 404 instead of throwing
  optional?: boolean;
}

// A JSON API call through the proxy; throws on any other status than 2xx (and 404 if optional)
async function jsonApi(base: string, method: string, path: string, options: ApiOptions) {
  const headers: Record<string, string> = { "Content-Type": "application/json" };
  if (options.as) {
    headers.Authorization = basicAuth(options.as);
  }
  const result = await fetchWithProxy(`${base}${path}`, {
    method,
    timeout: SEED_REQUEST_TIMEOUT,
    headers,
    body: options.body === undefined ? undefined : JSON.stringify(options.body),
  });
  if (options.optional && result.httpCode === 404) {
    return null;
  }
  if (result.httpCode < 200 || result.httpCode >= 300) {
    throw new Error(
      `${method} ${base}${path}: HTTP ${result.httpCode} ${result.error || result.body}`,
    );
  }
  return result.body ? JSON.parse(result.body) : null;
}

export function giteaApi(method: string, path: string, options: ApiOptions = {}) {
  return jsonApi("https://gitea.zoo/api/v1", method, path, options);
}

export function minifluxApi(method: string, path: string, options: ApiOptions = {}) {
  return jsonApi("https://miniflux.zoo/v1", method, path, options);
}

// Mattermost's API over its local-mode socket, which needs no session and allows everything
export function mattermostLocalApi(method: string, path: string, body?: unknown) {
  const output = execDockerArgs("mattermost", [
    "curl",
    "-sS",
    "--unix-socket",
    "/var/tmp/mattermost_local.socket",
    "-X",
    method,
    "-H",
    "Content-Type: application/json",
    ...(body === undefined ? [] : ["--data-binary", JSON.stringify(body)]),
    "-w",
    "\n%{http_code}",
    `http://localhost/api/v4${path}`,
  ]);
  const at = output.lastIndexOf("\n");
  const status = Number(output.slice(at + 1));
  if (status < 200 || status >= 300) {
    throw new Error(`Mattermost ${method} ${path}: HTTP ${status} ${output.slice(0, at)}`);
  }
  return JSON.parse(output.slice(0, at));
}
