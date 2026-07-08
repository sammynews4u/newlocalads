import { defineConfig } from "drizzle-kit";
import "dotenv/config";

const databaseUrl =
  process.env.DATABASE_MIGRATION_URL ||
  process.env.DATABASE_DIRECT_URL ||
  process.env.DATABASE_URL;

if (!databaseUrl) {
  throw new Error(
    "DATABASE_URL is required. For production migrations, set DATABASE_MIGRATION_URL or DATABASE_DIRECT_URL to your Supabase direct connection string."
  );
}

export default defineConfig({
  dialect: "postgresql",
  schema: "./src/db/schema.ts",
  dbCredentials: {
    url: databaseUrl,
    ssl: true,
  },
});
