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

      // Link the Gitea account to auth.zoo for OAuth login
      const authUuid = (
        await execDocker(
          "postgres",
          `psql -U auth_user -d auth_db -t -c "SELECT id FROM users WHERE username = '${persona.username}';"`,
        )
      ).trim();
      const giteaId = (
        await execDocker(
          "postgres",
          `psql -U gitea_user -d gitea_db -t -c "SELECT id FROM public.\\\"user\\\" WHERE lower_name = '${persona.username}';"`,
        )
      ).trim();

      if (authUuid && giteaId) {
        await execDocker(
          "postgres",
          `psql -U gitea_user -d gitea_db -c "INSERT INTO external_login_user (external_id, user_id, login_source_id, provider, email, name) ` +
            `SELECT '${authUuid}', ${giteaId}, 1, 'openidConnect', '${persona.username}@snappymail.zoo', '${persona.fullName.replace(/'/g, "''")}' ` +
            `WHERE NOT EXISTS (SELECT 1 FROM external_login_user WHERE external_id = '${authUuid}' AND login_source_id = 1);"`,
        );
        console.log(`✓ Linked ${persona.username} in gitea.zoo to auth.zoo (${authUuid})`);
      }
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

  "mattermost.zoo": {
    name: "mattermost.zoo",
    description: "Team messaging and collaboration",
    seed: async (persona: Persona) => {
      // Use mmctl with --local flag (requires MM_SERVICESETTINGS_ENABLELOCALMODE=true)
      const email = `${persona.username}@snappymail.zoo`;
      const isAdmin = persona.role === "admin";
      const adminFlag = isAdmin ? "--system-admin" : "";
      // Mattermost requires 8+ character passwords, pad if needed
      const password = persona.password.padEnd(8, "!");

      // Disable plugins whose JS bundles have syntax errors in Firefox (SpiderMonkey).
      // Both NPS and Playbooks produce "SyntaxError: missing ) after argument list"
      // which shows a "A JavaScript error has occurred" banner on every page load.
      // The bundles parse fine in Node/V8 but fail in Firefox's JS engine.
      // Can't be done via env var because plugin IDs contain dots that conflict
      // with Mattermost's _-delimited env var config path format.
      for (const plugin of ["com.mattermost.nps", "playbooks"]) {
        try {
          execSync(
            `docker compose exec -T mattermost mmctl plugin disable ${plugin} --local 2>&1`,
            { encoding: "utf8", stdio: "pipe" },
          );
          console.log(`✓ Disabled ${plugin} plugin in mattermost.zoo`);
        } catch {
          // Plugin may already be disabled
        }
      }

      // Platform team members (engineering-focused subset)
      const platformTeamMembers = ["alice", "frank", "grace", "alex.chen", "blake.sullivan", "eve"];

      // Ensure the "zoo" team exists (idempotent - will fail silently if exists)
      try {
        execSync(
          `docker compose exec -T mattermost mmctl team create ` +
            `--name "zoo" --display-name "Zoo" --private=false --local 2>&1`,
          { encoding: "utf8", stdio: "pipe" },
        );
        console.log(`✓ Created team "zoo" in mattermost.zoo`);
      } catch {
        // Team already exists, which is fine
      }

      // Ensure the "platform" team exists (private engineering team)
      try {
        execSync(
          `docker compose exec -T mattermost mmctl team create ` +
            `--name "platform" --display-name "Platform Team" --private=true --local 2>&1`,
          { encoding: "utf8", stdio: "pipe" },
        );
        console.log(`✓ Created team "platform" in mattermost.zoo`);
      } catch {
        // Team already exists, which is fine
      }

      // Create the user
      try {
        execSync(
          `docker compose exec -T mattermost mmctl user create ` +
            `--email "${email}" ` +
            `--username "${persona.username}" ` +
            `--password "${password}" ` +
            `${adminFlag} --local 2>&1`,
          { encoding: "utf8", stdio: "pipe" },
        );
        console.log(`✓ Created ${persona.username} in mattermost.zoo`);
      } catch {
        console.log(`✓ ${persona.username} may already exist in mattermost.zoo`);
      }

      // Reset password to ensure it's properly hashed (mmctl user create has a bug)
      execSync(
        `docker compose exec -T mattermost mmctl user change-password "${persona.username}" ` +
          `--password "${password}" --local 2>&1`,
        { encoding: "utf8", stdio: "pipe" },
      );

      // Add user to the zoo team
      try {
        execSync(
          `docker compose exec -T mattermost mmctl team users add "zoo" "${persona.username}" --local 2>&1`,
          { encoding: "utf8", stdio: "pipe" },
        );
        console.log(`✓ Added ${persona.username} to team "zoo"`);
      } catch {
        // Already a member, which is fine
      }

      // Add engineering members to the platform team
      if (platformTeamMembers.includes(persona.username)) {
        try {
          execSync(
            `docker compose exec -T mattermost mmctl team users add "platform" "${persona.username}" --local 2>&1`,
            { encoding: "utf8", stdio: "pipe" },
          );
          console.log(`✓ Added ${persona.username} to team "platform"`);
        } catch {
          // Already a member, which is fine
        }
      }
    },
  },

  "focalboard.zoo": {
    name: "focalboard.zoo",
    description: "Project management and kanban boards",
    seed: async (persona: Persona) => {
      // Get the signup token from the database
      const tokenResult = await execDocker(
        "postgres",
        `psql -U focalboard_user -d focalboard_db -t -c "SELECT signup_token FROM teams WHERE id = '0';"`,
      );

      const signupToken = tokenResult.trim();
      if (!signupToken) {
        console.error("Failed to get Focalboard signup token");
        return;
      }

      // Register user using the API with the signup token
      const email = `${persona.username}@snappymail.zoo`;
      const result = await fetchWithProxy("https://focalboard.zoo/api/v2/register", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Requested-With": "XMLHttpRequest",
        },
        body: JSON.stringify({
          username: persona.username,
          email: email,
          password: persona.password,
          token: signupToken,
        }),
      });

      if (result.httpCode === 200 || result.httpCode === 201) {
        console.log(`✓ Created ${persona.username} in focalboard.zoo`);
      } else if (result.body.includes("already exists") || result.body.includes("duplicate")) {
        console.log(`✓ ${persona.username} already exists in focalboard.zoo`);
      } else {
        console.error(`Failed to create ${persona.username} in focalboard.zoo: ${result.body}`);
      }
    },
  },
};
