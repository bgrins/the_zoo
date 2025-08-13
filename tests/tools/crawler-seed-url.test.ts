import { describe, it, beforeAll, afterAll } from "vitest";
import { expect } from "vitest";
import { exec } from "node:child_process";
import { promisify } from "node:util";
import { EXTRA_EXTENDED_TEST_TIMEOUT } from "../constants";

const execAsync = promisify(exec);

describe("Crawler Seed URL Tests", () => {
  beforeAll(async () => {
    console.log("Starting crawler container...");
    await execAsync("docker compose --profile tools up -d zoo-crawler", {
      timeout: EXTRA_EXTENDED_TEST_TIMEOUT,
    });
    await new Promise((resolve) => setTimeout(resolve, 3000));
  });

  afterAll(async () => {
    await execAsync("docker compose stop zoo-crawler");
  });

  it("should use default seed URL from environment", async () => {
    // Reset and check queue
    await execAsync("docker compose exec -T zoo-crawler npm run cli reset");

    // Check queue is empty
    const { stdout: emptyQueue } = await execAsync(
      "docker compose exec -T zoo-crawler npm run cli queue",
    );
    expect(emptyQueue).toContain("Pending: 0");

    // Start crawler (should seed with default URL)
    await execAsync("docker compose exec -T zoo-crawler npm run cli start");

    // Wait a moment
    await new Promise((resolve) => setTimeout(resolve, 1000));

    // Check queue now has the seed URL
    const { stdout: seededQueue } = await execAsync(
      "docker compose exec -T zoo-crawler npm run cli queue",
    );
    expect(seededQueue).toMatch(/Pending: [1-9]/);

    // Stop crawler
    await execAsync("docker compose exec -T zoo-crawler npm run cli stop");
  });

  it("should accept custom seed URL via CLI", async () => {
    // Reset and check queue
    await execAsync("docker compose exec -T zoo-crawler npm run cli reset");

    // Start with custom seed URL
    await execAsync(
      'docker compose exec -T zoo-crawler npm run cli start --seed-url "http://search.zoo"',
    );

    console.log("Started crawler with custom seed URL");

    // Stop crawler
    await execAsync("docker compose exec -T zoo-crawler npm run cli stop");
  });
});
