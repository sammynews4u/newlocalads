-- Local Ads Network production repair v3
-- Run once in Supabase SQL Editor before redeploying the repaired app.
-- Safe/idempotent: uses IF NOT EXISTS and non-fatal DO blocks where needed.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$ BEGIN CREATE TYPE user_role AS ENUM ('admin', 'advertiser', 'publisher'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE user_status AS ENUM ('pending', 'active', 'suspended', 'banned'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE campaign_status AS ENUM ('draft', 'pending_approval', 'active', 'paused', 'budget_finished', 'rejected', 'completed'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE ad_status AS ENUM ('pending', 'approved', 'rejected', 'paused'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE conversion_type AS ENUM ('lead', 'signup', 'purchase', 'download', 'custom'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE approval_status AS ENUM ('pending', 'approved', 'rejected', 'cancelled'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE module_key AS ENUM ('ad_trust', 'performance_lab', 'geo_zones', 'targeting', 'disputes', 'approvals', 'wallet_operations', 'publisher_metrics', 'automation_rules', 'notifications'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE targeting_rule_type AS ENUM ('niche', 'country', 'device', 'browser', 'audience', 'placement', 'geo_zone'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'admin';
ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'advertiser';
ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'publisher';
ALTER TYPE user_status ADD VALUE IF NOT EXISTS 'pending';
ALTER TYPE user_status ADD VALUE IF NOT EXISTS 'active';
ALTER TYPE user_status ADD VALUE IF NOT EXISTS 'suspended';
ALTER TYPE user_status ADD VALUE IF NOT EXISTS 'banned';
ALTER TYPE campaign_status ADD VALUE IF NOT EXISTS 'draft';
ALTER TYPE campaign_status ADD VALUE IF NOT EXISTS 'pending_approval';
ALTER TYPE campaign_status ADD VALUE IF NOT EXISTS 'active';
ALTER TYPE campaign_status ADD VALUE IF NOT EXISTS 'paused';
ALTER TYPE campaign_status ADD VALUE IF NOT EXISTS 'budget_finished';
ALTER TYPE campaign_status ADD VALUE IF NOT EXISTS 'rejected';
ALTER TYPE campaign_status ADD VALUE IF NOT EXISTS 'completed';
ALTER TYPE ad_status ADD VALUE IF NOT EXISTS 'pending';
ALTER TYPE ad_status ADD VALUE IF NOT EXISTS 'approved';
ALTER TYPE ad_status ADD VALUE IF NOT EXISTS 'rejected';
ALTER TYPE ad_status ADD VALUE IF NOT EXISTS 'paused';
ALTER TYPE conversion_type ADD VALUE IF NOT EXISTS 'lead';
ALTER TYPE conversion_type ADD VALUE IF NOT EXISTS 'signup';
ALTER TYPE conversion_type ADD VALUE IF NOT EXISTS 'purchase';
ALTER TYPE conversion_type ADD VALUE IF NOT EXISTS 'download';
ALTER TYPE conversion_type ADD VALUE IF NOT EXISTS 'custom';
ALTER TYPE approval_status ADD VALUE IF NOT EXISTS 'pending';
ALTER TYPE approval_status ADD VALUE IF NOT EXISTS 'approved';
ALTER TYPE approval_status ADD VALUE IF NOT EXISTS 'rejected';
ALTER TYPE approval_status ADD VALUE IF NOT EXISTS 'cancelled';
ALTER TYPE module_key ADD VALUE IF NOT EXISTS 'approvals';
ALTER TYPE module_key ADD VALUE IF NOT EXISTS 'targeting';
ALTER TYPE targeting_rule_type ADD VALUE IF NOT EXISTS 'niche';
ALTER TYPE targeting_rule_type ADD VALUE IF NOT EXISTS 'country';

-- ---------------------------
-- USER + REFERRAL REPAIR
-- ---------------------------
ALTER TABLE users ADD COLUMN IF NOT EXISTS referral_code varchar(20);
ALTER TABLE users ADD COLUMN IF NOT EXISTS referred_by uuid REFERENCES users(id);
ALTER TABLE users ADD COLUMN IF NOT EXISTS referral_level integer DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS updated_at timestamp DEFAULT now() NOT NULL;

UPDATE users
SET referral_code = NULL
WHERE referral_code = '';

-- Backfill every existing user with a unique 10-character invite code.
DO $$
DECLARE
  rec record;
  candidate text;
BEGIN
  FOR rec IN SELECT id FROM users WHERE referral_code IS NULL LOOP
    LOOP
      candidate := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10));
      EXIT WHEN NOT EXISTS (SELECT 1 FROM users WHERE referral_code = candidate);
    END LOOP;

    UPDATE users
    SET referral_code = candidate, updated_at = now()
    WHERE id = rec.id;
  END LOOP;
END $$;

-- Repair duplicate existing referral codes before the unique index is created.
DO $$
DECLARE
  rec record;
  candidate text;
BEGIN
  FOR rec IN
    SELECT id FROM (
      SELECT id, referral_code, row_number() OVER (PARTITION BY referral_code ORDER BY created_at, id) AS rn
      FROM users
      WHERE referral_code IS NOT NULL AND referral_code <> ''
    ) duplicates
    WHERE rn > 1
  LOOP
    LOOP
      candidate := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10));
      EXIT WHEN NOT EXISTS (SELECT 1 FROM users WHERE referral_code = candidate);
    END LOOP;

    UPDATE users
    SET referral_code = candidate, updated_at = now()
    WHERE id = rec.id;
  END LOOP;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS users_referral_code_unique_idx
  ON users (referral_code)
  WHERE referral_code IS NOT NULL AND referral_code <> '';
CREATE INDEX IF NOT EXISTS users_referred_by_idx ON users (referred_by);
CREATE INDEX IF NOT EXISTS users_role_idx ON users (role);
CREATE INDEX IF NOT EXISTS users_status_idx ON users (status);
CREATE INDEX IF NOT EXISTS users_created_at_idx ON users (created_at);

CREATE TABLE IF NOT EXISTS referral_levels (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  level integer NOT NULL UNIQUE,
  commission_percent numeric(5,2) NOT NULL,
  label varchar(50),
  active boolean DEFAULT true,
  created_at timestamp DEFAULT now() NOT NULL,
  updated_at timestamp DEFAULT now() NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS referral_levels_level_idx ON referral_levels (level);

INSERT INTO referral_levels (level, commission_percent, label, active)
VALUES
  (1, 5.00, 'Direct Referral', true),
  (2, 2.50, 'Level 2', true),
  (3, 1.50, 'Level 3', true),
  (4, 1.00, 'Level 4', true),
  (5, 0.75, 'Level 5', true),
  (6, 0.50, 'Level 6', true),
  (7, 0.40, 'Level 7', true),
  (8, 0.30, 'Level 8', true),
  (9, 0.20, 'Level 9', true),
  (10, 0.10, 'Level 10', true)
ON CONFLICT (level) DO NOTHING;

CREATE TABLE IF NOT EXISTS referral_earnings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  earner_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  source_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  level integer NOT NULL,
  source_type varchar(20) NOT NULL,
  source_earning numeric(12,4) NOT NULL,
  commission_percent numeric(5,2) NOT NULL,
  commission_amount numeric(12,4) NOT NULL,
  reference_id uuid,
  created_at timestamp DEFAULT now() NOT NULL
);
CREATE INDEX IF NOT EXISTS referral_earnings_earner_idx ON referral_earnings (earner_id);
CREATE INDEX IF NOT EXISTS referral_earnings_source_idx ON referral_earnings (source_user_id);
CREATE INDEX IF NOT EXISTS referral_earnings_created_idx ON referral_earnings (created_at);
CREATE UNIQUE INDEX IF NOT EXISTS referral_earnings_dedupe_idx
  ON referral_earnings (earner_id, source_user_id, level, source_type, reference_id)
  WHERE reference_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS referral_clicks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  referral_code varchar(20) NOT NULL,
  referrer_id uuid REFERENCES users(id) ON DELETE CASCADE,
  ip_address varchar(45),
  user_agent text,
  referer text,
  created_at timestamp DEFAULT now() NOT NULL
);
CREATE INDEX IF NOT EXISTS referral_clicks_code_idx ON referral_clicks (referral_code);
CREATE INDEX IF NOT EXISTS referral_clicks_referrer_idx ON referral_clicks (referrer_id);
CREATE INDEX IF NOT EXISTS referral_clicks_created_idx ON referral_clicks (created_at);

-- ---------------------------
-- CAMPAIGN + AD REPAIR
-- ---------------------------
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS spent_budget numeric(12,2) DEFAULT 0.00;
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS today_spent numeric(12,2) DEFAULT 0.00;
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS rejection_reason text;
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS niches jsonb DEFAULT '[]'::jsonb;
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS updated_at timestamp DEFAULT now() NOT NULL;
CREATE INDEX IF NOT EXISTS campaigns_advertiser_idx ON campaigns (advertiser_id);
CREATE INDEX IF NOT EXISTS campaigns_status_idx ON campaigns (status);
CREATE INDEX IF NOT EXISTS campaigns_created_at_idx ON campaigns (created_at);

ALTER TABLE ads ADD COLUMN IF NOT EXISTS video_url text;
ALTER TABLE ads ADD COLUMN IF NOT EXISTS image_url text;
ALTER TABLE ads ADD COLUMN IF NOT EXISTS cta_text varchar(100) DEFAULT 'Learn More';
ALTER TABLE ads ADD COLUMN IF NOT EXISTS clicks integer DEFAULT 0;
ALTER TABLE ads ADD COLUMN IF NOT EXISTS conversions integer DEFAULT 0;
ALTER TABLE ads ADD COLUMN IF NOT EXISTS updated_at timestamp DEFAULT now() NOT NULL;
CREATE INDEX IF NOT EXISTS ads_campaign_idx ON ads (campaign_id);
CREATE INDEX IF NOT EXISTS ads_status_idx ON ads (status);

-- Active campaigns cannot serve if their ads are still pending. Backfill the operational state.
UPDATE ads a
SET status = 'approved', updated_at = now()
FROM campaigns c
WHERE a.campaign_id = c.id
  AND c.status = 'active'
  AND a.status = 'pending';

-- Pending campaign rows need child ad rows or there is nothing for admin to review/approve.
INSERT INTO ads (campaign_id, title, description, image_url, cta_text, status)
SELECT c.id, c.title, c.description, NULL, 'Learn More', 'pending'
FROM campaigns c
WHERE NOT EXISTS (SELECT 1 FROM ads a WHERE a.campaign_id = c.id);

-- ---------------------------
-- PIXEL + APPROVAL WORKFLOW REPAIR
-- ---------------------------
CREATE TABLE IF NOT EXISTS pixels (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id uuid NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  advertiser_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name varchar(100) NOT NULL DEFAULT 'Default Pixel',
  pixel_code text NOT NULL DEFAULT upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 12)),
  conversion_type conversion_type DEFAULT 'lead',
  conversion_value numeric(12,2),
  active boolean DEFAULT true,
  fires integer DEFAULT 0,
  created_at timestamp DEFAULT now() NOT NULL,
  updated_at timestamp DEFAULT now() NOT NULL
);
ALTER TABLE pixels ADD COLUMN IF NOT EXISTS name varchar(100) NOT NULL DEFAULT 'Default Pixel';
ALTER TABLE pixels ADD COLUMN IF NOT EXISTS pixel_code text NOT NULL DEFAULT upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 12));
ALTER TABLE pixels ADD COLUMN IF NOT EXISTS conversion_type conversion_type DEFAULT 'lead';
ALTER TABLE pixels ADD COLUMN IF NOT EXISTS conversion_value numeric(12,2);
ALTER TABLE pixels ADD COLUMN IF NOT EXISTS active boolean DEFAULT true;
ALTER TABLE pixels ADD COLUMN IF NOT EXISTS fires integer DEFAULT 0;
ALTER TABLE pixels ADD COLUMN IF NOT EXISTS created_at timestamp DEFAULT now() NOT NULL;
ALTER TABLE pixels ADD COLUMN IF NOT EXISTS updated_at timestamp DEFAULT now() NOT NULL;
CREATE INDEX IF NOT EXISTS pixels_campaign_idx ON pixels (campaign_id);
CREATE INDEX IF NOT EXISTS pixels_advertiser_idx ON pixels (advertiser_id);
CREATE INDEX IF NOT EXISTS pixels_active_idx ON pixels (active);

