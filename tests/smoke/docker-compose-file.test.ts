import { describe, it, expect } from "vitest";
import YAML from "yaml";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { dirname } from "node:path";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Custom tags to handle Docker Compose's !reset tag
const customTags = [
  {
    tag: "!reset",
    resolve: () => null,
  },
];

describe("Docker Compose File Validation", () => {
  const dockerComposePath = resolve(__dirname, "../../docker-compose.yaml");
  const dockerComposeContent = readFileSync(dockerComposePath, "utf8");
  const dockerCompose = YAML.parse(dockerComposeContent) as any;

  describe("Service Profiles", () => {
    it("should only allow core services to start by default", () => {
      // Core services that are allowed to start without a profile
      const ALLOWED_CORE_SERVICES = [
        "coredns",
        "caddy",
        "proxy",
        "postgres",
        "redis",
        "stalwart",
        "hydra",
        "meilisearch",
        "auth-zoo", // Currently has no profile but is needed
        "mysql",
      ];

      const servicesWithoutProfiles: string[] = [];
      const servicesWithProfiles: Record<string, string[]> = {};

      // Check all services for profile configuration
      for (const [serviceName, serviceConfig] of Object.entries(dockerCompose.services || {})) {
        const service = serviceConfig as any;
        if (service.profiles) {
          servicesWithProfiles[serviceName] = service.profiles;
        } else {
          servicesWithoutProfiles.push(serviceName);
        }
      }

      // Check that only allowed services start by default
      const unexpectedDefaultServices = servicesWithoutProfiles.filter(
        (service) => !ALLOWED_CORE_SERVICES.includes(service),
      );

      expect(unexpectedDefaultServices).toHaveLength(0);

      if (unexpectedDefaultServices.length > 0) {
        throw new Error(
          `The following services will start by default but are not in the allowed list:\n` +
            `  ${unexpectedDefaultServices.join(", ")}\n\n` +
            `Either add a profile (e.g., profiles: ["on-demand"]) or add to ALLOWED_CORE_SERVICES if they are truly core services.`,
        );
      }

      // Profile configuration is validated by the test assertions
    });

    it("should have consistent profile naming", () => {
      const knownProfiles = new Set(["on-demand", "tools"]);
      const usedProfiles = new Set<string>();

      for (const [_serviceName, serviceConfig] of Object.entries(dockerCompose.services || {})) {
        const service = serviceConfig as any;
        if (service.profiles) {
          service.profiles.forEach((profile: string) => usedProfiles.add(profile));
        }
      }

      const unknownProfiles = Array.from(usedProfiles).filter((p) => !knownProfiles.has(p));

      expect(unknownProfiles).toHaveLength(0);

      if (unknownProfiles.length > 0) {
        throw new Error(
          `Unknown profiles detected: ${unknownProfiles.join(", ")}\n` +
            `Known profiles are: ${Array.from(knownProfiles).join(", ")}`,
        );
      }
    });
  });

  describe("Port Binding Security", () => {
    it("should only allow proxy service to bind ports to the host", () => {
      const servicesWithHostPorts: Record<string, string[]> = {};

      // Check all services for port bindings
      for (const [serviceName, serviceConfig] of Object.entries(dockerCompose.services || {})) {
        const service = serviceConfig as any;
        const ports = service.ports || [];

        if (ports.length > 0) {
          servicesWithHostPorts[serviceName] = ports;
        }
      }

      // Only proxy should have ports bound to the host
      const allowedServices = ["proxy"];
      const unauthorizedServices = Object.keys(servicesWithHostPorts).filter(
        (service) => !allowedServices.includes(service),
      );

      expect(unauthorizedServices).toHaveLength(0);

      // If other services have host port bindings, provide a helpful error message
      if (unauthorizedServices.length > 0) {
        const details = unauthorizedServices
          .map((service) => `  ${service}: ${servicesWithHostPorts[service].join(", ")}`)
          .join("\n");
        throw new Error(
          `Unauthorized host port bindings detected in services:\n${details}\n\n` +
            `Only the 'proxy' service is allowed to bind ports to the host.`,
        );
      }

      // Verify proxy service exists and has port binding
      expect(servicesWithHostPorts).toHaveProperty("proxy");
      if (servicesWithHostPorts.proxy) {
        const proxyPort = servicesWithHostPorts.proxy[0];
        // Should bind to port 3128 (with or without environment variable)
        expect(proxyPort).toMatch(/:3128$/);
      }
    });
  });

  describe("Docker Volume Mount Security", () => {
    it("should only mount allowed paths and restrict sensitive host access", () => {
      const servicesWithSuspiciousPaths: Record<string, string[]> = {};

      // Globally allowed paths that are harmless
      const globallyAllowed = [
        "/etc/timezone",
        "/etc/localtime",
        "/usr/share/zoneinfo", // Alternative timezone path
      ];

      // Service-specific allowed exceptions
      const serviceExceptions: Record<string, string[]> = {
        caddy: ["/var/run/docker.sock"], // Caddy needs Docker access for on-demand containers
      };

      // Paths that are particularly dangerous if mounted
      const highlySensitivePaths = [
        "/var/run/docker.sock",
        "/var/lib/docker",
        "/usr/bin/docker",
        "/usr/local/bin/docker",
        "/etc/passwd",
        "/etc/shadow",
        "/root",
        "/home",
      ];

      // Check if path is allowed
      const isAllowedPath = (volumeSpec: string, serviceName: string): boolean => {
        const parts = volumeSpec.split(":");

        // Anonymous volume (just target path)
        if (parts.length === 1) return true;

        const source = parts[0];

        // Named volume (no slashes)
        if (!source.includes("/")) return true;

        // Relative path within project
        if (source.startsWith("./")) return true;

        // Check globally allowed paths
        if (globallyAllowed.some((allowed) => source === allowed)) {
          return true;
        }

        // Check service-specific exceptions
        const exceptions = serviceExceptions[serviceName] || [];
        if (exceptions.some((allowed) => source === allowed)) {
          return true;
        }

        // Everything else is suspicious
        return false;
      };

      // Check all services for suspicious volume mounts
      for (const [serviceName, serviceConfig] of Object.entries(dockerCompose.services || {})) {
        const service = serviceConfig as any;
        const volumes = service.volumes || [];
        const suspiciousPaths: string[] = [];

        for (const volume of volumes) {
          if (typeof volume === "string" && !isAllowedPath(volume, serviceName)) {
            suspiciousPaths.push(volume);
          }
        }

        if (suspiciousPaths.length > 0) {
          servicesWithSuspiciousPaths[serviceName] = suspiciousPaths;
        }
      }

      // No services should have suspicious paths
      expect(Object.keys(servicesWithSuspiciousPaths)).toHaveLength(0);

      // If services have suspicious paths, provide a detailed error
      if (Object.keys(servicesWithSuspiciousPaths).length > 0) {
        const details = Object.entries(servicesWithSuspiciousPaths)
          .map(([service, paths]) => {
            const pathDetails = paths
              .map((path) => {
                const source = path.split(":")[0];
                const isHighlySensitive = highlySensitivePaths.some(
                  (sensitive) => source === sensitive || source.startsWith(`${sensitive}/`),
                );
                return `    ${path}${isHighlySensitive ? " [HIGHLY SENSITIVE]" : ""}`;
              })
              .join("\n");
            return `  ${service}:\n${pathDetails}`;
          })
          .join("\n");

        throw new Error(
          `Volume mounts detected that access paths outside the project:\n${details}\n\n` +
            `Only the following are allowed:\n` +
            `- Relative paths (./...)\n` +
            `- Named volumes\n` +
            `- Timezone files (/etc/timezone, /etc/localtime)\n` +
            `- Service-specific exceptions (e.g., Docker socket for Caddy)`,
        );
      }
    });

    it("should have the docker_status module configured in Caddy", () => {
      // Check that Caddy service exists
      expect(dockerCompose.services).toHaveProperty("caddy");

      // Check that Caddy has the Docker socket mounted
      const caddyService = dockerCompose.services.caddy;
      expect(caddyService.volumes).toBeDefined();

      const hasDockerSocket = caddyService.volumes.some((volume: string) =>
        volume.includes("/var/run/docker.sock"),
      );
      expect(hasDockerSocket).toBe(true);

      // Check that the Caddyfile has the docker_status module configured
      const caddyfilePath = resolve(__dirname, "../../core/caddy/Caddyfile");
      const caddyfileContent = readFileSync(caddyfilePath, "utf8");

      // Check for docker_status module order directive
      expect(caddyfileContent).toContain("order docker_status before reverse_proxy");

      // Check for system-api.zoo configuration with docker_status
      expect(caddyfileContent).toContain("system-api.zoo");
      expect(caddyfileContent).toContain("docker_status");
    });
  });

  describe("Build Services Consistency", () => {
    it("should have all services with build directives in packages file and workflow", () => {
      // Core services that should be excluded from packages/workflow
      const coreServices = new Set(["analytics-zoo"]);

      // Find all services with build directives in main docker-compose.yaml
      const servicesWithBuild = new Set<string>();
      for (const [serviceName, serviceConfig] of Object.entries(dockerCompose.services || {})) {
        const service = serviceConfig as any;
        if (service && typeof service === "object" && "build" in service) {
          // Exclude core services
          if (!coreServices.has(serviceName)) {
            servicesWithBuild.add(serviceName);
          }
        }
      }

      // Read and parse docker-compose.packages.yaml
      const packagesPath = resolve(__dirname, "../../docker-compose.packages.yaml");
      const packagesContent = readFileSync(packagesPath, "utf8");
      const packagesCompose = YAML.parse(packagesContent, { customTags }) as any;

      // Check services in packages file
      const servicesInPackages = new Set<string>(Object.keys(packagesCompose.services || {}));

      // Read GitHub workflow
      const workflowPath = resolve(__dirname, "../../.github/workflows/docker-publish.yml");
      const workflowContent = readFileSync(workflowPath, "utf8");
      const workflow = YAML.parse(workflowContent) as any;

      // Extract services from workflow matrix (image names now match service names)
      const servicesInWorkflow = new Set<string>();
      const matrixIncludes = workflow.jobs?.["build-and-push"]?.strategy?.matrix?.include || [];

      for (const item of matrixIncludes) {
        if (item.image) {
          servicesInWorkflow.add(item.image);
        }
      }

      // Check for missing services in packages file
      const missingInPackages = Array.from(servicesWithBuild).filter(
        (service) => !servicesInPackages.has(service),
      );

      // Check for missing services in workflow
      const missingInWorkflow = Array.from(servicesWithBuild).filter(
        (service) => !servicesInWorkflow.has(service),
      );

      // Check for extra services in packages (that don't have build directive)
      const extraInPackages = Array.from(servicesInPackages).filter(
        (service) => !servicesWithBuild.has(service),
      );

      // Check for extra services in workflow (that don't have build directive)
      const extraInWorkflow = Array.from(servicesInWorkflow).filter(
        (service) => !servicesWithBuild.has(service),
      );

      // Assert all checks pass
      expect(missingInPackages).toHaveLength(0);
      if (missingInPackages.length > 0) {
        throw new Error(
          `Services with build directive missing from docker-compose.packages.yaml:\n  ${missingInPackages.join(", ")}`,
        );
      }

      expect(missingInWorkflow).toHaveLength(0);
      if (missingInWorkflow.length > 0) {
        throw new Error(
          `Services with build directive missing from GitHub workflow:\n  ${missingInWorkflow.join(", ")}`,
        );
      }

      expect(extraInPackages).toHaveLength(0);
      if (extraInPackages.length > 0) {
        throw new Error(
          `Services in docker-compose.packages.yaml without build directive:\n  ${extraInPackages.join(", ")}`,
        );
      }

      expect(extraInWorkflow).toHaveLength(0);
      if (extraInWorkflow.length > 0) {
        throw new Error(
          `Services in GitHub workflow without build directive:\n  ${extraInWorkflow.join(", ")}`,
        );
      }
    });
  });
});
