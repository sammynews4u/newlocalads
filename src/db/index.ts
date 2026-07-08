import { drizzle, NodePgDatabase } from "drizzle-orm/node-postgres";
import { Pool, PoolConfig } from "pg";
import { attachDatabasePool } from "@vercel/functions";
import * as schema from "./schema";

const globalForDb = globalThis as typeof globalThis & {
  __arenaNextJsPostgresqlPool?: Pool;
  __arenaNextJsDrizzle?: NodePgDatabase<typeof schema>;
};

function isTruthy(value: string | undefined): boolean {
  return ["1", "true", "yes", "on"].includes((value || "").toLowerCase());
}

function shouldUseSsl(databaseUrl: string): boolean {
  try {
    const url = new URL(databaseUrl);
    const sslMode = url.searchParams.get("sslmode")?.toLowerCase();

    return (
      sslMode === "require" ||
      sslMode === "verify-full" ||
      url.hostname.endsWith(".supabase.co") ||
      url.hostname.endsWith(".pooler.supabase.com") ||
      isTruthy(process.env.DATABASE_SSL)
    );
  } catch {
    return isTruthy(process.env.DATABASE_SSL);
  }
}

function getNumberEnv(name: string, fallback: number): number {
  const value = Number(process.env[name]);
  return Number.isFinite(value) && value > 0 ? value : fallback;
}

function getPool(): Pool {
  if (globalForDb.__arenaNextJsPostgresqlPool) {
    return globalForDb.__arenaNextJsPostgresqlPool;
  }

  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) {
    throw new Error("DATABASE_URL is required");
  }

  const max = getNumberEnv("DATABASE_POOL_MAX", 5);
  const config: PoolConfig = {
    connectionString: databaseUrl,
    max,
    idleTimeoutMillis: getNumberEnv("DATABASE_IDLE_TIMEOUT_MS", 5_000),
    connectionTimeoutMillis: getNumberEnv("DATABASE_CONNECTION_TIMEOUT_MS", 10_000),
    allowExitOnIdle: true,
  };

  if (shouldUseSsl(databaseUrl)) {
    config.ssl = { rejectUnauthorized: false };
  }

  const pool = new Pool(config);

  // Vercel reuses warm serverless instances. Keeping one global pool prevents
  // a new pool from being constructed on every invocation, while attachDatabasePool
  // closes idle connections before the function instance is suspended.
  attachDatabasePool(pool);

  globalForDb.__arenaNextJsPostgresqlPool = pool;
  return pool;
}

function getDb(): NodePgDatabase<typeof schema> {
  if (globalForDb.__arenaNextJsDrizzle) {
    return globalForDb.__arenaNextJsDrizzle;
  }

  const db = drizzle(getPool(), { schema });
  globalForDb.__arenaNextJsDrizzle = db;
  return db;
}

// Lazy proxies: pool and db are only created on first actual use at runtime,
// never at import/build time. This lets `npm run build` succeed without
// DATABASE_URL being present during the build phase.
export const pool: Pool = new Proxy({} as Pool, {
  get(_target, prop, receiver) {
    const real = getPool();
    const value = Reflect.get(real, prop, receiver);
    return typeof value === "function" ? value.bind(real) : value;
  },
});

export const db: NodePgDatabase<typeof schema> = new Proxy(
  {} as NodePgDatabase<typeof schema>,
  {
    get(_target, prop, receiver) {
      const real = getDb();
      const value = Reflect.get(real, prop, receiver);
      return typeof value === "function" ? value.bind(real) : value;
    },
  }
);
