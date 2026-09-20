import { appendFileSync } from "node:fs";
import { relative } from "node:path";
import type { Reporter, TestCase } from "vitest/node";

/**
 * Lists the tests that passed only on a retry in the GitHub Actions job summary, so a
 * retry can't hide them
 */
export default class FlakySummaryReporter implements Reporter {
  private flaky: string[] = [];

  onTestCaseResult(testCase: TestCase) {
    if (testCase.diagnostic()?.flaky) {
      const file = relative(process.cwd(), testCase.module.moduleId);
      this.flaky.push(`\`${file}\` > ${testCase.fullName}`);
    }
  }

  onTestRunEnd() {
    const summary = process.env.GITHUB_STEP_SUMMARY;
    if (!summary || this.flaky.length === 0) return;
    const list = this.flaky.map((test) => `- ${test}`).join("\n");
    appendFileSync(summary, `### Tests that passed only on a retry\n\n${list}\n\n`);
  }
}
