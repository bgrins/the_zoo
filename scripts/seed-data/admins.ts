import { serviceEnvironment } from "../docker-compose-utils";

export interface Credentials {
  username: string;
  password: string;
}

function envValue(service: string, key: string): string {
  const value = serviceEnvironment(service)[key];
  if (!value) {
    throw new Error(`docker-compose.yaml sets no ${key} for ${service}`);
  }
  return value;
}

/** Admin accounts the apps create from their docker-compose.yaml environment */
export function adminCredentials(): Record<
  "stalwart" | "miniflux" | "microbin" | "snappymail",
  Credentials
> {
  return {
    // Stalwart's fallback admin; config.toml holds the hash of ADMIN_PASSWORD
    stalwart: { username: "admin", password: envValue("stalwart", "ADMIN_PASSWORD") },
    miniflux: {
      username: envValue("miniflux", "ADMIN_USERNAME"),
      password: envValue("miniflux", "ADMIN_PASSWORD"),
    },
    microbin: {
      username: envValue("microbin", "MICROBIN_ADMIN_USERNAME"),
      password: envValue("microbin", "MICROBIN_ADMIN_PASSWORD"),
    },
    snappymail: {
      username: envValue("snappymail-zoo", "ADMIN_USER"),
      password: envValue("snappymail-zoo", "ADMIN_PASS"),
    },
  };
}
