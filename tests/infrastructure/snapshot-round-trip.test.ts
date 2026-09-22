import { exec } from "node:child_process";
import { promisify } from "node:util";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { composeProjectName } from "../utils/docker-project";

const execAsync = promisify(exec);

// Restarts the databases and every app that uses them. npm run test:infrastructure runs it
// after database-reset.test.ts, on its own.
const shouldRun = process.env.RUN_INFRASTRUCTURE_TESTS === "1";

const SNAPSHOT = "infrastructure-round-trip";
// Written before the snapshot, so its restore can be told apart from the golden state's
const PROBE = "zoo_snapshot_probe";
// A save stops and restarts every app that uses the databases
const TIMEOUT = 900_000;

// Asynchronous, as a command that blocks the worker for a minute times out its RPC to vitest
async function run(command: string, env: Record<string, string> = {}): Promise<string> {
  try {
    const { stdout } = await execAsync(command, { env: { ...process.env, ...env } });
    return stdout.trim();
  } catch (error: any) {
    throw new Error(`${command}\n${error.stderr || error.message}`);
  }
}

// The dev-mode CLI, pointed at the project under test in case several are running
function cli(command: string, args = "", env: Record<string, string> = {}): Promise<string> {
  return run(`npm run --silent cli -- ${command} --instance ${composeProjectName()} ${args}`, env);
}

const psql = (sql: string) =>
  run(`docker compose exec -T postgres psql -U postgres -d auth_db -tAc "${sql}"`);
const mysql = (sql: string) =>
  run(`docker compose exec -T mysql mysql -u root -N northwind_db -e "${sql}"`);

async function setProbe(state: string) {
  await psql(`UPDATE ${PROBE} SET state = '${state}'`);
  await mysql(`UPDATE ${PROBE} SET state = '${state}'`);
}

const probe = async () => ({
  postgres: await psql(`SELECT state FROM ${PROBE}`),
  mysql: await mysql(`SELECT state FROM ${PROBE}`),
});

// The dev environment isn't a CLI instance, whose .env `snapshot restore` sets the baseline
// in, so this does what its hint says: recreate the databases with ZOO_BASELINE
async function recreateDatabases(baseline: string) {
  await run("docker compose up -d --no-deps --wait --wait-timeout 300 postgres mysql", {
    ZOO_BASELINE: baseline,
  });
}

const snapshots = () => cli("snapshot", "list");

describe.skipIf(!shouldRun)("Snapshot round trip", { retry: 0 }, () => {
  // Also cleans up after an interrupted run
  const restoreGolden = async () => {
    await recreateDatabases("");
    if ((await snapshots()).includes(SNAPSHOT)) {
      await cli("snapshot", `rm ${SNAPSHOT}`);
    }
  };
  beforeAll(restoreGolden, TIMEOUT);
  afterAll(restoreGolden, TIMEOUT);

  it(
    "a saved snapshot restores as the baseline, and the golden state drops it",
    async () => {
      const create = `DROP TABLE IF EXISTS ${PROBE}; CREATE TABLE ${PROBE} (state text); INSERT INTO ${PROBE} VALUES ('saved');`;
      await psql(create);
      await mysql(create);

      await cli("snapshot", `save ${SNAPSHOT}`);
      expect(await snapshots()).toContain(SNAPSHOT);
      expect(await probe(), "after save").toEqual({ postgres: "saved", mysql: "saved" });

      await setProbe("changed");
      await recreateDatabases(SNAPSHOT);
      expect(await probe(), "after restoring the snapshot").toEqual({
        postgres: "saved",
        mysql: "saved",
      });
      const { databases } = JSON.parse(await cli("state", "--json"));
      expect([databases.postgres.source, databases.mysql.source]).toEqual([
        `snapshot:${SNAPSHOT}`,
        `snapshot:${SNAPSHOT}`,
      ]);

      await setProbe("changed");
      await cli("reset", "", { ZOO_BASELINE: SNAPSHOT });
      expect(await probe(), "after a reset").toEqual({ postgres: "saved", mysql: "saved" });

      await recreateDatabases("");
      await expect(psql(`SELECT state FROM ${PROBE}`)).rejects.toThrow(
        `relation "${PROBE}" does not exist`,
      );
      await expect(mysql(`SELECT state FROM ${PROBE}`)).rejects.toThrow(
        `Table 'northwind_db.${PROBE}' doesn't exist`,
      );

      await cli("snapshot", `rm ${SNAPSHOT}`);
      expect(await snapshots()).not.toContain(SNAPSHOT);
    },
    TIMEOUT,
  );
});
