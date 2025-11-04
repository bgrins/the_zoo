import { beforeAll, describe, expect, test } from "vitest";
import { getCachedNetworkInfo } from "../utils/test-cache";
import { fetchWithProxy } from "../utils/http-client";

describe("Gravatar Service Tests", () => {
  beforeAll(async () => {
    await getCachedNetworkInfo();
  });

  test("should return a PNG image for avatar request", async () => {
    const hash = "d8f0406e56d8133992149ac639e16ce2";
    const result = await fetchWithProxy(
      `http://secure.gravatar.com/avatar/${hash}?d=identicon&s=48`,
    );

    if (!result.success) {
      throw new Error(`Failed to fetch avatar: ${result.error}`);
    }

    expect(result.headers["content-type"]).toBe("image/png");
    expect(result.body.length).toBeGreaterThan(0);
  });

  test("should handle different avatar sizes", async () => {
    const hash = "test123";
    const sizes = [48, 80, 200];

    for (const size of sizes) {
      const result = await fetchWithProxy(`http://secure.gravatar.com/avatar/${hash}?s=${size}`);

      if (!result.success) {
        throw new Error(`Failed to fetch avatar with size ${size}: ${result.error}`);
      }

      expect(result.headers["content-type"]).toBe("image/png");
      expect(result.body.length).toBeGreaterThan(0);
    }
  });

  test("should handle different hash values", async () => {
    const hashes = [
      "d8f0406e56d8133992149ac639e16ce2",
      "00000000000000000000000000000000",
      "ffffffffffffffffffffffffffffffff",
    ];

    for (const hash of hashes) {
      const result = await fetchWithProxy(`http://secure.gravatar.com/avatar/${hash}?s=80`);

      if (!result.success) {
        throw new Error(`Failed to fetch avatar with hash ${hash}: ${result.error}`);
      }

      expect(result.headers["content-type"]).toBe("image/png");
      expect(result.body.length).toBeGreaterThan(0);
    }
  });
});
