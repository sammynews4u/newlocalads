-- Local Ads Network - base production seed data
-- This file creates platform defaults only. It does NOT create demo users.

INSERT INTO country_rates (country_code, country_name, default_cpc, publisher_share, platform_share, active)
VALUES
  ('US', 'United States', 0.1000, 80.00, 20.00, true),
  ('GB', 'United Kingdom', 0.0800, 80.00, 20.00, true),
  ('CA', 'Canada', 0.0700, 80.00, 20.00, true),
  ('AU', 'Australia', 0.0700, 80.00, 20.00, true),
  ('DE', 'Germany', 0.0600, 80.00, 20.00, true),
  ('FR', 'France', 0.0600, 80.00, 20.00, true),
  ('NG', 'Nigeria', 0.0500, 80.00, 20.00, true),
  ('KE', 'Kenya', 0.0400, 80.00, 20.00, true),
  ('CM', 'Cameroon', 0.0300, 80.00, 20.00, true),
  ('GH', 'Ghana', 0.0400, 80.00, 20.00, true),
  ('ZA', 'South Africa', 0.0500, 80.00, 20.00, true),
  ('IN', 'India', 0.0200, 80.00, 20.00, true),
  ('BR', 'Brazil', 0.0400, 80.00, 20.00, true),
  ('MX', 'Mexico', 0.0300, 80.00, 20.00, true)
ON CONFLICT (country_code) DO UPDATE SET
  country_name = EXCLUDED.country_name,
  default_cpc = EXCLUDED.default_cpc,
  publisher_share = EXCLUDED.publisher_share,
  platform_share = EXCLUDED.platform_share,
  active = EXCLUDED.active,
  updated_at = now();

INSERT INTO module_feature_settings (module_key, label, description, allowed_roles, status, display_order, config)
VALUES
  ('ad_trust', 'Ad Trust', 'Traffic quality, fraud evidence, wallet confidence and dispute signals.', '["admin","advertiser","publisher"]'::jsonb, 'active', 1, '{"dashboardPath":"/dashboard/modules","primaryPath":"/dashboard/fraud"}'::jsonb),
  ('performance_lab', 'Performance Lab', 'Campaign diagnostics, conversion learning, spend analysis and optimisation snapshots.', '["admin","advertiser","publisher"]'::jsonb, 'active', 2, '{"dashboardPath":"/dashboard/analytics"}'::jsonb),
  ('geo_zones', 'Geo Zones', 'Country pricing, regional CPC controls and campaign-level geo rules.', '["admin","advertiser"]'::jsonb, 'active', 3, '{"dashboardPath":"/dashboard/country-rates"}'::jsonb),
  ('targeting', 'Targeting', 'Niche, placement, device, country and segment targeting rules.', '["admin","advertiser","publisher"]'::jsonb, 'active', 4, '{"dashboardPath":"/dashboard/campaigns/new"}'::jsonb),
  ('disputes', 'Disputes', 'Evidence-based support cases for refunds, wallet issues, approvals and traffic quality.', '["admin","advertiser","publisher"]'::jsonb, 'active', 5, '{"dashboardPath":"/dashboard/disputes"}'::jsonb),
  ('approvals', 'Approvals', 'Campaign, publisher site and account review workflow.', '["admin","advertiser","publisher"]'::jsonb, 'active', 6, '{"dashboardPath":"/dashboard/approvals"}'::jsonb),
  ('wallet_operations', 'Wallet Operations', 'Deposits, spending, publisher earnings, withdrawals and transaction records.', '["admin","advertiser","publisher"]'::jsonb, 'active', 7, '{"dashboardPath":"/dashboard/wallet"}'::jsonb),
  ('publisher_metrics', 'Publisher Metrics', 'Publisher site, ad unit, widget, impressions, CTR and earnings performance.', '["admin","publisher"]'::jsonb, 'active', 8, '{"dashboardPath":"/dashboard/earnings"}'::jsonb),
  ('notifications', 'Notification Centre', 'System alerts tied to approvals, disputes, payments and campaign changes.', '["admin","advertiser","publisher"]'::jsonb, 'active', 9, '{"dashboardPath":"/dashboard/notifications"}'::jsonb)