INSERT INTO pixels (campaign_id, advertiser_id, name, pixel_code, conversion_type, active)
SELECT c.id, c.advertiser_id, 'Default Pixel', upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 12)), 'lead', true
FROM campaigns c
WHERE NOT EXISTS (SELECT 1 FROM pixels p WHERE p.campaign_id = c.id);

CREATE TABLE IF NOT EXISTS campaign_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id uuid NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  user_id uuid REFERENCES users(id),
  action varchar(100) NOT NULL,
  old_value jsonb,
  new_value jsonb,
  ip_address varchar(45),
  created_at timestamp DEFAULT now() NOT NULL
);
CREATE INDEX IF NOT EXISTS campaign_logs_campaign_idx ON campaign_logs (campaign_id);
CREATE INDEX IF NOT EXISTS campaign_logs_created_idx ON campaign_logs (created_at);

CREATE TABLE IF NOT EXISTS module_activity_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  module_key module_key NOT NULL,
  user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  entity_type varchar(80),
  entity_id uuid,
  action varchar(120) NOT NULL,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamp DEFAULT now() NOT NULL
);
CREATE INDEX IF NOT EXISTS module_activity_logs_module_idx ON module_activity_logs (module_key);
CREATE INDEX IF NOT EXISTS module_activity_logs_user_idx ON module_activity_logs (user_id);
CREATE INDEX IF NOT EXISTS module_activity_logs_entity_idx ON module_activity_logs (entity_type, entity_id);
CREATE INDEX IF NOT EXISTS module_activity_logs_created_idx ON module_activity_logs (created_at);

