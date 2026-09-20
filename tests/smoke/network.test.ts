import { execFileSync, spawnSync } from "node:child_process";
import { describe, expect, test } from "vitest";
import { getZooNetworkName } from "../utils/docker-project";
import { getCachedContainerNames } from "../utils/test-cache";

const docker = (...args: string[]) => execFileSync("docker", args, { encoding: "utf8" }).trim();
const connects = (container: string, host: string, port: string) =>
  spawnSync("docker", ["exec", container, "nc", "-z", "-w", "2", host, port]).status === 0;

describe("zoo-network", () => {
  test("containers can't connect to the Docker host through the bridge", async () => {
    const { caddy, redis } = await getCachedContainerNames(["caddy", "redis"]);
    // A listener in the Docker host's network namespace: this machine, or Docker Desktop's
    // VM. The redis image carries no compose labels, so the container isn't taken for a zoo one.
    const listener = `zoo-network-test-${process.pid}`;
    const port = String(20000 + Math.floor(Math.random() * 40000));
    const image = docker("inspect", "--format", "{{.Config.Image}}", redis);
    docker(
      ...["run", "-d", "--rm", "--name", listener, "--network", "host", "--entrypoint", "nc"],
      ...[image, "-lk", "-p", port, "-e", "true"],
    );
    try {
      await expect
        .poll(() => connects(listener, "127.0.0.1", port), { message: `listener on ${port}` })
        .toBe(true);

      const [ipam] = JSON.parse(
        docker("network", "inspect", "--format", "{{json .IPAM.Config}}", getZooNetworkName()),
      ) as { Subnet: string; Gateway?: string }[];
      // Docker 28+ reserves no gateway for a bridge without an address; before, the first one
      const gateway = ipam.Gateway ?? ipam.Subnet.replace(/\.0\/\d+$/, ".1");
      expect(connects(caddy, gateway, port), `${gateway}:${port} from caddy`).toBe(false);
    } finally {
      // With the anonymous volume the image declares for /data
      docker("rm", "-fv", listener);
    }
  });
});
