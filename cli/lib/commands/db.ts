import path from "node:path";
import chalk from "chalk";
import { checkDocker, dockerComposeExec } from "../utils/docker";
import { getProjectName } from "../utils/project";
import { paths } from "../utils/config";

interface DbOptions {
  instance?: string;
}

interface CompareOptions extends DbOptions {
  database?: string;
}

/**
 * Get the zoo source path for a running instance
 */
function getZooSourcePath(projectName: string): string {
  const match = projectName.match(/^thezoo-cli-instance-(.+?)-v/);
  if (match) {
    const instanceId = match[1];
    const instancePath = path.join(paths.runtime, instanceId, "zoo");
    return instancePath;
  }
  return process.cwd();
}

/**
 * List available database snapshots
 */
export async function dbList(options: DbOptions): Promise<void> {
  const dockerRunning = await checkDocker();
  if (!dockerRunning) {
    console.error(chalk.red("❌ Docker is not running. Please start Docker first."));
    process.exit(1);
  }

  try {
    const projectName = await getProjectName(options.instance);
    const zooSourcePath = getZooSourcePath(projectName);

    console.log(chalk.cyan("\n📦 PostgreSQL Snapshots:"));
    const pgResult = await dockerComposeExec(
      "postgres",
      [
        "sh",
        "-c",
        "ls -lh /var/lib/postgresql/snapshots/*.sql.xz 2>/dev/null || echo 'No snapshots found'",
      ],
      { cwd: zooSourcePath, projectName },
    );
    if (pgResult.stdout) {
      const lines = pgResult.stdout.trim().split("\n");
      for (const line of lines) {
        if (line.includes(".sql.xz")) {
          const parts = line.split(/\s+/);
          const size = parts[4];
          const filename = parts[8].split("/").pop()?.replace(".sql.xz", "") || "";
          console.log(`  ${chalk.green("✓")} ${filename} (${size})`);
        } else {
          console.log(`  ${line}`);
        }
      }
    }

    console.log(chalk.cyan("\n📦 MySQL Snapshots:"));
    const mysqlResult = await dockerComposeExec(
      "mysql",
      [
        "sh",
        "-c",
        "ls -lh /var/lib/mysql/snapshots/*.sql.xz 2>/dev/null || echo 'No snapshots found'",
      ],
      { cwd: zooSourcePath, projectName },
    );
    if (mysqlResult.stdout) {
      const lines = mysqlResult.stdout.trim().split("\n");
      for (const line of lines) {
        if (line.includes(".sql.xz")) {
          const parts = line.split(/\s+/);
          const size = parts[4];
          const filename = parts[8].split("/").pop()?.replace(".sql.xz", "") || "";
          console.log(`  ${chalk.green("✓")} ${filename} (${size})`);
        } else {
          console.log(`  ${line}`);
        }
      }
    }
  } catch (error) {
    if (error instanceof Error) {
      console.error(chalk.red(`❌ ${error.message}`));
      process.exit(1);
    }
    throw error;
  }
}

/**
 * Compare snapshot with live database
 */
export async function dbCompare(options: CompareOptions): Promise<void> {
  const dockerRunning = await checkDocker();
  if (!dockerRunning) {
    console.error(chalk.red("❌ Docker is not running. Please start Docker first."));
    process.exit(1);
  }

  try {
    const projectName = await getProjectName(options.instance);
    const zooSourcePath = getZooSourcePath(projectName);

    if (!options.database) {
      console.error(chalk.red("❌ Please specify a database with --database"));
      process.exit(1);
    }

    const dbName = options.database;

    // Determine database type
    let dbType: "postgres" | "mysql" | null = null;
    let service: string | null = null;

    // Check if snapshot exists in postgres
    const pgCheck = await dockerComposeExec(
      "postgres",
      ["test", "-f", `/var/lib/postgresql/snapshots/${dbName}.sql.xz`],
      { cwd: zooSourcePath, projectName },
    );
    if (pgCheck.exitCode === 0) {
      dbType = "postgres";
      service = "postgres";
    }

    // Check if snapshot exists in mysql
    if (!dbType) {
      const mysqlCheck = await dockerComposeExec(
        "mysql",
        ["test", "-f", `/var/lib/mysql/snapshots/${dbName}.sql.xz`],
        { cwd: zooSourcePath, projectName },
      );
      if (mysqlCheck.exitCode === 0) {
        dbType = "mysql";
        service = "mysql";
      }
    }

    if (!dbType || !service) {
      console.error(chalk.red(`❌ No snapshot found for database: ${dbName}`));
      console.log(chalk.yellow("\n💡 Use 'thezoo db list' to see available snapshots"));
      process.exit(1);
    }

    console.log(chalk.cyan(`\n🔍 Comparing ${dbType} database: ${dbName}`));
    console.log(chalk.gray(`   Snapshot → Live database\n`));

    if (dbType === "postgres") {
      await comparePostgres(dbName, service, zooSourcePath, projectName);
    } else {
      await compareMysql(dbName, service, zooSourcePath, projectName);
    }
  } catch (error) {
    if (error instanceof Error) {
      console.error(chalk.red(`❌ ${error.message}`));
      process.exit(1);
    }
    throw error;
  }
}