CREATE TABLE IF NOT EXISTS approval_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  approval_number varchar(40) NOT NULL UNIQUE,
  module_key module_key NOT NULL DEFAULT 'approvals',
  entity_type varchar(80) NOT NULL,
  entity_id uuid,
  requested_by uuid REFERENCES users(id) ON DELETE SET NULL,
  assigned_to uuid REFERENCES users(id) ON DELETE SET NULL,
  subject varchar(255) NOT NULL,
  notes text,
  status approval_status NOT NULL DEFAULT 'pending',
  decision_reason text,
  decided_by uuid REFERENCES users(id) ON DELETE SET NULL,
  decided_at timestamp,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamp DEFAULT now() NOT NULL,
  updated_at timestamp DEFAULT now() NOT NULL
);
ALTER TABLE approval_requests ADD COLUMN IF NOT EXISTS module_key module_key NOT NULL DEFAULT 'approvals';
ALTER TABLE approval_requests ADD COLUMN IF NOT EXISTS decision_reason text;
ALTER TABLE approval_requests ADD COLUMN IF NOT EXISTS decided_by uuid REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE approval_requests ADD COLUMN IF NOT EXISTS decided_at timestamp;
ALTER TABLE approval_requests ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE approval_requests ADD COLUMN IF NOT EXISTS updated_at timestamp DEFAULT now() NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS approval_requests_number_idx ON approval_requests (approval_number);
CREATE INDEX IF NOT EXISTS approval_requests_status_idx ON approval_requests (status);
CREATE INDEX IF NOT EXISTS approval_requests_entity_idx ON approval_requests (entity_type, entity_id);
CREATE INDEX IF NOT EXISTS approval_requests_requested_by_idx ON approval_requests (requested_by);

