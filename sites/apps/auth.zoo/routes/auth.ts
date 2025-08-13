import { Router, type Request, type Response } from "express";
import { userService } from "../userService.js";
import { emailService } from "../emailService.js";
import { renderPage, userSessions } from "../utils/index.js";
import type { LoginRequest } from "../types.js";

const router = Router();

// Direct login endpoint (for homepage form)
router.post(
  "/direct-login",
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
                 pattern="[a-zA-Z0-9_-]+" 
                 title="Username can only contain letters, numbers, underscores, and hyphens">
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
router.post("/register", async (req: Request, res: Response) => {
  const { username, email, name, password } = req.body;

  try {
    // Check if username already exists
    const existingUser = await userService.findByUsername(username);
    if (existingUser) {
      const content = `
        <div class="auth-container">
          <h1>Registration Failed</h1>
          <div class="error">Username already exists</div>
          <div style="margin-top: 20px;">
            <a href="/register" class="link">← Back to registration</a>
          </div>
        </div>
      `;
      return res.status(400).send(renderPage("Registration Failed", content, { hideNav: true }));
    }

    // Check if email already exists
    const existingEmail = await userService.findByEmail(email);
    if (existingEmail) {
      const content = `
        <div class="auth-container">
          <h1>Registration Failed</h1>
          <div class="error">Email already registered</div>
          <div style="margin-top: 20px;">
            <a href="/register" class="link">← Back to registration</a>
          </div>
        </div>
      `;
      return res.status(400).send(renderPage("Registration Failed", content, { hideNav: true }));
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
    const content = `
      <div class="auth-container">
        <h1>Registration Failed</h1>
        <div class="error">Failed to create account. Please try again.</div>
        <div style="margin-top: 20px;">
          <a href="/register" class="link">← Back to registration</a>
        </div>
      </div>
    `;
    res.status(500).send(renderPage("Registration Failed", content, { hideNav: true }));
  }
});

// Logout endpoint for regular logouts
router.post("/logout", (req: Request, res: Response) => {
  if (req.session.user) {
    userSessions.delete(req.session.user.username);
  }

  req.session.destroy(() => {
    res.redirect("/");
  });
});

export default router;
