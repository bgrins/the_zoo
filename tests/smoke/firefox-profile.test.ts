import { readFileSync } from "node:fs";
import { describe, expect, test } from "vitest";
import { ZOO_FIREFOX_PREFS } from "../utils/browser";

describe("Firefox profile", () => {
  test("the Playwright browser uses the documented profile's prefs", () => {
    const userJs = readFileSync(
      new URL("../../docs/firefox-profile/user.js", import.meta.url),
      "utf8",
    );
    const documented = Object.fromEntries(
      Object.keys(ZOO_FIREFOX_PREFS).map((name) => {
        const pattern = new RegExp(`^user_pref\\("${name.replaceAll(".", "\\.")}", (.+)\\);`, "m");
        const value = userJs.match(pattern)?.[1];
        return [name, value === undefined ? undefined : JSON.parse(value)];
      }),
    );
    expect(documented).toEqual(ZOO_FIREFOX_PREFS);
  });
});
