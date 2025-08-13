import { execSync } from "node:child_process";
import { fetchWithProxy } from "../../tests/utils/http-client";
import type { Persona } from "./personas";

export interface AppSeeder {
  name: string;
  description: string;
  seed: (persona: Persona) => Promise<void>;
}

// Helper to run commands in containers
async function execDocker(container: string, command: string): Promise<string> {
  try {
    return execSync(`docker compose exec -T ${container} ${command}`, {
      encoding: "utf8",
    });
  } catch {
    // Some commands may fail if user already exists, which is ok
    return "";
  }
}

export const apps: Record<string, AppSeeder> = {
  "auth.zoo": {
    name: "auth.zoo",
    description: "Authentication service",
    seed: async (persona: Persona) => {
      // Use auth.zoo's API to create users
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
        console.log(`✓ Created ${persona.username} in auth.zoo`);
      } else if (result.httpCode === 409) {
        console.log(`✓ ${persona.username} already exists in auth.zoo`);
      } else {
        console.error(`Failed to create ${persona.username} in auth.zoo: ${result.body}`);
      }
    },
  },

  "gitea.zoo": {
    name: "gitea.zoo",
    description: "Git repository hosting",
    seed: async (persona: Persona) => {
      const isAdmin = persona.role === "admin" ? "--admin" : "";

      await execDocker(
        "gitea-zoo",
        `su git -c "gitea admin user create --username '${persona.username}' ` +
          `--password '${persona.password}' --email '${persona.username}@gitea.zoo' ` +
          `${isAdmin} --must-change-password=false || true"`,
      );

      console.log(`✓ Created ${persona.username} in gitea.zoo`);
    },
  },

  "snappymail.zoo": {
    name: "snappymail.zoo",
    description: "Webmail client",
    seed: async (persona: Persona) => {
      // SnappyMail uses email accounts, so we create domain-specific email
      const snappyEmail = `${persona.username}@snappymail.zoo`;
      const adminPassword = "zoo-mail-admin-pw";
      const auth = Buffer.from(`admin:${adminPassword}`).toString("base64");

      // First ensure domain exists
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

      // Then create user
      const result = await fetchWithProxy("https://mail-api.zoo/api/principal", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Basic ${auth}`,
        },
        body: JSON.stringify({
          type: "individual",
          name: snappyEmail,
          description: persona.fullName,
          secrets: [persona.password],
          emails: [snappyEmail],
          quota: 0,
          roles: ["user"],
        }),
      });

      if (result.httpCode === 200 || result.httpCode === 201) {
        console.log(`✓ Created ${snappyEmail} for SnappyMail`);
      } else if (result.httpCode === 409) {
        console.log(`✓ ${snappyEmail} already exists`);
      } else {
        console.error(`Failed to create ${snappyEmail}: ${result.body}`);
      }
    },
  },

  "miniflux.zoo": {
    name: "miniflux.zoo",
    description: "RSS feed reader with OAuth",
    seed: async (persona: Persona) => {
      // Step 1: Ensure user exists in auth.zoo (OAuth provider)
      await apps["auth.zoo"].seed(persona);

      // Step 2: Create user in Miniflux using API
      // Note: This requires admin credentials for Miniflux API
      const adminAuth = Buffer.from("admin:zoopassword").toString("base64");

      const result = await fetchWithProxy("https://miniflux.zoo/v1/users", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Basic ${adminAuth}`,
        },
        body: JSON.stringify({
          username: persona.username,
          password: persona.password,
          is_admin: persona.role === "admin",
        }),
      });

      if (result.httpCode === 201) {
        console.log(`✓ Created ${persona.username} in miniflux.zoo`);
      } else if (result.httpCode === 409) {
        console.log(`✓ ${persona.username} already exists in miniflux.zoo`);
      } else if (result.httpCode === 401) {
        console.log(`⚠️  Miniflux not accessible or admin credentials incorrect`);
      } else {
        console.error(`Failed to create ${persona.username} in miniflux.zoo: ${result.body}`);
      }

      console.log(`✓ ${persona.username} can now login to miniflux.zoo via OAuth`);
    },
  },
};
