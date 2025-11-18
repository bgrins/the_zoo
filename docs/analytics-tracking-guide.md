# Comprehensive Agent Tracking Guide

This guide documents the complete analytics tracking system implemented in The Zoo for monitoring LLM agent behavior.

## Architecture Overview

```
┌─────────────────┐
│   Caddy Proxy   │  Injects shared.js before </body>
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ performance.zoo │  Serves shared.js
│  /public/       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  analytics.zoo  │  Matomo instance
│   (Site IDs)    │  Stores all tracking data
└─────────────────┘
```

## What We Track (Priority Order)

#### 1. Navigation & Page Flow

- **Page views** with full URL paths
- **Referrer chains** (how agents navigate between sites)
- **Cross-domain tracking** across all .zoo sites
- **Entry/exit pages** per session
- **Session duration** with HeartBeat timer (15s intervals)

**Why**: Understanding agent navigation patterns reveals decision-making logic and task completion strategies.

**Data captured**:

- Every page view with timestamp
- Complete referrer URL
- Cross-site journey tracking
- Time spent on each page (accurate to 15s)

---

#### 2. Interaction Events

- **All clicks** with element context (tag, id, class, text)
- **Button clicks** with timestamp
- **Link clicks** with href targets
- **Form submissions** with form ID and action
- **Form field interactions** (focus, blur, filled status)

**Why**: Agents interact purposefully. Tracking every interaction reveals which UI elements work/fail and how agents recover from errors.

**Data captured**:

```javascript
// Example event structure
{
  category: 'Click',
  action: 'button',
  name: 'submit-btn|btn-primary|Submit Form',
  value: 1731942345678
}
```

---

#### 3. Custom Agent Dimensions

Custom dimensions 1-4 track agent-specific context:

| Dimension | Field          | Example Values                                    |
| --------- | -------------- | ------------------------------------------------- |
| 1         | Agent Type     | `Playwright/Puppeteer`, `Chrome-Agent`, `Unknown` |
| 2         | Session ID     | `lj3k9x2m` (base36 timestamp)                     |
| 3         | Task Type      | `email-composition`, `form-fill`, `search-task`   |
| 4         | Attempt Number | `1`, `2`, `3`, etc.                               |

**Why**: THE MOST VALUABLE data - allows comparing different agents, tracking success rates, and correlating outcomes with agent parameters.

**Usage**:

```javascript
// Set agent context from your test script
window.__zooTracking.setAgentContext({
  agentType: "Claude-Sonnet-4",
  taskType: "compose-email",
  attemptNumber: 3,
});
```

---

#### 4. Goal & Conversion Tracking

Track task completion via goals:

```javascript
// Track goal completion
window.__zooTracking.trackGoal(1); // Goal ID 1: Email sent
window.__zooTracking.trackGoal(2, 150.0); // Goal ID 2: Purchase ($150)
```

**Why**: The ultimate measure of agent success - did it complete the task?

**Configuration**: Goals must be created in Matomo UI first (see Setup section).

---

#### 5. Search Behavior

- **Search queries** (exact keywords)
- **Search category** (if specified)
- **Results count** (if available)

**Why**: Shows how agents formulate queries and whether they understand search capabilities.

**Auto-detected**: Tracks any form with `input[type="search"]` or input names containing "search", "query", or "q".

**Manual tracking**:

```javascript
window.__zooTracking.trackSearch("user authentication", "documentation", 42);
```

---

#### 6. Error Tracking

- **JavaScript errors** (message, file, line number)
- **Promise rejections** (unhandled)
- **AJAX errors** (HTTP status, URL, duration)
- **Network failures** (fetch errors)

**Why**: Errors show where agents get stuck and how they recover.

**Auto-tracked**: All errors are automatically captured.

---

#### 7. Performance Metrics

- **Page load time** (network, server, transfer, DOM processing)
- **Time to interactive**
- **AJAX request timing**
- **Resource load timing**

**Why**: Performance affects agent behavior differently than humans - shows impact of slow responses on task completion.

**Data captured**:

- Network time (DNS + connection)
- Server time (request to response)
- Transfer time (response download)
- DOM processing time
- DOM completion time
- Onload event time

---

#### 8. Session & Engagement Patterns

- **Scroll depth** (max percentage reached)
- **Time on page** (at page exit)
- **Tab visibility** (hidden/visible events)
- **Content impressions** (visible content blocks)

**Why**: Shows agent attention patterns and whether they process all content or skip sections.

---

#### 9. Downloads & Outlinks

- **File downloads** (.pdf, .zip, .doc, .json, .csv, .xml, .sql, .md, etc.)
- **External link clicks**

**Why**: Shows whether agents follow external references and interact with files.

---

## Site ID Mapping

Each .zoo domain has a unique Site ID in Matomo:

| Domain            | Site ID | Status            |
| ----------------- | ------- | ----------------- |
| snappymail.zoo    | 1       | ❌ Error          |
| search.zoo        | 2       | ✅ Configured     |
| auth.zoo          | 3       | ⏳ Needs creation |
| utils.zoo         | 4       | ⏳ Needs creation |
| wiki.zoo          | 5       | ⏳ Needs creation |
| miniflux.zoo      | 6       | ⏳ Needs creation |
| focalboard.zoo    | 7       | ⏳ Needs creation |
| excalidraw.zoo    | 8       | ⏳ Needs creation |
| gitea.zoo         | 9       | ⏳ Needs creation |
| planka.zoo        | 10      | ⏳ Needs creation |
| classifieds.zoo   | 11      | ⏳ Needs creation |
| oauth-example.zoo | 12      | ⏳ Needs creation |
| lorem-rss.zoo     | 13      | ⏳ Needs creation |
| northwind.zoo     | 14      | ⏳ Needs creation |
| example.zoo       | 15      | ⏳ Needs creation |