async function comparePostgres(
  dbName: string,
  service: string,
  zooSourcePath: string,
  projectName: string,
): Promise<void> {
  // Create temporary database for snapshot
  const tempDbName = `${dbName}_snapshot_temp`;

  console.log(chalk.gray(`   Creating temporary database...`));

  // Drop temp db if exists
  await dockerComposeExec(
    service,
    ["psql", "-U", "postgres", "-c", `DROP DATABASE IF EXISTS ${tempDbName}`],
    { cwd: zooSourcePath, projectName },
  );

  // Create temp db
  await dockerComposeExec(
    service,
    ["psql", "-U", "postgres", "-c", `CREATE DATABASE ${tempDbName}`],
    { cwd: zooSourcePath, projectName },
  );

  // Load snapshot into temp db
  console.log(chalk.gray(`   Loading snapshot...`));
  await dockerComposeExec(
    service,
    [
      "sh",
      "-c",
      `xzcat /var/lib/postgresql/snapshots/${dbName}.sql.xz | psql -U postgres -d ${tempDbName}`,
    ],
    { cwd: zooSourcePath, projectName },
  );

  // Compare schemas
  console.log(chalk.cyan("\n📊 Schema Comparison:"));

  // Get table counts
  const snapshotTables = await dockerComposeExec(
    service,
    [
      "psql",
      "-U",
      "postgres",
      "-d",
      tempDbName,
      "-t",
      "-c",
      "SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename",
    ],
    { cwd: zooSourcePath, projectName },
  );

  const liveTables = await dockerComposeExec(
    service,
    [
      "psql",
      "-U",
      "postgres",
      "-d",
      dbName,
      "-t",
      "-c",
      "SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename",
    ],
    { cwd: zooSourcePath, projectName },
  );

  const snapshotTableList = snapshotTables.stdout
    .trim()
    .split("\n")
    .filter(Boolean)
    .map((t) => t.trim());
  const liveTableList = liveTables.stdout
    .trim()
    .split("\n")
    .filter(Boolean)
    .map((t) => t.trim());

  // Compare table lists
  const onlyInSnapshot = snapshotTableList.filter((t) => !liveTableList.includes(t));
  const onlyInLive = liveTableList.filter((t) => !snapshotTableList.includes(t));
  const commonTables = snapshotTableList.filter((t) => liveTableList.includes(t));

  if (onlyInSnapshot.length > 0) {
    console.log(chalk.red(`   ⚠ Tables only in snapshot: ${onlyInSnapshot.join(", ")}`));
  }
  if (onlyInLive.length > 0) {
    console.log(chalk.yellow(`   ⚠ Tables only in live: ${onlyInLive.join(", ")}`));
  }
  if (onlyInSnapshot.length === 0 && onlyInLive.length === 0) {
    console.log(chalk.green(`   ✓ All tables match`));
  }

  // Compare row counts and data for common tables
  console.log(chalk.cyan("\n📊 Table Data Comparison:"));
  for (const table of commonTables) {
    const snapshotCount = await dockerComposeExec(
      service,
      ["psql", "-U", "postgres", "-d", tempDbName, "-t", "-c", `SELECT COUNT(*) FROM "${table}"`],
      { cwd: zooSourcePath, projectName },
    );

    const liveCount = await dockerComposeExec(
      service,
      ["psql", "-U", "postgres", "-d", dbName, "-t", "-c", `SELECT COUNT(*) FROM "${table}"`],
      { cwd: zooSourcePath, projectName },
    );

    const snapshotRows = parseInt(snapshotCount.stdout.trim());
    const liveRows = parseInt(liveCount.stdout.trim());

    // Get column list for this table
    const columnsResult = await dockerComposeExec(
      service,
      [
        "psql",
        "-U",
        "postgres",
        "-d",
        dbName,
        "-t",
        "-c",
        `SELECT column_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name = '${table}' ORDER BY ordinal_position`,
      ],
      { cwd: zooSourcePath, projectName },
    );

    const columns = columnsResult.stdout
      .trim()
      .split("\n")
      .filter(Boolean)
      .map((c) => c.trim());

    // Skip if no columns or row count differs
    if (columns.length === 0) {
      console.log(chalk.gray(`   ⊝ ${table}: no columns`));
      continue;
    }

    if (snapshotRows !== liveRows) {
      const diff = liveRows - snapshotRows;
      const sign = diff > 0 ? "+" : "";
      console.log(
        chalk.yellow(`   ⚠ ${table}: ${snapshotRows} → ${liveRows} rows (${sign}${diff})`),
      );
      continue;
    }

    // If row counts match, compare data by computing hash of each column
    const changedColumns: string[] = [];
    for (const column of columns) {
      const snapshotHash = await dockerComposeExec(
        service,
        [
          "psql",
          "-U",
          "postgres",
          "-d",
          tempDbName,
          "-t",
          "-c",
          `SELECT md5(string_agg(COALESCE("${column}"::text, 'NULL'), '|' ORDER BY ctid)) FROM "${table}"`,
        ],
        { cwd: zooSourcePath, projectName },
      );

      const liveHash = await dockerComposeExec(
        service,
        [
          "psql",
          "-U",
          "postgres",
          "-d",
          dbName,
          "-t",
          "-c",
          `SELECT md5(string_agg(COALESCE("${column}"::text, 'NULL'), '|' ORDER BY ctid)) FROM "${table}"`,
        ],
        { cwd: zooSourcePath, projectName },
      );

      if (snapshotHash.stdout.trim() !== liveHash.stdout.trim()) {
        changedColumns.push(column);
      }
    }

    if (changedColumns.length > 0) {
      console.log(
        chalk.yellow(
          `   ⚠ ${table}: ${liveRows} rows, ${changedColumns.length} column(s) changed: ${changedColumns.join(", ")}`,
        ),
      );
    } else {
      console.log(chalk.green(`   ✓ ${table}: ${liveRows} rows (no changes)`));
    }
  }

  // Clean up temp database
  console.log(chalk.gray(`\n   Cleaning up temporary database...`));
  await dockerComposeExec(
    service,
    ["psql", "-U", "postgres", "-c", `DROP DATABASE ${tempDbName}`],
    { cwd: zooSourcePath, projectName },
  );

  console.log(chalk.green("\n✅ Comparison complete\n"));
}

