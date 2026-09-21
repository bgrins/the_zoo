import { runHelper } from "./docker";

export interface Manifest {
  name: string;
  createdAt: string;
  cliVersion: string;
  // How each stateful service's archive was made: "saved" from its files, "copied" from the
  // snapshot its files still match, or "golden" (none: it restores the golden state)
  services: Record<string, { image: string; digests: string[]; archive: string }>;
}

/**
 * The manifest of snapshot `name` in a snapshots volume, read in a container of `image`, or null
 * if there is no such snapshot
 */
export async function readManifest(
  image: string,
  volume: string,
  name: string,
): Promise<Manifest | null> {
  const content = await runHelper(
    image,
    '[ ! -f "/zoo-snapshots/$1/manifest.json" ] || cat "/zoo-snapshots/$1/manifest.json"',
    [name],
    { volumes: { [volume]: "/zoo-snapshots:ro" } },
  );
  return content.trim() ? JSON.parse(content) : null;
}

/**
 * The services a snapshot was saved with other images of than the ones `imageOf` gives (as
 * image IDs), whose archives could hold data another version can't read
 */
export function servicesWithOtherImages(
  manifest: Manifest,
  imageOf: (service: string) => string | undefined,
): string[] {
  return Object.entries(manifest.services)
    .filter(([service, { image }]) => imageOf(service) !== image)
    .map(([service]) => service);
}