ON CONFLICT (module_key) DO UPDATE SET
  label = EXCLUDED.label,
  description = EXCLUDED.description,
  allowed_roles = EXCLUDED.allowed_roles,
  status = EXCLUDED.status,
  display_order = EXCLUDED.display_order,
  config = EXCLUDED.config,
  updated_at = now();

INSERT INTO geo_zones (code, name, country_codes, default_cpc, publisher_share, platform_share, active)
VALUES
  ('tier_1', 'Tier 1 Markets', '["US","GB","CA","AU"]'::jsonb, 0.0800, 80.00, 20.00, true),
  ('western_europe', 'Western Europe', '["DE","FR","NL","BE","IE"]'::jsonb, 0.0600, 80.00, 20.00, true),
  ('west_africa', 'West Africa', '["NG","GH","CM"]'::jsonb, 0.0400, 80.00, 20.00, true),
  ('east_africa', 'East Africa', '["KE","UG","TZ","RW"]'::jsonb, 0.0350, 80.00, 20.00, true),
  ('emerging_global', 'Emerging Global Markets', '["IN","BR","MX","ZA"]'::jsonb, 0.0300, 80.00, 20.00, true)
ON CONFLICT (code) DO UPDATE SET
  name = EXCLUDED.name,
  country_codes = EXCLUDED.country_codes,
  default_cpc = EXCLUDED.default_cpc,
  publisher_share = EXCLUDED.publisher_share,
  platform_share = EXCLUDED.platform_share,
  active = EXCLUDED.active,
  updated_at = now();

INSERT INTO targeting_segments (name, segment_type, niches, countries, rules, active)
SELECT 'Business and Finance Audience', 'niche', '["Business","Finance"]'::jsonb, '["US","GB","NG","GH"]'::jsonb, '{"intent":"commercial"}'::jsonb, true
WHERE NOT EXISTS (SELECT 1 FROM targeting_segments WHERE name = 'Business and Finance Audience');

INSERT INTO targeting_segments (name, segment_type, niches, countries, rules, active)
SELECT 'Technology Readers', 'niche', '["Technology","Software","AI"]'::jsonb, '["US","GB","CA","NG"]'::jsonb, '{"intent":"software_interest"}'::jsonb, true
WHERE NOT EXISTS (SELECT 1 FROM targeting_segments WHERE name = 'Technology Readers');

INSERT INTO targeting_segments (name, segment_type, niches, countries, rules, active)
SELECT 'African Consumer Reach', 'geo_zone', '["Shopping","Lifestyle","Business"]'::jsonb, '["NG","GH","KE","ZA"]'::jsonb, '{"region":"africa"}'::jsonb, true
WHERE NOT EXISTS (SELECT 1 FROM targeting_segments WHERE name = 'African Consumer Reach');

-- Referral defaults. Admin can adjust these from /dashboard/admin-referrals.
INSERT INTO referral_levels (level, commission_percent, label, active)
VALUES
  (1, 10.0000, 'Level 1', true),
  (2, 5.0000, 'Level 2', true),
  (3, 2.5000, 'Level 3', true),
  (4, 1.0000, 'Level 4', true),
  (5, 0.5000, 'Level 5', true)
ON CONFLICT (level) DO UPDATE SET
  commission_percent = EXCLUDED.commission_percent,
  label = EXCLUDED.label,
  active = EXCLUDED.active,
  updated_at = now();

INSERT INTO referral_program_settings (enabled, min_commissionable_amount, max_levels, cookie_days, commission_source)
SELECT true, 0.0000, 5, 30, 'publisher_earnings'
WHERE NOT EXISTS (SELECT 1 FROM referral_program_settings);

-- Sanity check output.
SELECT 'country_rates' AS table_name, count(*)::text AS rows FROM country_rates
UNION ALL SELECT 'module_feature_settings', count(*)::text FROM module_feature_settings
UNION ALL SELECT 'geo_zones', count(*)::text FROM geo_zones
UNION ALL SELECT 'targeting_segments', count(*)::text FROM targeting_segments
UNION ALL SELECT 'referral_levels', count(*)::text FROM referral_levels
UNION ALL SELECT 'referral_program_settings', count(*)::text FROM referral_program_settings;
