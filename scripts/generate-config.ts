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
  extractPortFromServiceConfig,
  parseDockerCompose,
  type DockerComposeService,
} from "./docker-compose-utils.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT = path.resolve(__dirname, "..");

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
  containerName?: string;
  httpsOnly?: boolean;
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
   * Scan docker-compose services for apps that have build paths in sites/apps
   * Only include services that are explicitly defined in docker-compose.yaml
   */
  scanDockerServicesForApps() {
    const appServices: Record<string, ServiceInfo> = {};

    for (const [serviceName, serviceConfig] of Object.entries(this.composeServices)) {
      // Services with a zoo.domains label are handled in parseComposeFile
      if (serviceLabels(serviceConfig).some((label) => label.startsWith("zoo.domains="))) {
        continue;
      }

      if (serviceConfig.build) {
        const buildPath =
          typeof serviceConfig.build === "string"
            ? serviceConfig.build
            : serviceConfig.build.context;

        if (buildPath?.includes("/sites/apps/")) {
          // Use the app directory name as the domain
          const appDir = buildPath.split("/sites/apps/")[1];
          const domain = appDir.endsWith(".zoo") ? appDir : `${appDir}.zoo`;
          const port = extractPortFromServiceConfig(serviceConfig);

          appServices[serviceName] = {
            domains: [domain],
            type: "proxy",
            port: port ? Number(port) : undefined,
            containerName: serviceName,
          };
        }
      }
    }

    return appServices;
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

    // Add services discovered from docker-compose that have build paths in sites/apps
    const appServices = this.scanDockerServicesForApps();
    for (const [serviceName, appConfig] of Object.entries(appServices)) {
      const domainAlreadyClaimed = Object.values(this.services).some((service) =>
        service.domains?.includes(appConfig.domains?.[0] || ""),
      );

      if (!this.services[serviceName] && !domainAlreadyClaimed) {
        this.services[serviceName] = appConfig;
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
    let content = `# Auto-generated Caddyfile - DO NOT EDIT MANUALLY
# \`npm run generate-config\` to regenerate

{
    # Global options for development
    local_certs  # Use local CA for development certificates
    auto_https disable_redirects  # Enable HTTPS but don't force redirects

    # PKI configuration for stable test environment
    pki {
        ca local {
            # Set intermediate certificate lifetime to 1 year (default is 7 days)
            # This prevents constant regeneration on different machines
            intermediate_lifetime 365d
        }
    }

    # Load the replace-response module
    # replace must be nested inside encode so it sees the body before compression
    order replace after encode
    # Load the fail_injector module
    order fail_injector before reverse_proxy
    order fail_injector before file_server
    # Load the on_demand_docker module
    order on_demand_docker before reverse_proxy
    # Load the docker_status module
    order docker_status before reverse_proxy
}

# Container healthcheck endpoint (not logged: no log directive)
http://localhost {
    respond /health 200
    respond 404
}

# Logging configuration
(logging) {
    log {
        output file /var/log/caddy/access.log {
            roll_size 100mb
            roll_keep 10
            roll_keep_for 720h
        }
        format json
        level INFO
    }
}

# Performance Zoo auto-injection snippet
# Matches on the response Content-Type so only HTML documents are rewritten.
(performance_zoo) {
    replace {
        match {
            header Content-Type text/html*
        }
        "</body>" "<script src='https://performance.zoo/shared.js' async defer></script></body>"
        "</BODY>" "<script src='https://performance.zoo/shared.js' async defer></script></BODY>"

        # Convert CSP meta tags to report-only mode (allows injected scripts while logging violations)
        "http-equiv=\\"Content-Security-Policy\\"" "http-equiv=\\"Content-Security-Policy-Report-Only\\""
        "http-equiv='Content-Security-Policy'" "http-equiv='Content-Security-Policy-Report-Only'"
    }

    # Strip CSP headers to allow injected scripts in development environment
    header {
        match {
            header Content-Type text/html*
        }
        -Content-Security-Policy
        X-Performance-Zoo "injected"
    }

    # Apply compression after replacement (order directive ensures replace runs first)
    encode gzip
}

# Snippet for fail injection (uses environment CHAOS_MODE)
(fail_injection) {
    fail_injector {
        # This will only activate when CHAOS_MODE=1 in environment
        # The fail_injector reads CHAOS_MODE from environment automatically
    }
}

# Common proxy handler for on-demand containers
(proxy_handler) {
    import fail_injection
    on_demand_docker {args[0]} {args[1]} {
        timeout ${ON_DEMAND_TIMEOUT_SECONDS}
    }
    reverse_proxy {args[0]}:{args[1]} {
        # Trust only the proxy for client IP
        trusted_proxies {$ZOO_PROXY_IP}
        # Caddy will automatically handle X-Forwarded-* headers when trusted_proxies is set

        # Request uncompressed content from upstream so replace directive can modify it
        # This is critical for the replace directive to work on upstream responses
        header_up Accept-Encoding identity
    }
}

# Proxied site served on both HTTPS and HTTP: args[0]=container, args[1]=port
(proxy_site) {
    import logging
    @https_only {
        protocol http
        expression "{$ZOO_ALL_HTTPS_ONLY:false}" == "true"
    }
    redir @https_only https://{host}{uri} permanent
    import performance_zoo
    route {
        import proxy_handler {args[0]} {args[1]}
    }
}

# Proxied site that always redirects HTTP to HTTPS: args[0]=container, args[1]=port
(proxy_site_https_only) {
    import logging
    @http protocol http
    redir @http https://{host}{uri} permanent
    import performance_zoo
    route {
        import proxy_handler {args[0]} {args[1]}
    }
}

# Headers shared by all static sites
(static_headers) {
    header {
        X-Frame-Options "SAMEORIGIN"
        X-XSS-Protection "1; mode=block"
        X-Content-Type-Options "nosniff"
    }
}

# HTTP to HTTPS redirect for static sites
(static_https_redirect) {
    @https_only {
        protocol http
        expression "{$ZOO_STATIC_HTTPS_ONLY:false}" == "true" || "{$ZOO_ALL_HTTPS_ONLY:false}" == "true"
    }
    redir @https_only https://{host}{uri} permanent
}

# Static site served from sites/static/{args[0]}/dist
(static_site) {
    import logging
    import static_https_redirect
    import performance_zoo
    route {
        import fail_injection
        # Headers must come before file_server, which ends the route
        import static_headers
        root * /static/{args[0]}/dist
        file_server
    }
}

`;

    for (const [serviceName, config] of Object.entries(this.services)) {
      if (config.type === "static") {
        for (const domain of config.domains || []) {
          if (domain === "performance.zoo") {
            // performance.zoo serves shared.js cross-origin and must not inject into itself
            content += `${domain}, http://${domain} {
    import logging
    import static_https_redirect
    route {
        import fail_injection
        import static_headers
        header {
            Access-Control-Allow-Origin "*"
            Access-Control-Allow-Methods "GET, OPTIONS"
            Access-Control-Allow-Headers "Content-Type"
        }
        root * /static/${domain}/dist
        file_server
    }
}

`;
          } else {
            content += `${domain}, http://${domain} {\n    import static_site ${domain}\n}\n\n`;
          }
        }
        continue;
      }

      // Use containerName if provided (for directory-based services), otherwise use serviceName
      const containerName = config.containerName || serviceName;
      const snippet = config.httpsOnly ? "proxy_site_https_only" : "proxy_site";

      for (const domain of config.domains || []) {
        // Use domain-specific port if specified, otherwise fall back to service port
        const port = config.domainPorts?.[domain] || config.port;
        content += `${domain}, http://${domain} {\n    import ${snippet} ${containerName} ${port}\n}\n\n`;
      }
    }

    const systemApiDescription = `System API - Docker monitoring for The Zoo

Endpoints:
  GET https://system-api.zoo/docker/ok                         - Health check
  GET https://system-api.zoo/docker/api/containers             - List all containers
  GET https://system-api.zoo/docker/api/containers?stats=true  - List containers with CPU/memory stats
  GET https://system-api.zoo/docker/api/container/{name}/logs  - Get container logs (default: last 50 lines)
  GET https://system-api.zoo/docker/api/system-metrics         - Get system-wide Docker metrics

Features: CORS enabled, auto-filters Zoo containers, 2s stats cache`;

    content += `# Docker Status API - provides container status information
system-api.zoo, http://system-api.zoo {
    import logging

    route /docker/* {
        uri strip_prefix /docker
        docker_status
    }

    route {
        respond "${systemApiDescription}" 200
    }
}

`;

    content += `# Swallowed external domains - absorb telemetry/analytics requests\n`;
    for (const domain of SWALLOWED_DOMAINS) {
      content += `${domain}, http://${domain} {
    import logging

    header {
        Access-Control-Allow-Origin "*"
        Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
        Access-Control-Allow-Headers "*, Authorization"
    }
    respond 200
}

`;
    }

    return content;
  }

  /**
   * Generate SITES.yaml file content
   */
  generateSitesList() {
    const oauthClients = this.getOAuthClients();

    interface SiteInfo {
      domain: string;
      type: "proxy" | "static";
      port: string | number;
      service: string;
      description?: string;
      icon?: string;
      hasOAuth: boolean;
      httpsOnly?: boolean;
      onDemand?: boolean;
      heavy?: boolean;
    }
    const sitesMap = new Map<string, SiteInfo>();

    for (const [serviceName, config] of Object.entries(this.services)) {
      const composeService = this.composeServices[serviceName];
      const labels = composeService ? serviceLabels(composeService) : [];
      const labelValue = (key: string) =>
        labels.find((l) => l.startsWith(`${key}=`))?.substring(key.length + 1);
      const profiles = composeService?.profiles || [];

      for (const domain of config.domains || []) {
        sitesMap.set(domain, {
          domain,
          type: config.type || "proxy",
          // Use domain-specific port if specified, otherwise fall back to service port
          port: Number(config.domainPorts?.[domain] || config.port || 80),
          service: serviceName,
          description: labelValue("zoo.description"),
          icon: labelValue("zoo.icon"),
          hasOAuth: oauthClients.has(domain),
          httpsOnly: labels.includes("zoo.https-only=true"),
          onDemand: profiles.includes("on-demand"),
          heavy: profiles.includes("heavy"),
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
      sites: sites.map((site) => ({
        domain: site.domain,
        type: site.type,
        port: site.port,
        service: site.service,
        ...(site.description && { description: site.description }),
        ...(site.icon && { icon: site.icon }),
        hasOAuth: site.hasOAuth,
        ...(site.httpsOnly && { httpsOnly: site.httpsOnly }),
        ...(site.onDemand && { onDemand: site.onDemand }),
        ...(site.heavy && { heavy: site.heavy }),
      })),
    };

    return yaml.stringify(yamlData);
  }

  /**
   * Generate CoreDNS Corefile configuration
   */
  generateCorefileContent() {
    const allDomains: string[] = [];
    const externalDomains = new Set<string>(SWALLOWED_DOMAINS);
    for (const config of Object.values(this.services)) {
      for (const domain of config.domains || []) {
        if (domain.endsWith(".zoo")) {
          allDomains.push(domain);
        } else {
          externalDomains.add(domain);
        }
      }
    }

    let content = `# Auto-generated CoreDNS configuration - DO NOT EDIT MANUALLY
# \`npm run generate-config\` to regenerate

# Handle services that use Docker network aliases
postgres.zoo:53 redis.zoo:53 stalwart.zoo:53 hydra.zoo:53 mysql.zoo:53 {
    # Rewrite queries to remove .zoo suffix
    rewrite name suffix .zoo .

    # Forward to Docker's internal DNS
    forward . 127.0.0.11

    # Logging - only log denials and errors
    log . {
        class denial
    }
    errors
}

`;

    content += `# Handle external compatibility domains\n`;
    for (const domain of [...externalDomains].sort()) {
      content += `${domain}:53 {\n`;
      content += `    hosts {\n`;
      content += `        {$ZOO_CADDY_IP} ${domain}\n`;
      content += `        fallthrough\n`;
      content += `    }\n`;
      content += `    \n`;
      content += `    log . {\n`;
      content += `        class denial\n`;
      content += `    }\n`;
      content += `    errors\n`;
      content += `}\n\n`;
    }

    content += `# Handle only .zoo domains
zoo:53 {
    # Use hosts plugin with environment variable support
    hosts {
`;

    for (const domain of allDomains.sort()) {
      content += `        {$ZOO_CADDY_IP} ${domain}\n`;
    }

    content += `        {$ZOO_CADDY_IP} system-api.zoo\n`;

    content += `
        # Fallthrough for undefined subdomains
        fallthrough
    }

    # Template for wildcard domains not in hosts
    template IN A zoo {
        match ^[^.]+\\.zoo\\.?$
        answer "{{ .Name }} 3600 IN A {$ZOO_CADDY_IP}"
        fallthrough
    }

    # Email service records
    template IN MX zoo {
        match ^zoo\\.?$
        answer "{{ .Name }} 3600 IN MX 10 stalwart.zoo."
    }

    template IN SRV zoo {
        match ^_smtp\\._tcp\\.zoo\\.?$
        answer "{{ .Name }} 3600 IN SRV 0 10 25 stalwart.zoo."
    }

    template IN SRV zoo {
        match ^_smtps\\._tcp\\.zoo\\.?$
        answer "{{ .Name }} 3600 IN SRV 0 10 465 stalwart.zoo."
    }

    template IN SRV zoo {
        match ^_submission\\._tcp\\.zoo\\.?$
        answer "{{ .Name }} 3600 IN SRV 0 10 587 stalwart.zoo."
    }

    template IN SRV zoo {
        match ^_imap\\._tcp\\.zoo\\.?$
        answer "{{ .Name }} 3600 IN SRV 0 10 143 stalwart.zoo."
    }

    template IN SRV zoo {
        match ^_imaps\\._tcp\\.zoo\\.?$
        answer "{{ .Name }} 3600 IN SRV 0 10 993 stalwart.zoo."
    }

    # Logging - only log denials and errors
    log . {
        class denial
    }
    errors
}

# Refuse all other domains (return NXDOMAIN)
.:53 {
    # Template to catch any non-.zoo domains and refuse them
    template IN A {
        rcode NXDOMAIN
    }

    # Logging - only log denials and errors
    log . {
        class denial
    }
    errors
}
`;

    return content;
  }

  /**
   * Write generated configuration files
   */
  async writeFiles(dryRun = false) {
    const files = [
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
        path: path.join(ROOT, "core/SITES.yaml"),
        content: this.generateSitesList(),
        name: "SITES.yaml",
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

      if (fs.existsSync(file.path)) {
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
