import { describe, it, expect } from "vitest";
import { fetchWithProxy } from "../utils/http-client";
import { ON_DEMAND_TIMEOUT } from "../constants";

describe("docs.gitea.zoo", () => {
  it("should be accessible", { timeout: ON_DEMAND_TIMEOUT }, async () => {
    const response = await fetchWithProxy("http://docs.gitea.zoo");
    expect(response.httpCode).toBe(200);
    expect(response.contentType).toContain("text/html");
  });

  it("should serve Gitea documentation", async () => {
    const response = await fetchWithProxy("http://docs.gitea.zoo");
    expect(response.body).toContain("Gitea");
    expect(response.body).toContain("docs.gitea.zoo");
  });
});
