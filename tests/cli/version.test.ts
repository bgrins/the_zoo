import { describe, expect, it } from "vitest";
import { compareVersions, parseVersion, type Version } from "../../cli/lib/utils/version";

function parse(version: string): Version {
  const parsed = parseVersion(version);
  if (!parsed) {
    throw new Error(`Could not parse ${version}`);
  }
  return parsed;
}

describe("CLI versions", () => {
  it("should order versions by semver precedence", () => {
    const ordered = [
      "0.9.0",
      "v0.10.0-alpha",
      "0.10.0-alpha.1",
      "0.10.0-alpha.beta",
      "0.10.0-beta",
      "0.10.0-beta.2",
      "0.10.0-beta.11",
      "0.10.0-rc.1",
      "v0.10.0",
      "0.10.1-dev",
      "0.11.0",
    ];
    const shuffled = [...ordered].reverse();

    expect(shuffled.sort((a, b) => compareVersions(parse(a), parse(b)))).toEqual(ordered);
    expect(compareVersions(parse("v1.2.3"), parse("1.2.3+build.5"))).toBe(0);
  });

  it("should reject what isn't a version", () => {
    for (const tag of ["latest", "0.10", "v0.10.0.rc.1", "0.10.0-", "0.10.0-rc..1"]) {
      expect(parseVersion(tag), tag).toBeNull();
    }
  });
});
