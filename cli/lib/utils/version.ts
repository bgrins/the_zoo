export interface Version {
  core: number[];
  prerelease: string[];
}

/**
 * Parse a semver version such as "0.10.0", "v0.10.0-rc.1" or "25.0.3+dfsg1"
 */
export function parseVersion(version: string): Version | null {
  const match = version
    .trim()
    .match(/^v?(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+[0-9A-Za-z.-]+)?$/);
  if (!match) {
    return null;
  }
  return { core: match.slice(1, 4).map(Number), prerelease: match[4]?.split(".") ?? [] };
}

function compareIdentifiers(a: string, b: string): number {
  const [aNumeric, bNumeric] = [/^\d+$/.test(a), /^\d+$/.test(b)];
  if (aNumeric && bNumeric) {
    return Number(a) - Number(b);
  }
  if (aNumeric !== bNumeric) {
    return aNumeric ? -1 : 1;
  }
  return a < b ? -1 : a > b ? 1 : 0;
}

/**
 * Semver precedence: negative when a comes before b. A prerelease comes before its release.
 */
export function compareVersions(a: Version, b: Version): number {
  const index = a.core.findIndex((part, i) => part !== b.core[i]);
  if (index !== -1) {
    return a.core[index] - b.core[index];
  }
  if (a.prerelease.length === 0 || b.prerelease.length === 0) {
    return b.prerelease.length - a.prerelease.length;
  }
  for (let i = 0; i < Math.min(a.prerelease.length, b.prerelease.length); i++) {
    const order = compareIdentifiers(a.prerelease[i], b.prerelease[i]);
    if (order !== 0) {
      return order;
    }
  }
  return a.prerelease.length - b.prerelease.length;
}