INSERT INTO approval_requests (approval_number, module_key, entity_type, entity_id, requested_by, subject, notes, status, metadata)
SELECT
  'APR-' || to_char(now(), 'YYYYMMDD') || '-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6)),
  'approvals',
  'campaign',
  c.id,
  c.advertiser_id,
  'Campaign approval: ' || c.title,
  'Backfilled approval request for existing pending campaign.',
  'pending',
  jsonb_build_object('campaignId', c.id, 'totalBudget', c.total_budget, 'dailyBudget', c.daily_budget)
FROM campaigns c
WHERE c.status = 'pending_approval'
  AND NOT EXISTS (
    SELECT 1 FROM approval_requests ar
    WHERE ar.entity_type = 'campaign' AND ar.entity_id = c.id AND ar.status = 'pending'
  );

CREATE TABLE IF NOT EXISTS targeting_segments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid REFERENCES users(id) ON DELETE CASCADE,
  name varchar(120) NOT NULL,
  segment_type varchar(80) NOT NULL DEFAULT 'custom',
  niches jsonb DEFAULT '[]'::jsonb,
  countries jsonb DEFAULT '[]'::jsonb,
  devices jsonb DEFAULT '[]'::jsonb,
  browsers jsonb DEFAULT '[]'::jsonb,
  rules jsonb DEFAULT '{}'::jsonb,
  active boolean DEFAULT true,
  created_at timestamp DEFAULT now() NOT NULL,
  updated_at timestamp DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS campaign_targeting_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id uuid NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  segment_id uuid REFERENCES targeting_segments(id) ON DELETE SET NULL,
  rule_type targeting_rule_type NOT NULL,
  "include" boolean DEFAULT true,
  weight integer DEFAULT 100,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamp DEFAULT now() NOT NULL,
  updated_at timestamp DEFAULT now() NOT NULL
);
CREATE INDEX IF NOT EXISTS campaign_targeting_rules_campaign_idx ON campaign_targeting_rules (campaign_id);
CREATE INDEX IF NOT EXISTS campaign_targeting_rules_segment_idx ON campaign_targeting_rules (segment_id);
CREATE INDEX IF NOT EXISTS campaign_targeting_rules_type_idx ON campaign_targeting_rules (rule_type);

-- Final smoke-check queries. These return counts so you can quickly verify the repair.
SELECT 'users_without_referral_code' AS check_name, COUNT(*) AS count FROM users WHERE referral_code IS NULL OR referral_code = '';
SELECT 'pending_campaigns_visible_to_admin' AS check_name, COUNT(*) AS count FROM campaigns WHERE status = 'pending_approval';
SELECT 'active_campaign_ads_still_pending' AS check_name, COUNT(*) AS count
FROM ads a JOIN campaigns c ON c.id = a.campaign_id
WHERE c.status = 'active' AND a.status = 'pending';
SELECT 'campaigns_without_pixels' AS check_name, COUNT(*) AS count
FROM campaigns c WHERE NOT EXISTS (SELECT 1 FROM pixels p WHERE p.campaign_id = c.id);
