import { Router, type Request, type Response } from "express";
import { hydraClient } from "../hydraClient.js";
import { userService } from "../userService.js";
import { emailService } from "../emailService.js";
import { renderPage, getScopeDescription, userSessions } from "../utils/index.js";
import type { LoginRequest, ConsentRequest, AppInfo } from "../types.js";

const router = Router();

// OAuth2 login endpoint
router.get(
  "/login",
  async (
    req: Request<Record<string, never>, any, any, { login_challenge?: string }>,
    res: Response,
  ) => {
    const { login_challenge } = req.query;

    if (!login_challenge) {
      return res.status(400).send(
        renderPage(
          "Error",
          `
        <div class="auth-container">
          <h1>Error</h1>
          <div class="error">Missing login_challenge parameter</div>
        </div>
      `,
          { hideNav: true },
        ),
      );
    }

    try {
      const loginRequest = await hydraClient.getLoginRequest(login_challenge);

      // Auto-accept if skip is true
      if (loginRequest.skip) {
        const acceptResult = await hydraClient.acceptLoginRequest(login_challenge, {
          subject: loginRequest.subject,
          remember: true,
          remember_for: 3600,
        });
        return res.redirect(acceptResult.redirect_to);
      }

      // Show login form
      const content = `
      <div class="auth-container">
        <h1>Login to Zoo</h1>
        ${
          loginRequest.client
            ? `
          <div class="client-info">
            <strong>${loginRequest.client.client_name || loginRequest.client.client_id}</strong> is requesting access
          </div>
        `
            : ""
        }
        <form method="POST" action="/login">
          <input type="hidden" name="challenge" value="${login_challenge}">
          <div class="form-group">
            <label for="username">Username or Email</label>
            <input type="text" id="username" name="username" required autofocus>
          </div>
          <div class="form-group">
            <label for="password">Password</label>
            <input type="password" id="password" name="password" required>
          </div>
          <button type="submit">Login</button>
        </form>
        <div style="text-align: center; margin-top: 20px;">
          <span style="color: #666;">Don't have an account?</span> 
          <a href="/register" style="color: #007bff;">Sign up</a>
        </div>
      </div>
    `;

      res.send(renderPage("Login", content, { hideNav: true }));
    } catch (error) {
      console.error("Login error:", error);
      res.status(500).send(
        renderPage(
          "Error",
          `
        <div class="auth-container">
          <h1>Error</h1>
          <div class="error">Failed to process login request: ${error.message}</div>
        </div>
      `,
          { hideNav: true },
        ),
      );
    }
  },
);

// Handle OAuth2 login form submission
router.post(
  "/login",
  async (req: Request<Record<string, never>, any, LoginRequest>, res: Response) => {
    const { challenge, username, password } = req.body;

    // Validate credentials
    const user = await userService.findByUsernameOrEmail(username);
    const isValidPassword =
      user && (await userService.verifyPassword(password, user.password_hash));

    if (!isValidPassword || !challenge) {
      const content = `
      <div class="auth-container">
        <h1>Login Failed</h1>
        <div class="error">Invalid username or password</div>
        <form method="GET" action="/login">
          <input type="hidden" name="login_challenge" value="${challenge}">
          <button type="submit">Try Again</button>
        </form>
      </div>
    `;
      return res.status(401).send(renderPage("Login Failed", content, { hideNav: true }));
    }

    // Store user in session
    req.session.user = {
      id: user.id,
      username: user.username,
      name: user.name,
      email: user.email,
    };

    // Track user session
    userSessions.set(user.username, {
      loginTime: new Date(),
      lastActive: new Date(),
    });

    try {
      // Accept the login with user context
      const acceptResult = await hydraClient.acceptLoginRequest(challenge, {
        subject: user.id,
        remember: true,
        remember_for: 3600,
        context: {
          username: user.username,
          email: user.email,
          name: user.name,
          preferred_username: user.username,
          sub: user.id,
        },
      });
      res.redirect(acceptResult.redirect_to);
    } catch (error) {
      console.error("Error accepting login:", error);
      res.status(500).send(
        renderPage(
          "Error",
          `
        <div class="auth-container">
          <h1>Error</h1>
          <div class="error">Failed to complete login: ${error.message}</div>
        </div>
      `,
          { hideNav: true },
        ),
      );
    }
  },
);

