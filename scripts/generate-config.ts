#!/usr/bin/env -S npx tsx

/**
 * Configuration generator for Zoo development environment.
 * Parses docker-compose.yaml and generates Caddyfile and CoreDNS zone file.
 *
 * Node.js port of the original Python script.
 */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execSync } from "node:child_process";
import yaml from "yaml";
import {
  extractPortFromServiceConfig,
  getDockerComposeServices,
  parseDockerCompose,
  isServiceOnDemand,
  isServiceHeavy,
  type DockerComposeService,
} from "./docker-compose-utils.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

interface ServiceInfo {
  port?: number;
  domains?: string[];
  domainPorts?: Record<string, string>;
  type?: "proxy" | "static";
  containerName?: string;
  staticSites?: Record<string, string>;
  fromDockerCompose?: boolean;
  httpsOnly?: boolean;
}

class ConfigGenerator {
  private composeFile: string;
  private services: Record<string, ServiceInfo>;
  private projectName: string;

  constructor(composeFile = "docker-compose.yaml") {
    this.composeFile = path.resolve(composeFile);
    this.services = {};
    this.projectName = this.getProjectName();
  }

  /**
   * Get the Docker Compose project name dynamically
   */
  private getProjectName(): string {
    try {
      // Query docker compose for the actual project name
      const result = execSync("docker compose config --format json", {
        encoding: "utf8",
        cwd: path.dirname(this.composeFile),
      });
      const config = JSON.parse(result);
      return config.name || "thezoo"; // Fallback to 'thezoo' if name is not found
    } catch (_error) {
      console.warn("Could not determine project name from docker compose, using directory name");
      // Fallback to directory name
      return path.basename(path.dirname(this.composeFile));
    }
  }

  /**
   * Load OAuth client configurations from Hydra clients directory
   */
  private getOAuthClients(): Set<string> {
    const oauthClients = new Set<string>();
    const clientsDir = path.resolve("core/hydra/clients");

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
    const dockerServices = getDockerComposeServices();

    for (const [serviceName, serviceConfig] of Object.entries(dockerServices) as Array<
      [string, DockerComposeService]
    >) {
      // Skip if service already has zoo.domains label (handled elsewhere)
      if (serviceConfig.labels) {
        const labels = Array.isArray(serviceConfig.labels)
          ? serviceConfig.labels
          : Object.entries(serviceConfig.labels).map(([k, v]) => `${k}=${v}`);

        const hasZooLabels = labels.some((label: any) => String(label).startsWith("zoo.domains="));

        if (hasZooLabels) {
          continue;
        }
      }

      // Check if this service has a build path in sites/apps
      if (serviceConfig.build) {
        const buildPath =
          typeof serviceConfig.build === "string"
            ? serviceConfig.build
            : serviceConfig.build.context;

        if (buildPath?.includes("/sites/apps/")) {
          // Extract the app directory name from absolute path
          const appDir = buildPath.split("/sites/apps/")[1];

          // Skip if it's the static directory
          if (appDir === "static") {
            continue;
          }

          // Use the directory name as the domain
          const domain = appDir.endsWith(".zoo") ? appDir : `${appDir}.zoo`;
          const port = extractPortFromServiceConfig(serviceConfig);

          appServices[serviceName] = {
            domains: [domain],
            type: "proxy",
            port: Number(port),
            fromDockerCompose: true,
            containerName: serviceName,
          };
        }
      }
    }

    return appServices;
  }

