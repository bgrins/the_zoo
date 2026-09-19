import { Router, type Request, type Response } from "express";
import { hydraClient } from "../hydraClient.js";
import { userService } from "../userService.js";
import { emailService } from "../emailService.js";
import { renderPage, getScopeDescription } from "../utils/index.js";
import type { LoginRequest, ConsentRequest, AppInfo, User } from "../types.js";

const router = Router();

type Claims = Record<string, any>;

function userClaims(user: User): Claims {
  return {
    username: user.username,
    email: user.email,
    name: user.name,
    preferred_username: user.username,
    sub: user.id,
  };
}

// Hydra only carries the login context forward from an interactive login. When a login is
// skipped (existing Hydra session), the context is empty, so look the user up by subject.
async function claimsFor(subject: string, context: Claims | undefined): Promise<Claims> {
  if (context?.email && context.username) {
    return context;
  }
  const user = subject ? await userService.findById(subject) : undefined;
  return user ? userClaims(user) : context || {};
}

function idTokenClaims(subject: string, claims: Claims): Claims {
  const username = claims.username || claims.preferred_username;
  return {
    ...claims,
    sub: subject,
    email: claims.email,
    name: claims.name,
    preferred_username: username,
    username,
  };
}

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
          context: await claimsFor(loginRequest.subject, undefined),
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

    try {
      const acceptResult = await hydraClient.acceptLoginRequest(challenge, {
        subject: user.id,
        remember: true,
        remember_for: 3600,
        context: userClaims(user),
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
        const claims = await claimsFor(consentRequest.subject, consentRequest.context);
        const acceptResult = await hydraClient.acceptConsentRequest(consent_challenge, {
          grant_scope: consentRequest.requested_scope,
          grant_access_token_audience: consentRequest.requested_access_token_audience,
          remember: true,
          remember_for: 3600,
          session: {
            access_token: { ...claims },
            id_token: idTokenClaims(consentRequest.subject, claims),
          },
        });
        return res.redirect(acceptResult.redirect_to);
      }

      // Show consent form
      const userInfo = await claimsFor(consentRequest.subject, consentRequest.context);
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

      const consentRequest = await hydraClient.getConsentRequest(challenge);
      const userInfo = await claimsFor(consentRequest.subject, consentRequest.context);

      const acceptResult = await hydraClient.acceptConsentRequest(challenge, {
        grant_scope: scopes ? scopes.split(",") : consentRequest.requested_scope,
        grant_access_token_audience: consentRequest.requested_access_token_audience,
        remember: true,
        remember_for: 3600,
        session: {
          access_token: { ...userInfo },
          id_token: idTokenClaims(consentRequest.subject, userInfo),
        },
      });

      // Send app authorized email
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

const escapeHtml = (value: string) =>
  value.replace(
    /[&<>"']/g,
    (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c] as string,
  );

// Hydra redirects here (urls.error) when an OAuth2 request is invalid
router.get(
  "/error",
  (
    req: Request<
      Record<string, never>,
      any,
      any,
      { error?: string; error_description?: string; error_hint?: string }
    >,
    res: Response,
  ) => {
    const { error = "unknown_error", error_description, error_hint } = req.query;
    const content = `
      <div class="auth-container">
        <h1>Authorization Error</h1>
        <div class="error"><strong>${escapeHtml(error)}</strong></div>
        ${error_description ? `<p>${escapeHtml(error_description)}</p>` : ""}
        ${error_hint ? `<p class="text-muted">${escapeHtml(error_hint)}</p>` : ""}
        <p><a href="/" class="link">Return to homepage</a></p>
      </div>
    `;
    res.status(400).send(renderPage("Authorization Error", content, { hideNav: true }));
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
