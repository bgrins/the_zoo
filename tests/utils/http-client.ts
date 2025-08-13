import { ProxyAgent, fetch } from "undici";
import { PROXY_URL } from "../constants";

// Create proxy agents with certificate verification disabled for development
// This is necessary because Caddy uses self-signed certificates in the zoo environment
// Note: Since the proxy (Squid) already blocks non-.zoo domains, we can safely
// disable certificate verification for all connections through the proxy
const proxyAgent = new ProxyAgent({
  uri: PROXY_URL,
  // Configure the connection to the proxy itself
  connect: {
    rejectUnauthorized: false,
  },
  // Configure connections from proxy to destination
  // Safe because Squid proxy blocks all non-.zoo domains
  requestTls: {
    rejectUnauthorized: false,
  },
});

interface FetchOptions {
  proxy?: boolean;
  timeout?: number;
  headers?: Record<string, string>;
  method?: string;
  body?: string | Buffer;
}

interface FetchResult {
  url: string;
  httpCode: number;
  contentType: string;
  headers: Record<string, string>;
  body: string;
  success: boolean;
  error?: string;
  timeTotal?: number;
  cookies?: Array<{ name: string; value: string; flags: string[] }>;
}

/**
 * Node.js fetch wrapper with proxy support
 * Works with all .zoo domains through the proxy
 */
export async function fetchWithProxy(
  url: string,
  options: FetchOptions = {},
): Promise<FetchResult> {
  const { proxy = true, timeout = 2000, headers = {}, method = "GET", body } = options;

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeout);
  const startTime = performance.now();

  try {
    // Use proxy agent with certificate verification disabled
    const agent = proxy ? proxyAgent : undefined;

    const response = await fetch(url, {
      method,
      headers,
      body,
      signal: controller.signal,
      dispatcher: agent,
    });

    const responseHeaders: Record<string, string> = {};
    const cookies: Array<{ name: string; value: string; flags: string[] }> = [];

    // Get raw headers to properly parse Set-Cookie headers
    // The Headers API combines multiple Set-Cookie headers which we need to handle
    const setCookieHeaders: string[] = [];

    response.headers.forEach((value, key) => {
      responseHeaders[key.toLowerCase()] = value;

      // Collect all Set-Cookie headers
      if (key.toLowerCase() === "set-cookie") {
        setCookieHeaders.push(value);
      }
    });

    // Parse Set-Cookie headers for security tests
    // Note: fetch API may combine multiple Set-Cookie headers with comma separator
    setCookieHeaders.forEach((cookieHeader) => {
      // Split by comma but be careful of expires dates that contain commas
      const individualCookies = cookieHeader.split(/,(?=\s*\w+=)/).map((c) => c.trim());

      individualCookies.forEach((cookie) => {
        const cookieParts = cookie.split(";").map((p) => p.trim());
        const [nameValue, ...flags] = cookieParts;
        const [name, cookieValue] = nameValue.split("=");
        if (name) {
          cookies.push({
            name: name.trim(),
            value: cookieValue?.trim() || "",
            flags: flags.map((f) => f.toLowerCase()),
          });
        }
      });
    });

    const responseBody = await response.text();
    const timeTotal = (performance.now() - startTime) / 1000; // Convert to seconds like curl

    return {
      url,
      httpCode: response.status,
      contentType: response.headers.get("content-type") || "",
      headers: responseHeaders,
      body: responseBody,
      success: true,
      timeTotal,
      cookies: cookies.length > 0 ? cookies : undefined,
    };
  } catch (error) {
    const timeTotal = (performance.now() - startTime) / 1000;
    const err = error as Error;
    return {
      url,
      httpCode: 0,
      contentType: "",
      headers: {},
      body: "",
      success: false,
      error: err.cause ? `${err.message}: ${err.cause}` : err.message,
      timeTotal,
    };
  } finally {
    clearTimeout(timeoutId);
  }
}

/**
 * Batch fetch for multiple URLs
 * More efficient than curl for simple status checks
 */
export async function batchFetch(
  urls: string[],
  options: FetchOptions & { concurrency?: number } = {},
): Promise<FetchResult[]> {
  const { concurrency = 10, ...fetchOptions } = options;
  const results: FetchResult[] = [];

  for (let i = 0; i < urls.length; i += concurrency) {
    const batch = urls.slice(i, i + concurrency);
    const batchResults = await Promise.all(batch.map((url) => fetchWithProxy(url, fetchOptions)));
    results.push(...batchResults);
  }

  return results;
}

/**
 * Fetch with raw headers for security testing
 */
export async function fetchWithRawHeaders(
  url: string,
  options: FetchOptions & { includeRawHeaders?: boolean } = {},
): Promise<FetchResult & { rawHeaders?: string[] }> {
  const result = await fetchWithProxy(url, options);

  // For security tests, we need access to raw Set-Cookie headers
  // which are normally combined by the Headers API
  return result;
}

/**
 * Test URL with validation checks - compatible with curl-utils testUrl
 */
export interface TestUrlChecks {
  expectStatus?: number[];
  expectContentType?: string | null;
  expectHeaders?: string[];
  method?: string;
  fetchBody?: boolean;
  timeout?: number;
}

export interface TestUrlResult extends FetchResult {
  expectStatus: number[];
  expectContentType: string | null;
  expectHeaders: string[];
  statusOk?: boolean;
  contentTypeOk?: boolean;
  headersOk?: boolean;
  allOk?: boolean;
}

export async function testUrl(url: string, checks: TestUrlChecks = {}): Promise<TestUrlResult> {
  const {
    expectStatus = [200, 302],
    expectContentType = null,
    expectHeaders = [],
    method = "GET",
    timeout,
  } = checks;

  // Use provided timeout or fallback to default behavior
  const finalTimeout = timeout || (url.includes("?") ? 5000 : 2000);
  const result = await fetchWithProxy(url, { method, timeout: finalTimeout });

  // Validate expectations
  const validations = {
    statusOk: expectStatus.includes(result.httpCode),
    contentTypeOk: !expectContentType || result.contentType.includes(expectContentType),
    headersOk: expectHeaders.every((h) => result.headers[h.toLowerCase()]),
  };

  return {
    ...result,
    expectStatus,
    expectContentType,
    expectHeaders,
    ...validations,
    allOk: Object.values(validations).every((v) => v),
  };
}
