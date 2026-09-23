import { spawnSync } from "node:child_process";
import { readFileSync } from "node:fs";
import path from "node:path";
import YAML from "yaml";
import { describe, expect, it } from "vitest";
import { ROOT_DIR } from "./helpers";

const workflow = YAML.parse(
  readFileSync(path.join(ROOT_DIR, ".github/workflows/docker-publish.yml"), "utf8"),
) as { jobs: { "tests-passed": { steps: { name: string; run?: string }[] } } };
const waitScript =
  workflow.jobs["tests-passed"].steps.find(
    (step) => step.name === "Wait for the tests check on this commit",
  )?.run ?? "";

if (!waitScript) {
  throw new Error("Docker publish tests check gate is missing");
}

const mockGh = `
gh() {
  case "$MOCK_MODE" in
    rerun)
      if (( attempt < 22 )); then echo "completed failure"
      elif (( attempt == 22 )); then :
      elif (( attempt == 23 )); then echo "in_progress null"
      else echo "completed success"; fi ;;
    never) : ;;
    failed) echo "completed failure" ;;
  esac
}
sleep() { :; }
`;

function runGate(mode: string) {
  const githubExpression = (name: string) => ["$", "{{ github.", name, " }}"].join("");
  const script = waitScript
    .replaceAll(githubExpression("event_name"), "push")
    .replaceAll(githubExpression("repository"), "bgrins/the_zoo")
    .replaceAll(githubExpression("sha"), "testsha");
  return spawnSync("bash", ["-c", mockGh + script], {
    encoding: "utf8",
    timeout: 5000,
    env: { ...process.env, MOCK_MODE: mode, SHARED_REF: "true" },
  });
}

describe("Docker publish tests check gate", () => {
  it("waits through a missing check during a rerun", () => {
    const result = runGate("rerun");
    expect(result.status).toBe(0);
    expect(result.stdout).toContain("tests check: not started");
  });

  it("rejects a commit that never had a tests check", () => {
    const result = runGate("never");
    expect(result.status).toBe(1);
    expect(result.stdout).toContain("No tests check exists for testsha");
  });

  it("stops waiting after a failed check without a rerun", () => {
    const result = runGate("failed");
    expect(result.status).toBe(1);
    expect(result.stdout).toContain("tests failed and was not re-run to success within 30 minutes");
  });
});
