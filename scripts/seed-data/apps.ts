import { execSync } from "node:child_process";
import { fetchWithProxy } from "../../tests/utils/http-client";
import { minLengthPassword, type Persona } from "./personas";

// auth.zoo hashes the password and sends a welcome email before responding
const SEED_REQUEST_TIMEOUT = 15000;

export interface AppSeeder {
  name: string;
  description: string;
  seed: (persona: Persona) => Promise<void>;
}

// Run a command in a service container. Throws with the command's output on failure.
function execDocker(container: string, command: string): string {
  try {
    return execSync(`docker compose exec -T ${container} ${command}`, {
      encoding: "utf8",
      stdio: "pipe",
    });
  } catch (error) {
    const { stdout = "", stderr = "" } = error as { stdout?: string; stderr?: string };
    throw new Error(`${container}: ${command}\n${stdout}${stderr}`.trim());
  }
}

function psql(user: string, db: string, sql: string): string {
  return execDocker("postgres", `psql -U ${user} -d ${db} -t -A -c "${sql}"`).trim();
}

// auth.zoo user IDs are the OAuth subject that relying parties link accounts by
function authUserId(username: string): string {
  const id = psql("auth_user", "auth_db", `SELECT id FROM users WHERE username = '${username}';`);
  if (!id) {
    throw new Error(`${username} does not exist in auth.zoo`);
  }
  return id;
}

