import { expect } from "vitest";
import { COLD_START_TIMEOUT } from "../constants";
import { fetchWithProxy } from "./http-client";

// Leaves the hook time to report the URL, including after other setup in the same hook
const WARM_UP_FETCH_TIMEOUT = COLD_START_TIMEOUT - 5000;

// Caddy holds a request to a stopped on-demand app until its container is ready. Warming the
// app in beforeAll (with COLD_START_TIMEOUT as the hook timeout) keeps its cold start out of
// every individual test's budget. Hooks aren't retried, so the budget covers a slow start.
export async function warmUp(url: string): Promise<void> {
  const result = await fetchWithProxy(url, { timeout: WARM_UP_FETCH_TIMEOUT });
  expect(result.httpCode, `${url}: ${result.error ?? `HTTP ${result.httpCode}`}`).toBe(200);
}
