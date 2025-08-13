import pg from "pg";

const { Pool } = pg;

// Database connection configuration
const pool = new Pool({
  host: "postgres.zoo",
  port: 5432,
  database: "auth_db",
  user: "auth_user",
  password: "auth_pw",
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Test the connection
pool.on("connect", () => {
  console.log("Connected to auth_db database");
});

pool.on("error", (err: Error) => {
  console.error("Unexpected database error:", err);
  process.exit(-1);
});

export default pool;
