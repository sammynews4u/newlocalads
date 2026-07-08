-- Local Ads Network production repair v4 - STEP 2 OF 2
-- Run after STEP 1 has completed successfully.
-- Repairs campaign creation, Cloudinary-only image fields, referrals for every user,
-- referral admin settings, tracking clicks, commissions, pixels and approval workflow.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ---------------------------
-- USER + REFERRAL REPAIR
-- ---------------------------
ALTER TABLE users ADD COLUMN IF NOT EXISTS referral_code varchar(20);
ALTER TABLE users ADD COLUMN IF NOT EXISTS referred_by uuid REFERENCES users(id);
ALTER TABLE users ADD COLUMN IF NOT EXISTS referral_level integer DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS updated_at timestamp DEFAULT now() NOT NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS created_at timestamp DEFAULT now() NOT NULL;

UPDATE users SET referral_code = NULL WHERE referral_code = '';

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
    UPDATE users SET referral_code = candidate, updated_at = now() WHERE id = rec.id;
  END LOOP;
END $$;

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
    UPDATE users SET referral_code = candidate, updated_at = now() WHERE id = rec.id;
  END LOOP;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS users_referral_code_unique_idx ON users (referral_code) WHERE referral_code IS NOT NULL AND referral_code <> '';
CREATE INDEX IF NOT EXISTS users_referral_code_idx ON users (referral_code);
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

CREATE TABLE IF NOT EXISTS referral_program_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  enabled boolean DEFAULT true NOT NULL,
  min_commissionable_amount numeric(12,4) DEFAULT 0.0000 NOT NULL,
  max_levels integer DEFAULT 10 NOT NULL,
  cookie_days integer DEFAULT 30 NOT NULL,
  commission_source varchar(50) DEFAULT 'publisher_earnings' NOT NULL,
  updated_by uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at timestamp DEFAULT now() NOT NULL,
  updated_at timestamp DEFAULT now() NOT NULL
);
ALTER TABLE referral_program_settings ADD COLUMN IF NOT EXISTS enabled boolean DEFAULT true NOT NULL;
ALTER TABLE referral_program_settings ADD COLUMN IF NOT EXISTS min_commissionable_amount numeric(12,4) DEFAULT 0.0000 NOT NULL;
ALTER TABLE referral_program_settings ADD COLUMN IF NOT EXISTS max_levels integer DEFAULT 10 NOT NULL;
ALTER TABLE referral_program_settings ADD COLUMN IF NOT EXISTS cookie_days integer DEFAULT 30 NOT NULL;
ALTER TABLE referral_program_settings ADD COLUMN IF NOT EXISTS commission_source varchar(50) DEFAULT 'publisher_earnings' NOT NULL;
ALTER TABLE referral_program_settings ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE referral_program_settings ADD COLUMN IF NOT EXISTS created_at timestamp DEFAULT now() NOT NULL;
ALTER TABLE referral_program_settings ADD COLUMN IF NOT EXISTS updated_at timestamp DEFAULT now() NOT NULL;
CREATE INDEX IF NOT EXISTS referral_program_settings_enabled_idx ON referral_program_settings (enabled);

INSERT INTO referral_program_settings (enabled, min_commissionable_amount, max_levels, cookie_days, commission_source)
SELECT true, 0.0000, 10, 30, 'publisher_earnings'
WHERE NOT EXISTS (SELECT 1 FROM referral_program_settings);

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
CREATE UNIQUE INDEX IF NOT EXISTS referral_earnings_dedupe_idx ON referral_earnings (earner_id, source_user_id, level, source_type, reference_id) WHERE reference_id IS NOT NULL;

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
-- CAMPAIGN + AD CORE REPAIR
-- ---------------------------
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS spent_budget numeric(12,2) DEFAULT 0.00;
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS today_spent numeric(12,2) DEFAULT 0.00;
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS rejection_reason text;
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS niches jsonb DEFAULT '[]'::jsonb;
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS updated_at timestamp DEFAULT now() NOT NULL;
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS created_at timestamp DEFAULT now() NOT NULL;
CREATE INDEX IF NOT EXISTS campaigns_advertiser_idx ON campaigns (advertiser_id);
CREATE INDEX IF NOT EXISTS campaigns_status_idx ON campaigns (status);
CREATE INDEX IF NOT EXISTS campaigns_created_at_idx ON campaigns (created_at);

