import { describe, expect, test } from "vitest";
import { fetchWithProxy } from "../../scripts/lib/http-client";

// Width and height from a PNG's IHDR chunk, which follows the 8-byte signature
function pngSize(png: Buffer) {
  expect(png.subarray(0, 8).toString("hex"), "PNG signature").toBe("89504e470d0a1a0a");
  expect(png.subarray(12, 16).toString("latin1")).toBe("IHDR");
  return { width: png.readUInt32BE(16), height: png.readUInt32BE(20) };
}

async function avatar(path: string) {
  const result = await fetchWithProxy(`http://secure.gravatar.com/avatar/${path}`);
  expect(result.httpCode, result.error).toBe(200);
  expect(result.headers["content-type"]).toBe("image/png");
  return result.bytes;
}

describe("Gravatar Service Tests", () => {
  test("avatars are s pixels square, 80 by default", async () => {
    const hash = "d8f0406e56d8133992149ac639e16ce2";
    expect(pngSize(await avatar(`${hash}?d=identicon&s=48`))).toEqual({ width: 48, height: 48 });
    expect(pngSize(await avatar(`${hash}?s=200`))).toEqual({ width: 200, height: 200 });
    expect(pngSize(await avatar(hash))).toEqual({ width: 80, height: 80 });
  });

  test("each hash has its own identicon, the same on every request", async () => {
    const hashes = [
      "d8f0406e56d8133992149ac639e16ce2",
      "00000000000000000000000000000000",
      "ffffffffffffffffffffffffffffffff",
    ];
    const images = await Promise.all(hashes.map((hash) => avatar(`${hash}?s=80`)));
    expect(new Set(images.map((image) => image.toString("base64"))).size).toBe(hashes.length);

    expect((await avatar(`${hashes[0]}?s=80`)).equals(images[0])).toBe(true);
  });
});
