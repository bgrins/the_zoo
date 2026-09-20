import { beforeEach, describe, expect, it, vi } from "vitest";
import { checkDocker, dockerProbe, TimeoutError } from "../../cli/lib/utils/docker";
import { getDockerSubnets } from "../../cli/lib/utils/network-env";

vi.mock("../../cli/lib/utils/docker", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../../cli/lib/utils/docker")>()),
  checkDocker: vi.fn(),
  dockerProbe: vi.fn(),
}));

const NETWORKS: Record<string, object> = {
  a: { Labels: {}, IPAM: { Config: [{ Subnet: "172.25.0.0/16" }] } },
  b: {
    Labels: { "com.docker.compose.project": "other" },
    IPAM: { Config: [{ Subnet: "10.200.0.0/16" }] },
  },
  own: {
    Labels: { "com.docker.compose.project": "mine" },
    IPAM: { Config: [{ Subnet: "172.26.0.0/16" }] },
  },
};

/**
 * A docker CLI whose `network ls` reports each of `listings` in turn (the last one from
 * then on), and whose `network inspect` fails like Docker's for any ID not in NETWORKS
 */
function fakeDocker(listings: string[][]) {
  let calls = 0;
  vi.mocked(dockerProbe).mockImplementation(async (args) => {
    if (args.join(" ") === "network ls -q") {
      const ids = listings[Math.min(calls++, listings.length - 1)];
      return { stdout: `${ids.join("\n")}\n`, stderr: "" };
    }
    const ids = args.slice(2);
    const missing = ids.find((id) => !(id in NETWORKS));
    if (missing) {
      throw new Error(`Command failed with code 1: network ${missing} not found`);
    }
    return { stdout: JSON.stringify(ids.map((id) => NETWORKS[id])), stderr: "" };
  });
}

describe("getDockerSubnets", () => {
  beforeEach(() => {
    vi.mocked(dockerProbe).mockReset();
    vi.mocked(checkDocker).mockReset();
  });

  it("should list again when a network disappears between ls and inspect", async () => {
    fakeDocker([
      ["a", "gone", "b", "own"],
      ["a", "b", "own"],
    ]);

    await expect(getDockerSubnets("mine")).resolves.toEqual(["172.25.0.0/16", "10.200.0.0/16"]);
  });

  it("should fail rather than ignore every network when inspect keeps failing", async () => {
    fakeDocker([["a", "gone"]]);

    await expect(getDockerSubnets("mine")).rejects.toThrow(
      "Could not inspect Docker networks: Command failed with code 1: network gone not found",
    );
  });

  it("should find no subnets only when Docker is unavailable", async () => {
    vi.mocked(dockerProbe).mockRejectedValue(new Error("Cannot connect to the Docker daemon"));

    vi.mocked(checkDocker).mockResolvedValue(false);
    await expect(getDockerSubnets("mine")).resolves.toEqual([]);

    vi.mocked(checkDocker).mockResolvedValue(true);
    await expect(getDockerSubnets("mine")).rejects.toThrow("Cannot connect to the Docker daemon");
  });

  it("should fail at once when Docker doesn't answer", async () => {
    const timeout = new TimeoutError('"docker network inspect a" did not finish within 15s');
    vi.mocked(dockerProbe)
      .mockResolvedValueOnce({ stdout: "a\n", stderr: "" })
      .mockRejectedValueOnce(timeout);

    await expect(getDockerSubnets("mine")).rejects.toBe(timeout);
    expect(dockerProbe).toHaveBeenCalledTimes(2);
    expect(checkDocker).not.toHaveBeenCalled();
  });
});
