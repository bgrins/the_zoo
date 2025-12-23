#!/usr/bin/env tsx

import { execSync } from "node:child_process";
import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { stringify } from "yaml";
import { personas } from "./seed-data/personas";
import { apps } from "./seed-data/apps";

const __dirname = dirname(fileURLToPath(import.meta.url));
const credentialsDir = join(__dirname, "../docs/credentials");

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
  ];

  const missing: string[] = [];
  const found: string[] = [];

  // Get list of running containers using docker compose
  try {
    const output = execSync(`docker compose ps --format json`, {
      encoding: "utf8",
    });

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
      execSync(`docker compose --profile on-demand up -d ${missing.join(" ")}`, {
        stdio: "inherit",
      });
      console.log(`✓ Started containers: ${missing.join(", ")}\n`);
    } catch (error) {
      console.error("❌ Failed to start containers:", error);
      process.exit(1);
    }
  }

  console.log(`✓ Found containers: ${found.join(", ")}\n`);

  // Seed each app with each persona
  for (const [appName, app] of Object.entries(apps)) {
    console.log(`\nSeeding ${appName}...`);

    for (const persona of personas) {
      try {
        await app.seed(persona);
      } catch (error) {
        console.error(`Failed to seed ${persona.username} in ${appName}:`, error);
      }
    }
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
        email: `${p.username}@gitea.zoo`,
        role: p.role === "admin" ? "admin" : "user",
      })),
    },
    {
      site: "snappymail.zoo",
      description: "Webmail client",
      admin: {
        username: "admin",
        password: "admin123",
        note: "Admin panel at /?admin",
      },
      users: personas.map((p) => ({
        username: `${p.username}@snappymail.zoo`,
        password: p.password,
      })),
    },
    {
      site: "miniflux.zoo",
      description: "RSS feed reader",
      admin: {
        username: "admin",
        password: "zoopassword",
      },
      users: personas.map((p) => ({
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
        password: p.password,
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
      admin: {
        username: "admin",
        password: "zoopassword",
      },
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
      admin: {
        username: "admin",
        password: "zoo-mail-admin-pw",
      },
      users: [],
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