  /**
   * Scan the apps/static directory for static sites following the convention:
   * /static/{domain}/dist/
   */
  scanStaticSites() {
    const staticDir = path.resolve("sites/static");
    const staticSites: Record<string, any> = {};

    if (!fs.existsSync(staticDir)) {
      return staticSites;
    }

    // Read all directories in sites/static
    const entries = fs.readdirSync(staticDir, { withFileTypes: true });

    for (const entry of entries) {
      if (entry.isDirectory() || entry.isSymbolicLink()) {
        const domainName = entry.name;
        const distPath = path.join(staticDir, domainName, "dist");

        // Check if this follows the /static/{domain}/dist pattern
        if (fs.existsSync(distPath) && fs.statSync(distPath).isDirectory()) {
          // The directory name should be the domain (e.g., "staticsite.zoo")
          if (domainName.endsWith(".zoo")) {
            staticSites[domainName] = {
              path: distPath,
              domain: domainName,
            };
          }
        }
      }
    }

    return staticSites;
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
    const composeData = parseDockerCompose(this.composeFile);

    // Extract service information from parsed YAML
    if (composeData.services) {
      for (const [serviceName, serviceConfig] of Object.entries(composeData.services) as Array<
        [string, DockerComposeService]
      >) {
        // Skip infrastructure services
        if (["dns", "caddy", "proxy"].includes(serviceName)) {
          continue;
        }

        const serviceInfo: ServiceInfo = {};

        // Extract port using shared utility
        const extractedPort = extractPortFromServiceConfig(serviceConfig);
        if (extractedPort) {
          serviceInfo.port = Number(extractedPort);
        }

        // Extract zoo labels
        if (serviceConfig.labels) {
          const labels = Array.isArray(serviceConfig.labels)
            ? serviceConfig.labels
            : Object.entries(serviceConfig.labels).map(([k, v]) => `${k}=${v}`);

          for (const label of labels) {
            const labelStr = String(label);

            if (labelStr.startsWith("zoo.domains=")) {
              const value = labelStr.substring(12);
              const domainSpecs = value.split(",").map((d) => d.trim());

              // Parse domains with optional port specification
              serviceInfo.domains = [];
              serviceInfo.domainPorts = {};

              for (const spec of domainSpecs) {
                if (spec.includes(":")) {
                  const [domain, port] = spec.split(":");
                  serviceInfo.domains.push(domain);
                  // Always store domain-specific port when explicitly specified
                  serviceInfo.domainPorts[domain] = port;
                } else {
                  serviceInfo.domains.push(spec);
                }
              }

              serviceInfo.type = "proxy";
            }

            // Check for HTTPS-only flag
            if (labelStr === "zoo.https-only=true") {
              serviceInfo.httpsOnly = true;
            }
          }
        }

        // Store service info if it has relevant data
        if (Object.keys(serviceInfo).length > 0) {
          this.services[serviceName] = serviceInfo;
        }
      }
    }

    // Only keep services that have zoo.domains labels
    const zooServices: Record<string, ServiceInfo> = {};

    for (const [serviceName, config] of Object.entries(this.services)) {
      if (config.domains) {
        zooServices[serviceName] = config;
      }
    }

    this.services = zooServices;

    // Now add services discovered from docker-compose that have build paths in sites/apps
    const appServices = this.scanDockerServicesForApps();
    for (const [serviceName, appConfig] of Object.entries(appServices)) {
      // Check if domain is already claimed by another service
      const domainAlreadyClaimed = Object.values(this.services).some((service) =>
        service.domains?.includes(appConfig.domains?.[0] || ""),
      );

      // Only add if not already defined via zoo.domains label
      if (!this.services[serviceName] && !domainAlreadyClaimed) {
        this.services[serviceName] = appConfig;
      }
    }

    // Now add static sites discovered from filesystem
    const staticSites = this.scanStaticSites();
    if (Object.keys(staticSites).length > 0) {
      // Create a virtual static-server service entry
      this.services["static-server"] = {
        domains: Object.keys(staticSites),
        type: "static",
        port: 80,
        staticSites: Object.fromEntries(
          Object.entries(staticSites).map(([domain, _info]) => [domain, domain]),
        ),
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

    const allowedExternalDomains = [
      "secure.gravatar.com",
      "pdat.matterlytics.com",
      "api.rudderlabs.com",
    ];

    for (const [serviceName, config] of Object.entries(this.services)) {
      // At this point all services should have domains (filtered above)
      if (!config.domains) {
        errors.push(`Service '${serviceName}' missing zoo labels`);
      }

      // Only require PORT for proxy services, not static services
      if (config.type === "proxy" && !config.port) {
        errors.push(`Service '${serviceName}' missing PORT environment variable`);
      }

      // Check for duplicate domains
      if (config.domains) {
        for (const domain of config.domains) {
          const existingService = Object.entries(this.services).find(
            ([name, svc]) => name !== serviceName && svc.domains && svc.domains.includes(domain),
          );

          if (allDomains.includes(domain)) {
            if (existingService) {
              errors.push(
                `Duplicate domain '${domain}' - used by both '${serviceName}' and '${existingService[0]}'`,
              );
            } else {
              errors.push(`Duplicate domain '${domain}' found in service '${serviceName}'`);
            }
          }
          allDomains.push(domain);

          // Validate domain format
          if (!domain.endsWith(".zoo") && !allowedExternalDomains.includes(domain)) {
            errors.push(`Domain '${domain}' must end with .zoo`);
          }
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
    # Replace must happen BEFORE encode so we can modify uncompressed content
    order replace before encode
    # Load the fail_injector module
    order fail_injector before reverse_proxy
    order fail_injector before file_server
    # Load the on_demand_docker module
    order on_demand_docker before reverse_proxy
    # Load the docker_status module
    order docker_status before reverse_proxy
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
(performance_zoo) {
    @notBinary {
        # Exclude common non-HTML content types
        not header Content-Type application/*
        not header Content-Type image/*
        not header Content-Type video/*
        not header Content-Type audio/*
        not header Content-Type font/*
        not header Content-Type model/*
        not header Content-Type multipart/*

        # Exclude specific text formats that aren't HTML
        not header Content-Type text/css*
        not header Content-Type text/javascript*
        not header Content-Type text/json*
        not header Content-Type text/csv*
        not header Content-Type text/xml*
        not header Content-Type text/plain*
    }

    handle @notBinary {
        # Only inject before </body> - the replace directive won't modify content
        # that doesn't contain this tag, providing natural HTML detection
        replace "</body>" "<script src='https://performance.zoo/shared.js' async defer></script></body>"
        replace "</BODY>" "<script src='https://performance.zoo/shared.js' async defer></script></BODY>"

        # Convert CSP meta tags to report-only mode (allows injected scripts while logging violations)
        replace "http-equiv=\\"Content-Security-Policy\\"" "http-equiv=\\"Content-Security-Policy-Report-Only\\""
        replace "http-equiv='Content-Security-Policy'" "http-equiv='Content-Security-Policy-Report-Only'"

        # Strip CSP headers to allow injected scripts in development environment
        # This is acceptable for Zoo since it's a development-only environment
        header -Content-Security-Policy
        header X-Performance-Zoo "injected"
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
        timeout 30
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

`;

    // Generate entries for each service - keep individual entries but use snippets
    for (const [serviceName, config] of Object.entries(this.services)) {
      const serviceType = config.type || "proxy";

      if (serviceType === "proxy") {
        // Use containerName if provided (for directory-based services), otherwise use serviceName
        const containerName = config.containerName || serviceName;

        if (config.domains) {
          for (const domain of config.domains) {
            // Use domain-specific port if specified, otherwise fall back to service port
            const port = config.domainPorts?.[domain] || config.port || 3000;

            // HTTPS
            content += `${domain} {\n`;
            content += `    import logging\n`;
            // Don't inject on performance.zoo itself
            if (domain !== "performance.zoo") {
              content += `    import performance_zoo\n`;
            }
            content += `    \n`;
            content += `    route {\n`;
            content += `        import proxy_handler ${containerName} ${port}\n`;
            content += `    }\n`;
            content += `}\n\n`;

            // HTTP
            content += `http://${domain} {\n`;
            content += `    import logging\n`;

            // Check for global HTTPS-only mode first
            content += `    \n`;
            content += `    # Check if all sites should redirect to HTTPS\n`;
            content += `    @all_https_only expression "{$ZOO_ALL_HTTPS_ONLY:false}" == "true"\n`;
            content += `    redir @all_https_only https://{host}{uri} permanent\n`;

            if (config.httpsOnly) {
              // Individual site has HTTPS-only enabled
              content += `    \n`;
              content += `    # Site-specific HTTPS-only redirect\n`;
              content += `    redir https://{host}{uri} permanent\n`;
            } else {
              // Normal HTTP handling
              content += `    \n`;
              // Don't inject on performance.zoo itself
              if (domain !== "performance.zoo") {
                content += `    import performance_zoo\n`;
              }
              content += `    \n`;
              content += `    route {\n`;
              content += `        import proxy_handler ${containerName} ${port}\n`;
              content += `    }\n`;
            }

            content += `}\n\n`;
          }
        }
      } else if (serviceType === "static") {
        // Serve static files directly from Caddy
        if (config.domains) {
          for (const domain of config.domains) {
            // Extract the domain folder name (e.g., "app1.zoo" from the domain)
            const domainFolder = domain;

            // performance.zoo needs CORS headers since shared.js is loaded cross-origin
            const isPerformanceZoo = domain === "performance.zoo";

            content += `${domain} {\n`;
            content += `    import logging\n`;
            // Don't inject on performance.zoo itself
            if (!isPerformanceZoo) {
              content += `    import performance_zoo\n`;
            }
            content += `    \n`;
            content += `    route {\n`;
            content += `        import fail_injection\n`;
            content += `        root * /static/${domainFolder}/dist\n`;
            content += `        file_server\n`;
            content += `        \n`;
            content += `        header {\n`;
            content += `            X-Frame-Options "SAMEORIGIN"\n`;
            content += `            X-XSS-Protection "1; mode=block"\n`;
            content += `            X-Content-Type-Options "nosniff"\n`;
            if (isPerformanceZoo) {
              content += `            Access-Control-Allow-Origin "*"\n`;
              content += `            Access-Control-Allow-Methods "GET, OPTIONS"\n`;
              content += `            Access-Control-Allow-Headers "Content-Type"\n`;
            }
            content += `        }\n`;
            content += `    }\n`;
            content += `}\n\n`;

            content += `http://${domain} {\n`;
            content += `    import logging\n`;
            content += `    \n`;
            content += `    # Check if all sites should redirect to HTTPS\n`;
            content += `    @all_https_only expression "{$ZOO_ALL_HTTPS_ONLY:false}" == "true"\n`;
            content += `    redir @all_https_only https://{host}{uri} permanent\n`;
            content += `    \n`;
            content += `    # Check if static sites should redirect to HTTPS\n`;
            content += `    @static_https_only expression "{$ZOO_STATIC_HTTPS_ONLY:false}" == "true"\n`;
            content += `    redir @static_https_only https://{host}{uri} permanent\n`;
            content += `    \n`;
            // Don't inject on performance.zoo itself
            if (!isPerformanceZoo) {
              content += `    import performance_zoo\n`;
            }
            content += `    \n`;
            content += `    route {\n`;
            content += `        import fail_injection\n`;
            content += `        root * /static/${domainFolder}/dist\n`;
            content += `        file_server\n`;
            content += `        \n`;
            content += `        header {\n`;
            content += `            X-Frame-Options "SAMEORIGIN"\n`;
            content += `            X-XSS-Protection "1; mode=block"\n`;
            content += `            X-Content-Type-Options "nosniff"\n`;
            if (isPerformanceZoo) {
              content += `            Access-Control-Allow-Origin "*"\n`;
              content += `            Access-Control-Allow-Methods "GET, OPTIONS"\n`;
              content += `            Access-Control-Allow-Headers "Content-Type"\n`;
            }
            content += `        }\n`;
            content += `    }\n`;
            content += `}\n\n`;
          }
        }
      }
    }

    // Removed wildcard catch-all to fix SSL certificate issues
    // Individual certificates will be generated for each configured domain

    // Define the system API description as a constant
    const systemApiDescription = `System API - Docker monitoring for The Zoo

Endpoints:
  GET https://system-api.zoo/docker/ok                         - Health check
  GET https://system-api.zoo/docker/api/containers             - List all containers
  GET https://system-api.zoo/docker/api/containers?stats=true  - List containers with CPU/memory stats
  GET https://system-api.zoo/docker/api/container/{name}/logs  - Get container logs (default: last 50 lines)
  GET https://system-api.zoo/docker/api/system-metrics         - Get system-wide Docker metrics

Features: CORS enabled, auto-filters Zoo containers, 2s stats cache`;

    // Add Docker Status API endpoint
    content += `# Docker Status API - provides container status information
# HTTPS
system-api.zoo {
    import logging
    
    route /docker/* {
        uri strip_prefix /docker
        docker_status
    }
    
    route {
        respond "${systemApiDescription}" 200
    }
}

# HTTP
http://system-api.zoo {
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

    // Swallowed external domains - return 200 with CORS to absorb telemetry/analytics requests
    const swallowedDomains = ["pdat.matterlytics.com", "api.rudderlabs.com"];
    content += `# Swallowed external domains - absorb telemetry/analytics requests\n`;
    for (const domain of swallowedDomains) {
      for (const scheme of ["", "http://"]) {
        content += `${scheme}${domain} {\n`;
        content += `    import logging\n`;
        content += `    \n`;
        content += `    header {\n`;
        content += `        Access-Control-Allow-Origin "*"\n`;
        content += `        Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"\n`;
        content += `        Access-Control-Allow-Headers "*, Authorization"\n`;
        content += `    }\n`;
        content += `    respond 200\n`;
        content += `}\n\n`;
      }
    }

    return content;
  }

  /**
   * Generate SITES.yaml file content
   */
  generateSitesList() {
    // Get OAuth clients
    const oauthClients = this.getOAuthClients();

    // Get docker-compose services for metadata
    const dockerServices = getDockerComposeServices();

    // Generate network config for services section
    const networkConfig = this.generateNetworkConfig();

    // Collect all sites with enriched metadata
    interface SiteInfo {
      name: string;
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
      const serviceType = config.type || "proxy";

      if (config.domains) {
        for (const domain of config.domains) {
          // Use domain-specific port if specified, otherwise fall back to service port
          const port = config.domainPorts?.[domain] || config.port || "80";

          // Extract site name from domain (remove .zoo if present, otherwise use domain as-is)
          const siteName = domain.endsWith(".zoo")
            ? domain.replace(".zoo", "").replace(/\./g, "_")
            : domain.replace(/\./g, "_");

          // Get metadata from docker-compose labels
          let description: string | undefined;
          let icon: string | undefined;
          let httpsOnly = false;

          const dockerService = dockerServices[serviceName];
          if (dockerService?.labels) {
            const labels = Array.isArray(dockerService.labels)
              ? dockerService.labels
              : Object.entries(dockerService.labels).map(([k, v]) => `${k}=${v}`);

            for (const label of labels) {
              const labelStr = String(label);
              if (labelStr.startsWith("zoo.description=")) {
                description = labelStr.substring("zoo.description=".length);
              } else if (labelStr.startsWith("zoo.icon=")) {
                icon = labelStr.substring("zoo.icon=".length);
              } else if (labelStr === "zoo.https-only=true") {
                httpsOnly = true;
              }
            }
          }

          sitesMap.set(domain, {
            name: siteName,
            domain: domain,
            type: serviceType,
            port: port,
            service: serviceName,
            description,
            icon,
            hasOAuth: oauthClients.has(domain),
            httpsOnly,
            onDemand: isServiceOnDemand(serviceName),
            heavy: isServiceHeavy(serviceName),
          });
        }
      }
    }

    // Convert to sorted array
    const sites = Array.from(sitesMap.values()).sort((a, b) => a.domain.localeCompare(b.domain));

    // Build services section with only hasHealthCheck field
    const services: Record<string, { hasHealthCheck: boolean }> = {};
    for (const [serviceName, serviceConfig] of Object.entries(networkConfig.services)) {
      if (serviceConfig.hasHealthCheck) {
        services[serviceName] = { hasHealthCheck: true };
      }
    }

    // Generate YAML content
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
      services: services,
    };

    return yaml.stringify(yamlData);
  }

  /**
   * Generate CoreDNS Corefile configuration
   */
  generateCorefileContent() {
    // Collect all domains
    const allDomains: string[] = [];
    const externalDomains: string[] = [];
    for (const [_serviceName, config] of Object.entries(this.services)) {
      if (config.domains) {
        for (const domain of config.domains) {
          if (domain.endsWith(".zoo")) {
            allDomains.push(domain);
          } else {
            externalDomains.push(domain);
          }
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

    // Add swallowed external domains (no backing docker service)
    const swallowedExternalDomains = ["pdat.matterlytics.com", "api.rudderlabs.com"];
    for (const domain of swallowedExternalDomains) {
      if (!externalDomains.includes(domain)) {
        externalDomains.push(domain);
      }
    }

    // Add external domains if any exist
    if (externalDomains.length > 0) {
      content += `# Handle external compatibility domains\n`;
      for (const domain of externalDomains.sort()) {
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
    }

    content += `# Handle only .zoo domains
zoo:53 {
    # Use hosts plugin with environment variable support
    hosts {
`;

    // Add all domains pointing to Caddy IP
    for (const domain of allDomains.sort()) {
      content += `        {$ZOO_CADDY_IP} ${domain}\n`;
    }

    // Add system-api
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
   * Extract network configuration from docker-compose
   */
  generateNetworkConfig() {
    // Get the expanded compose configuration
    const compose = parseDockerCompose(this.composeFile);

    interface NetworkServiceConfig {
      ip?: string;
      fullIp?: string;
      dns?: string[];
      needsProjectName?: boolean;
      hasHealthCheck?: boolean;
    }

    const networkConfig: {
      version: string;
      network: {
        subnet: string;
        driver: string;
      };
      services: Record<string, NetworkServiceConfig>;
    } = {
      version: "1.0",
      network: {
        subnet: compose.networks?.["zoo-network"]?.ipam?.config?.[0]?.subnet || "172.20.0.0/16",
        driver: compose.networks?.["zoo-network"]?.driver || "bridge",
      },
      services: {},
    };

    // Extract the base subnet for parsing
    const [baseIP] = networkConfig.network.subnet.split("/");
    const [octet1, octet2] = baseIP.split(".").map(Number);

    // Extract service IPs and other network-related configs
    for (const [serviceName, serviceConfig] of Object.entries(compose.services || {}) as Array<
      [string, DockerComposeService]
    >) {
      const service = serviceConfig;
      const networks = service.networks;
      const ipv4Address =
        networks && typeof networks === "object" && !Array.isArray(networks)
          ? networks["zoo-network"]?.ipv4_address
          : undefined;
      const dnsServers = service.dns;

      if (ipv4Address || dnsServers || service.healthcheck) {
        networkConfig.services[serviceName] = {};

        if (ipv4Address) {
          // Extract the last two octets to make it relative to the subnet
          const [, , octet3, octet4] = ipv4Address.split(".").map(Number);
          networkConfig.services[serviceName].ip = `${octet3}.${octet4}`;
          networkConfig.services[serviceName].fullIp = ipv4Address;
        }

        if (dnsServers) {
          // Store DNS servers as relative IPs too
          networkConfig.services[serviceName].dns = dnsServers.map((dns) => {
            if (typeof dns === "string" && dns.startsWith(`${octet1}.${octet2}.`)) {
              const [, , octet3, octet4] = dns.split(".").map(Number);
              return `${octet3}.${octet4}`;
            }
            return dns;
          });
        }

        // Add health check information
        if (service.healthcheck) {
          networkConfig.services[serviceName].hasHealthCheck = true;
        }
      }
    }

    // Find services that need environment variables
    const envServices = ["caddy"];
    for (const serviceName of envServices) {
      if (!(networkConfig.services as any)[serviceName]) {
        networkConfig.services[serviceName] = {};
      }
      networkConfig.services[serviceName].needsProjectName = true;
    }

    return networkConfig;
  }

  /**
   * Write generated configuration files
   */
  async writeFiles(dryRun = false) {
    const caddyFile = path.resolve("core/caddy/Caddyfile");
    const coreFile = path.resolve("core/coredns/Corefile");
    const sitesFile = path.resolve("core/SITES.yaml");

    const caddyfileContent = this.generateCaddyfile();
    const corefileContent = this.generateCorefileContent();
    const sitesContent = this.generateSitesList();

    if (dryRun) {
      console.log("=== DRY RUN MODE ===");
      console.log(`\nWould write to ${caddyFile}:`);
      console.log("-".repeat(50));
      console.log(caddyfileContent);
      console.log(`\nWould write to ${coreFile}:`);
      console.log("-".repeat(50));
      console.log(corefileContent);
      console.log(`\nWould write to ${sitesFile}:`);
      console.log("-".repeat(50));
      console.log(sitesContent);
      return;
    }

    // Helper function to check if file needs updating
    const needsUpdate = (filePath: string, newContent: string): boolean => {
      if (!fs.existsSync(filePath)) {
        return true;
      }
      const existingContent = fs.readFileSync(filePath, "utf8");
      return existingContent !== newContent;
    };

    // Process each file
    const files = [
      { path: caddyFile, content: caddyfileContent, name: "Caddyfile" },
      { path: coreFile, content: corefileContent, name: "Corefile" },
      { path: sitesFile, content: sitesContent, name: "SITES.yaml" },
    ];

    let updatedCount = 0;
    for (const file of files) {
      if (needsUpdate(file.path, file.content)) {
        // Backup existing file
        if (fs.existsSync(file.path)) {
          const backupPath = `${file.path}.bak`;
          fs.copyFileSync(file.path, backupPath);
          console.log(`Backed up ${file.path} to ${backupPath}`);
        }

        // Write new content
        fs.writeFileSync(file.path, file.content);
        console.log(`Generated ${file.path}`);
        updatedCount++;
      } else {
        console.log(`Skipped ${file.name} (no changes detected)`);
      }
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
  const composeFile = composeFileIndex !== -1 ? args[composeFileIndex + 1] : "docker-compose.yaml";

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
    const domains = (config.domains || []).join(", ");
    const serviceType = config.type || "unknown";
    const port = config.port || "unknown";
    console.log(`  ${serviceName} (${serviceType}): ${domains} -> :${port}`);
  }

  console.log("\nValidating configuration...");
  if (!generator.validateServices()) {
    process.exit(1);
  }

  console.log("Validation passed!");

  console.log("\nGenerating configuration files...");
  await generator.writeFiles(dryRun);

  // Build home.zoo static site
  if (!dryRun) {
    console.log("\nBuilding home.zoo...");
    const { execSync } = await import("node:child_process");
    execSync("tsx scripts/build-home-zoo.ts", {
      stdio: "inherit",
      cwd: path.dirname(__dirname),
    });
  }
}

// Run if this script is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}

export { ConfigGenerator };
