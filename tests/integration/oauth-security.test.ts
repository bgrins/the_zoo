import { exec } from "node:child_process";
import { promisify } from "node:util";
import { beforeAll, describe, expect, test } from "vitest";
import { fetchWithProxy, testUrl } from "../utils/http-client";
import { getCachedContainerName } from "../utils/test-cache";

const execAsync = promisify(exec);

describe("OAuth Security Integration Tests", () => {
  let hydraContainer: string;

  beforeAll(async () => {
    hydraContainer = await getCachedContainerName("hydra");
  });
  test("misc.zoo OAuth login redirects to auth provider", async () => {
    // When starting OAuth flow, misc.zoo should redirect through to auth.zoo
    const httpResult = await fetchWithProxy("http://misc.zoo/oauth/login", { timeout: 5000 });

    expect(httpResult.success).toBe(true);
    // After following redirects, we should end up at the login page
    expect(httpResult.httpCode).toBe(200);

    // The final URL should be the auth.zoo login page
    expect(httpResult.body).toContain("login");
  });

  test("token exchange endpoint validates requests", async () => {
    const tokenEndpoint = "http://auth.zoo/oauth2/token";
    const clientId = "zoo-misc-app";
    const clientSecret = "zoo-misc-secret";

    // Test with invalid authorization code
    const authHeader = Buffer.from(`${clientId}:${clientSecret}`).toString("base64");

    const result = await fetchWithProxy(tokenEndpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        Authorization: `Basic ${authHeader}`,
      },
      body: "grant_type=authorization_code&code=invalid_code&redirect_uri=http://misc.zoo/oauth/callback",
      timeout: 5000,
    });

    // Should return 400 Bad Request for invalid code
    expect(result.httpCode).toBe(400);

    // Response should be JSON error
    expect(result.body).toBeTruthy();
    const parsed = JSON.parse(result.body);
    expect(parsed).toHaveProperty("error");
    // Common OAuth error codes for invalid authorization code
    expect(["invalid_grant", "invalid_request"]).toContain(parsed.error);
  });

  test("token endpoint requires proper authentication", async () => {
    const tokenEndpoint = "http://auth.zoo/oauth2/token";

    // Test without authentication
    const result = await fetchWithProxy(tokenEndpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: "grant_type=authorization_code&code=test_code&redirect_uri=http://misc.zoo/oauth/callback",
      timeout: 5000,
    });

    // Ory Hydra returns 400 Bad Request for missing client credentials
    expect(result.httpCode).toBe(400);

    // Verify the error message mentions missing credentials
    expect(result.body).toBeTruthy();
    const parsed = JSON.parse(result.body);
    expect(parsed.error).toBe("invalid_request");
    expect(parsed.error_description).toContain("Client credentials missing");
  });

  test("OAuth authorization endpoint is accessible", async () => {
    // Test that OAuth auth endpoint is reachable and responds
    const authUrl =
      "http://auth.zoo/oauth2/auth?client_id=zoo-misc-app&redirect_uri=http://misc.zoo/oauth/callback&response_type=code&scope=openid+profile+email&state=test123456789";

    const result = await fetchWithProxy(authUrl, { timeout: 5000 });

    expect(result.success).toBe(true);

    // OAuth auth endpoint should either:
    // 1. Return 200 with a login form
    // 2. Return 302/303 redirect to login page
    expect([200, 302, 303]).toContain(result.httpCode);

    // Note: CSRF protection testing would require following redirects
    // and examining cookies on the actual login page, which is complex
    // with the fetch API. The original curl test used verbose output
    // to capture intermediate redirect responses.
  });

  test("Hydra service should be running and healthy", async () => {
    // Check container status
    const statusCmd = `docker inspect ${hydraContainer} --format "{{.State.Status}}"`;
    const { stdout: status } = await execAsync(statusCmd);
    expect(status.trim(), "Hydra container is not running").toBe("running");

    // Check health status
    const healthCmd = `docker inspect ${hydraContainer} --format "{{.State.Health.Status}}"`;
    const { stdout: health } = await execAsync(healthCmd);
    expect(health.trim(), "Hydra container is not healthy").toBe("healthy");
  });

  test("admin.auth.zoo health endpoint should respond", async () => {
    const result = await testUrl("http://admin.auth.zoo/health/ready", {
      expectStatus: [200],
    });

    expect(result.success, `Hydra admin health check failed: ${result.error}`).toBe(true);
    expect(result.httpCode, `Hydra admin health check failed with ${result.httpCode}`).toBe(200);
  });

  test("Hydra should have database connectivity", async () => {
    const dbCheckCmd = `docker exec ${hydraContainer} hydra migrate status --read-from-env --config /etc/hydra/hydra.yaml 2>&1`;
    const { stdout } = await execAsync(dbCheckCmd);

    // Check for connectivity errors
    expect(stdout, "Hydra cannot connect to database: connection refused").not.toContain(
      "connection refused",
    );
    expect(stdout, "Hydra cannot connect to database: no such host").not.toContain("no such host");
    expect(stdout, "Hydra migrations not applied").toContain("Applied");
  });

  test("CORS should be enabled for zoo domains", async () => {
    const result = await fetchWithProxy("https://auth.zoo/oauth2/token", {
      method: "OPTIONS",
      headers: {
        Origin: "https://misc.zoo",
        "Access-Control-Request-Method": "POST",
      },
      timeout: 5000,
    });

    expect(result.success).toBe(true);
    expect(result.headers["access-control-allow-origin"], "CORS headers not present").toBeDefined();
    expect(
      result.headers["access-control-allow-origin"],
      "CORS not configured for misc.zoo",
    ).toContain("https://misc.zoo");
  });
});