export const apps: Record<string, AppSeeder> = {
  "auth.zoo": {
    name: "auth.zoo",
    description: "Authentication service",
    seed: async (persona: Persona) => {
      // Use auth.zoo's API to create users
      const result = await fetchWithProxy("https://auth.zoo/api/users", {
        method: "POST",
        timeout: SEED_REQUEST_TIMEOUT,
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
        throw new Error(`HTTP ${result.httpCode} ${result.error || result.body}`);
      }
    },
  },

  "gitea.zoo": {
    name: "gitea.zoo",
    description: "Git repository hosting",
    seed: async (persona: Persona) => {
      const isAdmin = persona.role === "admin" ? "--admin" : "";

      try {
        execDocker(
          "gitea-zoo",
          `su git -c "gitea admin user create --username '${persona.username}' ` +
            `--password '${persona.password}' --email '${persona.username}@gitea.zoo' ` +
            `${isAdmin} --must-change-password=false"`,
        );
        console.log(`✓ Created ${persona.username} in gitea.zoo`);
      } catch (error) {
        if (!(error as Error).message.includes("already exists")) {
          throw error;
        }
        console.log(`✓ ${persona.username} already exists in gitea.zoo`);
      }

      // Link the Gitea account to auth.zoo for OAuth login
      const authUuid = authUserId(persona.username);
      const giteaId = psql(
        "gitea_user",
        "gitea_db",
        `SELECT id FROM public.\\"user\\" WHERE lower_name = '${persona.username}';`,
      );
      if (!giteaId) {
        throw new Error(`${persona.username} missing from gitea_db after create`);
      }

      psql(
        "gitea_user",
        "gitea_db",
        `INSERT INTO external_login_user (external_id, user_id, login_source_id, provider, email, name) ` +
          `SELECT '${authUuid}', ${giteaId}, 1, 'openidConnect', '${persona.username}@snappymail.zoo', '${persona.fullName.replace(/'/g, "''")}' ` +
          `WHERE NOT EXISTS (SELECT 1 FROM external_login_user WHERE external_id = '${authUuid}' AND login_source_id = 1);`,
      );
      console.log(`✓ Linked ${persona.username} in gitea.zoo to auth.zoo (${authUuid})`);
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

      // Stalwart answers 200 with {"data": id} on create and {"error": ...} otherwise
      const createPrincipal = async (principal: Record<string, unknown>) => {
        const result = await fetchWithProxy("https://mail-api.zoo/api/principal", {
          method: "POST",
          timeout: SEED_REQUEST_TIMEOUT,
          headers: {
            "Content-Type": "application/json",
            Authorization: `Basic ${auth}`,
          },
          body: JSON.stringify(principal),
        });
        const body = result.httpCode === 200 ? JSON.parse(result.body) : {};
        if (body.data !== undefined) {
          return "created";
        }
        if (body.error === "fieldAlreadyExists") {
          return "exists";
        }
        throw new Error(`HTTP ${result.httpCode} ${result.error || result.body}`);
      };

      await createPrincipal({
        type: "domain",
        name: "snappymail.zoo",
        description: "SnappyMail webmail domain",
      });

      const status = await createPrincipal({
        type: "individual",
        name: snappyEmail,
        description: persona.fullName,
        secrets: [persona.password],
        emails: [snappyEmail],
        quota: 0,
        roles: ["user"],
      });
      console.log(
        status === "created"
          ? `✓ Created ${snappyEmail} for SnappyMail`
          : `✓ ${snappyEmail} already exists`,
      );
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
        timeout: SEED_REQUEST_TIMEOUT,
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
      } else if (result.httpCode === 400 && result.body.includes("already exists")) {
        console.log(`✓ ${persona.username} already exists in miniflux.zoo`);
      } else {
        throw new Error(`HTTP ${result.httpCode} ${result.error || result.body}`);
      }

      // Miniflux maps an OIDC login to a user by openid_connect_id (the auth.zoo subject).
      // Without it, an OAuth login tries to create a duplicate user and fails.
      const authUuid = authUserId(persona.username);
      const updated = psql(
        "miniflux_user",
        "miniflux_db",
        `UPDATE users SET openid_connect_id = '${authUuid}' WHERE username = '${persona.username}';`,
      );
      if (updated !== "UPDATE 1") {
        throw new Error(`Linking ${persona.username} in miniflux_db: ${updated}`);
      }
      console.log(`✓ Linked ${persona.username} in miniflux.zoo to auth.zoo (${authUuid})`);
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
      const password = minLengthPassword(persona.password);

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

        // Reset password to ensure it's properly hashed (mmctl user create has a bug).
        // Only for new users, so re-seeding doesn't churn hashes and audit rows.
        execSync(
          `docker compose exec -T mattermost mmctl user change-password "${persona.username}" ` +
            `--password "${password}" --local 2>&1`,
          { encoding: "utf8", stdio: "pipe" },
        );
      } catch (error) {
        const output = String((error as { stdout?: string }).stdout ?? error);
        if (!/already exists|exists with/i.test(output)) {
          throw error;
        }
        console.log(`✓ ${persona.username} already exists in mattermost.zoo`);
      }

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
      const signupToken = psql(
        "focalboard_user",
        "focalboard_db",
        "SELECT signup_token FROM teams WHERE id = '0';",
      );
      if (!signupToken) {
        throw new Error("Failed to get Focalboard signup token");
      }

      // Register user using the API with the signup token
      const email = `${persona.username}@snappymail.zoo`;
      const result = await fetchWithProxy("https://focalboard.zoo/api/v2/register", {
        method: "POST",
        timeout: SEED_REQUEST_TIMEOUT,
        headers: {
          "Content-Type": "application/json",
          "X-Requested-With": "XMLHttpRequest",
        },
        body: JSON.stringify({
          username: persona.username,
          email: email,
          password: minLengthPassword(persona.password),
          token: signupToken,
        }),
      });

      if (result.httpCode === 200 || result.httpCode === 201) {
        console.log(`✓ Created ${persona.username} in focalboard.zoo`);
      } else if (result.body.includes("already exists") || result.body.includes("duplicate")) {
        console.log(`✓ ${persona.username} already exists in focalboard.zoo`);
      } else {
        throw new Error(`HTTP ${result.httpCode} ${result.error || result.body}`);
      }
    },
  },
};
