-- Local Ads Network production repair v4 - STEP 1 OF 2
-- Run this first in Supabase SQL Editor, then run STEP 2.
-- This file only repairs extensions/enums. Keeping enum repair separate avoids
-- PostgreSQL's "unsafe use of new value" problem when newly-added enum values
-- are used later in the same execution batch.

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

ALTER TYPE module_key ADD VALUE IF NOT EXISTS 'ad_trust';
ALTER TYPE module_key ADD VALUE IF NOT EXISTS 'performance_lab';
ALTER TYPE module_key ADD VALUE IF NOT EXISTS 'geo_zones';
ALTER TYPE module_key ADD VALUE IF NOT EXISTS 'targeting';
ALTER TYPE module_key ADD VALUE IF NOT EXISTS 'disputes';
ALTER TYPE module_key ADD VALUE IF NOT EXISTS 'approvals';
ALTER TYPE module_key ADD VALUE IF NOT EXISTS 'wallet_operations';
ALTER TYPE module_key ADD VALUE IF NOT EXISTS 'publisher_metrics';
ALTER TYPE module_key ADD VALUE IF NOT EXISTS 'automation_rules';
ALTER TYPE module_key ADD VALUE IF NOT EXISTS 'notifications';

ALTER TYPE targeting_rule_type ADD VALUE IF NOT EXISTS 'niche';
ALTER TYPE targeting_rule_type ADD VALUE IF NOT EXISTS 'country';
ALTER TYPE targeting_rule_type ADD VALUE IF NOT EXISTS 'device';
ALTER TYPE targeting_rule_type ADD VALUE IF NOT EXISTS 'browser';
ALTER TYPE targeting_rule_type ADD VALUE IF NOT EXISTS 'audience';
ALTER TYPE targeting_rule_type ADD VALUE IF NOT EXISTS 'placement';
ALTER TYPE targeting_rule_type ADD VALUE IF NOT EXISTS 'geo_zone';
