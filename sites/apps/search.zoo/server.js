import express from "express";
import { MeiliSearch } from "meilisearch";
import { createClient } from "redis";

const app = express();
const port = process.env.PORT || 3000;

// Initialize MeiliSearch client
const client = new MeiliSearch({
  host: process.env.MEILI_HOST || "http://search-api.zoo",
  apiKey: process.env.MEILI_MASTER_KEY || "",
});

// Initialize Redis client
const redis = createClient({
  url: process.env.REDIS_URL || "redis://redis:6379",
});

redis.on("error", (err) => console.log("Redis Client Error", err));

// Connect to Redis
async function connectRedis() {
  try {
    await redis.connect();
    console.log("Connected to Redis");
  } catch (error) {
    console.error("Failed to connect to Redis:", error);
  }
}

connectRedis();

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Helper function to render HTML template
function renderHTML(content, options = {}) {
  const { title = "Zoo Search" } = options;

  return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${title}</title>
    <link rel="search" type="application/opensearchdescription+xml" title="Zoo Search" href="/opensearch.xml">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            color: #333;
            padding: 20px;
        }
        .container { max-width: 800px; margin: 0 auto; }
        h1 { color: white; text-align: center; font-size: 48px; margin-bottom: 10px; }
        .subtitle { color: rgba(255,255,255,0.9); text-align: center; margin-bottom: 30px; }
        .search-form {
            background: rgba(255,255,255,0.95);
            padding: 30px;
            border-radius: 12px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.1);
            margin-bottom: 30px;
        }
        .search-group { display: flex; gap: 10px; margin-bottom: 15px; }
        input[type="text"] {
            flex: 1;
            padding: 15px;
            font-size: 16px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            outline: none;
        }
        input[type="text"]:focus { border-color: #667eea; }
        button {
            padding: 15px 30px;
            background: #667eea;
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
        }
        button:hover { background: #764ba2; }
        .filters { display: flex; gap: 15px; flex-wrap: wrap; }
        .filter-group { display: flex; flex-direction: column; gap: 5px; }
        .filter-label { font-size: 12px; color: #666; font-weight: 600; text-transform: uppercase; }
        select, .filter-input {
            padding: 8px 12px;
            border: 1px solid #e0e0e0;
            border-radius: 6px;
            font-size: 14px;
        }
        .result {
            background: rgba(255,255,255,0.95);
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 15px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        .result-title {
            font-size: 20px;
            font-weight: 600;
            color: #667eea;
            text-decoration: none;
            display: block;
            margin-bottom: 5px;
        }
        .result-title:hover { color: #764ba2; }
        .result-domain { font-size: 14px; color: #666; margin-bottom: 10px; }
        .result-content { font-size: 14px; line-height: 1.6; color: #444; }
        .highlight { background-color: #ffd93d; padding: 2px 4px; border-radius: 2px; }
        .no-results { text-align: center; color: white; font-size: 18px; padding: 40px; }
        .error {
            background: rgba(255,255,255,0.95);
            border: 2px solid #ff4444;
            color: #ff4444;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            text-align: center;
        }
        .stats { text-align: center; color: rgba(255,255,255,0.8); font-size: 14px; margin-top: 20px; }
        .results-header { color: white; text-align: center; margin-bottom: 20px; }
        .nav { text-align: center; margin-bottom: 10px; }
        .nav a { color: white; text-decoration: none; margin: 0 10px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔍 Zoo Search</h1>
        <p class="subtitle">Search across all Zoo sites</p>
        <div class="nav">
            <a href="/dashboard">Dashboard →</a>
            <a href="/firefox-setup">Add to Firefox →</a>
        </div>
        ${content}
    </div>
</body>
</html>`;
}

// Main search page
app.get("/", async (req, res) => {
  const query = req.query.q || "";
  let results = null;
  let error = null;
  let stats = null;

  // Get stats
  try {
    const indexes = await client.getIndexes();
    const zooPages = indexes.results.find((idx) => idx.uid === "zoo-pages");
    if (zooPages) {
      stats = `${zooPages.numberOfDocuments || 0} pages indexed`;
    }
  } catch (err) {
    console.error("Failed to load stats:", err);
  }

  // Perform search if query exists
  if (query) {
    try {
      const searchOptions = {
        limit: parseInt(req.query.limit) || 20,
        attributesToRetrieve: ["title", "content", "url", "domain", "timestamp"],
        attributesToHighlight: ["title", "content"],
        highlightPreTag: '<span class="highlight">',
        highlightPostTag: "</span>",
        attributesToCrop: ["content"],
        cropLength: 200,
      };

      if (req.query.sort) {
        searchOptions.sort = [req.query.sort];
      }

      if (req.query.domain) {
        searchOptions.filter = `domain = "${req.query.domain}"`;
      }

      const index = client.index("zoo-pages");
      results = await index.search(query, searchOptions);
    } catch (err) {
      error = err.message;
    }
  }

  const content = `
    <form method="get" action="/" class="search-form">
      <div class="search-group">
        <input type="text" name="q" value="${query}" placeholder="Search for anything..." autofocus>
        <button type="submit">Search</button>
      </div>
      <div class="filters">
        <div class="filter-group">
          <label class="filter-label">Sort by</label>
          <select name="sort">
            <option value="">Relevance</option>
            <option value="timestamp:desc" ${req.query.sort === "timestamp:desc" ? "selected" : ""}>Newest</option>
            <option value="timestamp:asc" ${req.query.sort === "timestamp:asc" ? "selected" : ""}>Oldest</option>
          </select>
        </div>
        <div class="filter-group">
          <label class="filter-label">Domain</label>
          <input type="text" name="domain" class="filter-input" placeholder="e.g., wiki.zoo" value="${req.query.domain || ""}">
        </div>
        <div class="filter-group">
          <label class="filter-label">Limit</label>
          <select name="limit">
            <option value="20" ${req.query.limit === "20" ? "selected" : ""}>20</option>
            <option value="50" ${req.query.limit === "50" ? "selected" : ""}>50</option>
            <option value="100" ${req.query.limit === "100" ? "selected" : ""}>100</option>
          </select>
        </div>
      </div>
    </form>
    
    ${error ? `<div class="error">Error: ${error}</div>` : ""}
    
    ${
      results
        ? `
      <div class="results-header">Found ${results.estimatedTotalHits} results in ${results.processingTimeMs}ms</div>
      ${
        results.hits.length === 0
          ? '<div class="no-results">No results found</div>'
          : results.hits
              .map(
                (hit) => `
          <div class="result">
            <a href="${hit.url}" class="result-title">${hit._formatted?.title || hit.title || "Untitled"}</a>
            <div class="result-domain">${hit.domain}</div>
            <div class="result-content">${hit._formatted?.content || hit.content || ""}</div>
          </div>
        `,
              )
              .join("")
      }
    `
        : ""
    }
    
    ${stats ? `<div class="stats">${stats}</div>` : ""}
  `;

  res.send(renderHTML(content, { query, results, error, stats }));
});

// ====================
// Static Pages
// ====================

// Serve dashboard page
app.get("/dashboard", (_req, res) => {
  res.sendFile("dashboard.html", { root: "./public" });
});

// Serve crawler page
app.get("/crawler", (_req, res) => {
  res.sendFile("crawler.html", { root: "./public" });
});

// Serve firefox setup page
app.get("/firefox-setup", (_req, res) => {
  res.sendFile("firefox-setup.html", { root: "./public" });
});

// Serve static files (opensearch.xml, etc)
app.use(express.static("public"));

// ====================
// API Endpoints
// ====================

// API endpoint to get search client info
app.get("/api/info", async (_req, res) => {
  try {
    const health = await client.health();
    const version = await client.getVersion();
    const stats = await client.getStats();

    res.json({
      health,
      version,
      stats,
      apiUrl: "http://api.new-search.zoo",
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// API endpoint to list indexes
app.get("/api/indexes", async (_req, res) => {
  try {
    const indexes = await client.getIndexes();
    res.json(indexes);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// API endpoint to create an index
app.post("/api/indexes", async (req, res) => {
  try {
    const { uid, primaryKey } = req.body;
    const index = await client.createIndex(uid, { primaryKey });
    res.json(index);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// API endpoint to add documents
app.post("/api/indexes/:indexUid/documents", async (req, res) => {
  try {
    const { indexUid } = req.params;
    const documents = req.body;
    const index = client.index(indexUid);
    const response = await index.addDocuments(documents);
    res.json(response);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// API endpoint to search (supports both GET and POST)
app
  .route("/api/search/:indexUid")
  .get(async (req, res) => {
    try {
      const { indexUid } = req.params;
      const { q, query, limit, offset, ...options } = req.query;
      const searchQuery = q || query || "";
      const searchOptions = {
        limit: limit ? parseInt(limit) : 20,
        offset: offset ? parseInt(offset) : 0,
        ...options,
      };
      const index = client.index(indexUid);
      const results = await index.search(searchQuery, searchOptions);
      res.json(results);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  })
  .post(async (req, res) => {
    try {
      const { indexUid } = req.params;
      const { query, options = {} } = req.body;
      const index = client.index(indexUid);
      const results = await index.search(query, options);
      res.json(results);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

// Crawler status endpoint
app.get("/api/crawler/status", async (_req, res) => {
  try {
    // Get queue sizes
    const [pendingLength, activeLength, failedLength] = await Promise.all([
      redis.lLen("crawler:pending"),
      redis.zCard("crawler:activeSet"),
      redis.lLen("crawler:failed"),
    ]);

    // Get worker information from Redis
    const workerIds = await redis.sMembers("crawler:workers");
    const workers = [];

    // Get details for each worker
    for (const workerId of workerIds) {
      const workerData = await redis.hGetAll(`crawler:workers:${workerId}`);
      if (workerData && Object.keys(workerData).length > 0) {
        workers.push({
          id: workerId,
          ...workerData,
        });
      }
    }

    // Get completed URLs count
    const completedKeys = await redis.keys("crawler:completed:*");
    const urlsCrawled = completedKeys.length;

    // Get recent URLs from the recent list
    const recentUrls = await redis.lRange("crawler:recent", 0, 9);

    // Get crawler state to check if running
    const crawlerState = await redis.hGetAll("crawler:state");
    const currentUrlsCrawled = parseInt(crawlerState.urls_crawled || "0");

    // Determine if crawler is running based on:
    // 1. Active workers exist
    // 2. Active URLs being processed
    // 3. Pending URLs exist and urls_crawled is changing
    const isRunning =
      workers.length > 0 || activeLength > 0 || (pendingLength > 0 && currentUrlsCrawled > 0);

    // Get start time from first worker
    let startedAt = null;
    if (workers.length > 0 && workers[0].started_at) {
      startedAt = workers[0].started_at;
    }

    // Build status response
    const status = {
      status: isRunning ? "running" : "stopped",
      started_at: startedAt,
      urls_crawled: urlsCrawled.toString(),
      urls_queued: pendingLength.toString(),
      urls_active: activeLength.toString(),
      urls_failed: failedLength.toString(),
      errors: crawlerState.errors || "0",
      current_url: null,
      recent_urls: recentUrls,
      workers: workers,
      progress: {},
    };

    res.json(status);
  } catch (error) {
    console.error("Crawler status error:", error);
    res.status(500).json({ error: error.message });
  }
});

// Health check endpoint
app.get("/ok", (_req, res) => {
  res.send("OK");
});

app.listen(port, () => {
  console.log(`New Search app listening at http://localhost:${port}`);
  console.log(`MeiliSearch API: ${process.env.MEILI_HOST || "http://api.new-search.zoo"}`);
  console.log(
    `Using API Key: ${process.env.MEILI_MASTER_KEY ? `***${process.env.MEILI_MASTER_KEY.slice(-4)}` : "Not set"}`,
  );
});
