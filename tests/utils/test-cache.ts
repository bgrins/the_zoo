import { exec } from "node:child_process";
import { promisify } from "node:util";
import { getZooNetworkName } from "./docker-project";

// Types for test caching
interface ContainerInfo {
  Names: string;
  State: { Status: string; Health?: { Status: string } };
  NetworkSettings?: {
    Networks?: {
      [key: string]: {
        IPAddress?: string;
      };
    };
  };
}

interface NetworkInfo {
  subnet: string;
  gateway?: string;
  driver?: string;
}

const execAsync = promisify(exec);

// Cache for project name
let cachedProjectName: string | null = null;

// Get the Docker Compose project name
export const getProjectName = async (): Promise<string> => {
  if (cachedProjectName) {
    return cachedProjectName;
  }

  const { stdout } = await execAsync("docker compose config --format json");
  const config = JSON.parse(stdout);
  cachedProjectName = config.name as string;
  return cachedProjectName;
};

interface CacheEntry<T> {
  value: T;
  timestamp: number;
}

// Global caches
const containerNameCache = new Map<string, CacheEntry<string>>();
const siteRegistryCache = new Map<string, CacheEntry<any>>();
const dockerInspectCache = new Map<string, CacheEntry<ContainerInfo>>();
const networkCache = new Map<string, CacheEntry<NetworkInfo>>();

// Cache TTL - 5 minutes for test runs
const CACHE_TTL = 5 * 60 * 1000;

// Helper to check if cache entry is still valid
const isCacheValid = <T>(entry: CacheEntry<T> | undefined): entry is CacheEntry<T> => {
  return !!entry && Date.now() - entry.timestamp < CACHE_TTL;
};

// Cached container name lookup
export const getCachedContainerName = async (serviceName: string): Promise<string> => {
  const cacheKey = serviceName;
  const cached = containerNameCache.get(cacheKey);

  if (isCacheValid(cached)) {
    return cached.value;
  }

  const { stdout } = await execAsync(
    `docker ps --filter "label=com.docker.compose.service=${serviceName}" --format "{{.Names}}" | head -1`,
  );
  const containerName = stdout.trim();

  containerNameCache.set(cacheKey, {
    value: containerName,
    timestamp: Date.now(),
  });

  return containerName;
};

// Batch container name lookup
export const getCachedContainerNames = async (
  serviceNames: string[],
): Promise<Record<string, string>> => {
  const results: Record<string, string> = {};
  const uncachedServices: string[] = [];

  // Check cache first
  for (const service of serviceNames) {
    const cached = containerNameCache.get(service);
    if (isCacheValid(cached)) {
      results[service] = cached.value;
    } else {
      uncachedServices.push(service);
    }
  }

  // Batch fetch uncached names
  if (uncachedServices.length > 0) {
    const cmd = `docker ps --format "{{.Label \\"com.docker.compose.service\\"}}:{{.Names}}"`;
    const { stdout } = await execAsync(cmd);

    stdout
      .trim()
      .split("\n")
      .forEach((line) => {
        const [service, name] = line.split(":");
        // Skip containers without service labels (e.g., ":container_name")
        if (service && uncachedServices.includes(service)) {
          results[service] = name;
          containerNameCache.set(service, {
            value: name,
            timestamp: Date.now(),
          });
        }
      });
  }

  return results;
};

// Cached docker inspect
export const getCachedDockerInspect = async (
  containerNames: string | string[],
): Promise<Record<string, ContainerInfo> | ContainerInfo> => {
  const results: Record<string, ContainerInfo> = {};
  const uncachedContainers: string[] = [];

  // Check cache
  const names = Array.isArray(containerNames) ? containerNames : [containerNames];
  for (const name of names) {
    const cached = dockerInspectCache.get(name);
    if (isCacheValid(cached)) {
      results[name] = cached.value;
    } else {
      uncachedContainers.push(name);
    }
  }

  // Batch inspect uncached
  if (uncachedContainers.length > 0) {
    const cmd = `docker inspect ${uncachedContainers.join(" ")} 2>/dev/null`;
    try {
      const { stdout } = await execAsync(cmd);
      const inspectData = JSON.parse(stdout);

      inspectData.forEach((data: any) => {
        const name = data.Name.replace(/^\//, "");
        results[name] = data;
        dockerInspectCache.set(name, {
          value: data,
          timestamp: Date.now(),
        });
      });
    } catch (_e) {
      // Some containers might not exist
    }
  }

  return Array.isArray(containerNames) ? results : results[containerNames];
};

// Cached network info
export const getCachedNetworkInfo = async (
  networkName = getZooNetworkName(),
): Promise<NetworkInfo> => {
  const cached = networkCache.get(networkName);
  if (isCacheValid(cached)) {
    return cached.value;
  }

  const cmd = `docker network inspect ${networkName} --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}'`;
  const { stdout } = await execAsync(cmd);
  const subnet = stdout.trim();

  const info = { subnet };
  networkCache.set(networkName, {
    value: info,
    timestamp: Date.now(),
  });

  return info;
};

// Clear all caches (useful for test cleanup)
export const clearAllCaches = () => {
  containerNameCache.clear();
  siteRegistryCache.clear();
  dockerInspectCache.clear();
  networkCache.clear();
};

// Preload caches for better performance
export const preloadCaches = async () => {
  // Preload all container names
  const { stdout } = await execAsync(
    'docker ps --format "{{.Label \\"com.docker.compose.service\\"}}:{{.Names}}"',
  );
  stdout
    .trim()
    .split("\n")
    .forEach((line) => {
      const [service, name] = line.split(":");
      if (service && name) {
        containerNameCache.set(service, {
          value: name,
          timestamp: Date.now(),
        });
      }
    });

  // Preload network info
  await getCachedNetworkInfo();
};