ALTER TABLE ads ADD COLUMN IF NOT EXISTS video_url text;
ALTER TABLE ads ADD COLUMN IF NOT EXISTS image_url text;
ALTER TABLE ads ADD COLUMN IF NOT EXISTS cta_text varchar(100) DEFAULT 'Learn More';
ALTER TABLE ads ADD COLUMN IF NOT EXISTS clicks integer DEFAULT 0;
ALTER TABLE ads ADD COLUMN IF NOT EXISTS conversions integer DEFAULT 0;
ALTER TABLE ads ADD COLUMN IF NOT EXISTS updated_at timestamp DEFAULT now() NOT NULL;
ALTER TABLE ads ADD COLUMN IF NOT EXISTS created_at timestamp DEFAULT now() NOT NULL;
CREATE INDEX IF NOT EXISTS ads_campaign_idx ON ads (campaign_id);
CREATE INDEX IF NOT EXISTS ads_status_idx ON ads (status);

CREATE TABLE IF NOT EXISTS ad_targeting (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id uuid NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  country varchar(100) NOT NULL,
  cpc numeric(10,4) NOT NULL,
  active boolean DEFAULT true,
  created_at timestamp DEFAULT now() NOT NULL
);
CREATE INDEX IF NOT EXISTS ad_targeting_campaign_idx ON ad_targeting (campaign_id);
CREATE UNIQUE INDEX IF NOT EXISTS ad_targeting_campaign_country_idx ON ad_targeting (campaign_id, country);

UPDATE ads a
SET status = 'approved', updated_at = now()
FROM campaigns c
WHERE a.campaign_id = c.id AND c.status = 'active' AND a.status = 'pending';

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

INSERT INTO approval_requests (approval_number, module_key, entity_type, entity_id, requested_by, subject, notes, status, metadata)
SELECT
  'APR-' || to_char(now(), 'YYYYMMDD') || '-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6)),
  'approvals', 'campaign', c.id, c.advertiser_id,
  'Campaign approval: ' || c.title,
  'Backfilled approval request for existing pending campaign.',
  'pending',
  jsonb_build_object('campaignId', c.id, 'totalBudget', c.total_budget, 'dailyBudget', c.daily_budget)
FROM campaigns c
WHERE c.status = 'pending_approval'
  AND NOT EXISTS (SELECT 1 FROM approval_requests ar WHERE ar.entity_type = 'campaign' AND ar.entity_id = c.id);

-- ---------------------------
-- HEALTH CHECKS
-- ---------------------------
SELECT 'users_without_referral_code' AS check_name, count(*)::text AS value FROM users WHERE referral_code IS NULL OR referral_code = ''
UNION ALL
SELECT 'duplicate_referral_codes', count(*)::text FROM (
  SELECT referral_code FROM users WHERE referral_code IS NOT NULL AND referral_code <> '' GROUP BY referral_code HAVING count(*) > 1
) d
UNION ALL
SELECT 'referral_settings_rows', count(*)::text FROM referral_program_settings
UNION ALL
SELECT 'campaigns_missing_ads', count(*)::text FROM campaigns c WHERE NOT EXISTS (SELECT 1 FROM ads a WHERE a.campaign_id = c.id)
UNION ALL
SELECT 'campaigns_missing_pixels', count(*)::text FROM campaigns c WHERE NOT EXISTS (SELECT 1 FROM pixels p WHERE p.campaign_id = c.id);
