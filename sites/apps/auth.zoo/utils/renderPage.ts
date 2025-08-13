import type { SessionUser } from "../types.js";

export interface RenderPageOptions {
  hideNav?: boolean;
  user?: SessionUser | null;
}

export function renderPage(
  title: string,
  content: string,
  options: RenderPageOptions = {},
): string {
  const { hideNav = false, user = null } = options;

  return `
    <!DOCTYPE html>
    <html>
    <head>
      <title>${title} - Zoo Identity</title>
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <style>
        * {
          box-sizing: border-box;
        }
        
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
          margin: 0;
          padding: 0;
          background: #ffffff;
          color: #1a1a1a;
          line-height: 1.6;
        }
        
        .nav {
          background: #ffffff;
          border-bottom: 1px solid #e5e7eb;
          padding: 16px 0;
          position: fixed;
          top: 0;
          left: 0;
          right: 0;
          z-index: 1000;
          backdrop-filter: blur(8px);
          background: rgba(255, 255, 255, 0.95);
        }
        
        .nav-container {
          max-width: 1200px;
          margin: 0 auto;
          padding: 0 20px;
          display: flex;
          justify-content: space-between;
          align-items: center;
        }
        
        .nav-brand {
          font-size: 20px;
          font-weight: 600;
          color: #1a1a1a;
          text-decoration: none;
          display: flex;
          align-items: center;
          gap: 8px;
        }
        
        .nav-menu {
          display: flex;
          gap: 24px;
          align-items: center;
        }
        
        .nav-link {
          color: #6b7280;
          text-decoration: none;
          font-weight: 500;
          transition: color 0.2s;
        }
        
        .nav-link:hover {
          color: #1a1a1a;
        }
        
        .nav-user {
          display: flex;
          align-items: center;
          gap: 12px;
          padding: 8px 16px;
          background: #f3f4f6;
          border-radius: 8px;
        }
        
        .container {
          max-width: 1200px;
          margin: 0 auto;
          padding: 20px;
          margin-top: ${hideNav ? "0" : "80px"};
        }
        
        .auth-container {
          max-width: 400px;
          margin: 60px auto;
          padding: 40px;
          background: #ffffff;
          border: 1px solid #e5e7eb;
          border-radius: 12px;
          box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        }
        
        h1, h2, h3 {
          margin-top: 0;
          color: #1a1a1a;
        }
        
        .form-group {
          margin-bottom: 20px;
        }
        
        label {
          display: block;
          margin-bottom: 8px;
          font-weight: 500;
          color: #374151;
        }
        
        input[type="text"],
        input[type="email"],
        input[type="password"] {
          width: 100%;
          padding: 12px 16px;
          border: 1px solid #d1d5db;
          border-radius: 8px;
          font-size: 16px;
          transition: border-color 0.2s;
        }
        
        input:focus {
          outline: none;
          border-color: #3b82f6;
        }
        
        button {
          background: #3b82f6;
          color: white;
          border: none;
          padding: 12px 24px;
          border-radius: 8px;
          font-size: 16px;
          font-weight: 500;
          cursor: pointer;
          transition: background 0.2s;
          width: 100%;
        }
        
        button:hover {
          background: #2563eb;
        }
        
        .secondary-button {
          background: #6b7280;
        }
        
        .secondary-button:hover {
          background: #4b5563;
        }
        
        .error {
          background: #fee2e2;
          border: 1px solid #fecaca;
          color: #dc2626;
          padding: 12px 16px;
          border-radius: 8px;
          margin-bottom: 20px;
        }
        
        .success {
          background: #d1fae5;
          border: 1px solid #a7f3d0;
          color: #059669;
          padding: 12px 16px;
          border-radius: 8px;
          margin-bottom: 20px;
        }
        
        .text-muted {
          color: #6b7280;
        }
        
        .link {
          color: #3b82f6;
          text-decoration: none;
        }
        
        .link:hover {
          text-decoration: underline;
        }
        
        .hero-section {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          padding: 80px 20px;
          margin: -20px -20px 40px -20px;
        }
        
        .dashboard-grid {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 40px;
          margin-top: 40px;
        }
        
        @media (max-width: 768px) {
          .dashboard-grid {
            grid-template-columns: 1fr;
          }
        }
        
        .info-card {
          background: #f9fafb;
          border: 1px solid #e5e7eb;
          border-radius: 12px;
          padding: 24px;
        }
        
        .app-grid {
          display: grid;
          grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
          gap: 16px;
        }
        
        .app-card {
          text-decoration: none;
          display: flex;
          flex-direction: column;
          align-items: center;
          padding: 20px;
          background: #f9fafb;
          border: 1px solid #e5e7eb;
          border-radius: 12px;
          transition: all 0.2s;
          min-height: 140px;
        }
        
        .app-card:hover {
          background: #f3f4f6;
          border-color: #d1d5db;
          transform: translateY(-2px);
        }
        
        .app-icon {
          font-size: 36px;
          margin-bottom: 12px;
        }
        
        .app-name {
          font-weight: 600;
          color: #1a1a1a;
          margin-bottom: 4px;
        }
        
        .app-description {
          text-align: center;
          color: #6b7280;
          font-size: 13px;
          line-height: 1.4;
        }
        
        /* Missing styles */
        .hero-grid {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 80px;
          align-items: center;
          max-width: 1280px;
          margin: 0 auto;
          width: 100%;
        }
        
        @media (max-width: 968px) {
          .hero-grid {
            grid-template-columns: 1fr;
            gap: 48px;
          }
        }
        
        .hero-content h1 {
          font-size: 48px;
          margin-bottom: 16px;
        }
        
        .hero-content .subtitle {
          font-size: 20px;
          color: #e5e7eb;
          margin-bottom: 32px;
        }
        
        .feature-list {
          list-style: none;
          padding: 0;
          margin: 0 0 40px 0;
        }
        
        .feature-list li {
          display: flex;
          align-items: center;
          gap: 12px;
          margin-bottom: 16px;
          color: #f3f4f6;
        }
        
        .feature-icon {
          width: 24px;
          height: 24px;
          background: rgba(255, 255, 255, 0.2);
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          flex-shrink: 0;
        }
        
        .divider {
          margin: 32px 0;
          border: 0;
          border-top: 1px solid #e5e7eb;
        }
        
        .text-center {
          text-align: center;
        }
        
        .connected-apps {
          display: grid;
          gap: 16px;
        }
        
        .app-item {
          background: #ffffff;
          border: 1px solid #e5e7eb;
          border-radius: 12px;
          padding: 24px;
          display: flex;
          justify-content: space-between;
          align-items: start;
        }
        
        .revoke-button {
          background: #ef4444;
          padding: 8px 16px;
          width: auto;
        }
        
        .revoke-button:hover {
          background: #dc2626;
        }
        
        .danger-button {
          background: #ef4444;
        }
        
        .danger-button:hover {
          background: #dc2626;
        }
        
        .section {
          margin-bottom: 48px;
        }
        
        .info {
          background: #eff6ff;
          border: 1px solid #dbeafe;
          color: #1e40af;
          padding: 12px 16px;
          border-radius: 8px;
          margin-bottom: 24px;
          font-size: 14px;
        }
        
        .client-info {
          margin-bottom: 24px;
          padding: 16px;
          background: #f9fafb;
          border: 1px solid #e5e7eb;
          border-radius: 8px;
        }
        
        .scope-list {
          margin: 16px 0;
          padding: 16px;
          background: #f9fafb;
          border-radius: 8px;
          font-size: 14px;
        }
      </style>
    </head>
    <body>
      ${
        !hideNav
          ? `
        <nav class="nav">
          <div class="nav-container">
            <a href="/" class="nav-brand">
              🦁 Zoo Identity
            </a>
            <div class="nav-menu">
              ${
                user
                  ? `
                <a href="/dashboard" class="nav-link">Dashboard</a>
                <a href="/explore" class="nav-link">Explore Apps</a>
                <div class="nav-user">
                  <span>👤 ${user.name}</span>
                  <form method="POST" action="/logout" style="margin: 0;">
                    <button type="submit" style="padding: 4px 12px; font-size: 14px; width: auto;">Logout</button>
                  </form>
                </div>
              `
                  : `
                <a href="/" class="nav-link">Login</a>
                <a href="/register" class="nav-link">Register</a>
              `
              }
            </div>
          </div>
        </nav>
      `
          : ""
      }
      <div class="container">
        ${content}
      </div>
    </body>
    </html>
  `;
}
