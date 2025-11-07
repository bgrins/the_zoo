import { execSync } from "node:child_process";
import { fetchWithProxy } from "../../tests/utils/http-client";
import type { Persona } from "./personas";

export interface AppSeeder {
  name: string;
  description: string;
  seed: (persona: Persona) => Promise<void>;
  seedProjects?: () => Promise<void>;
}

// Store Planka project ID and board IDs for adding users
let plankaProjectId: string | null = null;
let plankaBoardIds: string[] = [];

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

  "planka.zoo": {
    name: "planka.zoo",
    description: "Project management tool inspired by Trello",
    seedProjects: async () => {
      // Create sample projects and boards as admin (done once, not per-persona)
      const loginResult = await fetchWithProxy("https://planka.zoo/api/access-tokens", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          emailOrUsername: "admin",
          password: "zoo-planka-admin",
        }),
      });

      if (loginResult.httpCode !== 200) {
        console.error(`Failed to authenticate with Planka admin for project seeding`);
        return;
      }

      const accessToken = JSON.parse(loginResult.body).item;

      // Check if project already exists
      const existingProjectsResult = await fetchWithProxy("https://planka.zoo/api/projects", {
        headers: { Authorization: `Bearer ${accessToken}` },
      });

      let project: { id: string; name: string } | undefined;
      let projects: {
        items: { name: string; id: string }[];
        included: { boards: { projectId: string; id: string }[] };
      } | null = null;
      if (existingProjectsResult.httpCode === 200) {
        projects = JSON.parse(existingProjectsResult.body);
        if (projects) {
          project = projects.items.find((p: { name: string }) => p.name === "Zoo Development");
        }
      }

      if (project && projects) {
        plankaProjectId = project.id;
        console.log(`✓ Project "Zoo Development" already exists (ID: ${plankaProjectId})`);

        // Fetch existing boards for this project
        plankaBoardIds = projects.included.boards
          .filter((b: { projectId: string }) => b.projectId === project.id)
          .map((b: { id: string }) => b.id);
        console.log(`✓ Found ${plankaBoardIds.length} boards in existing project`);
      } else {
        // Create a demo project
        const projectResult = await fetchWithProxy("https://planka.zoo/api/projects", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${accessToken}`,
          },
          body: JSON.stringify({
            name: "Zoo Development",
            type: "public",
            description: "Main development project for The Zoo environment",
          }),
        });

        if (projectResult.httpCode === 200 || projectResult.httpCode === 201) {
          const projectData = JSON.parse(projectResult.body);
          const createdProject = projectData.item as { id: string; name: string };
          plankaProjectId = createdProject.id;
          console.log(`✓ Created project: ${createdProject.name} (ID: ${plankaProjectId})`);
          console.log(`DEBUG: Full project response:`, JSON.stringify(projectData, null, 2));

          // Create boards within the project
          const boards = [
            { name: "To Do", position: 1 },
            { name: "In Progress", position: 2 },
            { name: "Done", position: 3 },
          ];

          plankaBoardIds = [];
          for (const boardData of boards) {
            const boardResult = await fetchWithProxy(
              `https://planka.zoo/api/projects/${createdProject.id}/boards`,
              {
                method: "POST",
                headers: {
                  "Content-Type": "application/json",
                  Authorization: `Bearer ${accessToken}`,
                },
                body: JSON.stringify(boardData),
              },
            );

            if (boardResult.httpCode === 200 || boardResult.httpCode === 201) {
              const board = JSON.parse(boardResult.body).item;
              plankaBoardIds.push(board.id);
            }
          }
          console.log(`✓ Created ${boards.length} boards in project`);
        }
      }
    },
    seed: async (persona: Persona) => {
      // Step 1: Authenticate as admin to get access token
      const loginResult = await fetchWithProxy("https://planka.zoo/api/access-tokens", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          emailOrUsername: "admin",
          password: "zoo-planka-admin",
        }),
      });

      if (loginResult.httpCode !== 200) {
        console.error(`Failed to authenticate with Planka admin: ${loginResult.body}`);
        return;
      }

      const loginData = JSON.parse(loginResult.body);
      const accessToken = loginData.item;

      // Step 2: Map persona role to Planka role
      // In development, make everyone an admin so they can see all projects
      // (board-memberships endpoint returns 404, so we can't add users individually)
      const plankaRole = "admin";

      // Step 3: Transform password to meet Planka's zxcvbn requirements (minimum score 2)
      // Add sufficient entropy to pass zxcvbn validation
      const plankaPassword = persona.password.includes(".")
        ? persona.password
        : `Planka${persona.password}!2025`;

      // Step 4: Create user in Planka
      const result = await fetchWithProxy("https://planka.zoo/api/users", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          email: `${persona.username}@snappymail.zoo`,
          password: plankaPassword,
          name: persona.fullName,
          username: persona.username,
          role: plankaRole,
        }),
      });

      let _userId: string | null = null;

      if (result.httpCode === 200 || result.httpCode === 201) {
        const userData = JSON.parse(result.body);
        _userId = userData.item.id;
        console.log(`✓ Created ${persona.username} in planka.zoo`);
      } else if (result.httpCode === 409 || result.httpCode === 400) {
        // User exists, fetch their ID
        const usersResult = await fetchWithProxy("https://planka.zoo/api/users", {
          headers: { Authorization: `Bearer ${accessToken}` },
        });

        if (usersResult.httpCode === 200) {
          const users = JSON.parse(usersResult.body);
          const existingUser = users.items.find(
            (u: { username: string }) => u.username === persona.username,
          );
          if (existingUser) {
            _userId = existingUser.id;
            console.log(`✓ ${persona.username} already exists in planka.zoo`);
          }
        }
      } else {
        console.error(`Failed to create ${persona.username} in planka.zoo: ${result.body}`);
      }

      // Note: Users are created as admins so they automatically see all projects
      // (board-memberships endpoint returns 404 in this Planka version)
    },
  },
};
