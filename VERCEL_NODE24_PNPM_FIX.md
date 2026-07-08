# Vercel Node 24 + pnpm Install Fix

## Why the last deployment failed

The Vercel log showed three important problems:

1. `engines.node` was pinned to `20.x`, but Vercel now warns that Node 20 is deprecated for future deployments.
2. Vercel ran `npm install`, then npm failed with `Exit handler never called!`. That is an npm install/runtime failure before the Next.js build stage.
3. Vercel then said it could not detect Next.js because dependency installation failed before the `next` package was available.

## What changed

- `package.json` now uses:

```json
"engines": {
  "node": "24.x"
}
```

- The project now uses pnpm for Vercel installation instead of npm:

```json
"packageManager": "pnpm@10.24.0"
```

- `package-lock.json` was removed so Vercel does not keep treating the project as an npm install.

- `vercel.json` now uses:

```json
"installCommand": "corepack enable && corepack prepare pnpm@10.24.0 --activate && pnpm install --no-frozen-lockfile --prefer-offline=false",
"buildCommand": "pnpm run build"
```

## Required Vercel settings

In Vercel, check:

`Project Settings → General → Build & Development Settings`

Use:

```bash
Install Command:
corepack enable && corepack prepare pnpm@10.24.0 --activate && pnpm install --no-frozen-lockfile --prefer-offline=false
```

```bash
Build Command:
pnpm run build
```

Root Directory must be blank or set to the exact folder that contains `package.json`.

If Vercel still says `No Next.js version detected`, the Root Directory is wrong or the GitHub commit does not contain `package.json` at the selected root.

## Required Vercel environment variable for pnpm/Corepack

Add this in Vercel environment variables:

```env
ENABLE_EXPERIMENTAL_COREPACK=1
```

## Required Supabase/Vercel runtime variables

```env
DATABASE_URL=postgresql://postgres.jjucyadatlpruinptwdk:<YOUR_SUPABASE_DB_PASSWORD>@aws-0-eu-central-1.pooler.supabase.com:6543/postgres?sslmode=require
NEXT_PUBLIC_SUPABASE_URL=https://jjucyadatlpruinptwdk.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=sb_publishable_vcWrgdO6_1pB0CrmqrwcKQ_ZZv0I6Jf
NEXT_PUBLIC_SUPABASE_ANON_KEY=sb_publishable_vcWrgdO6_1pB0CrmqrwcKQ_ZZv0I6Jf
JWT_SECRET=<LONG_RANDOM_SECRET>
AUTH_SECRET=<SAME_LONG_RANDOM_SECRET_OR_ANOTHER_LONG_RANDOM_SECRET>
NEXT_PUBLIC_BASE_URL=https://your-new-vercel-domain.vercel.app
NODE_ENV=production
ENABLE_EXPERIMENTAL_COREPACK=1
```

Do not put `DATABASE_MIGRATION_URL` in Vercel unless a server script explicitly needs it. Use it locally for migrations.

## Deployment steps

1. Replace your project files with this package.
2. Commit and push to GitHub.
3. In Vercel, verify Root Directory is correct.
4. Add the environment variables above.
5. Redeploy with **Clear Build Cache**.

## The key trap

Do not keep a Vercel dashboard override that still says `npm install` or `npm ci`. If the build log still shows npm as the installer, you did not apply this fix.
