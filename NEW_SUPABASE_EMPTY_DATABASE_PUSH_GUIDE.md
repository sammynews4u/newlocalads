# Local Ads Network: push v5 to a fresh Supabase database

Your new Supabase database is empty, so login will fail until the schema and at least one admin user exist. This project uses its own `users` table, not Supabase Auth.

## Recommended local push path

1. Create `.env` in the project root:

```env
DATABASE_URL=postgresql://postgres:<YOUR_PASSWORD>@db.<YOUR_PROJECT_REF>.supabase.co:5432/postgres?sslmode=require
JWT_SECRET=<LONG_RANDOM_SECRET_AT_LEAST_32_CHARS>
NEXT_PUBLIC_BASE_URL=https://your-vercel-domain.vercel.app

CLOUDINARY_CLOUD_NAME=<YOUR_CLOUDINARY_CLOUD_NAME>
CLOUDINARY_API_KEY=<YOUR_CLOUDINARY_API_KEY>
CLOUDINARY_API_SECRET=<YOUR_ROTATED_CLOUDINARY_API_SECRET>
CLOUDINARY_UPLOAD_FOLDER=local-ads/campaign-images
MAX_CAMPAIGN_IMAGE_SIZE_MB=5

DATABASE_POOL_MAX=5
DISABLE_RUNTIME_SCHEMA_SETUP=false
EXPOSE_API_ERRORS=false
SEED_DEMO_USERS=false

ADMIN_EMAIL=<YOUR_ADMIN_EMAIL>
ADMIN_PASSWORD=<YOUR_STRONG_ADMIN_PASSWORD_AT_LEAST_12_CHARS>
ADMIN_FIRST_NAME=Admin
ADMIN_LAST_NAME=User
```

2. Install dependencies:

```bash
npm ci
```

3. Push the complete Drizzle schema to the empty Supabase database:

```bash
npm run db:push
```

4. Seed production base data only, no demo users:

```bash
npm run db:seed
```

5. Create/reset your production admin account:

```bash
npm run db:prod-admin
```

Or run everything together:

```bash
npm run db:init-new-supabase
```

## Manual SQL Editor path

Use this path only if your local terminal cannot reach Supabase.

Run these files in Supabase SQL Editor in this exact order:

1. `NEW_SUPABASE_FULL_SCHEMA_FROM_DRIZZLE.sql`
2. `SUPABASE_PRODUCTION_REPAIR_V5_STEP1_ENUMS.sql`
3. `SUPABASE_PRODUCTION_REPAIR_V5_STEP2_SCHEMA_DATA.sql`
4. `NEW_SUPABASE_BASE_SEED.sql`

Then still create the admin user locally with:

```bash
npm run db:prod-admin
```

If your local machine cannot connect to Supabase, create the admin row through a temporary secure script on a machine that can connect. Do not create a plaintext password manually; the app requires `users.password_hash` generated with bcrypt.

## Vercel setup

Set the same production values in Vercel Environment Variables. Do not put database passwords or service role keys in `NEXT_PUBLIC_*` variables.

After saving env variables, redeploy with the Vercel build cache cleared.
