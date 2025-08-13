import { Router, type Request, type Response } from "express";
import { readFileSync } from "node:fs";
import { requireAuth } from "../middleware.js";
import { hydraClient } from "../hydraClient.js";
import { userService } from "../userService.js";
import { emailService } from "../emailService.js";
import { renderPage, formatDomainName } from "../utils/index.js";
import type { SessionUser, Site, SitesData } from "../types.js";

const router = Router();

// Dashboard - shows logged in user and connected apps
router.get("/dashboard", requireAuth, async (req: Request, res: Response) => {
  const user = req.session.user as SessionUser;
  const connectedApps = await getConnectedApps(user.id);

  const content = `
    <div class="container" style="padding: 40px 20px;">
      <h1>Welcome to Your Zoo Identity</h1>
      
      <div class="dashboard-grid">
        <div class="profile-section">
          <h2>👤 Your Profile</h2>
          <div class="info-card">
            <p><strong>Name:</strong> ${user.name}</p>
            <p><strong>Username:</strong> ${user.username}</p>
            <p><strong>Email:</strong> ${user.email}</p>
            <div style="margin-top: 20px;">
              <a href="/profile" class="link">Edit Profile →</a>
            </div>
          </div>
        </div>
        
        <div class="apps-section">
          <h2>🔐 Connected Applications</h2>
          ${
            connectedApps.length > 0
              ? `
            <div class="connected-apps">
              ${connectedApps
                .map(
                  (app) => `
                <div class="app-item">
                  <div>
                    <strong>${app.clientName}</strong>
                    <div class="text-muted" style="font-size: 14px;">
                      Authorized: ${new Date(app.consentedAt).toLocaleDateString()}
                    </div>
                    <div class="text-muted" style="font-size: 13px;">
                      Permissions: ${app.scopes.join(", ")}
                    </div>
                  </div>
                  <form method="POST" action="/revoke-app" style="margin: 0;">
                    <input type="hidden" name="clientId" value="${app.clientId}">
                    <button type="submit" class="revoke-button">Revoke</button>
                  </form>
                </div>
              `,
                )
                .join("")}
            </div>
          `
              : `
            <p class="text-muted">No applications connected yet.</p>
          `
          }
        </div>
      </div>
      
      <div style="margin-top: 40px; text-align: center;">
        <a href="/explore" class="link">Explore Zoo Apps →</a>
      </div>
    </div>
  `;

  res.send(renderPage("Dashboard", content, { user }));
});

// Profile page
router.get("/profile", requireAuth, async (req: Request, res: Response) => {
  const user = req.session.user as SessionUser;
  const error = req.query.error as string;

  const content = `
    <div class="container" style="padding: 40px 20px; max-width: 600px; margin: 0 auto;">
      <h1>Profile Settings</h1>
      
      ${
        error === "email-taken"
          ? `
        <div class="error" style="margin-bottom: 20px;">
          Email address is already in use by another account
        </div>
      `
          : ""
      }
      
      <form method="POST" action="/profile" style="margin-top: 30px;">
        <h2>Personal Information</h2>
        <div class="form-group">
          <label for="name">Full Name</label>
          <input type="text" id="name" name="name" value="${user.name}" required>
        </div>
        <div class="form-group">
          <label for="email">Email</label>
          <input type="email" id="email" name="email" value="${user.email}" required>
        </div>
        <button type="submit">Update Profile</button>
      </form>
      
      <form method="POST" action="/change-password" style="margin-top: 40px;">
        <h2>Change Password</h2>
        <div class="form-group">
          <label for="currentPassword">Current Password</label>
          <input type="password" id="currentPassword" name="currentPassword" required>
        </div>
        <div class="form-group">
          <label for="newPassword">New Password</label>
          <input type="password" id="newPassword" name="newPassword" required minlength="8">
        </div>
        <div class="form-group">
          <label for="confirmNewPassword">Confirm New Password</label>
          <input type="password" id="confirmNewPassword" name="confirmNewPassword" required minlength="8">
        </div>
        <button type="submit">Change Password</button>
      </form>
      
      <div style="text-align: center; margin-top: 30px;">
        <a href="/dashboard" style="text-decoration: none; color: #007bff;">← Back to Dashboard</a>
      </div>
    </div>
  `;

  res.send(renderPage("Profile", content, { user }));
});

