import path from "node:path";
import { fileURLToPath } from "node:url";
import express from "express";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3000;

// Enable CORS for cross-origin script loading
app.use((_req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Methods", "GET, OPTIONS");
  res.header("Access-Control-Allow-Headers", "Content-Type");
  next();
});

// Serve static files from public directory
app.use(express.static(path.join(__dirname, "public")));

// Health check endpoint
app.get("/health", (_req, res) => {
  res.json({ status: "ok", service: "performance.zoo" });
});

// Root endpoint
app.get("/", (_req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Performance Zoo</title>
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          max-width: 800px;
          margin: 0 auto;
          padding: 2rem;
          background: #f5f5f5;
        }
        .container {
          background: white;
          padding: 2rem;
          border-radius: 8px;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 { color: #333; }
        .status { color: #22c55e; }
        code {
          background: #f0f0f0;
          padding: 0.2rem 0.4rem;
          border-radius: 3px;
          font-family: 'Monaco', 'Consolas', monospace;
        }
        pre {
          background: #f8f8f8;
          padding: 1rem;
          border-radius: 4px;
          overflow-x: auto;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>📊 Performance Zoo</h1>
        <p class="status">Service is running!</p>
        
        <h2>Shared Script</h2>
        <p>Include this script in your zoo apps to enable performance monitoring:</p>
        <pre><code>&lt;script src="https://performance.zoo/shared.js"&gt;&lt;/script&gt;</code></pre>
        
        <h2>Test the Script</h2>
        <p>Open your browser console to see the script output:</p>
        <button onclick="loadScript()">Load shared.js</button>
        
        <script>
          function loadScript() {
            const script = document.createElement('script');
            script.src = '/shared.js';
            document.head.appendChild(script);
          }
        </script>
      </div>
    </body>
    </html>
  `);
});

app.listen(PORT, () => {
  console.log(`Performance.zoo server running on port ${PORT}`);
});
