# Local Ads Network — New Supabase Database Setup

This project uses the `users` table in PostgreSQL for login. It does **not** authenticate existing users through Supabase Auth. When you change to a new Supabase database, login will fail until the schema exists and at least one admin user has been created in the new database.

## 1. Set local environment variables

Create a local `.env` file from `.env.example` and set `DATABASE_URL` to your new Supabase PostgreSQL connection string. Keep `sslmode=require` at the end of the URL.

Do not commit `.env`.

## 2. Push the Drizzle schema into the new Supabase database

Run:

```bash
npm ci
npm run db:push
```

This creates the base tables that the v5 repair SQL assumes already exist, including `users`, `wallets`, `campaigns`, `ads`, `clicks`, `transactions`, publisher tables and dashboard module tables.

## 3. Run the v5 repair SQL

After `db:push`, run these in Supabase SQL Editor, in order:

1. `SUPABASE_PRODUCTION_REPAIR_V5_STEP1_ENUMS.sql`
2. `SUPABASE_PRODUCTION_REPAIR_V5_STEP2_SCHEMA_DATA.sql`

## 4. Create or reset the production admin login

Set these locally, using your own secure values:

```bash
export ADMIN_EMAIL="your-admin-email@example.com"
export ADMIN_PASSWORD="use-a-secure-password-at-least-12-characters"
```

Then run:

```bash
npm run db:prod-admin
```

This creates the admin user if it does not exist. If it already exists, it resets that user's password, activates the user, assigns the admin role, ensures a wallet exists, and ensures the user has a referral code.

## 5. Set Vercel environment variables

Set these in Vercel Project Settings → Environment Variables:

```env
DATABASE_URL=postgresql://postgres:<PASSWORD>@db.<PROJECT_REF>.supabase.co:5432/postgres?sslmode=require
JWT_SECRET=<random-strong-secret-at-least-32-characters>
NEXT_PUBLIC_BASE_URL=https://your-production-domain.com

CLOUDINARY_CLOUD_NAME=<cloud-name>
CLOUDINARY_API_KEY=<api-key>
CLOUDINARY_API_SECRET=<api-secret>
CLOUDINARY_UPLOAD_FOLDER=local-ads/campaign-images
MAX_CAMPAIGN_IMAGE_SIZE_MB=5

DATABASE_POOL_MAX=5
DISABLE_RUNTIME_SCHEMA_SETUP=false
EXPOSE_API_ERRORS=false
```

Only set Supabase anon/service-role keys if you later add Supabase client features. This v5 backend uses `DATABASE_URL`, not Supabase Auth. Never expose the service-role key in any `NEXT_PUBLIC_` variable.

## 6. Redeploy

After setting the environment variables, redeploy from Vercel and clear build cache once.

If login still fails after this, check these in order:

1. `DATABASE_URL` in Vercel points to the same database where you ran `db:push`.
2. `users` table contains the admin email you are trying to use.
3. `status` is `active` for that user.
4. `JWT_SECRET` exists in Vercel.
5. You redeployed after changing environment variables.