async function compareMysql(
  dbName: string,
  service: string,
  zooSourcePath: string,
  projectName: string,
): Promise<void> {
  // Create temporary database for snapshot
  const tempDbName = `${dbName}_snapshot_temp`;

  console.log(chalk.gray(`   Creating temporary database...`));

  // Drop temp db if exists
  await dockerComposeExec(
    service,
    [
      "mysql",
      "-h",
      "127.0.0.1",
      "-uroot",
      "-ppassword",
      "-e",
      `DROP DATABASE IF EXISTS ${tempDbName}`,
    ],
    { cwd: zooSourcePath, projectName },
  );

  // Create temp db
  await dockerComposeExec(
    service,
    ["mysql", "-h", "127.0.0.1", "-uroot", "-ppassword", "-e", `CREATE DATABASE ${tempDbName}`],
    { cwd: zooSourcePath, projectName },
  );

  // Load snapshot into temp db
  console.log(chalk.gray(`   Loading snapshot...`));
  await dockerComposeExec(
    service,
    [
      "sh",
      "-c",
      `xzcat /var/lib/mysql/snapshots/${dbName}.sql.xz | mysql -h 127.0.0.1 -uroot -ppassword ${tempDbName}`,
    ],
    { cwd: zooSourcePath, projectName },
  );

  // Compare schemas
  console.log(chalk.cyan("\n📊 Schema Comparison:"));

  // Get table lists
  const snapshotTables = await dockerComposeExec(
    service,
    ["mysql", "-h", "127.0.0.1", "-uroot", "-ppassword", "-e", `SHOW TABLES FROM ${tempDbName}`],
    { cwd: zooSourcePath, projectName },
  );

  const liveTables = await dockerComposeExec(
    service,
    ["mysql", "-h", "127.0.0.1", "-uroot", "-ppassword", "-e", `SHOW TABLES FROM ${dbName}`],
    { cwd: zooSourcePath, projectName },
  );

  const snapshotTableList = snapshotTables.stdout
    .trim()
    .split("\n")
    .slice(1)
    .filter(Boolean)
    .map((t) => t.trim());
  const liveTableList = liveTables.stdout
    .trim()
    .split("\n")
    .slice(1)
    .filter(Boolean)
    .map((t) => t.trim());

  // Compare table lists
  const onlyInSnapshot = snapshotTableList.filter((t) => !liveTableList.includes(t));
  const onlyInLive = liveTableList.filter((t) => !snapshotTableList.includes(t));
  const commonTables = snapshotTableList.filter((t) => liveTableList.includes(t));

  if (onlyInSnapshot.length > 0) {
    console.log(chalk.red(`   ⚠ Tables only in snapshot: ${onlyInSnapshot.join(", ")}`));
  }
  if (onlyInLive.length > 0) {
    console.log(chalk.yellow(`   ⚠ Tables only in live: ${onlyInLive.join(", ")}`));
  }
  if (onlyInSnapshot.length === 0 && onlyInLive.length === 0) {
    console.log(chalk.green(`   ✓ All tables match`));
  }

  // Compare row counts and data for common tables
  console.log(chalk.cyan("\n📊 Table Data Comparison:"));
  for (const table of commonTables) {
    const snapshotCount = await dockerComposeExec(
      service,
      [
        "mysql",
        "-h",
        "127.0.0.1",
        "-uroot",
        "-ppassword",
        "-e",
        `SELECT COUNT(*) FROM ${tempDbName}.${table}`,
      ],
      { cwd: zooSourcePath, projectName },
    );

    const liveCount = await dockerComposeExec(
      service,
      [
        "mysql",
        "-h",
        "127.0.0.1",
        "-uroot",
        "-ppassword",
        "-e",
        `SELECT COUNT(*) FROM ${dbName}.${table}`,
      ],
      { cwd: zooSourcePath, projectName },
    );

    const snapshotRows = parseInt(snapshotCount.stdout.trim().split("\n")[1]);
    const liveRows = parseInt(liveCount.stdout.trim().split("\n")[1]);

    // Get column list for this table
    const columnsResult = await dockerComposeExec(
      service,
      [
        "mysql",
        "-h",
        "127.0.0.1",
        "-uroot",
        "-ppassword",
        "-e",
        `SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = '${dbName}' AND TABLE_NAME = '${table}' ORDER BY ORDINAL_POSITION`,
      ],
      { cwd: zooSourcePath, projectName },
    );

    const columns = columnsResult.stdout
      .trim()
      .split("\n")
      .slice(1)
      .filter(Boolean)
      .map((c) => c.trim());

    // Skip if no columns
    if (columns.length === 0) {
      console.log(chalk.gray(`   ⊝ ${table}: no columns`));
      continue;
    }

    if (snapshotRows !== liveRows) {
      const diff = liveRows - snapshotRows;
      const sign = diff > 0 ? "+" : "";
      console.log(
        chalk.yellow(`   ⚠ ${table}: ${snapshotRows} → ${liveRows} rows (${sign}${diff})`),
      );
      continue;
    }

    // If row counts match, compare data by computing hash of each column
    const changedColumns: string[] = [];
    for (const column of columns) {
      // Use GROUP_CONCAT with MD5 to compare column data
      const snapshotHash = await dockerComposeExec(
        service,
        [
          "mysql",
          "-h",
          "127.0.0.1",
          "-uroot",
          "-ppassword",
          "-N",
          "-e",
          `SELECT MD5(GROUP_CONCAT(IFNULL(\`${column}\`, 'NULL') ORDER BY \`${column}\` SEPARATOR '|')) FROM ${tempDbName}.\`${table}\``,
        ],
        { cwd: zooSourcePath, projectName },
      );

      const liveHash = await dockerComposeExec(
        service,
        [
          "mysql",
          "-h",
          "127.0.0.1",
          "-uroot",
          "-ppassword",
          "-N",
          "-e",
          `SELECT MD5(GROUP_CONCAT(IFNULL(\`${column}\`, 'NULL') ORDER BY \`${column}\` SEPARATOR '|')) FROM ${dbName}.\`${table}\``,
        ],
        { cwd: zooSourcePath, projectName },
      );

      if (snapshotHash.stdout.trim() !== liveHash.stdout.trim()) {
        changedColumns.push(column);
      }
    }

    if (changedColumns.length > 0) {
      console.log(
        chalk.yellow(
          `   ⚠ ${table}: ${liveRows} rows, ${changedColumns.length} column(s) changed: ${changedColumns.join(", ")}`,
        ),
      );
    } else {
      console.log(chalk.green(`   ✓ ${table}: ${liveRows} rows (no changes)`));
    }
  }

  // Clean up temp database
  console.log(chalk.gray(`\n   Cleaning up temporary database...`));
  await dockerComposeExec(
    service,
    ["mysql", "-h", "127.0.0.1", "-uroot", "-ppassword", "-e", `DROP DATABASE ${tempDbName}`],
    { cwd: zooSourcePath, projectName },
  );

  console.log(chalk.green("\n✅ Comparison complete\n"));
}
