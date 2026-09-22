import { describe, expect, it } from "vitest";
import { extractPortFromServiceConfig } from "../../scripts/docker-compose-utils";

describe("extractPortFromServiceConfig", () => {
  it("reads the target port from `docker compose config --format json` port objects", () => {
    expect(extractPortFromServiceConfig({ ports: [{ target: 8080 }] })).toBe("8080");
  });

  it("returns undefined instead of guessing a port, so the generator reports it", () => {
    expect(extractPortFromServiceConfig({ image: "example:1" })).toBeUndefined();
  });
});
