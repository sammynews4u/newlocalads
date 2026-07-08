# Local Ads Network v5 — Database Switch + Login Cleanup Report

## What changed

1. Removed public demo credentials from `src/app/login/page.tsx`.
2. Added `src/scripts/create-production-admin.ts` so a real admin account can be created or reset in the new Supabase database.
3. Added package scripts:
   - `npm run db:prod-admin`
   - `npm run db:setup-production`
4. Updated `.env.example` with the production admin bootstrap variables and Supabase/Vercel runtime variables.
5. Changed `src/scripts/seed.ts` so demo users are skipped unless `SEED_DEMO_USERS=true`.
6. Added `NEW_SUPABASE_DATABASE_SETUP.md` with the correct setup order for a fresh Supabase database.

## Why login failed after switching Supabase

The project does not use Supabase Auth for login. It checks the PostgreSQL `users` table directly through `/api/auth/login`. A new Supabase database has no existing users until the schema is pushed and an admin account is created.

Changing only `DATABASE_URL` is not enough.

## Correct setup order

1. Set `DATABASE_URL` locally with `sslmode=require`.
2. Run `npm ci`.
3. Run `npm run db:push`.
4. Run the v5 SQL repair files:
   - `SUPABASE_PRODUCTION_REPAIR_V5_STEP1_ENUMS.sql`
   - `SUPABASE_PRODUCTION_REPAIR_V5_STEP2_SCHEMA_DATA.sql`
5. Set `ADMIN_EMAIL` and `ADMIN_PASSWORD` locally.
6. Run `npm run db:prod-admin`.
7. Set the same `DATABASE_URL`, `JWT_SECRET`, Cloudinary variables, and runtime variables in Vercel.
8. Redeploy Vercel.

## Security note

The database password, anon key and service-role key were pasted into chat. Rotate them before final production use. Never commit `.env`, database URLs, or service-role keys into GitHub.
