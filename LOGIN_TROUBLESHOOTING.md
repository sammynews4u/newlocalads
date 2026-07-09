# Registration & Login Troubleshooting Guide

## Current Issue
**Login is failing** because the database connection cannot be established on Vercel. The authentication code is correct, but requests to the database are timing out or being rejected.

## Root Causes (In Order of Likelihood)

### 1. **DATABASE_URL Not Set or Incorrect** (Most Common)
The `DATABASE_URL` environment variable is missing or pointing to the wrong connection string.

**Fix:**
```bash
# In Vercel Dashboard:
# 1. Go to Settings → Environment Variables
# 2. Add/verify DATABASE_URL with your Supabase pooler URL:
postgresql://postgres.<PROJECT_REF>.pooler.supabase.com:6543/postgres?sslmode=require

# Password must be URL-encoded if it contains special characters
```

### 2. **JWT_SECRET Not Set**
Missing or inconsistent JWT secret causes token creation/verification to fail.

**Fix:**
```bash
# In Vercel Dashboard → Environment Variables:
JWT_SECRET=<generate-a-long-random-string-32+-chars>

# Generate one:
# Option 1: openssl rand -base64 32
# Option 2: node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

### 3. **Database Schema Not Pushed**
Drizzle migrations haven't been run on your Supabase database.

**Fix (One-time Setup):**
```bash
# Locally with your .env.local:
npm run db:push

# Or on Vercel (after setting DATABASE_URL):
# 1. Install Vercel CLI: npm i -g vercel
# 2. Link your project: vercel link
# 3. Pull environment: vercel env pull .env.local
# 4. Run migrations: npm run db:push
```

### 4. **Supabase Connection Pooler Issues**
- Using the wrong connection port (should be 6543 for Vercel, 5432 for local)
- IP whitelisting blocking Vercel's IPs
- Connection pool exhausted

**Fix:**
```bash
# Verify in Supabase Dashboard → Database → Connection String:
# - Use "Transaction Pooler" (port 6543) for Vercel/serverless
# - Use "Direct Connection" (port 5432) for local development

# In Supabase Dashboard → Database → Logs:
# Check for connection errors
```

### 5. **SEED_DEMO_USERS Not Enabled**
Demo users are only created when `SEED_DEMO_USERS=true`

**Fix:**
```bash
# In Vercel Dashboard → Environment Variables:
SEED_DEMO_USERS=true

# Then run the seed script:
npm run db:seed

# Or for production admin:
npm run db:prod-admin
```

## Step-by-Step Diagnostic

### Step 1: Check Environment Variables on Vercel
```bash
# In Vercel Dashboard:
Settings → Environment Variables
```

Verify these are set:
- ✅ `DATABASE_URL` (with correct Supabase pooler URL)
- ✅ `JWT_SECRET` (32+ characters)
- ✅ `NEXT_PUBLIC_BASE_URL` (https://your-domain.vercel.app)
- ✅ `SEED_DEMO_USERS=true` (if you want demo users)

### Step 2: Check Supabase Connection
```bash
# Get your Supabase credentials:
# 1. Supabase Dashboard → Project Settings → Database
# 2. Copy the "Transaction Pooler" connection string (port 6543)
# 3. Verify it includes: ?sslmode=require
```

Example format:
```
postgresql://postgres.YOUR_REF.pooler.supabase.com:6543/postgres?sslmode=require
```

### Step 3: Run Database Migrations
```bash
# After setting DATABASE_URL and DATABASE_MIGRATION_URL:
npm run db:push

# Verify tables were created:
npm run db:check
```

### Step 4: Seed Demo Users
```bash
# Option 1: Create demo users (development/staging)
SEED_DEMO_USERS=true npm run db:seed

# Option 2: Create production admin (production)
ADMIN_EMAIL=admin@yourdomain.com \
ADMIN_PASSWORD=<strong-password-12+-chars> \
ADMIN_FIRST_NAME=Admin \
ADMIN_LAST_NAME=User \
npm run db:prod-admin
```

## Demo Credentials

After seeding with `SEED_DEMO_USERS=true`:

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@localadnetwork.com | admin123 |
| Advertiser | advertiser@example.com | advertiser123 |
| Publisher | publisher@example.com | publisher123 |

## Testing Login Locally

```bash
# 1. Create .env.local with your Supabase credentials:
DATABASE_URL=postgresql://postgres:PASSWORD@db.PROJECT_REF.supabase.co:5432/postgres?sslmode=require
JWT_SECRET=your-secret-here
NEXT_PUBLIC_BASE_URL=http://localhost:3000
SEED_DEMO_USERS=true

# 2. Push database schema:
npm run db:push

# 3. Seed demo users:
npm run db:seed

# 4. Start dev server:
npm run dev

# 5. Test login at http://localhost:3000/login
# Use: admin@localadnetwork.com / admin123
```

## Vercel Deployment Checklist

- [ ] `DATABASE_URL` set to Supabase Transaction Pooler (port 6543)
- [ ] `DATABASE_MIGRATION_URL` set to Direct Connection (port 5432) - optional but recommended
- [ ] `JWT_SECRET` set to a long random string (32+ characters)
- [ ] `NEXT_PUBLIC_BASE_URL` set to your Vercel domain
- [ ] Database schema pushed: `npm run db:push`
- [ ] Demo users created: `npm run db:seed` OR production admin: `npm run db:prod-admin`
- [ ] Vercel redeployed after setting env vars
- [ ] Check Vercel Function logs for errors

## Common Error Messages

**"Invalid email or password"**
- User doesn't exist → Run `npm run db:seed` to create demo users
- Password hash mismatch → Verify bcryptjs version matches (^3.0.3)

**"Login failed" (500 error)**
- Database connection error → Check DATABASE_URL
- JWT token error → Check JWT_SECRET is set
- Check Vercel Function logs for exact error

**"Connection timeout"**
- Supabase is down or unreachable
- DATABASE_URL is incorrect
- Network/firewall blocking connection
- Connection pool exhausted → Increase DATABASE_POOL_MAX

## Need Help?

1. Check Vercel Function Logs: Vercel Dashboard → Deployments → Function Logs
2. Check Supabase Logs: Supabase Dashboard → Database → Logs
3. Test DB connection locally first before pushing to Vercel
4. Verify all environment variables are set (not inheriting defaults)
