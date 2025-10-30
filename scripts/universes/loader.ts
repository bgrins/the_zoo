import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import type { GiteaData, SnappyMailData, Universe, UniverseData } from "./types";

/**
 * Load a universe from disk
 * @param universeId - The ID of the universe to load (matches directory name)
 * @returns Complete universe data
 */
export async function loadUniverseFromDisk(universeId: string): Promise<UniverseData> {
  const universePath = join(process.cwd(), "universes", universeId);

  // Check if universe exists
  if (!existsSync(universePath)) {
    throw new Error(`Universe "${universeId}" not found at ${universePath}`);
  }

  // Load universe metadata
  const universeJsonPath = join(universePath, "universe.json");
  if (!existsSync(universeJsonPath)) {
    throw new Error(`Universe metadata not found: ${universeJsonPath}`);
  }

  const universe: Universe = JSON.parse(readFileSync(universeJsonPath, "utf-8"));

  // Validate universe ID matches directory
  if (universe.id !== universeId) {
    throw new Error(
      `Universe ID mismatch: directory is "${universeId}" but universe.json has id "${universe.id}"`,
    );
  }

  // Load app-specific data
  const appsPath = join(universePath, "apps");
  const apps: UniverseData["apps"] = {};

  // Load SnappyMail data
  const snappyMailPath = join(appsPath, "snappymail.zoo");
  if (existsSync(snappyMailPath)) {
    const emailsPath = join(snappyMailPath, "emails.json");
    const snappyMailData: SnappyMailData = {};

    if (existsSync(emailsPath)) {
      snappyMailData.emails = JSON.parse(readFileSync(emailsPath, "utf-8"));
    }

    apps["snappymail.zoo"] = snappyMailData;
  }

  // Load Gitea data
  const giteaPath = join(appsPath, "gitea.zoo");
  if (existsSync(giteaPath)) {
    const repositoriesPath = join(giteaPath, "repositories.json");
    const giteaData: GiteaData = {};

    if (existsSync(repositoriesPath)) {
      giteaData.repositories = JSON.parse(readFileSync(repositoriesPath, "utf-8"));
    }

    apps["gitea.zoo"] = giteaData;
  }

  return {
    universe,
    apps,
  };
}

/**
 * Validate universe data
 * @param data - Universe data to validate
 */
export function validateUniverse(data: UniverseData): void {
  const { universe, apps } = data;

  // Validate required fields
  if (!universe.id) {
    throw new Error("Universe must have an 'id' field");
  }

  if (!universe.personas || !Array.isArray(universe.personas) || universe.personas.length === 0) {
    throw new Error("Universe must have at least one persona");
  }

  // Validate emails reference existing personas
  const emails = apps["snappymail.zoo"]?.emails || [];
  for (const email of emails) {
    const fromUsername = email.from.split("@")[0];
    const toUsernames = Array.isArray(email.to)
      ? email.to.map((e) => e.split("@")[0])
      : [email.to.split("@")[0]];

    // Check sender exists (warning, not error)
    if (!universe.personas.includes(fromUsername)) {
      console.warn(
        `Warning: Email from "${fromUsername}" but persona not in universe. Email may not be delivered.`,
      );
    }

    // Check recipients exist (warning, not error)
    for (const toUsername of toUsernames) {
      if (!universe.personas.includes(toUsername)) {
        console.warn(
          `Warning: Email to "${toUsername}" but persona not in universe. Email may not be delivered.`,
        );
      }
    }
  }

  // Validate repositories reference existing owners
  const repositories = apps["gitea.zoo"]?.repositories || [];
  for (const repo of repositories) {
    if (!universe.personas.includes(repo.owner)) {
      throw new Error(
        `Repository "${repo.name}" has owner "${repo.owner}" but persona not found in universe`,
      );
    }
  }
}
