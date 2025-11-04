import { execSync } from "node:child_process";
import { fetchWithProxy } from "../../tests/utils/http-client";
import { personas } from "../seed-data/personas";
import type { AppSeeder, UniverseData } from "./types";

/**
 * Helper to run commands in containers
 */
async function execDocker(container: string, command: string): Promise<string> {
  try {
    return execSync(`docker compose exec -T ${container} ${command}`, {
      encoding: "utf8",
    });
  } catch {
    // Some commands may fail if resource already exists
    return "";
  }
}

/**
 * Seeder for auth.zoo - creates user accounts
 */
export const authSeeder: AppSeeder = {
  name: "auth.zoo",
  async load(_data: UniverseData, personaUsernames: string[]): Promise<void> {
    console.log("\n📝 Seeding auth.zoo users...");

    for (const username of personaUsernames) {
      const persona = personas.find((p) => p.username === username);
      if (!persona) {
        console.warn(`⚠️  Persona "${username}" not found, skipping`);
        continue;
      }

      const result = await fetchWithProxy("https://auth.zoo/api/users", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-API-Key": "zoo-seed-api-key",
        },
        body: JSON.stringify({
          username: persona.username,
          email: `${persona.username}@snappymail.zoo`,
          name: persona.fullName,
          password: persona.password,
        }),
      });

      if (result.httpCode === 201) {
        console.log(`  ✓ Created ${persona.username}`);
      } else if (result.httpCode === 409) {
        console.log(`  ✓ ${persona.username} already exists`);
      } else {
        console.error(
          `  ✗ Failed to create ${persona.username} (HTTP ${result.httpCode}): ${result.body || "No response"}`,
        );
      }
    }
  },
};

/**
 * Seeder for snappymail.zoo - creates email accounts and sends emails
 */
export const snappyMailSeeder: AppSeeder = {
  name: "snappymail.zoo",
  async load(data: UniverseData, personaUsernames: string[]): Promise<void> {
    console.log("\n📧 Seeding snappymail.zoo...");

    const adminPassword = "zoo-mail-admin-pw";
    const auth = Buffer.from(`admin:${adminPassword}`).toString("base64");

    // Ensure domain exists
    await fetchWithProxy("https://mail-api.zoo/api/principal", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Basic ${auth}`,
      },
      body: JSON.stringify({
        type: "domain",
        name: "snappymail.zoo",
        description: "SnappyMail webmail domain",
      }),
    });

    // Create email accounts for all personas
    for (const username of personaUsernames) {
      const persona = personas.find((p) => p.username === username);
      if (!persona) continue;

      const email = `${persona.username}@snappymail.zoo`;
      const result = await fetchWithProxy("https://mail-api.zoo/api/principal", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Basic ${auth}`,
        },
        body: JSON.stringify({
          type: "individual",
          name: email,
          description: persona.fullName,
          secrets: [persona.password],
          emails: [email],
          quota: 0,
          roles: ["user"],
        }),
      });

      if (result.httpCode === 200 || result.httpCode === 201) {
        console.log(`  ✓ Created email account ${email}`);
      } else if (result.httpCode === 409) {
        console.log(`  ✓ Email account ${email} already exists`);
      } else {
        console.error(`  ✗ Failed to create ${email}: ${result.body}`);
      }
    }

    // Send emails from universe data
    const emails = data.apps["snappymail.zoo"]?.emails || [];
    if (emails.length > 0) {
      console.log(`\n📬 Sending ${emails.length} email(s)...`);

      for (const email of emails) {
        try {
          // Send email via SMTP using swaks
          const toRecipients = Array.isArray(email.to) ? email.to.join(",") : email.to;
          const body = email.body.replace(/\n/g, "\\n"); // Escape newlines for command line

          const sendCommand = [
            "docker compose exec -T stalwart",
            "swaks",
            `--from "${email.from}"`,
            `--to "${toRecipients}"`,
            "--server localhost:25",
            `--header "Subject: ${email.subject}"`,
            `--body "${body}"`,
            email.html ? '--header "Content-Type: text/html"' : "",
          ]
            .filter(Boolean)
            .join(" ");

          const result = execSync(sendCommand, {
            encoding: "utf8",
            stdio: ["pipe", "pipe", "pipe"],
          });

          if (result.includes("250")) {
            console.log(`  ✓ Sent: "${email.subject}" to ${toRecipients}`);
          } else {
            console.error(`  ✗ Failed to send email: ${result}`);
          }
        } catch (error) {
          console.error(`  ✗ Error sending email "${email.subject}": ${error}`);
        }
      }
    }
  },
};

/**
 * Seeder for gitea.zoo - creates repositories
 */
export const giteaSeeder: AppSeeder = {
  name: "gitea.zoo",
  async load(data: UniverseData, personaUsernames: string[]): Promise<void> {
    console.log("\n🔧 Seeding gitea.zoo...");

    // Create user accounts in Gitea
    for (const username of personaUsernames) {
      const persona = personas.find((p) => p.username === username);
      if (!persona) continue;

      const isAdmin = persona.role === "admin" ? "--admin" : "";
      await execDocker(
        "gitea-zoo",
        `su git -c "gitea admin user create --username '${persona.username}' ` +
          `--password '${persona.password}' --email '${persona.username}@gitea.zoo' ` +
          `${isAdmin} --must-change-password=false || true"`,
      );

      console.log(`  ✓ Created user ${persona.username}`);
    }

    // Create repositories from universe data
    const repositories = data.apps["gitea.zoo"]?.repositories || [];
    if (repositories.length > 0) {
      console.log(`\n📦 Creating ${repositories.length} repositor(y/ies)...`);

      for (const repo of repositories) {
        try {
          // Find owner persona for authentication
          const ownerPersona = personas.find((p) => p.username === repo.owner);
          if (!ownerPersona) {
            console.error(`  ✗ Owner "${repo.owner}" not found in personas`);
            continue;
          }

          const auth = Buffer.from(`${repo.owner}:${ownerPersona.password}`).toString("base64");

          // Create repository via Gitea API
          const createResult = await fetchWithProxy(`https://gitea.zoo/api/v1/user/repos`, {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              Authorization: `Basic ${auth}`,
            },
            body: JSON.stringify({
              name: repo.name,
              description: repo.description || "",
              private: repo.private || false,
              auto_init: true, // Auto-initialize with README
              default_branch: repo.defaultBranch || "main",
            }),
          });

          if (createResult.httpCode === 201) {
            console.log(`  ✓ Created repository ${repo.owner}/${repo.name}`);

            // TODO: Add files if provided (skipped for now, will be implemented later)
            if (repo.files && repo.files.length > 0) {
              console.log(
                `    ℹ Skipping ${repo.files.length} file(s) (file creation not yet implemented)`,
              );
            }
          } else if (createResult.httpCode === 409) {
            console.log(`  ✓ Repository ${repo.owner}/${repo.name} already exists`);
          } else {
            console.error(
              `  ✗ Failed to create repository (HTTP ${createResult.httpCode}): ${createResult.body || "No response"}`,
            );
          }
        } catch (error) {
          console.error(`  ✗ Error creating repository ${repo.name}: ${error}`);
        }
      }
    }
  },
};

/**
 * All available seeders
 */
export const seeders: AppSeeder[] = [authSeeder, snappyMailSeeder, giteaSeeder];
