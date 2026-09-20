import { describe, it, expect } from "vitest";
import { runCLI } from "./helpers";

describe("thezoo create network options", () => {
  it("should show custom base IP in dry-run", async () => {
    const { code, stdout } = await runCLI(["create", "--dry-run", "--ip-base", "10.10.100.50"]);

    expect(code).toBe(0);
    expect(stdout).toContain("Custom base IP: 10.10.100.50");
    expect(stdout).toContain("Service IPs will be: 10.10.100.50 + 1, 2, 3");
  });

  it("should show defaults when no custom options", async () => {
    const { code, stdout } = await runCLI(["create", "--dry-run"]);

    expect(code).toBe(0);
    expect(stdout).toContain("Network: <randomly generated with high-range IPs>");
  });
});
