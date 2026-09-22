import { Router, type Request, type Response } from "express";
import { userService } from "../userService.js";
import { emailService } from "../emailService.js";
import { requireFormFields } from "../middleware.js";
import { renderPage } from "../utils/index.js";
import type { LoginRequest } from "../types.js";

const router = Router();

// Written so it compiles under the v flag browsers give a pattern attribute
const USERNAME_PATTERN = "[a-zA-Z0-9_\\-]+";
const USERNAME_RULE = "Username can only contain letters, numbers, underscores, and hyphens";
const USERNAME = new RegExp(`^(?:${USERNAME_PATTERN})$`, "v");

function registrationFailed(res: Response, status: number, message: string) {
  const content = `
    <div class="auth-container">
      <h1>Registration Failed</h1>
      <div class="error">${message}</div>
      <div style="margin-top: 20px;">
        <a href="/register" class="link">← Back to registration</a>
      </div>
    </div>
  `;
  res.status(status).send(renderPage("Registration Failed", content, { hideNav: true }));
}

// Direct login endpoint (for homepage form)
router.post(
  "/direct-login",
  requireFormFields(["username", "password"]),
  async (req: Request<Record<string, never>, any, LoginRequest>, res: Response) => {
    const { username, password } = req.body;

    // Validate credentials against database (username or email)
    const user = await userService.findByUsernameOrEmail(username);
    const isValidPassword =
      user && (await userService.verifyPassword(password, user.password_hash));

    if (!isValidPassword) {
      const content = `
      <div class="hero-section">
        <div class="auth-container" style="max-width: 400px;">
          <h1>Login Failed</h1>
          <div class="error">Invalid username or password</div>
          <div style="margin-top: 20px;">
            <a href="/" class="link">← Back to login</a>
          </div>
        </div>
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

    res.redirect("/dashboard");
  },
);

// Register endpoint
router.get("/register", (_req: Request, res: Response) => {
  const content = `
    <div class="auth-container">
      <h1>Create Zoo Identity Account</h1>
      <form method="POST" action="/register">
        <div class="form-group">
          <label for="username">Username</label>
          <input type="text" id="username" name="username" required
                 pattern="${USERNAME_PATTERN}"
                 title="${USERNAME_RULE}">
        </div>
        <div class="form-group">
          <label for="email">Email</label>
          <input type="email" id="email" name="email" required>
        </div>
        <div class="form-group">
          <label for="name">Full Name</label>
          <input type="text" id="name" name="name" required>
        </div>
        <div class="form-group">
          <label for="password">Password</label>
          <input type="password" id="password" name="password" required minlength="8">
        </div>
        <button type="submit">Create Account</button>
      </form>
      <div style="text-align: center; margin-top: 20px;">
        <span style="color: #666;">Already have an account?</span> 
        <a href="/" style="color: #007bff;">Sign in</a>
      </div>
    </div>
  `;
  res.send(renderPage("Register", content, { hideNav: true }));
});

// Handle registration
router.post(
  "/register",
  requireFormFields(["username", "email", "name", "password"]),
  async (req: Request, res: Response) => {
    const { username, email, name, password } = req.body;
    if (!USERNAME.test(username)) {
      registrationFailed(res, 400, USERNAME_RULE);
      return;
    }

    try {
      // Check if username already exists
      const existingUser = await userService.findByUsername(username);
      if (existingUser) {
        registrationFailed(res, 400, "Username already exists");
        return;
      }

      // Check if email already exists
      const existingEmail = await userService.findByEmail(email);
      if (existingEmail) {
        registrationFailed(res, 400, "Email already registered");
        return;
      }

      // Create the user
      const user = await userService.create({
        username,
        email,
        name,
        password,
      });

      // Send welcome email
      await emailService.sendWelcomeEmail(user);

      // Auto-login after registration
      req.session.user = {
        id: user.id,
        username: user.username,
        name: user.name,
        email: user.email,
      };

      res.redirect("/dashboard");
    } catch (error) {
      console.error("Registration error:", error);
      registrationFailed(res, 500, "Failed to create account. Please try again.");
    }
  },
);

// Logout endpoint for regular logouts. Destroying the auth.zoo session is not enough:
// Hydra's login session would silently sign the previous user back in on the next OAuth
// flow. Hydra's logout endpoint ends it and redirects back via GET /logout, or straight to
// the post-logout URL when there is no Hydra session.
router.post("/logout", (req: Request, res: Response) => {
  req.session.destroy(() => {
    res.redirect("/oauth2/sessions/logout");
  });
});

export default router;
