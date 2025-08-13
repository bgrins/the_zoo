import { describe, it, beforeAll, afterAll } from "vitest";
import { expect } from "vitest";
import { exec } from "node:child_process";
import { promisify } from "node:util";
import { EXTRA_EXTENDED_TEST_TIMEOUT } from "../constants";

const execAsync = promisify(exec);

describe("Zoo Crawler Tests", () => {
  beforeAll(async () => {
    console.log("Starting crawler container...");

    // Start the crawler container with tools profile
    await execAsync("docker compose --profile tools up -d zoo-crawler", {
      timeout: EXTRA_EXTENDED_TEST_TIMEOUT, // 60 second timeout for startup
    });

    // Wait a moment for the container to be ready
    await new Promise((resolve) => setTimeout(resolve, 3000));

    console.log("Crawler container started");
  });

  afterAll(async () => {
    console.log("Cleaning up crawler test...");

    // Stop the crawler but leave other services running
    await execAsync("docker compose stop zoo-crawler");
  });

  it("should run crawler CLI queue command", async () => {
    const { stdout } = await execAsync("docker compose exec -T zoo-crawler npm run cli queue");

    expect(stdout).toContain("Queue Status");
    expect(stdout).toMatch(/Pending:\s*\d+/);
    expect(stdout).toMatch(/Active:\s*\d+/);
    expect(stdout).toMatch(/Failed:\s*\d+/);
  });

  it("should have Redis accessible from crawler", async () => {
    const { stdout } = await execAsync(
      `docker compose exec -T zoo-crawler sh -c "nc -zv redis 6379 2>&1"`,
    );

    expect(stdout.toLowerCase()).toContain("open");
  });

  it("should have Meilisearch accessible from crawler", async () => {
    const { stdout } = await execAsync(
      `docker compose exec -T zoo-crawler sh -c "wget -qO- http://search-api.zoo/health || echo 'failed'"`,
    );

    expect(stdout).toContain("available");
  });

  it("should add URLs and check queue", async () => {
    // Reset state first
    await execAsync("docker compose exec -T zoo-crawler npm run cli reset");

    // Add a URL
    const { stdout: addOutput } = await execAsync(
      "docker compose exec -T zoo-crawler npm run cli -- add --url http://test.zoo",
    );
    expect(addOutput).toContain("Added URL to queue");

    // Check queue
    const { stdout: queueOutput } = await execAsync(
      "docker compose exec -T zoo-crawler npm run cli queue",
    );
    expect(queueOutput).toContain("Pending: 1");
  });

  it("should support worker management commands", async () => {
    // Check workers
    const { stdout: workersOutput } = await execAsync(
      "docker compose exec -T zoo-crawler npm run cli workers",
    );
    expect(workersOutput).toMatch(/Active Workers|No active workers/);

    // Check queue
    const { stdout: queueOutput } = await execAsync(
      "docker compose exec -T zoo-crawler npm run cli queue",
    );
    expect(queueOutput).toContain("Queue Status");
    expect(queueOutput).toMatch(/Pending:|Active:|Failed:/);
  });

  it("should support recover and cleanup commands", async () => {
    // Test recover command
    const { stdout: recoverOutput } = await execAsync(
      "docker compose exec -T zoo-crawler npm run cli recover",
    );
    expect(recoverOutput).toMatch(/No stale URLs found|Recovered \d+ stale URLs/);

    // Test cleanup command
    const { stdout: cleanupOutput } = await execAsync(
      "docker compose exec -T zoo-crawler npm run cli cleanup",
    );
    expect(cleanupOutput).toMatch(/No dead workers found|Cleaned up \d+ dead workers/);
  });

  it("should run internal test suite", async () => {
    const { stdout } = await execAsync("docker compose exec -T zoo-crawler npm run test:container");

    expect(stdout).toContain("All tests completed!");
    expect(stdout).not.toContain("✗ Failed");
  });
});
