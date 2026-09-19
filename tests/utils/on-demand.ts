import { expect } from "vitest";
import { fetchWithProxy } from "./http-client";

// Caddy holds a request to a stopped on-demand app until its container is ready. Warming the
// app in beforeAll keeps its cold start out of every individual test's budget.
export async function warmUp(url: string, timeout: number): Promise<void> {
  const result = await fetchWithProxy(url, { timeout });
  expect(result.httpCode, `${url}: ${result.error ?? `HTTP ${result.httpCode}`}`).toBe(200);
}
