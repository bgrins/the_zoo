import { describe, expect, test } from "vitest";
import { fetchWithProxy } from "../utils/http-client";
import { getProjectName } from "../utils/docker-project";

// status.zoo calls these endpoints; stats collection for every container takes ~2s
const API = "https://system-api.zoo/docker/api";
const FETCH_TIMEOUT = 8000;

async function getJson(path: string) {
  const result = await fetchWithProxy(`${API}${path}`, { timeout: FETCH_TIMEOUT });
  expect(result.httpCode, `${path}: ${result.error ?? result.body}`).toBe(200);
  expect(result.contentType).toContain("application/json");
  return { result, json: JSON.parse(result.body) };
}

interface Container {
  name: string;
  state: string;
  labels: Record<string, string>;
  stats?: Record<string, string>;
}

describe("System API Docker Endpoints", () => {
  test("containers lists only this project's containers", async () => {
    const { json } = await getJson("/containers");
    const containers: Container[] = json.containers;
    const project = getProjectName();

    expect(containers.map((c) => c.labels["com.docker.compose.project"])).toEqual(
      containers.map(() => project),
    );
    expect(
      containers.find((c) => c.labels["com.docker.compose.service"] === "caddy"),
    ).toMatchObject({ state: "running" });
    expect(containers.every((c) => c.stats === undefined)).toBe(true);
  });

  test("containers?stats=true attaches docker-stats fields to running containers", async () => {
    const { json } = await getJson("/containers?stats=true");
    const running = (json.containers as Container[]).filter((c) => c.state === "running");
    expect(running.length).toBeGreaterThan(0);

    for (const container of running) {
      expect(container.stats, container.name).toEqual({
        cpuPerc: expect.stringMatching(/^\d+\.\d{2}%$/),
        memPerc: expect.stringMatching(/^\d+\.\d{2}%$/),
        memUsage: expect.stringMatching(/^[\d.]+[KMG]?i?B \/ [\d.]+[KMG]i?B$/),
        netIO: expect.stringMatching(/^[\d.]+[kMG]?B \/ [\d.]+[kMG]?B$/),
        blockIO: expect.stringMatching(/^[\d.]+[kMG]?B \/ [\d.]+[kMG]?B$/),
        pids: expect.stringMatching(/^\d+$/),
      });
      expect(json.stats[container.name], container.name).toEqual(container.stats);
    }
  });

  test("container logs honor tail", async () => {
    const name = `${getProjectName()}-caddy-1`;
    const { json } = await getJson(`/container/${name}/logs?tail=1`);
    expect(json).toMatchObject({ container: name, tail: "1" });
    expect(json.logs.trimEnd().split("\n")).toHaveLength(1);
  });

  test("system-metrics reports image, volume and memory totals", async () => {
    const { json } = await getJson("/system-metrics");
    expect(json).toEqual({
      images: expect.any(Number),
      volumes: expect.any(Number),
      memory: { total: expect.stringMatching(/^[\d.]+ GB$/) },
      timestamp: expect.any(Number),
    });
    expect(json.images).toBeGreaterThan(0);
  });

  test("responses include CORS headers", async () => {
    const { result } = await getJson("/containers");
    expect(result.headers["access-control-allow-origin"]).toBe("*");
    expect(result.headers["access-control-allow-methods"]).toContain("GET");
    expect(result.headers["access-control-allow-headers"]).toContain("Content-Type");
  });
});
