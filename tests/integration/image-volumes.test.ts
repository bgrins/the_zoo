import { execSync } from "node:child_process";
import { describe, expect, it } from "vitest";
import { isServiceAvailable } from "../utils/available";

// Inspects the local images, so it runs after CI has pulled the on-demand ones
describe("Image Volumes", () => {
  it("every volume an image declares has a mount, so no container gets an anonymous one", () => {
    // An anonymous volume is left behind on every recreate, and outlives the restore on start
    const config = JSON.parse(
      execSync("docker compose --profile '*' config --format json", { encoding: "utf8" }),
    );
    const unmounted = Object.entries(config.services)
      .filter(([name]) => isServiceAvailable(name))
      .flatMap(([name, service]: [string, any]) => {
        const declared = JSON.parse(
          execSync(`docker image inspect --format '{{json .Config.Volumes}}' ${service.image}`, {
            encoding: "utf8",
          }),
        );
        const mounted = new Set([
          ...(service.volumes ?? []).map((volume: { target: string }) => volume.target),
          ...(service.tmpfs ?? []).map((tmpfs: string) => tmpfs.split(":")[0]),
        ]);
        return Object.keys(declared ?? {})
          .filter((path) => !mounted.has(path))
          .map((path) => `${name}: ${path}`);
      });
    expect(unmounted).toEqual([]);
  });
});
