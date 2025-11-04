import express, { type Request, type Response } from "express";
import session from "express-session";
import { createProxyMiddleware } from "http-proxy-middleware";
import fetch from "node-fetch";
import runMigrations from "./migrate.js";
import authRoutes from "./routes/auth.js";
import oauthRoutes from "./routes/oauth.js";
import apiRoutes from "./routes/api.js";
import dashboardRoutes from "./routes/dashboard.js";
import { renderPage } from "./utils/index.js";

const app = express();
const PORT = process.env.PORT || 3000;

// Hydra URLs
const HYDRA_PUBLIC_URL = "http://hydra:4444";

// Note: Body parsing middleware is placed AFTER proxy routes
// to avoid interfering with proxy body handling

// Run database migrations at startup
await runMigrations();

// Homepage will be defined after session middleware

// Health endpoint
app.get("/health", async (_req, res) => {
  try {
    const hydraHealth = await fetch(`${HYDRA_PUBLIC_URL}/health/ready`);
    if (hydraHealth.ok) {
      res.json({ status: "healthy", hydra: "ready" });
    } else {
      res.status(503).json({ status: "unhealthy", hydra: "not ready" });
    }
  } catch (error) {
    res.status(503).json({ status: "unhealthy", error: (error as Error).message });
  }
});

// Custom userinfo endpoint that includes username
app.get("/userinfo", async (req: Request, res: Response) => {
  try {
    // Forward the request to Hydra to get base userinfo
    const response = await fetch(`${HYDRA_PUBLIC_URL}/userinfo`, {
      headers: {
        Authorization: req.headers.authorization || "",
        "Content-Type": "application/json",
      },
    });

    if (!response.ok) {
      return res.status(response.status).json({ error: "Failed to get userinfo" });
    }

    const userinfo = await response.json();

    // Add preferred_username from the access token context
    // The username should be in the 'sub' claim format or we need to extract it
    if (userinfo.sub && !userinfo.preferred_username) {
      // Try to extract username from the context
      // For now, we'll use the email username part as a fallback
      if (userinfo.email) {
        userinfo.preferred_username = userinfo.email.split("@")[0];
      }
    }

    // Also add 'username' field as some OIDC clients expect this
    if (!userinfo.username && userinfo.preferred_username) {
      userinfo.username = userinfo.preferred_username;
    }

    res.json(userinfo);
  } catch (error) {
    console.error("Userinfo error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Proxy Hydra's OAuth2 and OIDC endpoints (excluding userinfo which we handle above)
const hydraEndpoints = ["/oauth2", "/.well-known", "/health/ready", "/health/alive"];

hydraEndpoints.forEach((endpoint) => {
  app.use(
    endpoint,
    createProxyMiddleware({
      target: HYDRA_PUBLIC_URL,
      changeOrigin: true,
      secure: false, // Allow self-signed certificates
      logLevel: "warn",
      selfHandleResponse: false,
      onProxyReq: (proxyReq, _req, _res) => {
        // Ensure proper host header
        proxyReq.setHeader("Host", "auth.zoo");
      },
      onError: (err, _req, res) => {
        console.error(`Proxy error for ${endpoint}:`, err);
        res.status(502).send("Bad Gateway");
      },
    }),
  );
});

// Add body parsing middleware AFTER proxy routes
app.use(express.urlencoded({ extended: true }));
app.use(express.json());

// Session configuration for auth.zoo
app.use(
  session({
    secret: process.env.SESSION_SECRET || "auth-zoo-secret-change-in-production",
    resave: false,
    saveUninitialized: false,
    name: "auth_zoo_session",
    cookie: {
      secure: "auto",
      httpOnly: true,
      sameSite: "lax",
      maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days
    },
  }),
);

// Apply route modules
app.use("/api", apiRoutes);
app.use(authRoutes);
app.use(oauthRoutes);
app.use(dashboardRoutes);

// Homepage
app.get("/", (req: Request, res: Response) => {
  // If user is logged in, show dashboard
  if (req.session.user) {
    return res.redirect("/dashboard");
  }

  const content = `
    <div class="hero-section">
      <div class="hero-grid">
        <div class="hero-content">
          <h1>Unified Identity for Zoo</h1>
          <p class="subtitle">
            One account for all your Zoo applications. Secure, simple, and seamless.
          </p>
          
          <ul class="feature-list">
            <li>
              <div class="feature-icon">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#3b82f6" stroke-width="2">
                  <polyline points="20 6 9 17 4 12"></polyline>
                </svg>
              </div>
              Single sign-on across all Zoo services
            </li>
            <li>
              <div class="feature-icon">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#3b82f6" stroke-width="2">
                  <polyline points="20 6 9 17 4 12"></polyline>
                </svg>
              </div>
              Secure OAuth2 and OpenID Connect
            </li>
            <li>
              <div class="feature-icon">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#3b82f6" stroke-width="2">
                  <polyline points="20 6 9 17 4 12"></polyline>
                </svg>
              </div>
              Fine-grained permission control
            </li>
            <li>
              <div class="feature-icon">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#3b82f6" stroke-width="2">
                  <polyline points="20 6 9 17 4 12"></polyline>
                </svg>
              </div>
              Privacy-first architecture
            </li>
          </ul>
          
          <div>
            <h3>Explore Zoo Applications</h3>
            <div class="app-grid">
              <a href="http://gitea.zoo" class="app-card">
                <div class="app-icon">📦</div>
                <div class="app-name">Gitea</div>
              </a>
              <a href="http://planka.zoo" class="app-card">
                <div class="app-icon">📋</div>
                <div class="app-name">Planka</div>
              </a>
              <a href="http://status.zoo" class="app-card">
                <div class="app-icon">📊</div>
                <div class="app-name">Status</div>
              </a>
            </div>
          </div>
        </div>
        
        <div>
          <div class="auth-container">
            <h2>Welcome back</h2>
            <form method="POST" action="/direct-login">
              <div class="form-group">
                <label for="username">Username or Email</label>
                <input type="text" id="username" name="username" required autofocus placeholder="Enter username or email">
              </div>
              <div class="form-group">
                <label for="password">Password</label>
                <input type="password" id="password" name="password" required placeholder="Enter your password">
              </div>
              <button type="submit">Sign In</button>
            </form>
            
            <div class="divider"></div>
            
            <div class="text-center">
              <p class="text-muted">Don't have an account?</p>
              <a href="/register" class="link">Create an account</a>
            </div>
          </div>
        </div>
      </div>
    </div>
  `;

  res.send(
    renderPage("Zoo - Sign In", content, {
      user: req.session.user,
    }),
  );
});

// Catch-all for undefined routes
app.use((_req, res) => {
  res.status(404).send(
    renderPage(
      "Not Found",
      `
    <div class="auth-container">
      <h1>Not Found</h1>
      <p>The requested resource was not found.</p>
      <p><a href="/">Return to homepage</a></p>
    </div>
  `,
    ),
  );
});

app.listen(PORT, () => {
  console.log(`Auth.zoo server running on port ${PORT}`);
});