## Setting Up New Sites in Matomo

### Step 1: Create Site in Matomo UI

1. Login to `https://analytics.zoo` (user: `analytics_user`, pass: `analytics_pw`)
2. Go to **Administration → Measurables → Manage Measurables**
3. Click **+ Add a New Measurable**
4. Choose **Intranet Website**
5. Fill in:
   - **Name**: e.g., "Auth Zoo"
   - **URLs**: `http://auth.zoo` and `https://auth.zoo`
   - **Timezone**: Your timezone (e.g., `UTC`)
   - **Currency**: USD (or relevant)
6. Click **Save**

### Step 2: Configure Custom Dimensions

For each site, add custom dimensions:

1. Go to **Administration → Custom Dimensions**
2. Click **Configure a new Custom Dimension**
3. Create these dimensions:

| Name           | Scope  | Active | Description                                     |
| -------------- | ------ | ------ | ----------------------------------------------- |
| Agent Type     | Visit  | Yes    | Type of agent (Claude, GPT-4, Playwright, etc.) |
| Session ID     | Visit  | Yes    | Unique session identifier                       |
| Task Type      | Action | Yes    | Type of task being performed                    |
| Attempt Number | Action | Yes    | Which attempt at the task                       |

### Step 3: Configure Goals (Optional)

For task-based tracking, create goals:

1. Go to **Administration → Goals → Manage Goals**
2. Click **Add a new goal**
3. Examples:
   - **Goal**: Email Sent
     - **Triggered**: Manually (via `trackGoal(1)`)
     - **Revenue**: Optional
   - **Goal**: Form Completed
     - **Triggered**: URL matches `/success`
     - **Revenue**: Optional

### Step 4: Verify Tracking

1. Visit the site (e.g., `http://auth.zoo`)
2. Open browser console
3. Look for: `✅ Comprehensive tracking initialized for auth.zoo`
4. Check `window.__zooTracking` exists
5. Go to Matomo → **Visitors → Real-time** to see live data

### Step 5: Capture Golden State

After configuring all sites:

```bash
./scripts/seed-data/capture-analytics-state.sh
git add core/mysql/sql/analytics_seed.sql sites/apps/analytics.zoo/data-golden/
git commit -m "Add analytics configuration for new sites"
```

## Using the Tracking API

### Basic Usage

The tracking API is available at `window.__zooTracking`:

```javascript
// Check if tracking is loaded
if (window.__zooTracking) {
  console.log("Tracking version:", window.__zooTracking.version);
  console.log("Site ID:", window.__zooTracking.siteId);
  console.log("Domain:", window.__zooTracking.domain);
}
```

### Track Custom Events

```javascript
// Syntax: trackEvent(category, action, name, value)
window.__zooTracking.trackEvent("Email", "Compose", "new-message", 1);
window.__zooTracking.trackEvent("API", "Call", "/api/users", 245); // 245ms
window.__zooTracking.trackEvent("Agent", "Thinking", "analyzing-page", 5000);
```

### Track Goal Completion

```javascript
// Simple goal
window.__zooTracking.trackGoal(1);

// Goal with revenue
window.__zooTracking.trackGoal(2, 49.99);
```

### Update Agent Context

```javascript
window.__zooTracking.setAgentContext({
  agentType: "Claude-Sonnet-4",
  taskType: "email-composition",
  attemptNumber: 2,
});
```

### Track Search with Results

```javascript
// After getting search results
window.__zooTracking.trackSearch("authentication", "docs", 15);
```

### Set Custom Dimensions

```javascript
// Dimension 5 (must be configured in Matomo first)
window.__zooTracking.setDimension(5, "custom-value");
```

### Direct Matomo Access

For advanced use cases, access Matomo directly:

```javascript
// Access the _paq array
window.__zooTracking.matomo.push(["trackEvent", "Custom", "Event", "Name"]);

// Or use window._paq directly
window._paq.push(["trackPageView", "Custom Page Title"]);
```

## Example: Tracking an Agent Task

Here's how to track a complete agent workflow:

```javascript
// 1. Set agent context at start
window.__zooTracking.setAgentContext({
  agentType: "Claude-Sonnet-4",
  taskType: "send-email-via-snappymail",
  attemptNumber: 1,
});

// 2. Track major steps
window.__zooTracking.trackEvent("Task", "Step", "login", 1);
// ... agent logs in ...
window.__zooTracking.trackEvent("Task", "Step", "compose", 2);
// ... agent composes email ...
window.__zooTracking.trackEvent("Task", "Step", "send", 3);

// 3. Track completion
window.__zooTracking.trackGoal(1); // Goal 1: Email sent

// 4. Track success/failure
window.__zooTracking.trackEvent("Task", "Result", "success");
```

## Data Analysis

### Key Reports in Matomo

1. **Behavior → Pages**: See most visited pages
2. **Behavior → Events**: Analyze all tracked events
3. **Behavior → Site Search**: Review search patterns
4. **Visitors → Visits Log**: See individual visitor sessions

## References

- [Matomo JavaScript Tracking Guide](https://developer.matomo.org/guides/tracking-javascript-guide)
- [Matomo Tracking API Reference](https://developer.matomo.org/api-reference/tracking-javascript)
- [Custom Dimensions Documentation](https://matomo.org/docs/custom-dimensions/)
- [Goals & Conversions](https://matomo.org/docs/tracking-goals-web-analytics/)
