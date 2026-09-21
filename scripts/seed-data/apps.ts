import { fetchWithProxy } from "../lib/http-client";
import { adminCredentials } from "./admins";
import { giteaApi, mattermostLocalApi } from "./api";
import { seedGiteaContent, seedMattermostContent } from "./content-seeders";
import { execDocker, mmctl, outputOf, psql, SEED_REQUEST_TIMEOUT } from "./exec";
import { minLengthPassword, type Persona, personaId, platformTeamMembers } from "./personas";

export interface AppSeeder {
  name: string;
  description: string;
  seed: (persona: Persona) => Promise<void>;
  // Content shared by the personas, seeded once they all exist
  seedContent?: () => Promise<void>;
}

// Mattermost has first and last names; the last word of the full name is the last name
function splitName(fullName: string): { first_name: string; last_name: string } {
  const at = fullName.lastIndexOf(" ");
  return { first_name: fullName.slice(0, at), last_name: fullName.slice(at + 1) };
}

export const apps: Record<string, AppSeeder> = {
  "auth.zoo": {
    name: "auth.zoo",
    description: "Authentication service",
    seed: async (persona: Persona) => {
      const id = personaId(persona.username);
      const result = await fetchWithProxy("https://auth.zoo/api/users", {
        method: "POST",
        timeout: SEED_REQUEST_TIMEOUT,
        headers: {
          "Content-Type": "application/json",
          "X-API-Key": "zoo-seed-api-key",
        },
        body: JSON.stringify({
          id,
          username: persona.username,
          email: `${persona.username}@snappymail.zoo`,
          name: persona.fullName,
          password: persona.password,
        }),
      });

      if (result.httpCode === 201) {
        // An auth.zoo image that predates the id field ignores it
        const created = JSON.parse(result.body).data.id;
        if (created !== id) {
          throw new Error(`auth.zoo created ${persona.username} as ${created}, not ${id}`);
        }
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
            `--password '${persona.password}' --email '${persona.username}@snappymail.zoo' ` +
            `${isAdmin} --must-change-password=false"`,
        );
        console.log(`✓ Created ${persona.username} in gitea.zoo`);
      } catch (error) {
        if (!outputOf(error).includes("already exists")) {
          throw error;
        }
        console.log(`✓ ${persona.username} already exists in gitea.zoo`);
      }

      // Link the Gitea account to auth.zoo for OAuth login
      const authUuid = personaId(persona.username);
      const giteaId = psql(
        "gitea_user",
        "gitea_db",
        `SELECT id FROM public."user" WHERE lower_name = '${persona.username}';`,
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

      // Editing a user rewrites updated_unix, so only when the name differs
      const user = await giteaApi("GET", `/users/${persona.username}`);
      if (user.full_name !== persona.fullName) {
        await giteaApi("PATCH", `/admin/users/${persona.username}`, {
          as: "admin",
          body: { full_name: persona.fullName, source_id: 0 },
        });
        console.log(`✓ Set ${persona.username}'s full name in gitea.zoo`);
      }
    },
    seedContent: seedGiteaContent,
  },

  "snappymail.zoo": {
    name: "snappymail.zoo",
    description: "Webmail client",
    seed: async (persona: Persona) => {
      // SnappyMail uses email accounts, so we create domain-specific email
      const snappyEmail = `${persona.username}@snappymail.zoo`;
      const admin = adminCredentials().stalwart;
      const auth = Buffer.from(`${admin.username}:${admin.password}`).toString("base64");

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
      const admin = adminCredentials().miniflux;
      const adminAuth = Buffer.from(`${admin.username}:${admin.password}`).toString("base64");

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
      const authUuid = personaId(persona.username);
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
      const email = `${persona.username}@snappymail.zoo`;
      const isAdmin = persona.role === "admin";
      const adminFlag = isAdmin ? "--system-admin" : "";
      const password = minLengthPassword(persona.password);

      // Disable plugins whose JS bundles have syntax errors in Firefox (SpiderMonkey).
      // Both NPS and Playbooks produce "SyntaxError: missing ) after argument list"
      // which shows a "A JavaScript error has occurred" banner on every page load.
      // The bundles parse fine in Node/V8 but fail in Firefox's JS engine.
      // Calls needs WebRTC, which can't leave the zoo's proxy, and rewrites its bot user on
      // every start.
      // Can't be done via env var because plugin IDs contain dots that conflict
      // with Mattermost's _-delimited env var config path format.
      for (const plugin of ["com.mattermost.nps", "playbooks", "com.mattermost.calls"]) {
        if (mmctl(`plugin disable ${plugin}`, /Plugin is not installed\./)) {
          console.log(`✓ Disabled ${plugin} plugin in mattermost.zoo`);
        }
      }

      const teamExists = /A team with this URL already exists\./;
      if (mmctl(`team create --name "zoo" --display-name "Zoo" --private=false`, teamExists)) {
        console.log(`✓ Created team "zoo" in mattermost.zoo`);
      }
      if (
        mmctl(
          `team create --name "platform" --display-name "Platform Team" --private=true`,
          teamExists,
        )
      ) {
        console.log(`✓ Created team "platform" in mattermost.zoo`);
      }

      const created = mmctl(
        `user create --email "${email}" --username "${persona.username}" ` +
          `--password "${password}" ${adminFlag}`,
        /An account with that (username|email) already exists\./,
      );
      console.log(
        created
          ? `✓ Created ${persona.username} in mattermost.zoo`
          : `✓ ${persona.username} already exists in mattermost.zoo`,
      );

      // mmctl user create can store a hash the login check rejects; reset the password when
      // the user is new or can't log in. Skipping it otherwise keeps re-seeding from churning
      // password hashes. The probe's session is logged out again, its audit rows stay out of
      // captures (see docs/golden-state.md), and the login times it writes are put back.
      const loginTimes = psql(
        "mattermost_user",
        "mattermost_db",
        `SELECT 'updateat = ' || updateat || ', lastlogin = ' || lastlogin FROM users WHERE username = '${persona.username}';`,
      );
      const login = await fetchWithProxy("https://mattermost.zoo/api/v4/users/login", {
        method: "POST",
        timeout: SEED_REQUEST_TIMEOUT,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ login_id: persona.username, password }),
      });
      if (login.httpCode === 200) {
        const logout = await fetchWithProxy("https://mattermost.zoo/api/v4/users/logout", {
          method: "POST",
          timeout: SEED_REQUEST_TIMEOUT,
          headers: { Authorization: `Bearer ${login.headers.token}` },
        });
        if (logout.httpCode !== 200) {
          throw new Error(`Mattermost logout for ${persona.username} failed: ${logout.httpCode}`);
        }
        if (!created) {
          psql(
            "mattermost_user",
            "mattermost_db",
            `UPDATE users SET ${loginTimes} WHERE username = '${persona.username}';`,
          );
        }
      }
      if (created || login.httpCode !== 200) {
        mmctl(`user change-password "${persona.username}" --password "${password}"`);
        console.log(`✓ Reset ${persona.username}'s password in mattermost.zoo`);
      }

      // Adding an existing member succeeds without changes
      mmctl(`team users add "zoo" "${persona.username}"`);
      console.log(`✓ ${persona.username} is in team "zoo"`);
      if (platformTeamMembers.includes(persona.username)) {
        mmctl(`team users add "platform" "${persona.username}"`);
        console.log(`✓ ${persona.username} is in team "platform"`);
      }

      // An update rewrites update_at, so only when the names differ. Local mode has no patch.
      const names = splitName(persona.fullName);
      const user = mattermostLocalApi("GET", `/users/username/${persona.username}`);
      if (user.first_name !== names.first_name || user.last_name !== names.last_name) {
        mattermostLocalApi("PUT", `/users/${user.id}`, { ...user, ...names });
        console.log(`✓ Set ${persona.username}'s name in mattermost.zoo`);
      }
    },
    seedContent: seedMattermostContent,
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
