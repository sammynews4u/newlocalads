# Vercel + Supabase Deployment Guide

This project has been prepared for a fresh Vercel deployment using the Supabase project:

- Supabase project ref: `jjucyadatlpruinptwdk`
- Database host: `db.jjucyadatlpruinptwdk.supabase.co`
- Port: `5432`
- Database: `postgres`

## Critical database rule

Do **not** use the direct `db.jjucyadatlpruinptwdk.supabase.co:5432` URL as the Vercel runtime database URL unless your Supabase project has the IPv4 add-on enabled.

For Vercel runtime, use this instead:

```env
DATABASE_URL=postgresql://postgres.jjucyadatlpruinptwdk:<YOUR_SUPABASE_DB_PASSWORD>@aws-0-eu-central-1.pooler.supabase.com:6543/postgres?sslmode=require
```

Get the exact value from:

`Supabase Dashboard > Project > Connect > ORMs/Connection string > Transaction pooler`

The direct URL is still useful for local migrations:

```env
DATABASE_MIGRATION_URL=postgresql://postgres:<YOUR_SUPABASE_DB_PASSWORD>@db.jjucyadatlpruinptwdk.supabase.co:5432/postgres?sslmode=require
```

## Required Vercel environment variables

Add these in:

`Vercel > New Project > Import Git Repository > Settings > Environment Variables`

```env
DATABASE_URL=postgresql://postgres.jjucyadatlpruinptwdk:<YOUR_SUPABASE_DB_PASSWORD>@aws-0-eu-central-1.pooler.supabase.com:6543/postgres?sslmode=require
JWT_SECRET=<GENERATE_A_32_PLUS_CHARACTER_RANDOM_SECRET>
NEXT_PUBLIC_BASE_URL=https://<YOUR_NEW_VERCEL_PROJECT>.vercel.app
NEXT_PUBLIC_SUPABASE_URL=https://jjucyadatlpruinptwdk.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=sb_publishable_vcWrgdO6_1pB0CrmqrwcKQ_ZZv0I6Jf
NEXT_PUBLIC_SUPABASE_ANON_KEY=sb_publishable_vcWrgdO6_1pB0CrmqrwcKQ_ZZv0I6Jf
SUPABASE_SERVICE_ROLE_KEY=<YOUR_SUPABASE_SERVICE_ROLE_KEY_DO_NOT_EXPOSE>
DATABASE_POOL_MAX=5
DATABASE_SSL=true
DATABASE_IDLE_TIMEOUT_MS=5000
DATABASE_CONNECTION_TIMEOUT_MS=10000
DISABLE_RUNTIME_SCHEMA_SETUP=true
EXPOSE_API_ERRORS=false
SEED_DEMO_USERS=false
MAX_CAMPAIGN_IMAGE_SIZE_MB=5
CLOUDINARY_UPLOAD_FOLDER=local-ads/campaign-images
```

Do not add `DATABASE_MIGRATION_URL` to Vercel for normal runtime deployment. Run migrations locally before deployment.

Cloudinary is optional, but image upload routes need these if you want campaign image uploads:

```env
CLOUDINARY_CLOUD_NAME=<YOUR_CLOUDINARY_CLOUD_NAME>
CLOUDINARY_API_KEY=<YOUR_CLOUDINARY_API_KEY>
CLOUDINARY_API_SECRET=<YOUR_CLOUDINARY_API_SECRET>
```

## Local setup before pushing to Vercel

1. Install dependencies:

```bash
npm install --no-audit --no-fund --legacy-peer-deps --loglevel=error
```

2. Create `.env.local` from `.env.example` and add the real values.

3. Test the database connection:

```bash
npm run db:check
```

4. Push the schema to the new Supabase database:

```bash
npm run db:migrate
```

For a completely empty database, `npm run db:push` is also available if migration metadata is not yet prepared.

5. Optional: seed base data:

```bash
npm run db:seed
```

6. Optional: create production admin user:

```bash
npm run db:prod-admin
```

7. Check TypeScript:

```bash
npm run typecheck
```

8. Build locally:

```bash
npm run build
```

## Vercel project settings

- Framework preset: `Next.js`
- Install command: `npm install --no-audit --no-fund --legacy-peer-deps --loglevel=error`
- Build command: `npm run build`
- Output directory: leave default / auto-detected
- Node version: `20.x`

`vercel.json` has already been added with the build/install commands and API function duration settings.

## What was changed

- Added Vercel-aware PostgreSQL pooling using `@vercel/functions`.
- Added Supabase SSL handling for direct and pooler connection strings.
- Added `db:check` script to test Supabase connectivity before deployment.
- Updated Drizzle config to prefer `DATABASE_MIGRATION_URL` / `DATABASE_DIRECT_URL` for migrations.
- Added `.env.vercel.example` with the exact variable names needed in Vercel.
- Added `vercel.json` for predictable Vercel builds.

## Security warning

The database password was shared in the chat. Rotate the Supabase database password after deployment, then update the new password in Vercel environment variables. Do not commit `.env.local` or any real secret to GitHub.
