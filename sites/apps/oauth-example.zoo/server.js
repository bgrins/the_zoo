import crypto from "node:crypto";
import cookieParser from "cookie-parser";
import express from "express";
import session from "express-session";

const app = express();
const PORT = process.env.PORT || 3000;

// OAuth2 configuration
const oauth2Config = {
  clientId: process.env.OAUTH_CLIENT_ID || "zoo-example-app",
  clientSecret: process.env.OAUTH_CLIENT_SECRET || "zoo-example-secret",
  authorizationEndpoint: process.env.OAUTH_AUTH_ENDPOINT || "http://auth.zoo/oauth2/auth",
  tokenEndpoint: process.env.OAUTH_TOKEN_ENDPOINT || "http://auth.zoo/oauth2/token",
  userInfoEndpoint: process.env.OAUTH_USERINFO_ENDPOINT || "http://auth.zoo/userinfo",
  redirectUri: process.env.OAUTH_REDIRECT_URI || "http://oauth-example.zoo/callback",
  scope: process.env.OAUTH_SCOPE || "openid profile email",
};

// Trust proxy for accurate protocol detection
app.set("trust proxy", true);

// Cookie parser middleware
app.use(cookieParser());

// Session configuration
app.use(
  session({
    secret: process.env.SESSION_SECRET || "oauth-example-secret-key-change-in-production",
    resave: false,
    saveUninitialized: false, // Better security practice
    name: "oauth_example_session", // Custom session name
    cookie: {
      secure: "auto", // Automatically set secure based on connection
      httpOnly: true,
      sameSite: "lax",
      maxAge: 24 * 60 * 60 * 1000, // 24 hours
    },
  }),
);

// Generate random state for CSRF protection
function generateState() {
  return crypto.randomBytes(16).toString("hex");
}

// Render error page with debugging options
function renderErrorPage({ title, message, details, code, state }) {
  return `
    <!DOCTYPE html>
    <html>
    <head>
      <title>Error - OAuth2 Example</title>
      <style>
        body { 
          font-family: Arial, sans-serif; 
          max-width: 800px; 
          margin: 0 auto; 
          padding: 20px; 
          background: #f5f5f5;
        }
        .error-container {
          background: white;
          padding: 30px;
          border-radius: 8px;
          box-shadow: 0 2px 10px rgba(0,0,0,0.1);
          margin: 20px 0;
        }
        h1 { color: #dc3545; }
        .details {
          background: #f8f9fa;
          padding: 20px;
          border-radius: 5px;
          margin: 20px 0;
          border-left: 4px solid #dc3545;
        }
        .debug-info {
          background: #fff3cd;
          padding: 20px;
          border-radius: 5px;
          margin: 20px 0;
          border-left: 4px solid #ffc107;
        }
        pre {
          background: #f5f5f5;
          padding: 15px;
          border-radius: 5px;
          overflow-x: auto;
          white-space: pre-wrap;
        }
        .actions {
          margin: 30px 0;
        }
        a.button {
          background: #007bff;
          color: white;
          padding: 10px 20px;
          border: none;
          border-radius: 5px;
          cursor: pointer;
          text-decoration: none;
          display: inline-block;
          margin: 5px;
        }
        a.button:hover {
          background: #0056b3;
        }
        .danger { background: #dc3545; }
        .danger:hover { background: #c82333; }
        .warning { background: #ffc107; color: #212529; }
        .warning:hover { background: #e0a800; color: #212529; }
      </style>
    </head>
    <body>
      <div class="error-container">
        <h1>${title}</h1>
        <p>${message}</p>
        
        <div class="details">
          <h3>Error Details:</h3>
          <pre>${JSON.stringify(details, null, 2)}</pre>
        </div>
        
        <div class="debug-info">
          <h3>Debug Information:</h3>
          <p><strong>Authorization Code:</strong> ${code ? `${code.substring(0, 20)}...` : "None"}</p>
          <p><strong>State:</strong> ${state || "None"}</p>
          <p><strong>Time:</strong> ${new Date().toISOString()}</p>
        </div>
        
        <div class="actions">
          <h3>Debugging Actions:</h3>
          <a href="/debug/cookies" class="button warning">View All Cookies</a>
          <a href="/debug/clear-cookies" class="button danger">Clear All Cookies</a>
          <a href="/debug/clear-session" class="button danger">Clear Session</a>
          <a href="/" class="button">Home</a>
          <a href="/login" class="button">Try Login Again</a>
        </div>
        
        <div class="debug-info">
          <h3>Common Issues:</h3>
          <ul>
            <li><strong>Invalid authorization code:</strong> The code may have expired or already been used. Try logging in again.</li>
            <li><strong>Network errors:</strong> Check if Hydra is running and accessible.</li>
            <li><strong>CORS issues:</strong> Ensure CORS is properly configured in Hydra.</li>
            <li><strong>Cookie issues:</strong> Clear cookies and try again.</li>
          </ul>
        </div>
      </div>
    </body>
    </html>
  `;
}

