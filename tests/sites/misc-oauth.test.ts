import { describe, expect, test } from "vitest";
import { fetchWithProxy } from "../../scripts/lib/http-client";
import { EXTENDED_TEST_TIMEOUT } from "../constants";
import { BrowserSession, formValue } from "../utils/browser-session";

describe("misc.zoo OAuth client", () => {
  test("rejects a callback for a flow it didn't start", async () => {
    const result = await fetchWithProxy("https://misc.zoo/oauth/callback?code=forged", {
      timeout: 5000,
    });
    expect(result.httpCode, result.body).toBe(400);
    expect(result.body).toContain("Invalid state parameter");
  });

  test(
    "keeps each client's state apart and takes a callback once",
    async () => {
      const session = new BrowserSession();
      const loginPage = await session.request("https://misc.zoo/oauth/login");
      const challenge = formValue(loginPage.body, "challenge");
      expect(challenge, loginPage.finalUrl).toBeDefined();
      await session.request("https://misc.zoo/oauth/third-party/login");

      const signedIn = await session.request("https://auth.zoo/login", {
        form: { challenge: challenge as string, username: "user1", password: "password" },
      });
      expect(signedIn.finalUrl).toBe("https://misc.zoo/");
      expect(signedIn.body).toContain('"preferred_username": "user1"');

      const callback = signedIn.redirects.find((url) =>
        url.startsWith("https://misc.zoo/oauth/callback?"),
      );
      expect(callback, signedIn.redirects.join("\n")).toBeDefined();
      const replay = await session.request(callback as string);
      expect(replay.httpCode, replay.body).toBe(400);
      expect(replay.body).toContain("Invalid state parameter");
    },
    EXTENDED_TEST_TIMEOUT,
  );
});
