# Fresh Vercel + Supabase Deployment Guide

This package has been prepared for the new Supabase project:

- Project ref: `jjucyadatlpruinptwdk`
- Supabase URL: `https://jjucyadatlpruinptwdk.supabase.co`
- Pooler region: `eu-central-1`

## Critical rule

Do not hardcode your Supabase database password inside source files. Put it only in `.env` locally and in Vercel Environment Variables.

## 1. Local `.env`

Create `.env` from `.env.example` and replace `<YOUR_SUPABASE_DB_PASSWORD>` with your new Supabase database password.

Runtime URL for app/serverless:

```env
DATABASE_URL=postgresql://postgres.jjucyadatlpruinptwdk:<YOUR_SUPABASE_DB_PASSWORD>@aws-0-eu-central-1.pooler.supabase.com:6543/postgres?sslmode=require
```

Migration URL for local Drizzle migration:

```env
DATABASE_MIGRATION_URL=postgresql://postgres:<YOUR_SUPABASE_DB_PASSWORD>@db.jjucyadatlpruinptwdk.supabase.co:5432/postgres?sslmode=require
```

Add a strong secret:

```env
JWT_SECRET=<GENERATE_A_LONG_RANDOM_SECRET_32_PLUS_CHARACTERS>
```

## 2. Install and verify locally

```bash
npm install
npm run typecheck
npm run build
```

## 3. Push schema to the new Supabase database

Preferred if migrations are present:

```bash
npm run db:migrate
```

If you need to generate migrations first:

```bash
npm run db:generate
npm run db:migrate
```

For a brand-new empty Supabase database, `db:push` can also be used:

```bash
npm run db:push
```

## 4. Seed base data and create production admin

```bash
npm run db:seed
npm run db:prod-admin
npm run db:check
```

`db:prod-admin` reads:

```env
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=<STRONG_ADMIN_PASSWORD_AT_LEAST_12_CHARACTERS>
```

## 5. Vercel environment variables

In Vercel, add these under Project Settings > Environment Variables:

```env
DATABASE_URL=postgresql://postgres.jjucyadatlpruinptwdk:<YOUR_SUPABASE_DB_PASSWORD>@aws-0-eu-central-1.pooler.supabase.com:6543/postgres?sslmode=require
JWT_SECRET=<GENERATE_A_LONG_RANDOM_SECRET_32_PLUS_CHARACTERS>
NEXT_PUBLIC_BASE_URL=https://<YOUR_NEW_VERCEL_PROJECT>.vercel.app
NEXT_PUBLIC_SUPABASE_URL=https://jjucyadatlpruinptwdk.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=sb_publishable_vcWrgdO6_1pB0CrmqrwcKQ_ZZv0I6Jf
NEXT_PUBLIC_SUPABASE_ANON_KEY=sb_publishable_vcWrgdO6_1pB0CrmqrwcKQ_ZZv0I6Jf
DATABASE_POOL_MAX=5
DATABASE_SSL=true
DATABASE_IDLE_TIMEOUT_MS=5000
DATABASE_CONNECTION_TIMEOUT_MS=10000
DISABLE_RUNTIME_SCHEMA_SETUP=true
EXPOSE_API_ERRORS=false
SEED_DEMO_USERS=false
```

Do not put `DATABASE_MIGRATION_URL` in Vercel unless you know exactly why. Migrations should be run locally before deployment.

## 6. Vercel build settings

Install command:

```bash
npm install --no-audit --no-fund --legacy-peer-deps --loglevel=error
```

Build command:

```bash
npm run build
```

Node.js is pinned to `20.x` in `package.json`.

## 7. Deploy

- Import the GitHub repo into a new Vercel project.
- Add the environment variables above.
- Deploy.
- Use **Redeploy > Clear Build Cache** if you already attempted a failed deployment.

## 8. Post-deployment smoke test

Test:

1. Homepage opens.
2. Login page opens.
3. Admin login works.
4. Dashboard loads.
5. Database-backed pages do not throw connection errors.
6. `NEXT_PUBLIC_BASE_URL` is updated to the final production URL.

## Security warning

You shared your database password in chat. Rotate the Supabase database password after deployment, then update `.env` and Vercel.

---

## July 2026 Vercel Node 24 / pnpm Update

If Vercel fails with:

```text
Node.js version 20.x is deprecated
npm error Exit handler never called!
No Next.js version detected
```

use the updated files in this package. The fix is:

- Node engine changed from `20.x` to `24.x`
- package manager changed from npm to pnpm
- `package-lock.json` removed
- Vercel install command changed to Corepack + pnpm
- add `ENABLE_EXPERIMENTAL_COREPACK=1` in Vercel environment variables

Vercel Root Directory must point to the folder containing `package.json`.
