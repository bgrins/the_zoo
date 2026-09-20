#!/usr/bin/env -S npx tsx

/**
 * Configuration generator for Zoo development environment.
 * Parses docker-compose.yaml and generates Caddyfile and CoreDNS zone file.
 */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execSync } from "node:child_process";
import yaml from "yaml";
import {
  ANALYTICS_SEED_PATH,
  renderSharedJs,
  SHARED_JS_PATH,
  siteIdsFor,
} from "./analytics-sites.js";
import {
  extractPortFromServiceConfig,
  parseDockerCompose,
  type DockerComposeService,
} from "./docker-compose-utils.js";
import type { Site } from "./lib/sites.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT = path.resolve(__dirname, "..");
const TEMPLATES_DIR = path.join(__dirname, "templates");

// External domains with no backing service: Caddy answers 200 so telemetry doesn't fail
const SWALLOWED_DOMAINS = ["pdat.matterlytics.com", "api.rudderlabs.com"];
const ALLOWED_EXTERNAL_DOMAINS = ["secure.gravatar.com", ...SWALLOWED_DOMAINS];

// Seconds Caddy waits for an on-demand container to become ready before returning 504
const ON_DEMAND_TIMEOUT_SECONDS = 90;

interface ServiceInfo {
  port?: number;
  domains?: string[];
  domainPorts?: Record<string, string>;
  type?: "proxy" | "static";
  httpsOnly?: boolean;
}

/**
 * A file in scripts/templates with each @@NAME@@ replaced by values[NAME]. Throws on a
 * placeholder without a value and on a value without a placeholder.
 */
function renderTemplate(name: string, values: Record<string, string | number>): string {
  const template = fs.readFileSync(path.join(TEMPLATES_DIR, name), "utf8");
  const used = new Set<string>();
  const output = template.replace(/@@(\w+)@@/g, (_, key: string) => {
    if (!(key in values)) {
      throw new Error(`${name}: no value for @@${key}@@`);
    }
    used.add(key);
    return String(values[key]);
  });
  const unused = Object.keys(values).filter((key) => !used.has(key));
  if (unused.length > 0) {
    throw new Error(`${name} has no placeholder for ${unused.join(", ")}`);
  }
  return output;
}

// Blocks that each end in a newline, for a placeholder on a line of its own: blank lines
// between them, and the placeholder's own newline leaves one after the last
const joinBlocks = (blocks: string[]) => blocks.join("\n");

const generatedHeader = (name: string) =>
  `# Auto-generated ${name} - DO NOT EDIT MANUALLY\n# \`npm run generate-config\` to regenerate\n\n`;

const HTML_ENTITIES: Record<string, string> = {
  amp: "&",
  lt: "<",
  gt: ">",
  quot: '"',
  mdash: "—",
  ndash: "–",
  middot: "·",
};

