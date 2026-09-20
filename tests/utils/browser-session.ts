import { fetchWithProxy } from "../../scripts/lib/http-client";

type FetchResult = Awaited<ReturnType<typeof fetchWithProxy>>;

export interface SessionResponse extends FetchResult {
  finalUrl: string;
  redirects: string[];
}

/**
 * Minimal browser-like HTTP session: keeps cookies per host and follows redirects
 * manually so cookies set along a redirect chain (e.g. an OAuth flow) are carried forward.
 */
export class BrowserSession {
  private jar = new Map<string, Map<string, string>>();

  clearCookies(host: string) {
    this.jar.delete(host);
  }

  async request(
    url: string,
    options: { method?: string; form?: Record<string, string>; timeout?: number } = {},
  ): Promise<SessionResponse> {
    let current = url;
    let method = options.method || (options.form ? "POST" : "GET");
    let body = options.form ? new URLSearchParams(options.form).toString() : undefined;
    const redirects: string[] = [];

    for (let hop = 0; hop < 20; hop++) {
      const host = new URL(current).hostname;
      const cookies = this.jar.get(host);
      const headers: Record<string, string> = {};
      if (cookies?.size) {
        headers.Cookie = [...cookies].map(([k, v]) => `${k}=${v}`).join("; ");
      }
      if (body) {
        headers["Content-Type"] = "application/x-www-form-urlencoded";
      }

      const response = await fetchWithProxy(current, {
        method,
        body,
        headers,
        redirect: "manual",
        timeout: options.timeout ?? 10000,
      });
      if (!response.success) {
        throw new Error(`${method} ${current} failed: ${response.error}`);
      }

      const hostJar = this.jar.get(host) ?? new Map<string, string>();
      for (const cookie of response.cookies || []) {
        hostJar.set(cookie.name, cookie.value);
      }
      this.jar.set(host, hostJar);

      const location = response.headers.location;
      if (response.httpCode >= 300 && response.httpCode < 400 && location) {
        current = new URL(location, current).toString();
        redirects.push(current);
        // Browsers switch to GET after 301/302/303
        if (response.httpCode !== 307 && response.httpCode !== 308) {
          method = "GET";
          body = undefined;
        }
        continue;
      }

      return { ...response, finalUrl: current, redirects };
    }
    throw new Error(`Too many redirects starting from ${url}`);
  }
}

/** Value of a named form input in an HTML page */
export function formValue(html: string, name: string): string | undefined {
  return html.match(new RegExp(`name="${name}" value="([^"]*)"`))?.[1];
}

/** Accept the auth.zoo consent form shown in `consentPage` */
export async function acceptConsent(
  session: BrowserSession,
  consentPage: string,
): Promise<SessionResponse> {
  const challenge = formValue(consentPage, "challenge");
  const scopes = formValue(consentPage, "scopes");
  if (!challenge || scopes === undefined) {
    throw new Error("Page is not an auth.zoo consent form");
  }
  return session.request("https://auth.zoo/consent", {
    form: { challenge, scopes, submit: "accept" },
  });
}

/**
 * Start an OAuth flow at `startUrl`, sign in to auth.zoo interactively, consent if asked,
 * and return the page the relying party lands on.
 */
export async function oauthLogin(
  session: BrowserSession,
  startUrl: string,
  username: string,
  password: string,
): Promise<SessionResponse> {
  const loginPage = await session.request(startUrl);
  const challenge = formValue(loginPage.body, "challenge");
  if (!loginPage.finalUrl.startsWith("https://auth.zoo/login?") || !challenge) {
    throw new Error(`Expected the auth.zoo login form, got ${loginPage.finalUrl}`);
  }

  const page = await session.request("https://auth.zoo/login", {
    form: { challenge, username, password },
  });
  return page.finalUrl.startsWith("https://auth.zoo/consent")
    ? acceptConsent(session, page.body)
    : page;
}