// OAuth2 consent endpoint
router.get(
  "/consent",
  async (
    req: Request<Record<string, never>, any, any, { consent_challenge?: string }>,
    res: Response,
  ) => {
    const { consent_challenge } = req.query;

    if (!consent_challenge) {
      return res.status(400).send(
        renderPage(
          "Error",
          `
        <div class="auth-container">
          <h1>Error</h1>
          <div class="error">Missing consent_challenge parameter</div>
        </div>
      `,
          { hideNav: true },
        ),
      );
    }

    try {
      const consentRequest = await hydraClient.getConsentRequest(consent_challenge);

      // Auto-accept if skip is true or no new scopes
      if (
        consentRequest.skip ||
        !consentRequest.requested_scope ||
        consentRequest.requested_scope.length === 0
      ) {
        let sessionData = consentRequest.context || {};

        // Fetch user data if missing
        if (consentRequest.subject && (!sessionData.email || !sessionData.username)) {
          const user = await userService.findById(consentRequest.subject);
          if (user) {
            sessionData = {
              username: user.username,
              email: user.email,
              name: user.name,
              preferred_username: user.username,
              sub: user.id,
            };
          }
        }

        const acceptResult = await hydraClient.acceptConsentRequest(consent_challenge, {
          grant_scope: consentRequest.requested_scope,
          grant_access_token_audience: consentRequest.requested_access_token_audience,
          remember: true,
          remember_for: 3600,
          session: {
            access_token: { ...sessionData },
            id_token: {
              ...sessionData,
              sub: consentRequest.subject,
              email: sessionData.email,
              name: sessionData.name,
              preferred_username: sessionData.username || sessionData.preferred_username,
              username: sessionData.username || sessionData.preferred_username,
            },
          },
        });
        return res.redirect(acceptResult.redirect_to);
      }

      // Show consent form
      const userInfo = consentRequest.context || {};
      const username = userInfo.username || consentRequest.subject;

      const content = `
      <div class="auth-container" style="max-width: 500px; margin: 60px auto;">
        <h2>Authorize Application</h2>
        <div class="client-info">
          <p><strong>${consentRequest.client.client_name || consentRequest.client.client_id}</strong> is requesting access to your Zoo Identity account.</p>
          <p class="text-muted">Signed in as <strong>${username}</strong></p>
        </div>
        
        <div class="scope-list">
          <p><strong>This application will be able to:</strong></p>
          <ul>
            ${consentRequest.requested_scope
              .map(
                (scope) => `
              <li>${getScopeDescription(scope)}</li>
            `,
              )
              .join("")}
          </ul>
        </div>
        
        <form method="POST" action="/consent" style="margin-top: 32px;">
          <input type="hidden" name="challenge" value="${consent_challenge}">
          <input type="hidden" name="scopes" value="${consentRequest.requested_scope.join(",")}">
          <button type="submit" name="submit" value="accept">Allow Access</button>
          <button type="submit" name="submit" value="deny" class="secondary-button" style="margin-top: 12px;">
            Deny Access
          </button>
        </form>
      </div>
    `;

      const user = userInfo.username
        ? {
            name: userInfo.name || username,
            username: userInfo.username,
            email: userInfo.email || `${username}@zoo`,
          }
        : null;

      res.send(renderPage("Authorize Access", content, { user }));
    } catch (error) {
      console.error("Consent error:", error);
      res.status(500).send(
        renderPage(
          "Error",
          `
        <div class="auth-container">
          <h1>Error</h1>
          <div class="error">Failed to process consent request: ${error.message}</div>
        </div>
      `,
          { hideNav: true },
        ),
      );
    }
  },
);

// Handle consent form submission
router.post(
  "/consent",
  async (req: Request<Record<string, never>, any, ConsentRequest>, res: Response) => {
    const { challenge, submit, scopes } = req.body;

    try {
      if (submit === "deny") {
        const rejectResult = await hydraClient.rejectConsentRequest(
          challenge,
          "access_denied",
          "The user denied the consent request",
        );
        return res.redirect(rejectResult.redirect_to);
      }

      // Get consent request to get context
      const consentRequest = await hydraClient.getConsentRequest(challenge);

      // Accept the consent
      const acceptResult = await hydraClient.acceptConsentRequest(challenge, {
        grant_scope: scopes ? scopes.split(",") : consentRequest.requested_scope,
        grant_access_token_audience: consentRequest.requested_access_token_audience,
        remember: true,
        remember_for: 3600,
        session: {
          access_token: { ...consentRequest.context },
          id_token: {
            ...consentRequest.context,
            sub: consentRequest.subject,
            email: consentRequest.context?.email,
            name: consentRequest.context?.name,
            preferred_username:
              consentRequest.context?.username || consentRequest.context?.preferred_username,
            username:
              consentRequest.context?.username || consentRequest.context?.preferred_username,
          },
        },
      });

      // Send app authorized email
      const userInfo = consentRequest.context || {};
      if (userInfo.email) {
        const appInfo: AppInfo = {
          clientName: consentRequest.client.client_name || consentRequest.client.client_id,
          clientId: consentRequest.client.client_id,
          scopes: scopes ? scopes.split(",") : consentRequest.requested_scope,
        };
        await emailService.sendAppAuthorizedEmail(
          {
            id: consentRequest.subject,
            username: userInfo.username,
            email: userInfo.email,
            name: userInfo.name,
          },
          appInfo,
        );
      }

      res.redirect(acceptResult.redirect_to);
    } catch (error) {
      console.error("Error handling consent:", error);
      res.status(500).send(
        renderPage(
          "Error",
          `
        <div class="auth-container">
          <h1>Error</h1>
          <div class="error">Failed to process consent: ${error.message}</div>
        </div>
      `,
          { hideNav: true },
        ),
      );
    }
  },
);

// OAuth2 logout endpoint
router.get(
  "/logout",
  async (
    req: Request<Record<string, never>, any, any, { logout_challenge?: string }>,
    res: Response,
  ) => {
    const { logout_challenge } = req.query;

    if (!logout_challenge) {
      return res.redirect("/");
    }

    try {
      const acceptResult = await hydraClient.acceptLogoutRequest(logout_challenge);

      // Clear user session
      if (req.session.user) {
        userSessions.delete(req.session.user.username);
      }

      req.session.destroy(() => {
        res.redirect(acceptResult.redirect_to);
      });
    } catch (error) {
      console.error("Logout error:", error);
      res.redirect("/");
    }
  },
);

export default router;