function decodeHtmlEntities(text: string): string {
  return text.replace(/&(#\d+|[a-z]+);/g, (entity, name: string) =>
    name.startsWith("#")
      ? String.fromCodePoint(Number(name.slice(1)))
      : (HTML_ENTITIES[name] ?? entity),
  );
}

// zoo-sites serves many domains under one zoo.description label; each site's home page
// title describes it better
function loadSiteTitles(): Record<string, string> {
  const titles = JSON.parse(
    fs.readFileSync(path.join(ROOT, "core/zoo-sites-titles.json"), "utf8"),
  ) as Record<string, string>;
  return Object.fromEntries(
    Object.entries(titles).map(([domain, title]) => [domain, decodeHtmlEntities(title)]),
  );
}

function serviceLabels(service: DockerComposeService): string[] {
  if (!service.labels) return [];
  return Array.isArray(service.labels)
    ? service.labels.map(String)
    : Object.entries(service.labels).map(([k, v]) => `${k}=${v}`);
}

class ConfigGenerator {
  private composeFile: string;
  private composeServices: Record<string, DockerComposeService> = {};
  private services: Record<string, ServiceInfo> = {};

  constructor(composeFile = path.join(ROOT, "docker-compose.yaml")) {
    this.composeFile = path.resolve(composeFile);
  }

  /**
   * Load OAuth client configurations from Hydra clients directory
   */
  private getOAuthClients(): Set<string> {
    const oauthClients = new Set<string>();
    const clientsDir = path.join(ROOT, "core/hydra/clients");

    if (fs.existsSync(clientsDir)) {
      const files = fs.readdirSync(clientsDir);

      for (const file of files) {
        if (file.endsWith(".json")) {
          try {
            const content = fs.readFileSync(path.join(clientsDir, file), "utf8");
            const clients = JSON.parse(content);

            // Each file can contain multiple clients
            for (const client of clients) {
              // Extract domain from redirect_uris
              if (client.redirect_uris) {
                for (const uri of client.redirect_uris) {
                  const match = uri.match(/https?:\/\/([^/]+)\//);
                  if (match) {
                    oauthClients.add(match[1]);
                  }
                }
              }
            }
          } catch (error) {
            console.warn(`Failed to parse OAuth client file ${file}:`, error);
          }
        }
      }
    }

    return oauthClients;
  }

  /**
   * <service>.zoo for each core service with an IP Docker assigns, which CoreDNS resolves
   * through Docker's DNS. DNS, Caddy and the proxy have fixed IPs, which config refers to.
   */
  coreServiceAliases(): string[] {
    return Object.entries(this.composeServices)
      .filter(([, config]) => serviceLabels(config).includes("zoo.core=true"))
      .filter(
        ([, config]) =>
          Array.isArray(config.networks) ||
          !Object.values(config.networks ?? {}).some((network) => network?.ipv4_address),
      )
      .map(([name]) => `${name}.zoo`);
  }

  /**
   * Scan the sites/static directory for static sites following the convention:
   * sites/static/{domain}/dist/
   */
  scanStaticSites(): string[] {
    const staticDir = path.join(ROOT, "sites/static");
    if (!fs.existsSync(staticDir)) {
      return [];
    }

    return fs
      .readdirSync(staticDir, { withFileTypes: true })
      .filter((entry) => entry.isDirectory() || entry.isSymbolicLink())
      .map((entry) => entry.name)
      .filter((domain) => {
        const distPath = path.join(staticDir, domain, "dist");
        return (
          domain.endsWith(".zoo") && fs.existsSync(distPath) && fs.statSync(distPath).isDirectory()
        );
      });
  }

  /**
   * Parse docker-compose.yaml and extract zoo-labeled services
   */
  parseComposeFile() {
    if (!fs.existsSync(this.composeFile)) {
      console.error(`Error: ${this.composeFile} not found`);
      process.exit(1);
    }

    // Use the expanded configuration to resolve YAML anchors
    this.composeServices = parseDockerCompose(this.composeFile).services || {};
    this.services = {};

    for (const [serviceName, serviceConfig] of Object.entries(this.composeServices)) {
      const serviceInfo: ServiceInfo = {};

      const extractedPort = extractPortFromServiceConfig(serviceConfig);
      if (extractedPort) {
        serviceInfo.port = Number(extractedPort);
      }

      for (const label of serviceLabels(serviceConfig)) {
        if (label.startsWith("zoo.domains=")) {
          const domainSpecs = label
            .substring("zoo.domains=".length)
            .split(",")
            .map((d) => d.trim());

          // Parse domains with optional port specification
          serviceInfo.domains = [];
          serviceInfo.domainPorts = {};

          for (const spec of domainSpecs) {
            if (spec.includes(":")) {
              const [domain, port] = spec.split(":");
              serviceInfo.domains.push(domain);
              serviceInfo.domainPorts[domain] = port;
            } else {
              serviceInfo.domains.push(spec);
            }
          }

          serviceInfo.type = "proxy";
        }

        if (label === "zoo.https-only=true") {
          serviceInfo.httpsOnly = true;
        }
      }

      // Only keep services that have zoo.domains labels
      if (serviceInfo.domains) {
        this.services[serviceName] = serviceInfo;
      }
    }

    // Static sites are served by Caddy itself via a virtual service entry
    const staticSites = this.scanStaticSites();
    if (staticSites.length > 0) {
      this.services["static-server"] = {
        domains: staticSites,
        type: "static",
        port: 80,
      };
    }

    return this.services;
  }

  /**
   * Validate parsed service configuration
   */
  validateServices() {
    const errors: string[] = [];
    const allDomains: string[] = [];
    const aliases = this.coreServiceAliases();

    for (const [serviceName, config] of Object.entries(this.services)) {
      // Every proxied domain needs a port; guessing one would route it to nothing
      if (config.type === "proxy") {
        for (const domain of config.domains || []) {
          if (!config.domainPorts?.[domain] && !config.port) {
            errors.push(
              `Service '${serviceName}' has no port for ${domain}: set PORT or expose, or label it zoo.domains=${domain}:<port>`,
            );
          }
        }
      }

      for (const domain of config.domains || []) {
        if (allDomains.includes(domain)) {
          const existingService = Object.entries(this.services).find(
            ([name, svc]) => name !== serviceName && svc.domains?.includes(domain),
          );
          errors.push(
            existingService
              ? `Duplicate domain '${domain}' - used by both '${serviceName}' and '${existingService[0]}'`
              : `Duplicate domain '${domain}' found in service '${serviceName}'`,
          );
        }
        allDomains.push(domain);

        if (aliases.includes(domain)) {
          errors.push(`Domain '${domain}' of '${serviceName}' is a core service's DNS alias`);
        }

        if (!domain.endsWith(".zoo") && !ALLOWED_EXTERNAL_DOMAINS.includes(domain)) {
          errors.push(`Domain '${domain}' must end with .zoo`);
        }
      }
    }

    if (errors.length > 0) {
      console.log("Validation errors:");
      for (const error of errors) {
        console.log(`  - ${error}`);
      }
      return false;
    }

    return true;
  }

  /**
   * Generate Caddyfile content
   */
  generateCaddyfile() {
    const sites: string[] = [];
    for (const [serviceName, config] of Object.entries(this.services)) {
      for (const domain of config.domains || []) {
        if (config.type === "static") {
          // performance.zoo serves shared.js cross-origin and must not inject into itself
          sites.push(
            domain === "performance.zoo"
              ? renderTemplate("Caddyfile.performance-zoo", {})
              : `${domain}, http://${domain} {\n    import static_site ${domain}\n}\n`,
          );
        } else {
          const snippet = config.httpsOnly ? "proxy_site_https_only" : "proxy_site";
          // Use domain-specific port if specified, otherwise fall back to service port
          const port = config.domainPorts?.[domain] || config.port;
          sites.push(
            `${domain}, http://${domain} {\n    import ${snippet} ${serviceName} ${port}\n}\n`,
          );
        }
      }
    }

    return (
      generatedHeader("Caddyfile") +
      renderTemplate("Caddyfile", {
        ON_DEMAND_TIMEOUT_SECONDS,
        SITES: joinBlocks(sites),
        SWALLOWED_SITES: joinBlocks(
          SWALLOWED_DOMAINS.map((domain) =>
            renderTemplate("Caddyfile.swallowed-domain", { DOMAIN: domain }),
          ),
        ),
      })
    );
  }

  /**
   * Generate SITES.yaml file content
   */
  generateSitesList() {
    const oauthClients = this.getOAuthClients();
    const siteTitles = loadSiteTitles();

    const sitesMap = new Map<string, Site>();

    for (const [serviceName, config] of Object.entries(this.services)) {
      const composeService = this.composeServices[serviceName];
      const labels = composeService ? serviceLabels(composeService) : [];
      const labelValue = (key: string) =>
        labels.find((l) => l.startsWith(`${key}=`))?.substring(key.length + 1);
      const profiles = composeService?.profiles || [];

      for (const domain of config.domains || []) {
        const description = siteTitles[domain] ?? labelValue("zoo.description");
        const icon = labelValue("zoo.icon");
        // Optional fields only when set, in this order in the YAML
        sitesMap.set(domain, {
          domain,
          type: config.type || "proxy",
          // Use domain-specific port if specified, otherwise fall back to service port
          port: Number(config.domainPorts?.[domain] || config.port || 80),
          service: serviceName,
          ...(description && { description }),
          ...(icon && { icon }),
          hasOAuth: oauthClients.has(domain),
          ...(labels.includes("zoo.https-only=true") && { httpsOnly: true }),
          ...(profiles.includes("on-demand") && { onDemand: true }),
          ...(profiles.includes("heavy") && { heavy: true }),
        });
      }
    }

    const sites = Array.from(sitesMap.values()).sort((a, b) => a.domain.localeCompare(b.domain));

    const yamlData = {
      _comment: [
        "Auto-generated list of all sites in The Zoo",
        "DO NOT EDIT MANUALLY",
        "`npm run generate-config` to regenerate",
        "",
        "This file defines all sites for DNS and proxy configuration",
        "Databases must be explicitly configured - see docs/databases.md",
      ],
      sites,
    };

    return yaml.stringify(yamlData);
  }

  /**
   * Generate CoreDNS Corefile configuration
   */
  generateCorefileContent() {
    const zooDomains: string[] = [];
    const externalDomains = new Set<string>(SWALLOWED_DOMAINS);
    for (const config of Object.values(this.services)) {
      for (const domain of config.domains || []) {
        if (domain.endsWith(".zoo")) {
          zooDomains.push(domain);
        } else {
          externalDomains.add(domain);
        }
      }
    }

    return (
      generatedHeader("CoreDNS configuration") +
      renderTemplate("Corefile", {
        ALIASES: this.coreServiceAliases()
          .map((alias) => `${alias}:53`)
          .join(" "),
        EXTERNAL_DOMAINS: joinBlocks(
          [...externalDomains]
            .sort()
            .map((domain) => renderTemplate("Corefile.external-domain", { DOMAIN: domain })),
        ),
        HOSTS: zooDomains
          .sort()
          .map((domain) => `        {$ZOO_CADDY_IP} ${domain}`)
          .join("\n"),
      })
    );
  }

  /**
   * Squid ACLs for the domains DNS treats specially, included by core/proxy/squid.conf
   */
  generateSquidAcls() {
    return `# Auto-generated Squid ACLs - DO NOT EDIT MANUALLY
# \`npm run generate-config\` to regenerate

# External domains the proxy allows: DNS resolves them to Caddy, not the internet
acl external_domains dstdomain ${ALLOWED_EXTERNAL_DOMAINS.join(" ")}

# Service names DNS resolves to the containers themselves, which would bypass Caddy
acl internal_services dstdomain ${this.coreServiceAliases().join(" ")}
`;
  }

  /**
   * shared.js with a Matomo site ID for every tracked domain
   */
  generateSharedJs() {
    const domains = Object.values(this.services).flatMap((config) => config.domains || []);
    const { siteIds, missing } = siteIdsFor(domains);
    if (missing.length > 0) {
      console.warn(
        `Warning: no Matomo site in ${path.relative(ROOT, ANALYTICS_SEED_PATH)} for ${missing.join(", ")}; analytics won't track them (see docs/analytics.md)`,
      );
    }
    return renderSharedJs(fs.readFileSync(SHARED_JS_PATH, "utf8"), siteIds);
  }

  /**
   * Write generated configuration files
   */
  async writeFiles(dryRun = false) {
    const files: { path: string; content: string; name: string; backup?: boolean }[] = [
      {
        path: path.join(ROOT, "core/caddy/Caddyfile"),
        content: this.generateCaddyfile(),
        name: "Caddyfile",
      },
      {
        path: path.join(ROOT, "core/coredns/Corefile"),
        content: this.generateCorefileContent(),
        name: "Corefile",
      },
      {
        path: path.join(ROOT, "core/proxy/acls.conf"),
        content: this.generateSquidAcls(),
        name: "acls.conf",
      },
      {
        path: path.join(ROOT, "core/SITES.yaml"),
        content: this.generateSitesList(),
        name: "SITES.yaml",
      },
      {
        path: SHARED_JS_PATH,
        content: this.generateSharedJs(),
        name: "shared.js",
        // Caddy serves this directory, so no backup next to it
        backup: false,
      },
    ];

    if (dryRun) {
      console.log("=== DRY RUN MODE ===");
      for (const file of files) {
        console.log(`\nWould write to ${file.path}:`);
        console.log("-".repeat(50));
        console.log(file.content);
      }
      return;
    }

    let updatedCount = 0;
    for (const file of files) {
      if (fs.existsSync(file.path) && fs.readFileSync(file.path, "utf8") === file.content) {
        console.log(`Skipped ${file.name} (no changes detected)`);
        continue;
      }

      if (fs.existsSync(file.path) && file.backup !== false) {
        fs.copyFileSync(file.path, `${file.path}.bak`);
        console.log(`Backed up ${file.path} to ${file.path}.bak`);
      }

      fs.writeFileSync(file.path, file.content);
      console.log(`Generated ${file.path}`);
      updatedCount++;
    }

    if (updatedCount === 0) {
      console.log("\nNo files were updated - all configs are up to date");
    }
  }
}

/**
 * Main function
 */
async function main() {
  const args = process.argv.slice(2);
  const dryRun = args.includes("--dry-run");
  const composeFileIndex = args.indexOf("--compose-file");
  const composeFile = composeFileIndex !== -1 ? args[composeFileIndex + 1] : undefined;

  if (args.includes("--help") || args.includes("-h")) {
    console.log("Usage: node generate-config.js [options]");
    console.log("");
    console.log("Options:");
    console.log("  --dry-run           Show what would be generated without writing files");
    console.log("  --compose-file FILE Path to docker-compose.yaml (default: docker-compose.yaml)");
    console.log("  --help, -h          Show this help message");
    process.exit(0);
  }

  const generator = new ConfigGenerator(composeFile);

  console.log("Parsing docker-compose.yaml...");
  const services = generator.parseComposeFile();

  console.log(`Found ${Object.keys(services).length} services to configure:`);
  for (const [serviceName, config] of Object.entries(services)) {
    const serviceType = config.type || "unknown";
    const targets = (config.domains || [])
      .map((domain) => `${domain} -> :${config.domainPorts?.[domain] || config.port || "?"}`)
      .join(", ");
    console.log(`  ${serviceName} (${serviceType}): ${targets}`);
  }

  console.log("\nValidating configuration...");
  if (!generator.validateServices()) {
    process.exit(1);
  }

  console.log("Validation passed!");

  console.log("\nGenerating configuration files...");
  await generator.writeFiles(dryRun);

  if (!dryRun) {
    console.log("\nBuilding home.zoo...");
    execSync("npx tsx scripts/build-home-zoo.ts", { stdio: "inherit", cwd: ROOT });
  }
}

main();
