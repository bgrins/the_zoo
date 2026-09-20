import { Router, type Request, type Response } from "express";
import { hydraClient } from "../hydraClient.js";
import { userService } from "../userService.js";
import { emailService } from "../emailService.js";
import { renderPage, escapeHtml, getScopeDescription } from "../utils/index.js";
import type {
  LoginRequest,
  ConsentRequest,
  AppInfo,
  HydraConsentRequest,
  HydraResponse,
  User,
} from "../types.js";

const router = Router();

// Hydra's remember_for 0 keeps a login for the browser session and a consent until it is
// revoked, so which screens an OAuth flow shows never depends on the clock
const REMEMBER_FOR = 0;

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

// Grants consent and, unless Hydra is reusing a remembered grant, emails the user that the
// app is newly connected
async function grantConsent(
  challenge: string,
  consentRequest: HydraConsentRequest,
  scopes: string[],
): Promise<HydraResponse> {
  const claims = await claimsFor(consentRequest.subject, consentRequest.context);
  const acceptResult = await hydraClient.acceptConsentRequest(challenge, {
    grant_scope: scopes,
    grant_access_token_audience: consentRequest.requested_access_token_audience,
    remember: true,
    remember_for: REMEMBER_FOR,
    session: {
      access_token: claims,
      id_token: { ...claims, sub: consentRequest.subject },
    },
  });

  if (!consentRequest.skip && claims.email) {
    const appInfo: AppInfo = {
      clientName: consentRequest.client.client_name || consentRequest.client.client_id,
      clientId: consentRequest.client.client_id,
      scopes,
    };
    await emailService.sendAppAuthorizedEmail(
      {
        id: consentRequest.subject,
        username: claims.username,
        email: claims.email,
        name: claims.name,
      },
      appInfo,
    );
  }

  return acceptResult;
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
      const acceptLogin = async (subject: string, context: Claims) => {
        const acceptResult = await hydraClient.acceptLoginRequest(login_challenge, {
          subject,
          remember: true,
          remember_for: REMEMBER_FOR,
          context,
        });
        return res.redirect(acceptResult.redirect_to);
      };

      // Hydra's login session skips the form
      if (loginRequest.skip) {
        return acceptLogin(loginRequest.subject, await claimsFor(loginRequest.subject, undefined));
      }

      // So does a sign-in on auth.zoo's own pages, which Hydra doesn't know about, unless the
      // app asks for the password again
      const prompt =
        new URL(loginRequest.request_url, "https://auth.zoo").searchParams.get("prompt") ?? "";
      const sessionUser =
        req.session.user && !prompt.split(" ").includes("login")
          ? await userService.findById(req.session.user.id)
          : undefined;
      if (sessionUser) {
        return acceptLogin(sessionUser.id, userClaims(sessionUser));
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
          <div class="error">Failed to process login request: ${(error as Error).message}</div>
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
      res.status(401).send(renderPage("Login Failed", content, { hideNav: true }));
      return;
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
        remember_for: REMEMBER_FOR,
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
          <div class="error">Failed to complete login: ${(error as Error).message}</div>
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

      // No consent screen for a remembered grant, a first-party client (skip_consent in
      // core/hydra/clients), or a request without scopes
      if (
        consentRequest.skip ||
        consentRequest.client.skip_consent ||
        !consentRequest.requested_scope ||
        consentRequest.requested_scope.length === 0
      ) {
        const acceptResult = await grantConsent(
          consent_challenge,
          consentRequest,
          consentRequest.requested_scope || [],
        );
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
            id: consentRequest.subject,
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
          <div class="error">Failed to process consent request: ${(error as Error).message}</div>
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
      const acceptResult = await grantConsent(
        challenge,
        consentRequest,
        scopes ? scopes.split(",") : consentRequest.requested_scope,
      );
      res.redirect(acceptResult.redirect_to);
    } catch (error) {
      console.error("Error handling consent:", error);
      res.status(500).send(
        renderPage(
          "Error",
          `
        <div class="auth-container">
          <h1>Error</h1>
          <div class="error">Failed to process consent: ${(error as Error).message}</div>
        </div>
      `,
          { hideNav: true },
        ),
      );
    }
  },
);

// Hydra redirects here (urls.error) when an OAuth2 request is invalid
// Express parses a repeated parameter into an array
const firstQueryValue = (value: unknown): string | undefined =>
  typeof value === "string" ? value : Array.isArray(value) ? firstQueryValue(value[0]) : undefined;

router.get("/error", (req: Request, res: Response) => {
  const error = firstQueryValue(req.query.error) ?? "unknown_error";
  const error_description = firstQueryValue(req.query.error_description);
  const error_hint = firstQueryValue(req.query.error_hint);
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
});

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
