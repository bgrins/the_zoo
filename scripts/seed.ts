#!/usr/bin/env tsx

import { execSync } from "node:child_process";
import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { stringify } from "yaml";
import { adminCredentials } from "./seed-data/admins";
import { apps } from "./seed-data/apps";
import { minLengthPassword, personas, platformTeamMembers } from "./seed-data/personas";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const credentialsDir = join(ROOT, "docs/credentials");

// Check if required containers are running
function checkContainers(): { missing: string[]; found: string[] } {
  const requiredContainers = [
    "postgres",
    "stalwart",
    "gitea-zoo",
    "auth-zoo",
    "miniflux",
    "focalboard-zoo",
    "snappymail-zoo",
    "mattermost",
  ];

  const missing: string[] = [];
  const found: string[] = [];

  // Get list of running containers using docker compose
  try {
    const output = execSync("docker compose ps --format json", { encoding: "utf8", cwd: ROOT });

    const runningContainers = output
      .trim()
      .split("\n")
      .filter((line) => line)
      .map((line) => JSON.parse(line))
      .filter((container) => container.State === "running")
      .map((container) => container.Service);

    for (const container of requiredContainers) {
      if (runningContainers.includes(container)) {
        found.push(container);
      } else {
        missing.push(container);
      }
    }
  } catch {
    // If docker compose fails, all containers are considered missing
    missing.push(...requiredContainers);
  }

  return { missing, found };
}

async function main() {
  console.log("\n🌱 Zoo Seed Data Manager\n");

  // Check containers
  const { missing, found } = checkContainers();

  if (missing.length > 0) {
    console.log(`⚙️  Starting required containers: ${missing.join(", ")}`);
    try {
      // --wait blocks until the containers are healthy so seeding doesn't race startup
      execSync(`docker compose --profile on-demand up -d --wait ${missing.join(" ")}`, {
        stdio: "inherit",
        cwd: ROOT,
      });
      console.log(`✓ Started containers: ${missing.join(", ")}\n`);
    } catch (error) {
      console.error("❌ Failed to start containers:", error);
      process.exit(1);
    }
  }

  console.log(`✓ Found containers: ${found.join(", ")}\n`);

  // Seed each app with each persona
  const failures: string[] = [];
  for (const [appName, app] of Object.entries(apps)) {
    console.log(`\nSeeding ${appName}...`);

    for (const persona of personas) {
      try {
        await app.seed(persona);
      } catch (error) {
        console.error(`❌ Failed to seed ${persona.username} in ${appName}:`, error);
        failures.push(`${appName}: ${persona.username}`);
      }
    }
  }

  if (failures.length > 0) {
    console.error(`\n❌ ${failures.length} seed step(s) failed:\n  ${failures.join("\n  ")}\n`);
    process.exit(1);
  }

  console.log("\n✅ Seeding complete!\n");

  // Write credential YAML files
  writeCredentialFiles();
}

interface CredentialEntry {
  username: string;
  password: string;
  email?: string;
  role?: string;
  note?: string;
}

interface SiteCredentials {
  site: string;
  description: string;
  admin?: CredentialEntry;
  users: CredentialEntry[];
}

function writeCredentialFiles() {
  console.log("📝 Writing credential files...\n");
  mkdirSync(credentialsDir, { recursive: true });
  const admins = adminCredentials();

  const siteCredentials: SiteCredentials[] = [
    {
      site: "auth.zoo",
      description: "Authentication service (OAuth/OIDC provider)",
      users: personas.map((p) => ({
        username: p.username,
        password: p.password,
        email: `${p.username}@snappymail.zoo`,
        role: p.role,
      })),
    },
    {
      site: "gitea.zoo",
      description: "Git repository hosting",
      users: personas.map((p) => ({
        username: p.username,
        password: p.password,
        email: `${p.username}@snappymail.zoo`,
        role: p.role === "admin" ? "admin" : "user",
      })),
    },
    {
      site: "snappymail.zoo",
      description: "Webmail client",
      admin: { ...admins.snappymail, note: "Admin panel at /?admin" },
      users: personas.map((p) => ({
        username: `${p.username}@snappymail.zoo`,
        password: p.password,
      })),
    },
    {
      site: "miniflux.zoo",
      description: "RSS feed reader",
      admin: {
        ...admins.miniflux,
        note: "Created by CREATE_ADMIN; the admin persona's password is not applied",
      },
      users: personas
        .filter((p) => p.username !== "admin")
        .map((p) => ({
          username: p.username,
          password: p.password,
          note: "Can also login via OAuth through auth.zoo",
        })),
    },
    {
      site: "focalboard.zoo",
      description: "Project management and kanban boards",
      users: personas.map((p) => ({
        username: p.username,
        password: minLengthPassword(p.password),
        email: `${p.username}@snappymail.zoo`,
      })),
    },
    {
      site: "classifieds.zoo",
      description: "Classified ads marketplace (VWA)",
      users: [
        {
          username: "blake.sullivan@gmail.com",
          password: "Password.123",
          note: "Pre-seeded VWA user",
        },
      ],
    },
    {
      site: "paste.zoo",
      description: "Self-hosted pastebin (Microbin)",
      admin: admins.microbin,
      users: [],
    },
    {
      site: "northwind.zoo",
      description: "Northwind database with phpMyAdmin",
      admin: {
        username: "northwind_user",
        password: "northwind_pw",
        note: "Auto-logged in via PMA_USER/PMA_PASSWORD",
      },
      users: [],
    },
    {
      site: "onestopshop.zoo",
      description: "E-commerce site (VWA)",
      admin: {
        username: "admin",
        password: "admin1234",
        note: "Magento admin panel",
      },
      users: [
        {
          username: "emma.lopez@gmail.com",
          password: "Password.123",
          note: "Pre-seeded VWA user",
        },
      ],
    },
    {
      site: "postmill.zoo",
      description: "Reddit-like forum (VWA)",
      users: [
        {
          username: "MarvelsGrantMan136",
          password: "test1234",
          note: "Pre-seeded VWA user",
        },
      ],
    },
    {
      site: "mail-api.zoo",
      description: "Stalwart mail server API",
      admin: admins.stalwart,
      users: [],
    },
    {
      site: "mattermost.zoo",
      description: "Team messaging and collaboration",
      users: personas.map((p) => {
        const teams = ["zoo"];
        if (platformTeamMembers.includes(p.username)) {
          teams.push("platform");
        }
        return {
          username: p.username,
          password: minLengthPassword(p.password),
          email: `${p.username}@snappymail.zoo`,
          role: p.role === "admin" ? "admin" : "user",
          note: `Member of ${teams.join(", ")} team${teams.length > 1 ? "s" : ""}`,
        };
      }),
    },
  ];

  for (const site of siteCredentials) {
    const filePath = join(credentialsDir, `${site.site}.yaml`);
    writeFileSync(filePath, stringify(site));
    console.log(`  ✓ ${site.site}.yaml`);
  }

  console.log(`\n✅ Credential files written to docs/credentials/\n`);
}

// Run the main function
main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
