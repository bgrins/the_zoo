#!/usr/bin/env -S npx tsx

/**
 * Checks that every ghcr.io image the packaged CLI's compose file names can be pulled
 * anonymously for linux/amd64 and linux/arm64, so a release can't reference a missing or
 * private image (a new ghcr package is private until made public).
 *
 * Usage: verify-release-images.ts [compose file, default dist/zoo/docker-compose.yaml]
 */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import yaml from "yaml";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const PLATFORMS = ["linux/amd64", "linux/arm64"];
const MANIFEST_TYPES = [
  "application/vnd.oci.image.index.v1+json",
  "application/vnd.docker.distribution.manifest.list.v2+json",
  "application/vnd.oci.image.manifest.v1+json",
  "application/vnd.docker.distribution.manifest.v2+json",
].join(", ");

interface Manifest {
  // Only an index lists platforms; a single-platform manifest has none
  manifests?: { platform?: { os: string; architecture: string } }[];
}

/**
 * The ghcr.io images of the compose file, with each ${VAR:-default} replaced by its default
 * (the CLI build sets ZOO_IMAGE_TAG's to the release version)
 */
function releaseImages(composeFile: string): string[] {
  const { services } = yaml.parse(fs.readFileSync(composeFile, "utf8")) as {
    services: Record<string, { image?: string }>;
  };
  const images = Object.values(services)
    .map((service) => service.image?.replace(/\$\{\w+:-([^}]*)\}/g, "$1"))
    .filter((image): image is string => image?.startsWith("ghcr.io/") ?? false);
  return [...new Set(images)].sort();
}

/**
 * The platforms ghcr.io serves the image for, without credentials
 */
async function platforms(image: string): Promise<string[]> {
  const [name, digest] = image.slice("ghcr.io/".length).split("@");
  const tagAt = name.lastIndexOf(":");
  const repository = tagAt === -1 ? name : name.slice(0, tagAt);
  const reference = digest ?? (tagAt === -1 ? "latest" : name.slice(tagAt + 1));

  const tokenResponse = await fetch(`https://ghcr.io/token?scope=repository:${repository}:pull`);
  if (!tokenResponse.ok) {
    throw new Error(
      `anonymous pulls are denied (HTTP ${tokenResponse.status}): private or missing`,
    );
  }
  const { token } = (await tokenResponse.json()) as { token: string };
  const response = await fetch(`https://ghcr.io/v2/${repository}/manifests/${reference}`, {
    headers: { Authorization: `Bearer ${token}`, Accept: MANIFEST_TYPES },
  });
  if (!response.ok) {
    throw new Error(`no manifest for ${reference} (HTTP ${response.status})`);
  }
  const manifest = (await response.json()) as Manifest;
  return (manifest.manifests ?? []).flatMap(({ platform }) =>
    platform ? [`${platform.os}/${platform.architecture}`] : [],
  );
}

async function main() {
  const composeFile = path.resolve(ROOT, process.argv[2] ?? "dist/zoo/docker-compose.yaml");
  const images = releaseImages(composeFile);
  if (images.length === 0) {
    console.error(`No ghcr.io images in ${composeFile}`);
    process.exit(1);
  }

  const problems = await Promise.all(
    images.map(async (image) => {
      try {
        const served = await platforms(image);
        const missing = PLATFORMS.filter((platform) => !served.includes(platform));
        return missing.length > 0 ? `no ${missing.join(" or ")} image` : "";
      } catch (error) {
        return (error as Error).message;
      }
    }),
  );

  images.forEach((image, i) => {
    console.log(problems[i] ? `✗ ${image}: ${problems[i]}` : `✓ ${image}`);
  });
  if (problems.some(Boolean)) {
    console.error(
      "\nPublish the images first (push the release tag), and make any new ghcr.io package public in its package settings.",
    );
    process.exit(1);
  }
}

main();
