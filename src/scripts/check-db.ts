import "dotenv/config";
import { Pool, PoolConfig } from "pg";

function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`${name} is missing`);
  }
  return value;
}

function shouldUseSsl(databaseUrl: string): boolean {
  try {
    const url = new URL(databaseUrl);
    return (
      url.searchParams.get("sslmode") === "require" ||
      url.hostname.endsWith(".supabase.co") ||
      url.hostname.endsWith(".pooler.supabase.com") ||
      process.env.DATABASE_SSL === "true"
    );
  } catch {
    return process.env.DATABASE_SSL === "true";
  }
}

async function main() {
  const databaseUrl = requireEnv("DATABASE_URL");
  const config: PoolConfig = {
    connectionString: databaseUrl,
    max: 1,
    idleTimeoutMillis: 5_000,
    connectionTimeoutMillis: 10_000,
    allowExitOnIdle: true,
  };

  if (shouldUseSsl(databaseUrl)) {
    config.ssl = { rejectUnauthorized: false };
  }

  const pool = new Pool(config);

  try {
    const result = await pool.query<{
      now: string;
      current_database: string;
      current_user: string;
    }>("select now(), current_database(), current_user");

    console.log("Database connection OK");
    console.table(result.rows);
  } finally {
    await pool.end();
  }
}

main().catch((error) => {
  console.error("Database connection failed");
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
});
