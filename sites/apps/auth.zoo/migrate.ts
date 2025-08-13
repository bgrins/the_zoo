import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import db from "./db.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const MIGRATIONS_DIR = path.join(__dirname, "migrations");

interface MigrationRow {
  filename: string;
}

async function runMigrations(): Promise<void> {
  console.log("Running database migrations...");

  try {
    // Create migrations tracking table if it doesn't exist
    await db.query(`
      CREATE TABLE IF NOT EXISTS migrations (
        id SERIAL PRIMARY KEY,
        filename VARCHAR(255) UNIQUE NOT NULL,
        executed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Get list of migration files
    const files = await fs.readdir(MIGRATIONS_DIR);
    const sqlFiles = files.filter((f) => f.endsWith(".sql")).sort();

    // Get already executed migrations
    const result = await db.query<MigrationRow>("SELECT filename FROM migrations");
    const executed = new Set(result.rows.map((r) => r.filename));

    // Run pending migrations
    for (const file of sqlFiles) {
      if (!executed.has(file)) {
        console.log(`Running migration: ${file}`);
        const sql = await fs.readFile(path.join(MIGRATIONS_DIR, file), "utf8");

        // Execute migration in a transaction
        const client = await db.connect();
        try {
          await client.query("BEGIN");
          await client.query(sql);
          await client.query("INSERT INTO migrations (filename) VALUES ($1)", [file]);
          await client.query("COMMIT");
          console.log(`Migration ${file} completed successfully`);
        } catch (err) {
          await client.query("ROLLBACK");
          console.error(`Error running migration ${file}:`, err);
          throw err;
        } finally {
          client.release();
        }
      }
    }

    console.log("All migrations completed successfully");
  } catch (err) {
    console.error("Migration error:", err);
    throw err;
  }
}

export default runMigrations;
