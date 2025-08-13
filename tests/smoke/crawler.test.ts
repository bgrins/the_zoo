import { describe, it } from "vitest";
import { expect } from "vitest";
import YAML from "yaml";
import { readFileSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import fs from "node:fs/promises";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

describe("Simplified Crawler Smoke Tests", () => {
  const dockerComposePath = resolve(__dirname, "../../docker-compose.yaml");
  const dockerComposeContent = readFileSync(dockerComposePath, "utf8");
  const dockerCompose = YAML.parse(dockerComposeContent) as any;

  it("should have crawler service defined in docker-compose", () => {
    expect(dockerCompose.services).toHaveProperty("zoo-crawler");

    const crawlerService = dockerCompose.services["zoo-crawler"];
    expect(crawlerService.build).toBe("./core/crawler");
    expect(crawlerService.profiles).toContain("tools");
  });

  it("should have crawler dependencies configured", () => {
    const crawlerService = dockerCompose.services["zoo-crawler"];

    expect(crawlerService.depends_on).toBeDefined();
    expect(crawlerService.depends_on).toHaveProperty("meilisearch");
    expect(crawlerService.depends_on).toHaveProperty("redis");
    expect(crawlerService.depends_on).toHaveProperty("caddy");
  });

  it("should have crawler environment variables", () => {
    const crawlerService = dockerCompose.services["zoo-crawler"];

    expect(crawlerService.environment).toBeDefined();

    // Check environment variables exist
    const envVars = crawlerService.environment.reduce((acc: any, env: string) => {
      const [key, value] = env.split("=");
      acc[key] = value;
      return acc;
    }, {});

    expect(envVars).toHaveProperty("MEILI_HOST");
    expect(envVars).toHaveProperty("REDIS_URL");
    expect(envVars).toHaveProperty("MAX_CONCURRENCY");
    expect(envVars).toHaveProperty("SEED_URL");
    expect(envVars.SEED_URL).toBe("http://utils.zoo");
  });

  it("should have crawler volumes configured", () => {
    const crawlerService = dockerCompose.services["zoo-crawler"];

    expect(crawlerService.volumes).toBeDefined();
    expect(crawlerService.volumes).toContain("./core/crawler:/app");
    expect(crawlerService.volumes).toContain("zoo_crawler_modules:/app/node_modules");
    expect(crawlerService.volumes).toContain("./data/crawler:/app/storage");
  });

  it("should have meilisearch service for crawler", () => {
    expect(dockerCompose.services).toHaveProperty("meilisearch");

    const meilisearchService = dockerCompose.services.meilisearch;
    expect(meilisearchService.image).toContain("getmeili/meilisearch");
  });

  it("should have search.zoo service with crawler endpoints", async () => {
    const searchServerPath = "./sites/apps/search.zoo/server.js";
    const content = await fs.readFile(searchServerPath, "utf-8");

    expect(content).toContain("/api/crawler/status");
    expect(content).toContain("crawler:pending");
    expect(content).toContain("crawler:activeSet");
    expect(content).toContain("crawler:failed");
  });
});