// Home page
app.get("/", (req, res) => {
  const user = req.session.user;

  // Set a simple test cookie
  // Detect if request is over HTTPS
  const isSecure = req.protocol === "https" || req.get("X-Forwarded-Proto") === "https";

  res.cookie("oauth_example_visited", "true", {
    maxAge: 24 * 60 * 60 * 1000, // 24 hours
    httpOnly: false, // Allow JavaScript access for testing
    secure: isSecure, // Only send over HTTPS if request was HTTPS
    sameSite: "lax",
    path: "/",
  });

  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>OAuth2 Example - The Zoo</title>
      <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        .user-info { background: #f0f0f0; padding: 20px; border-radius: 5px; margin: 20px 0; }
        button, a.button { 
          background: #007bff; color: white; padding: 10px 20px; 
          text-decoration: none; border: none; border-radius: 5px; cursor: pointer; 
          display: inline-block; margin: 10px 0;
        }
        button:hover, a.button:hover { background: #0056b3; }
        pre { background: #f5f5f5; padding: 10px; overflow-x: auto; }
      </style>
    </head>
    <body>
      <h1>OAuth2 Example - The Zoo</h1>
      ${
        user
          ? `
        <div class="user-info">
          <h2>Welcome, ${user.name || user.sub}!</h2>
          <h3>User Information:</h3>
          <pre>${JSON.stringify(user, null, 2)}</pre>
          <form action="/logout" method="post" style="display: inline;">
            <button type="submit">Logout</button>
          </form>
        </div>
      `
          : `
        <p>This is a demonstration of OAuth2 authentication with ORY Hydra.</p>
        <a href="/login" class="button">Login with OAuth2</a>
      `
      }
      
      <h2>OAuth2 Flow Information</h2>
      <ul>
        <li><strong>Client ID:</strong> ${oauth2Config.clientId}</li>
        <li><strong>Authorization Endpoint:</strong> ${oauth2Config.authorizationEndpoint}</li>
        <li><strong>Token Endpoint:</strong> ${oauth2Config.tokenEndpoint}</li>
        <li><strong>UserInfo Endpoint:</strong> ${oauth2Config.userInfoEndpoint}</li>
        <li><strong>Scopes:</strong> ${oauth2Config.scope}</li>
      </ul>
      
      <h2>Test the API</h2>
      <p>Once logged in, you can test these endpoints:</p>
      <ul>
        <li><a href="/api/user">GET /api/user</a> - Get current user info</li>
        <li><a href="/api/token">GET /api/token</a> - View your access token (debug)</li>
      </ul>
      <h2>Debug Tools:</h2>
      <ul>
        <li><a href="/debug/cookies">View Cookies & Session</a> - Debug cookie and session data</li>
        <li><a href="/debug/clear-cookies">Clear All Cookies</a> - Clear all cookies</li>
        <li><a href="/debug/clear-session">Clear Session</a> - Destroy session data</li>
      </ul>
    </body>
    </html>
  `);
});

// Initiate OAuth2 login
app.get("/login", (req, res) => {
  const state = generateState();
  req.session.oauth2State = state;

  const authUrl = new URL(oauth2Config.authorizationEndpoint);
  authUrl.searchParams.append("client_id", oauth2Config.clientId);
  authUrl.searchParams.append("redirect_uri", oauth2Config.redirectUri);
  authUrl.searchParams.append("response_type", "code");
  authUrl.searchParams.append("scope", oauth2Config.scope);
  authUrl.searchParams.append("state", state);
  // Force fresh authentication - don't use cached/remembered sessions
  authUrl.searchParams.append("prompt", "login");

  res.redirect(authUrl.toString());
});

// OAuth2 callback
app.get("/callback", async (req, res) => {
  const { code, state, error, error_description } = req.query;

  // Check for OAuth2 errors
  if (error) {
    console.error("OAuth2 error:", error, error_description);
    return res.status(400).send(
      renderErrorPage({
        title: "OAuth2 Error",
        message: error_description || `OAuth2 authentication failed with error: ${error}`,
        details: {
          error: error,
          error_description: error_description,
        },
        code: code,
        state: state,
      }),
    );
  }

  // Verify state to prevent CSRF
  if (state !== req.session.oauth2State) {
    console.error("State mismatch:", {
      received: state,
      expected: req.session.oauth2State,
    });
    return res.status(400).send(
      renderErrorPage({
        title: "Invalid State Parameter",
        message:
          "The state parameter does not match. This could be a CSRF attack or your session may have expired.",
        details: {
          error: "invalid_state",
          received_state: state,
          expected_state: req.session.oauth2State,
          session_exists: !!req.session,
          has_oauth_state: !!req.session.oauth2State,
        },
        code: code,
        state: state,
      }),
    );
  }

  try {
    // Exchange authorization code for access token
    const params = new URLSearchParams({
      grant_type: "authorization_code",
      code: code,
      redirect_uri: oauth2Config.redirectUri,
    });
    const body = params.toString();

    console.log("Token exchange request:", {
      url: oauth2Config.tokenEndpoint,
      body: body,
      bodyLength: body.length,
      code: code,
      redirect_uri: oauth2Config.redirectUri,
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        Authorization:
          "Basic " +
          Buffer.from(`${oauth2Config.clientId}:${oauth2Config.clientSecret}`).toString("base64"),
      },
    });

    const tokenResponse = await fetch(oauth2Config.tokenEndpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        Authorization:
          "Basic " +
          Buffer.from(`${oauth2Config.clientId}:${oauth2Config.clientSecret}`).toString("base64"),
      },
      body: body,
    });

    if (!tokenResponse.ok) {
      const errorText = await tokenResponse.text();
      console.error("Token exchange failed:", tokenResponse.status, errorText);

      // Try to parse as JSON for better error details
      let errorDetails;
      try {
        errorDetails = JSON.parse(errorText);
      } catch (_e) {
        errorDetails = { error: errorText };
      }

      return res.status(500).send(
        renderErrorPage({
          title: "Token Exchange Failed",
          message: "Failed to exchange authorization code for access token",
          details: errorDetails,
          code: code,
          state: state,
        }),
      );
    }

    const tokens = await tokenResponse.json();
    req.session.accessToken = tokens.access_token;
    req.session.idToken = tokens.id_token;

    // Get user info
    const userResponse = await fetch(oauth2Config.userInfoEndpoint, {
      headers: {
        Authorization: `Bearer ${tokens.access_token}`,
      },
    });

    if (userResponse.ok) {
      const user = await userResponse.json();
      req.session.user = user;
    }

    res.redirect("/");
  } catch (error) {
    console.error("OAuth2 callback error:", error);
    return res.status(500).send(
      renderErrorPage({
        title: "Authentication Failed",
        message: "An error occurred during authentication",
        details: { error: error.message, stack: error.stack },
        code: code,
        state: state,
      }),
    );
  }
});

// Logout
app.post("/logout", (req, res) => {
  req.session.destroy();
  res.redirect("/");
});

// API endpoint - Get user info
app.get("/api/user", (req, res) => {
  if (!req.session.user) {
    return res.status(401).json({ error: "Not authenticated" });
  }
  res.json(req.session.user);
});

// API endpoint - Get token info (for debugging)
app.get("/api/token", (req, res) => {
  if (!req.session.accessToken) {
    return res.status(401).json({ error: "Not authenticated" });
  }
  res.json({
    accessToken: req.session.accessToken,
    idToken: req.session.idToken,
  });
});

// Debug endpoints
app.get("/debug/cookies", (req, res) => {
  const cookies = req.headers.cookie || "No cookies found";
  const sessionData = req.session || {};

  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Debug - Cookies</title>
      <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        pre { background: #f5f5f5; padding: 15px; border-radius: 5px; overflow-x: auto; }
        .section { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        a.button { background: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 10px 5px; }
        a.button:hover { background: #0056b3; }
      </style>
    </head>
    <body>
      <h1>Debug - Cookies & Session</h1>
      
      <div class="section">
        <h2>Raw Cookie Header:</h2>
        <pre>${cookies}</pre>
      </div>
      
      <div class="section">
        <h2>Parsed Cookies:</h2>
        <pre>${JSON.stringify(req.cookies || {}, null, 2)}</pre>
      </div>
      
      <div class="section">
        <h2>Session Data:</h2>
        <pre>${JSON.stringify(sessionData, null, 2)}</pre>
      </div>
      
      <div class="section">
        <h2>Session ID:</h2>
        <pre>${req.sessionID || "No session ID"}</pre>
      </div>
      
      <a href="/" class="button">Home</a>
      <a href="/debug/clear-cookies" class="button">Clear Cookies</a>
      <a href="/debug/clear-session" class="button">Clear Session</a>
    </body>
    </html>
  `);
});

app.get("/debug/clear-cookies", (req, res) => {
  // Clear all cookies we know about
  res.clearCookie("oauth_example_visited");
  res.clearCookie("connect.sid");

  // Try to clear any other cookies by setting them to expire
  const cookies = req.headers.cookie;
  if (cookies) {
    cookies.split(";").forEach((cookie) => {
      const [name] = cookie.trim().split("=");
      res.clearCookie(name);
      // Also try with different paths
      res.clearCookie(name, { path: "/" });
      res.clearCookie(name, { path: "/", domain: ".oauth-example.zoo" });
      res.clearCookie(name, { path: "/", domain: "oauth-example.zoo" });
    });
  }

  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Cookies Cleared</title>
      <style>
        body { font-family: Arial, sans-serif; max-width: 600px; margin: 100px auto; padding: 20px; text-align: center; }
        .success { color: #28a745; font-size: 24px; margin: 20px 0; }
        a { color: #007bff; }
      </style>
    </head>
    <body>
      <div class="success">✓ Cookies Cleared</div>
      <p>All cookies have been cleared.</p>
      <p><a href="/">Return to Home</a></p>
    </body>
    </html>
  `);
});

app.get("/debug/clear-session", (req, res) => {
  req.session.destroy((err) => {
    if (err) {
      console.error("Session destroy error:", err);
    }
    res.send(`
      <!DOCTYPE html>
      <html>
      <head>
        <title>Session Cleared</title>
        <style>
          body { font-family: Arial, sans-serif; max-width: 600px; margin: 100px auto; padding: 20px; text-align: center; }
          .success { color: #28a745; font-size: 24px; margin: 20px 0; }
          a { color: #007bff; }
        </style>
      </head>
      <body>
        <div class="success">✓ Session Cleared</div>
        <p>Your session has been destroyed.</p>
        <p><a href="/">Return to Home</a></p>
      </body>
      </html>
    `);
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`OAuth2 Example app listening on port ${PORT}`);
  console.log(`Visit https://oauth-example.zoo to test OAuth2 authentication`);
});
