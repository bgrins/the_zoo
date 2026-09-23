import { type ComposeConfig, localImageId, runHelper } from "./docker";

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

export type BaselineProblem =
  | { reason: "missing" }
  | { reason: "unpulled"; services: string[] }
  | { reason: "other images"; services: string[]; manifest: Manifest }
  | { reason: "missing archives"; services: string[] };

/**
 * Why the services of `config` can't restore snapshot `name` of a snapshots volume: there is no
 * such snapshot, the images configured for some of its services are not pulled, so there is
 * nothing to compare with, it was saved with other images than those, or its required archives
 * are missing. Compose creates the services from the configured images, whatever the running
 * containers were created from.
 * The manifest is read in a container of `helperImage`.
 */
export async function baselineProblem(
  config: ComposeConfig,
  helperImage: string,
  volume: string,
  name: string,
): Promise<BaselineProblem | null> {
  const manifest = await readManifest(helperImage, volume, name);
  if (!manifest) {
    return { reason: "missing" };
  }
  const images: Record<string, string | undefined> = {};
  const unpulled: string[] = [];
  for (const service of Object.keys(manifest.services)) {
    const configured = config.services[service]?.image;
    images[service] = configured && (await localImageId(configured));
    if (configured && images[service] === undefined) {
      unpulled.push(service);
    }
  }
  if (unpulled.length > 0) {
    return { reason: "unpulled", services: unpulled };
  }
  const changed = servicesWithOtherImages(manifest, (service) => images[service]);
  if (changed.length > 0) {
    return { reason: "other images", services: changed, manifest };
  }
  const archived = Object.entries(manifest.services)
    .filter(([, { archive }]) => archive !== "golden")
    .map(([service]) => service);
  if (archived.length === 0) {
    return null;
  }
  const missing = await runHelper(
    helperImage,
    'name=$1; shift; for service in "$@"; do [ -s "/zoo-snapshots/$name/$service.tar" ] || echo "$service"; done',
    [name, ...archived],
    { volumes: { [volume]: "/zoo-snapshots:ro" } },
  );
  const services = missing.trim().split("\n").filter(Boolean);
  return services.length > 0 ? { reason: "missing archives", services } : null;
}
