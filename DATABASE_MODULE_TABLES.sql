-- Local Ads module database update
-- Run this in Supabase SQL Editor only if you are not using `npm run db:push`.
-- Drizzle users should prefer: npm run db:push

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$ BEGIN CREATE TYPE module_key AS ENUM ('ad_trust', 'performance_lab', 'geo_zones', 'targeting', 'disputes', 'approvals', 'wallet_operations', 'publisher_metrics', 'automation_rules', 'notifications'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE module_status AS ENUM ('active', 'inactive', 'maintenance'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE approval_status AS ENUM ('pending', 'approved', 'rejected', 'cancelled'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE trust_signal_severity AS ENUM ('low', 'medium', 'high', 'critical'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE trust_signal_status AS ENUM ('open', 'reviewing', 'cleared', 'actioned', 'dismissed'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE targeting_rule_type AS ENUM ('niche', 'country', 'device', 'browser', 'audience', 'placement', 'geo_zone'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS module_feature_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  module_key module_key NOT NULL UNIQUE,
  label varchar(100) NOT NULL,
  description text,
  allowed_roles jsonb DEFAULT '[]'::jsonb,
  status module_status NOT NULL DEFAULT 'active',
  display_order integer DEFAULT 0,
  config jsonb DEFAULT '{}'::jsonb,
  created_at timestamp DEFAULT now() NOT NULL,
  updated_at timestamp DEFAULT now() NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS module_feature_settings_key_idx ON module_feature_settings (module_key);
CREATE INDEX IF NOT EXISTS module_feature_settings_status_idx ON module_feature_settings (status);

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
CREATE UNIQUE INDEX IF NOT EXISTS approval_requests_number_idx ON approval_requests (approval_number);
CREATE INDEX IF NOT EXISTS approval_requests_status_idx ON approval_requests (status);
CREATE INDEX IF NOT EXISTS approval_requests_entity_idx ON approval_requests (entity_type, entity_id);
CREATE INDEX IF NOT EXISTS approval_requests_requested_by_idx ON approval_requests (requested_by);

CREATE TABLE IF NOT EXISTS dispute_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  dispute_id uuid NOT NULL REFERENCES disputes(id) ON DELETE CASCADE,
  sender_id uuid REFERENCES users(id) ON DELETE SET NULL,
  message text NOT NULL,
  attachments jsonb DEFAULT '[]'::jsonb,
  internal_note boolean DEFAULT false,
  created_at timestamp DEFAULT now() NOT NULL
);
CREATE INDEX IF NOT EXISTS dispute_messages_dispute_idx ON dispute_messages (dispute_id);
CREATE INDEX IF NOT EXISTS dispute_messages_sender_idx ON dispute_messages (sender_id);
CREATE INDEX IF NOT EXISTS dispute_messages_created_idx ON dispute_messages (created_at);

CREATE TABLE IF NOT EXISTS ad_trust_signals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  campaign_id uuid REFERENCES campaigns(id) ON DELETE CASCADE,
  ad_id uuid REFERENCES ads(id) ON DELETE CASCADE,
  click_id uuid REFERENCES clicks(id) ON DELETE SET NULL,
  signal_type varchar(100) NOT NULL,
  severity trust_signal_severity NOT NULL DEFAULT 'medium',
  status trust_signal_status NOT NULL DEFAULT 'open',
  score integer DEFAULT 0,
  evidence jsonb DEFAULT '{}'::jsonb,
  reviewed_by uuid REFERENCES users(id) ON DELETE SET NULL,
  reviewed_at timestamp,
  created_at timestamp DEFAULT now() NOT NULL,
  updated_at timestamp DEFAULT now() NOT NULL
);
CREATE INDEX IF NOT EXISTS ad_trust_signals_user_idx ON ad_trust_signals (user_id);
CREATE INDEX IF NOT EXISTS ad_trust_signals_campaign_idx ON ad_trust_signals (campaign_id);
CREATE INDEX IF NOT EXISTS ad_trust_signals_status_idx ON ad_trust_signals (status);
CREATE INDEX IF NOT EXISTS ad_trust_signals_severity_idx ON ad_trust_signals (severity);

CREATE TABLE IF NOT EXISTS performance_snapshots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id uuid REFERENCES campaigns(id) ON DELETE CASCADE,
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  period_start timestamp NOT NULL,
  period_end timestamp NOT NULL,
  impressions integer DEFAULT 0,
  clicks integer DEFAULT 0,
  conversions integer DEFAULT 0,
  spend numeric(12,2) DEFAULT 0.00,
  revenue numeric(12,2) DEFAULT 0.00,
  ctr numeric(8,4) DEFAULT 0.0000,
  conversion_rate numeric(8,4) DEFAULT 0.0000,
  cpc numeric(10,4) DEFAULT 0.0000,
  roi numeric(10,4) DEFAULT 0.0000,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamp DEFAULT now() NOT NULL
);
CREATE INDEX IF NOT EXISTS performance_snapshots_campaign_idx ON performance_snapshots (campaign_id);
CREATE INDEX IF NOT EXISTS performance_snapshots_user_idx ON performance_snapshots (user_id);
CREATE INDEX IF NOT EXISTS performance_snapshots_period_idx ON performance_snapshots (period_start, period_end);

CREATE TABLE IF NOT EXISTS geo_zones (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code varchar(40) NOT NULL UNIQUE,
  name varchar(120) NOT NULL,
  country_codes jsonb DEFAULT '[]'::jsonb,
  default_cpc numeric(10,4) DEFAULT 0.0500,
  publisher_share numeric(5,2) DEFAULT 80.00,
  platform_share numeric(5,2) DEFAULT 20.00,
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamp DEFAULT now() NOT NULL,
  updated_at timestamp DEFAULT now() NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS geo_zones_code_idx ON geo_zones (code);
CREATE INDEX IF NOT EXISTS geo_zones_active_idx ON geo_zones (active);

CREATE TABLE IF NOT EXISTS campaign_geo_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id uuid NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  zone_id uuid REFERENCES geo_zones(id) ON DELETE SET NULL,
  country_code varchar(10),
  bid_adjustment numeric(6,2) DEFAULT 0.00,
  daily_budget_cap numeric(12,2),
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamp DEFAULT now() NOT NULL,
  updated_at timestamp DEFAULT now() NOT NULL
);
CREATE INDEX IF NOT EXISTS campaign_geo_rules_campaign_idx ON campaign_geo_rules (campaign_id);
CREATE INDEX IF NOT EXISTS campaign_geo_rules_zone_idx ON campaign_geo_rules (zone_id);
CREATE INDEX IF NOT EXISTS campaign_geo_rules_country_idx ON campaign_geo_rules (country_code);

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
CREATE INDEX IF NOT EXISTS targeting_segments_owner_idx ON targeting_segments (owner_id);
CREATE INDEX IF NOT EXISTS targeting_segments_type_idx ON targeting_segments (segment_type);
CREATE INDEX IF NOT EXISTS targeting_segments_active_idx ON targeting_segments (active);

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

INSERT INTO module_feature_settings (module_key, label, description, allowed_roles, display_order, config)
VALUES
  ('ad_trust', 'Ad Trust', 'Traffic quality, fraud evidence, wallet confidence and dispute signals.', '["admin","advertiser","publisher"]', 1, '{"dashboardPath":"/dashboard/modules","primaryPath":"/dashboard/fraud"}'),
  ('performance_lab', 'Performance Lab', 'Campaign diagnostics, conversion learning, spend analysis and optimisation snapshots.', '["admin","advertiser","publisher"]', 2, '{"dashboardPath":"/dashboard/analytics"}'),
  ('geo_zones', 'Geo Zones', 'Country pricing, regional CPC controls and campaign-level geo rules.', '["admin","advertiser"]', 3, '{"dashboardPath":"/dashboard/country-rates"}'),
  ('targeting', 'Targeting', 'Niche, placement, device, country and segment targeting rules.', '["admin","advertiser","publisher"]', 4, '{"dashboardPath":"/dashboard/campaigns/new"}'),
  ('disputes', 'Disputes', 'Evidence-based support cases for refunds, wallet issues, approvals and traffic quality.', '["admin","advertiser","publisher"]', 5, '{"dashboardPath":"/dashboard/disputes"}'),
  ('approvals', 'Approvals', 'Campaign, publisher site and account review workflow.', '["admin","advertiser","publisher"]', 6, '{"dashboardPath":"/dashboard/approvals"}'),
  ('wallet_operations', 'Wallet Operations', 'Deposits, spending, publisher earnings, withdrawals and transaction records.', '["admin","advertiser","publisher"]', 7, '{"dashboardPath":"/dashboard/wallet"}'),
  ('publisher_metrics', 'Publisher Metrics', 'Publisher site, ad unit, widget, impressions, CTR and earnings performance.', '["admin","publisher"]', 8, '{"dashboardPath":"/dashboard/earnings"}'),
  ('notifications', 'Notification Centre', 'System alerts tied to approvals, disputes, payments and campaign changes.', '["admin","advertiser","publisher"]', 9, '{"dashboardPath":"/dashboard/notifications"}')
ON CONFLICT (module_key) DO NOTHING;

INSERT INTO geo_zones (code, name, country_codes, default_cpc, publisher_share, platform_share)
VALUES
  ('tier_1', 'Tier 1 Markets', '["US","GB","CA","AU"]', 0.0800, 80.00, 20.00),
  ('western_europe', 'Western Europe', '["DE","FR","NL","BE","IE"]', 0.0600, 80.00, 20.00),
  ('west_africa', 'West Africa', '["NG","GH","CM"]', 0.0400, 80.00, 20.00),
  ('east_africa', 'East Africa', '["KE","UG","TZ","RW"]', 0.0350, 80.00, 20.00),
  ('emerging_global', 'Emerging Global Markets', '["IN","BR","MX","ZA"]', 0.0300, 80.00, 20.00)
ON CONFLICT (code) DO NOTHING;
