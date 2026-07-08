# Vercel Install Failure Fix

## Error seen on Vercel

```text
npm error Exit handler never called!
Error: Command "npm ci" exited with 1
```

## What it means

This failure happens before the project build starts. It is not a Supabase connection error, not a Drizzle schema error, and not a Next.js TypeScript error. Vercel failed while installing dependencies.

## Fix applied

### 1. Pinned Node.js for Vercel

`package.json` now uses:

```json
"engines": {
  "node": "20.x"
}
```

The previous value `>=20.11.0` allowed Vercel to automatically move to a newer major Node.js version. That can also change the bundled npm runtime.

### 2. Replaced fragile `npm ci` on Vercel

`vercel.json` now uses:

```json
"installCommand": "npm install --no-audit --no-fund --legacy-peer-deps --loglevel=error"
```

This avoids the npm internal crash path triggered by `npm ci` on the Vercel build machine.

### 3. Added `.npmrc`

The project now includes:

```ini
audit=false
fund=false
legacy-peer-deps=true
engine-strict=false
update-notifier=false
fetch-retries=5
fetch-retry-mintimeout=20000
fetch-retry-maxtimeout=120000
```

This makes Vercel dependency installation less fragile.

## What to do on Vercel

1. Push this updated project to GitHub.
2. In Vercel, go to the project settings.
3. Go to **Settings → Build & Development Settings**.
4. Make sure Install Command is not manually overridden to `npm ci` in the dashboard.
5. If it is overridden, clear it or set it to:

```bash
npm install --no-audit --no-fund --legacy-peer-deps --loglevel=error
```

6. Redeploy with **Clear Build Cache** enabled.

## If the old error still appears

If the log still says:

```text
Running "install" command: `npm ci`
```

then Vercel is still using an old dashboard override or an old Git commit. The fixed build must show:

```text
Running "install" command: `npm install --no-audit --no-fund --legacy-peer-deps --loglevel=error`
```
