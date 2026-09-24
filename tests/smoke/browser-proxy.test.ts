import { describe, expect, test } from "vitest";
import { selectBrowserProxy } from "../../scripts/lib/browser-proxy";

const instances = [
  { instanceId: null, project: "the_zoo", proxyUrl: "http://localhost:3128" },
  {
    instanceId: "sandbox",
    project: "thezoo-cli-instance-sandbox",
    proxyUrl: "http://localhost:3190",
  },
];

describe("MCP browser proxy selection", () => {
  test("uses the published port of the selected instance", () => {
    expect(selectBrowserProxy(instances, "sandbox")).toBe("http://localhost:3190");
    expect(selectBrowserProxy(instances, "the_zoo")).toBe("http://localhost:3128");
  });

  test("refuses ambiguous or absent instances rather than guessing a proxy", () => {
    expect(() => selectBrowserProxy(instances)).toThrow("Multiple Zoo instances");
    expect(() => selectBrowserProxy(instances, "unknown")).toThrow("No running Zoo instance");
    expect(() => selectBrowserProxy([])).toThrow("No running Zoo instance");
  });

  test("refuses a running instance without a published proxy", () => {
    expect(() => selectBrowserProxy([{ ...instances[0], proxyUrl: null }])).toThrow(
      "no published proxy port",
    );
  });
});