// Explore apps page
router.get("/explore", async (req: Request, res: Response) => {
  // Load app metadata from SITES.yaml
  let sites: Site[] = [];
  try {
    const sitesYaml = readFileSync(new URL("../SITES.yaml", import.meta.url), "utf8");
    const yaml = await import("yaml");
    const sitesData: SitesData = yaml.parse(sitesYaml);
    sites = sitesData.sites || [];
  } catch (error) {
    console.error("Error loading SITES.yaml:", error);
  }

  // Filter OAuth-enabled apps and other apps
  const oauthApps = sites.filter((site) => site.hasOAuth && site.domain !== "auth.zoo");
  const otherApps = sites.filter((site) => !site.hasOAuth && site.domain !== "auth.zoo");

  const content = `
    <div class="container" style="padding: 40px 20px;">
      <h1>🦁 Explore Zoo Applications</h1>
      <p class="text-muted">Discover all the applications available in the Zoo ecosystem</p>
      
      <div class="section">
        <h2>🔐 OAuth-Enabled Apps</h2>
        <p class="text-muted">Sign in to these apps with your Zoo Identity</p>
        <div class="app-grid" style="margin-top: 20px;">
          ${oauthApps
            .map(
              (site) => `
            <a href="http://${site.domain}" class="app-card">
              <div class="app-icon">${site.icon || "🌐"}</div>
              <div class="app-name">${formatDomainName(site.domain)}</div>
              <div class="app-description">${site.description || "Zoo application"}</div>
            </a>
          `,
            )
            .join("")}
        </div>
      </div>
      
      <div class="section">
        <h2>🌟 Other Zoo Apps</h2>
        <p class="text-muted">These apps have their own authentication or are publicly accessible</p>
        <div class="app-grid" style="margin-top: 20px;">
          ${otherApps
            .map(
              (site) => `
            <a href="http://${site.domain}" class="app-card">
              <div class="app-icon">${site.icon || "🌐"}</div>
              <div class="app-name">${formatDomainName(site.domain)}</div>
              <div class="app-description">${site.description || "Zoo application"}</div>
            </a>
          `,
            )
            .join("")}
        </div>
      </div>
    </div>
  `;

  res.send(renderPage("Explore Zoo Apps", content, { user: req.session.user }));
});

// Update profile
router.post("/profile", requireAuth, async (req: Request, res: Response) => {
  const { email, name } = req.body;
  const user = req.session.user as SessionUser;

  try {
    // Check if email is taken by another user
    const existingEmail = await userService.findByEmail(email);
    if (existingEmail && existingEmail.id !== user.id) {
      res.redirect("/profile?error=email-taken");
      return;
    }

    const updatedUser = await userService.update(user.id, {
      email,
      name,
    });

    // Update session
    req.session.user = {
      id: updatedUser.id,
      username: updatedUser.username,
      name: updatedUser.name,
      email: updatedUser.email,
    };

    res.redirect("/profile?success=profile-updated");
  } catch (error) {
    console.error("Profile update error:", error);
    res.redirect("/profile?error=update-failed");
  }
});

// Change password
router.post("/change-password", requireAuth, async (req: Request, res: Response) => {
  const { currentPassword, newPassword, confirmNewPassword } = req.body;
  const sessionUser = req.session.user as SessionUser;

  // Validate new passwords match
  if (newPassword !== confirmNewPassword) {
    res.redirect("/profile?error=passwords-mismatch");
    return;
  }

  try {
    // Verify current password
    const user = await userService.findById(sessionUser.id);
    if (!user) {
      res.redirect("/profile?error=user-not-found");
      return;
    }

    const isValidPassword = await userService.verifyPassword(currentPassword, user.password_hash);

    if (!isValidPassword) {
      res.redirect("/profile?error=invalid-password");
      return;
    }

    // Update password
    await userService.changePassword(sessionUser.id, newPassword);

    // Send password changed email notification
    await emailService.sendPasswordChangedEmail(sessionUser);

    res.redirect("/profile?success=password-changed");
  } catch (error) {
    console.error("Password change error:", error);
    res.redirect("/profile?error=password-change-failed");
  }
});

// Revoke app access
router.post("/revoke-app", requireAuth, async (req: Request, res: Response) => {
  const { clientId } = req.body;
  const userId = (req.session.user as SessionUser).id;

  try {
    // Get app info before revoking
    const apps = await getConnectedApps(userId);
    const appToRevoke = apps.find((app) => app.clientId === clientId);

    // Revoke all consent sessions for this client and user
    await hydraClient.revokeConsentSessions(userId, clientId);

    // Send email notification about revoked app
    if (appToRevoke) {
      await emailService.sendAppRevokedEmail(req.session.user as SessionUser, appToRevoke);
    }
  } catch (error) {
    console.error("Error revoking consent:", error);
  }

  // TODO: In production, should also revoke tokens via Hydra's API
  res.redirect("/dashboard");
});

// Helper functions
async function getConnectedApps(userId: string): Promise<any[]> {
  try {
    const consentSessions = await hydraClient.getConsentSessions(userId);

    return consentSessions.map((session: any) => ({
      clientId: session.consent_request.client.client_id,
      clientName:
        session.consent_request.client.client_name || session.consent_request.client.client_id,
      scopes: session.granted_scope || [],
      consentedAt: session.handled_at || session.requested_at,
      lastUsed: session.handled_at || session.requested_at,
    }));
  } catch (error) {
    console.error("Error fetching consent sessions:", error);
    return [];
  }
}

export default router;
