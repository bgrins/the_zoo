#!/usr/bin/env -S npx tsx

/**
 * Build script for home.zoo - generates a user-friendly gallery of Zoo apps
 * Reads the static HTML template and replaces placeholders with app data
 */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import yaml from "yaml";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

interface Site {
  domain: string;
  type: string;
  port: string | number;
  service: string;
  description?: string;
  icon?: string;
  hasOAuth?: boolean;
  httpsOnly?: boolean;
  onDemand?: boolean;
}

interface SitesYaml {
  sites: Site[];
}

// System services that should be hidden from the gallery
const SYSTEM_SERVICES = new Set([
  "coredns",
  "caddy",
  "proxy",
  "redis",
  "postgres",
  "mysql",
  "stalwart",
  "hydra",
  "static-server",
  "secure-gravatar-com",
  "auth-zoo",
]);

// System domains that should be hidden
const SYSTEM_DOMAINS = new Set([
  "system-api.zoo",
  "status.zoo",
  "home.zoo",
  "mail-api.zoo",
  "admin.auth.zoo",
  "auth.zoo",
  "secure.gravatar.com",
]);

function generateAppCards(sites: Site[]): string {
  if (sites.length === 0) {
    return `<div class="empty-state">
        <div class="empty-state-icon">🦒</div>
        <p>No applications configured yet</p>
      </div>`;
  }

  const cards = sites
    .map(
      (site) => `
    <a href="https://${site.domain}" class="app-card" target="_blank" rel="noopener noreferrer">
      <div class="app-icon">${site.icon || "🌐"}</div>
      <div class="app-info">
        <h3 class="app-name">${site.domain.replace(".zoo", "")}</h3>
        <p class="app-description">${site.description || "Zoo application"}</p>
        <div class="app-badges">
          ${site.onDemand ? '<span class="badge badge-on-demand">On-Demand</span>' : ""}
          ${site.hasOAuth ? '<span class="badge badge-oauth">OAuth</span>' : ""}
          ${site.httpsOnly ? '<span class="badge badge-https">HTTPS Only</span>' : ""}
        </div>
      </div>
    </a>`,
    )
    .join("");

  return `<div class="apps-grid">${cards}</div>`;
}

async function main() {
  const rootDir = path.resolve(__dirname, "..");
  const sitesYamlPath = path.join(rootDir, "core/SITES.yaml");
  const templatePath = path.join(rootDir, "sites/static/home.zoo/dist/index.html");

  // Read SITES.yaml
  if (!fs.existsSync(sitesYamlPath)) {
    console.error("Error: SITES.yaml not found. Run 'npm run generate-config' first.");
    process.exit(1);
  }

  // Read template
  if (!fs.existsSync(templatePath)) {
    console.error(`Error: Template not found at ${templatePath}`);
    process.exit(1);
  }

  const sitesYamlContent = fs.readFileSync(sitesYamlPath, "utf8");
  const sitesData: SitesYaml = yaml.parse(sitesYamlContent);

  // Filter to user-facing apps only
  const userApps = sitesData.sites.filter(
    (site) => !SYSTEM_SERVICES.has(site.service) && !SYSTEM_DOMAINS.has(site.domain),
  );

  // Sort by domain name
  userApps.sort((a, b) => a.domain.localeCompare(b.domain));

  // Generate app cards HTML
  const appsGridHtml = generateAppCards(userApps);

  // Read template and replace placeholders
  let html = fs.readFileSync(templatePath, "utf8");
  html = html.replace("<!--APPS_GRID-->", appsGridHtml);

  // Write back to the same file
  fs.writeFileSync(templatePath, html);

  console.log(`Generated home.zoo with ${userApps.length} applications`);
  console.log(`Output: ${templatePath}`);
}

main();
