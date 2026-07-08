-- Local Ads Network - Fresh Supabase database schema
-- Generated from src/db/schema.ts using drizzle-kit generate.
-- Run this first on an EMPTY Supabase database if you cannot run npm run db:push locally.
-- Safe prerequisite for gen_random_uuid(). Supabase usually has this, but keep it explicit.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE "public"."ad_status" AS ENUM('pending', 'approved', 'rejected', 'paused');--> statement-breakpoint
CREATE TYPE "public"."ad_unit_size" AS ENUM('responsive', '300x250', '336x280', '728x90', '300x600', '320x100', '320x50', '970x250', '970x90', 'custom');--> statement-breakpoint
CREATE TYPE "public"."ad_unit_type" AS ENUM('display', 'in_feed', 'in_article', 'matched_content', 'native', 'video', 'responsive');--> statement-breakpoint
CREATE TYPE "public"."ad_widget_style" AS ENUM('banner', 'sidebar', 'inline', 'popup', 'sticky_bottom', 'native_feed');--> statement-breakpoint
CREATE TYPE "public"."approval_status" AS ENUM('pending', 'approved', 'rejected', 'cancelled');--> statement-breakpoint
CREATE TYPE "public"."campaign_status" AS ENUM('draft', 'pending_approval', 'active', 'paused', 'budget_finished', 'rejected', 'completed');--> statement-breakpoint
CREATE TYPE "public"."click_status" AS ENUM('valid', 'fraud', 'pending');--> statement-breakpoint
CREATE TYPE "public"."conversion_type" AS ENUM('lead', 'signup', 'purchase', 'download', 'custom');--> statement-breakpoint
CREATE TYPE "public"."deal_status" AS ENUM('pending', 'closed', 'cancelled');--> statement-breakpoint
CREATE TYPE "public"."dispute_priority" AS ENUM('low', 'medium', 'high', 'urgent');--> statement-breakpoint
CREATE TYPE "public"."dispute_status" AS ENUM('open', 'under_review', 'resolved', 'rejected', 'closed');--> statement-breakpoint
CREATE TYPE "public"."module_key" AS ENUM('ad_trust', 'performance_lab', 'geo_zones', 'targeting', 'disputes', 'approvals', 'wallet_operations', 'publisher_metrics', 'automation_rules', 'notifications');--> statement-breakpoint
CREATE TYPE "public"."module_status" AS ENUM('active', 'inactive', 'maintenance');--> statement-breakpoint
CREATE TYPE "public"."notification_type" AS ENUM('campaign_approved', 'campaign_rejected', 'budget_low', 'withdrawal_status', 'fraud_alert', 'account_suspended', 'new_conversion', 'payment_received', 'system');--> statement-breakpoint
CREATE TYPE "public"."targeting_rule_type" AS ENUM('niche', 'country', 'device', 'browser', 'audience', 'placement', 'geo_zone');--> statement-breakpoint
CREATE TYPE "public"."transaction_status" AS ENUM('pending', 'completed', 'failed', 'cancelled');--> statement-breakpoint
CREATE TYPE "public"."transaction_type" AS ENUM('deposit', 'withdrawal', 'click_earning', 'click_spend', 'conversion_earning', 'conversion_spend', 'refund', 'adjustment');--> statement-breakpoint
CREATE TYPE "public"."trust_signal_severity" AS ENUM('low', 'medium', 'high', 'critical');--> statement-breakpoint
CREATE TYPE "public"."trust_signal_status" AS ENUM('open', 'reviewing', 'cleared', 'actioned', 'dismissed');--> statement-breakpoint
CREATE TYPE "public"."user_role" AS ENUM('admin', 'advertiser', 'publisher');--> statement-breakpoint
CREATE TYPE "public"."user_status" AS ENUM('pending', 'active', 'suspended', 'banned');--> statement-breakpoint
CREATE TYPE "public"."withdrawal_status" AS ENUM('pending', 'approved', 'rejected', 'completed');--> statement-breakpoint
CREATE TABLE "ad_serving_log" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"ad_unit_id" uuid NOT NULL,
	"publisher_id" uuid NOT NULL,
	"ad_id" uuid,
	"ad_source" varchar(20) NOT NULL,
	"reason" varchar(100),
	"revenue" numeric(10, 4),
	"ip_address" varchar(45),
	"country" varchar(100),
	"page_url" text,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "ad_targeting" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"campaign_id" uuid NOT NULL,
	"country" varchar(100) NOT NULL,
	"cpc" numeric(10, 4) NOT NULL,
	"active" boolean DEFAULT true,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "ad_trust_signals" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid,
	"campaign_id" uuid,
	"ad_id" uuid,
	"click_id" uuid,
	"signal_type" varchar(100) NOT NULL,
	"severity" "trust_signal_severity" DEFAULT 'medium' NOT NULL,
	"status" "trust_signal_status" DEFAULT 'open' NOT NULL,
	"score" integer DEFAULT 0,
	"evidence" jsonb DEFAULT '{}'::jsonb,
	"reviewed_by" uuid,
	"reviewed_at" timestamp,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "ad_unit_impressions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"ad_unit_id" uuid NOT NULL,
	"ad_id" uuid,
	"ip_address" varchar(45),
	"country" varchar(100),
	"country_code" varchar(10),
	"device" varchar(50),
	"browser" varchar(50),
	"page_url" text,
	"ad_source" varchar(20) DEFAULT 'network',
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "ad_units" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"name" varchar(100) NOT NULL,
	"type" "ad_unit_type" DEFAULT 'display' NOT NULL,
	"size" "ad_unit_size" DEFAULT 'responsive' NOT NULL,
	"custom_width" integer,
	"custom_height" integer,
	"background_color" varchar(20) DEFAULT '#ffffff',
	"border_color" varchar(20),
	"title_color" varchar(20) DEFAULT '#0000ff',
	"text_color" varchar(20) DEFAULT '#000000',
	"url_color" varchar(20) DEFAULT '#008000',
	"use_network_ads" boolean DEFAULT true,
	"use_adsense" boolean DEFAULT true,
	"adsense_slot_id" varchar(50),
	"target_niches" jsonb DEFAULT '[]'::jsonb,
	"impressions" integer DEFAULT 0,
	"clicks" integer DEFAULT 0,
	"earnings" numeric(12, 4) DEFAULT '0.00',
	"ctr" numeric(5, 2) DEFAULT '0.00',
	"rpm" numeric(10, 2) DEFAULT '0.00',
	"active" boolean DEFAULT true,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "ad_widgets" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"publisher_id" uuid NOT NULL,
	"name" varchar(100) NOT NULL,
	"style" "ad_widget_style" DEFAULT 'banner' NOT NULL,
	"width" varchar(20) DEFAULT '100%',
	"height" varchar(20) DEFAULT '250px',
	"max_ads" integer DEFAULT 1,
	"rotate_interval" integer DEFAULT 30,
	"target_niches" jsonb DEFAULT '[]'::jsonb,
	"target_countries" jsonb DEFAULT '[]'::jsonb,
	"background_color" varchar(20) DEFAULT '#ffffff',
	"border_radius" varchar(10) DEFAULT '8px',
	"show_branding" boolean DEFAULT true,
	"custom_css" text,
	"impressions" integer DEFAULT 0,
	"clicks" integer DEFAULT 0,
	"earnings" numeric(12, 4) DEFAULT '0.00',
	"active" boolean DEFAULT true,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "ads" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"campaign_id" uuid NOT NULL,
	"title" varchar(255) NOT NULL,
	"description" text,
	"video_url" text,
	"image_url" text,
	"cta_text" varchar(100) DEFAULT 'Learn More',
	"status" "ad_status" DEFAULT 'pending' NOT NULL,
	"clicks" integer DEFAULT 0,
	"conversions" integer DEFAULT 0,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "adsense_settings" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"publisher_id" varchar(50),
	"enabled" boolean DEFAULT false,
	"auto_ads_enabled" boolean DEFAULT false,
	"ad_client_id" varchar(100),
	"verification_code" text,
	"fallback_enabled" boolean DEFAULT true,
	"revenue_share" numeric(5, 2) DEFAULT '70.00',
	"estimated_earnings" numeric(12, 2) DEFAULT '0.00',
	"last_sync_at" timestamp,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "adsense_settings_user_id_unique" UNIQUE("user_id")
);
--> statement-breakpoint
CREATE TABLE "advertiser_profiles" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"company_name" varchar(255),
	"website" text,
	"industry" varchar(100),
	"country" varchar(100),
	"address" text,
	"phone" varchar(50),
	"tax_id" varchar(100),
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "advertiser_profiles_user_id_unique" UNIQUE("user_id")
);
--> statement-breakpoint
CREATE TABLE "approval_requests" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"approval_number" varchar(40) NOT NULL,
	"module_key" "module_key" DEFAULT 'approvals' NOT NULL,
	"entity_type" varchar(80) NOT NULL,
	"entity_id" uuid,
	"requested_by" uuid,
	"assigned_to" uuid,
	"subject" varchar(255) NOT NULL,
	"notes" text,
	"status" "approval_status" DEFAULT 'pending' NOT NULL,
	"decision_reason" text,
	"decided_by" uuid,
	"decided_at" timestamp,
	"metadata" jsonb DEFAULT '{}'::jsonb,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "approval_requests_approval_number_unique" UNIQUE("approval_number")
);
--> statement-breakpoint
CREATE TABLE "campaign_geo_rules" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"campaign_id" uuid NOT NULL,
	"zone_id" uuid,
	"country_code" varchar(10),
	"bid_adjustment" numeric(6, 2) DEFAULT '0.00',
	"daily_budget_cap" numeric(12, 2),
	"active" boolean DEFAULT true,
	"metadata" jsonb DEFAULT '{}'::jsonb,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "campaign_logs" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"campaign_id" uuid NOT NULL,
	"user_id" uuid,
	"action" varchar(100) NOT NULL,
	"old_value" jsonb,
	"new_value" jsonb,
	"ip_address" varchar(45),
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "campaign_targeting_rules" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"campaign_id" uuid NOT NULL,
	"segment_id" uuid,
	"rule_type" "targeting_rule_type" NOT NULL,
	"include" boolean DEFAULT true,
	"weight" integer DEFAULT 100,
	"metadata" jsonb DEFAULT '{}'::jsonb,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "campaigns" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"advertiser_id" uuid NOT NULL,
	"title" varchar(255) NOT NULL,
	"description" text,
	"landing_page_url" text NOT NULL,
	"total_budget" numeric(12, 2) NOT NULL,
	"daily_budget" numeric(12, 2) NOT NULL,
	"spent_budget" numeric(12, 2) DEFAULT '0.00',
	"today_spent" numeric(12, 2) DEFAULT '0.00',
	"status" "campaign_status" DEFAULT 'draft' NOT NULL,
	"start_date" timestamp,
	"end_date" timestamp,
	"niches" jsonb DEFAULT '[]'::jsonb,
	"rejection_reason" text,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "clicks" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"ad_id" uuid NOT NULL,
	"publisher_id" uuid NOT NULL,
	"campaign_id" uuid NOT NULL,
	"ip_address" varchar(45),
	"country" varchar(100),
	"country_code" varchar(10),
	"device" varchar(50),
	"browser" varchar(50),
	"os" varchar(50),
	"user_agent" text,
	"referer" text,
	"status" "click_status" DEFAULT 'pending' NOT NULL,
	"cpc" numeric(10, 4),
	"publisher_earning" numeric(10, 4),
	"platform_earning" numeric(10, 4),
	"fraud_reason" text,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "conversions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"click_id" uuid NOT NULL,
	"ad_id" uuid NOT NULL,
	"publisher_id" uuid NOT NULL,
	"campaign_id" uuid NOT NULL,
	"type" "conversion_type" DEFAULT 'lead' NOT NULL,
	"value" numeric(12, 2),
	"metadata" jsonb,
	"publisher_earning" numeric(10, 4),
	"platform_earning" numeric(10, 4),
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "country_rates" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"country_code" varchar(10) NOT NULL,
	"country_name" varchar(100) NOT NULL,
	"default_cpc" numeric(10, 4) DEFAULT '0.05' NOT NULL,
	"publisher_share" numeric(5, 2) DEFAULT '80.00' NOT NULL,
	"platform_share" numeric(5, 2) DEFAULT '20.00' NOT NULL,
	"active" boolean DEFAULT true,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "country_rates_country_code_unique" UNIQUE("country_code")
);
--> statement-breakpoint
CREATE TABLE "deals" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"conversion_id" uuid NOT NULL,
	"campaign_id" uuid NOT NULL,
	"publisher_id" uuid NOT NULL,
	"status" "deal_status" DEFAULT 'pending' NOT NULL,
	"deal_value" numeric(12, 2),
	"commission" numeric(12, 2),
	"notes" text,
	"closed_at" timestamp,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "dispute_messages" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"dispute_id" uuid NOT NULL,
	"sender_id" uuid,
	"message" text NOT NULL,
	"attachments" jsonb DEFAULT '[]'::jsonb,
	"internal_note" boolean DEFAULT false,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "disputes" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"dispute_number" varchar(40) NOT NULL,
	"created_by" uuid NOT NULL,
	"assigned_to" uuid,
	"related_type" varchar(50) DEFAULT 'general',
	"related_id" uuid,
	"subject" varchar(255) NOT NULL,
	"category" varchar(80) DEFAULT 'general' NOT NULL,
	"description" text NOT NULL,
	"amount" numeric(12, 2),
	"status" "dispute_status" DEFAULT 'open' NOT NULL,
	"priority" "dispute_priority" DEFAULT 'medium' NOT NULL,
	"resolution" text,
	"metadata" jsonb,
	"resolved_at" timestamp,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "disputes_dispute_number_unique" UNIQUE("dispute_number")
);
--> statement-breakpoint
CREATE TABLE "fraud_flags" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"click_id" uuid,
	"user_id" uuid,
	"ip_address" varchar(45),
	"reason" text NOT NULL,
	"severity" varchar(20) DEFAULT 'medium',
	"resolved" boolean DEFAULT false,
	"resolved_by" uuid,
	"resolved_at" timestamp,
	"metadata" jsonb,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "geo_zones" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"code" varchar(40) NOT NULL,
	"name" varchar(120) NOT NULL,
	"country_codes" jsonb DEFAULT '[]'::jsonb,
	"default_cpc" numeric(10, 4) DEFAULT '0.0500',
	"publisher_share" numeric(5, 2) DEFAULT '80.00',
	"platform_share" numeric(5, 2) DEFAULT '20.00',
	"active" boolean DEFAULT true,
	"metadata" jsonb DEFAULT '{}'::jsonb,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "geo_zones_code_unique" UNIQUE("code")
);
--> statement-breakpoint
CREATE TABLE "module_activity_logs" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"module_key" "module_key" NOT NULL,
	"user_id" uuid,
	"entity_type" varchar(80),
	"entity_id" uuid,
	"action" varchar(120) NOT NULL,
	"metadata" jsonb DEFAULT '{}'::jsonb,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "module_feature_settings" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"module_key" "module_key" NOT NULL,
	"label" varchar(100) NOT NULL,
	"description" text,
	"allowed_roles" jsonb DEFAULT '[]'::jsonb,
	"status" "module_status" DEFAULT 'active' NOT NULL,
	"display_order" integer DEFAULT 0,
	"config" jsonb DEFAULT '{}'::jsonb,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "module_feature_settings_module_key_unique" UNIQUE("module_key")
);
--> statement-breakpoint
CREATE TABLE "notifications" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"type" "notification_type" NOT NULL,
	"title" varchar(255) NOT NULL,
	"message" text NOT NULL,
	"read" boolean DEFAULT false,
	"metadata" jsonb,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "performance_snapshots" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"campaign_id" uuid,
	"user_id" uuid,
	"period_start" timestamp NOT NULL,
	"period_end" timestamp NOT NULL,
	"impressions" integer DEFAULT 0,
	"clicks" integer DEFAULT 0,
	"conversions" integer DEFAULT 0,
	"spend" numeric(12, 2) DEFAULT '0.00',
	"revenue" numeric(12, 2) DEFAULT '0.00',
	"ctr" numeric(8, 4) DEFAULT '0.0000',
	"conversion_rate" numeric(8, 4) DEFAULT '0.0000',
	"cpc" numeric(10, 4) DEFAULT '0.0000',
	"roi" numeric(10, 4) DEFAULT '0.0000',
	"metadata" jsonb DEFAULT '{}'::jsonb,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "pixels" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"campaign_id" uuid NOT NULL,
	"advertiser_id" uuid NOT NULL,
	"name" varchar(100) NOT NULL,
	"pixel_code" text NOT NULL,
	"conversion_type" "conversion_type" DEFAULT 'lead',
	"conversion_value" numeric(12, 2),
	"active" boolean DEFAULT true,
	"fires" integer DEFAULT 0,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "platform_settings" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"key" varchar(100) NOT NULL,
	"value" text NOT NULL,
	"description" text,
	"category" varchar(50) DEFAULT 'general',
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "platform_settings_key_unique" UNIQUE("key")
);
--> statement-breakpoint
CREATE TABLE "publisher_profiles" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"website_url" text,
	"social_media" jsonb,
	"niches" jsonb DEFAULT '[]'::jsonb,
	"country" varchar(100),
	"payment_method" varchar(50),
	"payment_details" jsonb,
	"min_payout" numeric(10, 2) DEFAULT '10.00',
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "publisher_profiles_user_id_unique" UNIQUE("user_id")
);
--> statement-breakpoint
CREATE TABLE "publisher_sites" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"domain" varchar(255) NOT NULL,
	"name" varchar(100),
	"verified" boolean DEFAULT false,
	"verification_method" varchar(50),
	"verification_token" varchar(100),
	"category" varchar(100),
	"monthly_pageviews" integer,
	"adsense_approved" boolean DEFAULT false,
	"active" boolean DEFAULT true,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "referral_clicks" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"referral_code" varchar(20) NOT NULL,
	"referrer_id" uuid,
	"ip_address" varchar(45),
	"user_agent" text,
	"referer" text,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "referral_earnings" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"earner_id" uuid NOT NULL,
	"source_user_id" uuid NOT NULL,
	"level" integer NOT NULL,
	"source_type" varchar(20) NOT NULL,
	"source_earning" numeric(12, 4) NOT NULL,
	"commission_percent" numeric(5, 2) NOT NULL,
	"commission_amount" numeric(12, 4) NOT NULL,
	"reference_id" uuid,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "referral_levels" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"level" integer NOT NULL,
	"commission_percent" numeric(5, 2) NOT NULL,
	"label" varchar(50),
	"active" boolean DEFAULT true,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "referral_levels_level_unique" UNIQUE("level")
);
--> statement-breakpoint
CREATE TABLE "referral_program_settings" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"enabled" boolean DEFAULT true NOT NULL,
	"min_commissionable_amount" numeric(12, 4) DEFAULT '0.0000' NOT NULL,
	"max_levels" integer DEFAULT 10 NOT NULL,
	"cookie_days" integer DEFAULT 30 NOT NULL,
	"commission_source" varchar(50) DEFAULT 'publisher_earnings' NOT NULL,
	"updated_by" uuid,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "sessions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid,
	"token" text NOT NULL,
	"expires_at" timestamp NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "sessions_token_unique" UNIQUE("token")
);
--> statement-breakpoint
CREATE TABLE "targeting_segments" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"owner_id" uuid,
	"name" varchar(120) NOT NULL,
	"segment_type" varchar(80) DEFAULT 'custom' NOT NULL,
	"niches" jsonb DEFAULT '[]'::jsonb,
	"countries" jsonb DEFAULT '[]'::jsonb,
	"devices" jsonb DEFAULT '[]'::jsonb,
	"browsers" jsonb DEFAULT '[]'::jsonb,
	"rules" jsonb DEFAULT '{}'::jsonb,
	"active" boolean DEFAULT true,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "transactions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"wallet_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"type" "transaction_type" NOT NULL,
	"amount" numeric(12, 2) NOT NULL,
	"balance_before" numeric(12, 2),
	"balance_after" numeric(12, 2),
	"status" "transaction_status" DEFAULT 'pending' NOT NULL,
	"description" text,
	"reference_id" uuid,
	"reference_type" varchar(50),
	"metadata" jsonb,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "users" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"email" varchar(255) NOT NULL,
	"password_hash" text NOT NULL,
	"role" "user_role" DEFAULT 'publisher' NOT NULL,
	"status" "user_status" DEFAULT 'pending' NOT NULL,
	"first_name" varchar(100),
	"last_name" varchar(100),
	"avatar_url" text,
	"email_verified" boolean DEFAULT false,
	"referral_code" varchar(20),
	"referred_by" uuid,
	"referral_level" integer DEFAULT 0,
	"last_login_at" timestamp,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "users_email_unique" UNIQUE("email"),
	CONSTRAINT "users_referral_code_unique" UNIQUE("referral_code")
);
--> statement-breakpoint
CREATE TABLE "wallets" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"balance" numeric(12, 2) DEFAULT '0.00' NOT NULL,
	"pending_balance" numeric(12, 2) DEFAULT '0.00',
	"total_earnings" numeric(12, 2) DEFAULT '0.00',
	"total_spent" numeric(12, 2) DEFAULT '0.00',
	"total_withdrawn" numeric(12, 2) DEFAULT '0.00',
	"currency" varchar(10) DEFAULT 'USD',
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "wallets_user_id_unique" UNIQUE("user_id")
);
--> statement-breakpoint
CREATE TABLE "withdrawals" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"wallet_id" uuid NOT NULL,
	"amount" numeric(12, 2) NOT NULL,
	"fee" numeric(12, 2) DEFAULT '0.00',
	"net_amount" numeric(12, 2),
	"status" "withdrawal_status" DEFAULT 'pending' NOT NULL,
	"payment_method" varchar(50),
	"payment_details" jsonb,
	"processed_by" uuid,
	"processed_at" timestamp,
	"rejection_reason" text,
	"transaction_ref" varchar(255),
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "ad_serving_log" ADD CONSTRAINT "ad_serving_log_ad_unit_id_ad_units_id_fk" FOREIGN KEY ("ad_unit_id") REFERENCES "public"."ad_units"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "ad_serving_log" ADD CONSTRAINT "ad_serving_log_publisher_id_users_id_fk" FOREIGN KEY ("publisher_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "ad_serving_log" ADD CONSTRAINT "ad_serving_log_ad_id_ads_id_fk" FOREIGN KEY ("ad_id") REFERENCES "public"."ads"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "ad_targeting" ADD CONSTRAINT "ad_targeting_campaign_id_campaigns_id_fk" FOREIGN KEY ("campaign_id") REFERENCES "public"."campaigns"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "ad_trust_signals" ADD CONSTRAINT "ad_trust_signals_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "ad_trust_signals" ADD CONSTRAINT "ad_trust_signals_campaign_id_campaigns_id_fk" FOREIGN KEY ("campaign_id") REFERENCES "public"."campaigns"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "ad_trust_signals" ADD CONSTRAINT "ad_trust_signals_ad_id_ads_id_fk" FOREIGN KEY ("ad_id") REFERENCES "public"."ads"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "ad_trust_signals" ADD CONSTRAINT "ad_trust_signals_click_id_clicks_id_fk" FOREIGN KEY ("click_id") REFERENCES "public"."clicks"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "ad_trust_signals" ADD CONSTRAINT "ad_trust_signals_reviewed_by_users_id_fk" FOREIGN KEY ("reviewed_by") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "ad_unit_impressions" ADD CONSTRAINT "ad_unit_impressions_ad_unit_id_ad_units_id_fk" FOREIGN KEY ("ad_unit_id") REFERENCES "public"."ad_units"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "ad_unit_impressions" ADD CONSTRAINT "ad_unit_impressions_ad_id_ads_id_fk" FOREIGN KEY ("ad_id") REFERENCES "public"."ads"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "ad_units" ADD CONSTRAINT "ad_units_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "ad_widgets" ADD CONSTRAINT "ad_widgets_publisher_id_users_id_fk" FOREIGN KEY ("publisher_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "ads" ADD CONSTRAINT "ads_campaign_id_campaigns_id_fk" FOREIGN KEY ("campaign_id") REFERENCES "public"."campaigns"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "adsense_settings" ADD CONSTRAINT "adsense_settings_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "advertiser_profiles" ADD CONSTRAINT "advertiser_profiles_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "approval_requests" ADD CONSTRAINT "approval_requests_requested_by_users_id_fk" FOREIGN KEY ("requested_by") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "approval_requests" ADD CONSTRAINT "approval_requests_assigned_to_users_id_fk" FOREIGN KEY ("assigned_to") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "approval_requests" ADD CONSTRAINT "approval_requests_decided_by_users_id_fk" FOREIGN KEY ("decided_by") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "campaign_geo_rules" ADD CONSTRAINT "campaign_geo_rules_campaign_id_campaigns_id_fk" FOREIGN KEY ("campaign_id") REFERENCES "public"."campaigns"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "campaign_geo_rules" ADD CONSTRAINT "campaign_geo_rules_zone_id_geo_zones_id_fk" FOREIGN KEY ("zone_id") REFERENCES "public"."geo_zones"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "campaign_logs" ADD CONSTRAINT "campaign_logs_campaign_id_campaigns_id_fk" FOREIGN KEY ("campaign_id") REFERENCES "public"."campaigns"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "campaign_logs" ADD CONSTRAINT "campaign_logs_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "campaign_targeting_rules" ADD CONSTRAINT "campaign_targeting_rules_campaign_id_campaigns_id_fk" FOREIGN KEY ("campaign_id") REFERENCES "public"."campaigns"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "campaign_targeting_rules" ADD CONSTRAINT "campaign_targeting_rules_segment_id_targeting_segments_id_fk" FOREIGN KEY ("segment_id") REFERENCES "public"."targeting_segments"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "campaigns" ADD CONSTRAINT "campaigns_advertiser_id_users_id_fk" FOREIGN KEY ("advertiser_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "clicks" ADD CONSTRAINT "clicks_ad_id_ads_id_fk" FOREIGN KEY ("ad_id") REFERENCES "public"."ads"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "clicks" ADD CONSTRAINT "clicks_publisher_id_users_id_fk" FOREIGN KEY ("publisher_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "clicks" ADD CONSTRAINT "clicks_campaign_id_campaigns_id_fk" FOREIGN KEY ("campaign_id") REFERENCES "public"."campaigns"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "conversions" ADD CONSTRAINT "conversions_click_id_clicks_id_fk" FOREIGN KEY ("click_id") REFERENCES "public"."clicks"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "conversions" ADD CONSTRAINT "conversions_ad_id_ads_id_fk" FOREIGN KEY ("ad_id") REFERENCES "public"."ads"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "conversions" ADD CONSTRAINT "conversions_publisher_id_users_id_fk" FOREIGN KEY ("publisher_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "conversions" ADD CONSTRAINT "conversions_campaign_id_campaigns_id_fk" FOREIGN KEY ("campaign_id") REFERENCES "public"."campaigns"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "deals" ADD CONSTRAINT "deals_conversion_id_conversions_id_fk" FOREIGN KEY ("conversion_id") REFERENCES "public"."conversions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "deals" ADD CONSTRAINT "deals_campaign_id_campaigns_id_fk" FOREIGN KEY ("campaign_id") REFERENCES "public"."campaigns"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "deals" ADD CONSTRAINT "deals_publisher_id_users_id_fk" FOREIGN KEY ("publisher_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "dispute_messages" ADD CONSTRAINT "dispute_messages_dispute_id_disputes_id_fk" FOREIGN KEY ("dispute_id") REFERENCES "public"."disputes"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "dispute_messages" ADD CONSTRAINT "dispute_messages_sender_id_users_id_fk" FOREIGN KEY ("sender_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "disputes" ADD CONSTRAINT "disputes_created_by_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "disputes" ADD CONSTRAINT "disputes_assigned_to_users_id_fk" FOREIGN KEY ("assigned_to") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "fraud_flags" ADD CONSTRAINT "fraud_flags_click_id_clicks_id_fk" FOREIGN KEY ("click_id") REFERENCES "public"."clicks"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "fraud_flags" ADD CONSTRAINT "fraud_flags_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "fraud_flags" ADD CONSTRAINT "fraud_flags_resolved_by_users_id_fk" FOREIGN KEY ("resolved_by") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "module_activity_logs" ADD CONSTRAINT "module_activity_logs_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "performance_snapshots" ADD CONSTRAINT "performance_snapshots_campaign_id_campaigns_id_fk" FOREIGN KEY ("campaign_id") REFERENCES "public"."campaigns"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "performance_snapshots" ADD CONSTRAINT "performance_snapshots_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "pixels" ADD CONSTRAINT "pixels_campaign_id_campaigns_id_fk" FOREIGN KEY ("campaign_id") REFERENCES "public"."campaigns"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "pixels" ADD CONSTRAINT "pixels_advertiser_id_users_id_fk" FOREIGN KEY ("advertiser_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "publisher_profiles" ADD CONSTRAINT "publisher_profiles_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "publisher_sites" ADD CONSTRAINT "publisher_sites_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "referral_clicks" ADD CONSTRAINT "referral_clicks_referrer_id_users_id_fk" FOREIGN KEY ("referrer_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "referral_earnings" ADD CONSTRAINT "referral_earnings_earner_id_users_id_fk" FOREIGN KEY ("earner_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "referral_earnings" ADD CONSTRAINT "referral_earnings_source_user_id_users_id_fk" FOREIGN KEY ("source_user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "referral_program_settings" ADD CONSTRAINT "referral_program_settings_updated_by_users_id_fk" FOREIGN KEY ("updated_by") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "sessions" ADD CONSTRAINT "sessions_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "targeting_segments" ADD CONSTRAINT "targeting_segments_owner_id_users_id_fk" FOREIGN KEY ("owner_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_wallet_id_wallets_id_fk" FOREIGN KEY ("wallet_id") REFERENCES "public"."wallets"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "users" ADD CONSTRAINT "users_referred_by_users_id_fk" FOREIGN KEY ("referred_by") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "wallets" ADD CONSTRAINT "wallets_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "withdrawals" ADD CONSTRAINT "withdrawals_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "withdrawals" ADD CONSTRAINT "withdrawals_wallet_id_wallets_id_fk" FOREIGN KEY ("wallet_id") REFERENCES "public"."wallets"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "withdrawals" ADD CONSTRAINT "withdrawals_processed_by_users_id_fk" FOREIGN KEY ("processed_by") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "ad_serving_log_unit_idx" ON "ad_serving_log" USING btree ("ad_unit_id");--> statement-breakpoint
CREATE INDEX "ad_serving_log_publisher_idx" ON "ad_serving_log" USING btree ("publisher_id");--> statement-breakpoint
CREATE INDEX "ad_serving_log_created_idx" ON "ad_serving_log" USING btree ("created_at");--> statement-breakpoint
CREATE INDEX "ad_targeting_campaign_idx" ON "ad_targeting" USING btree ("campaign_id");--> statement-breakpoint
CREATE UNIQUE INDEX "ad_targeting_campaign_country_idx" ON "ad_targeting" USING btree ("campaign_id","country");--> statement-breakpoint
CREATE INDEX "ad_trust_signals_user_idx" ON "ad_trust_signals" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "ad_trust_signals_campaign_idx" ON "ad_trust_signals" USING btree ("campaign_id");--> statement-breakpoint
CREATE INDEX "ad_trust_signals_status_idx" ON "ad_trust_signals" USING btree ("status");--> statement-breakpoint
CREATE INDEX "ad_trust_signals_severity_idx" ON "ad_trust_signals" USING btree ("severity");--> statement-breakpoint
CREATE INDEX "ad_unit_impressions_unit_idx" ON "ad_unit_impressions" USING btree ("ad_unit_id");--> statement-breakpoint
CREATE INDEX "ad_unit_impressions_created_idx" ON "ad_unit_impressions" USING btree ("created_at");--> statement-breakpoint
CREATE INDEX "ad_units_user_idx" ON "ad_units" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "ad_units_type_idx" ON "ad_units" USING btree ("type");--> statement-breakpoint
CREATE INDEX "ad_widgets_publisher_idx" ON "ad_widgets" USING btree ("publisher_id");--> statement-breakpoint
CREATE INDEX "ads_campaign_idx" ON "ads" USING btree ("campaign_id");--> statement-breakpoint
CREATE INDEX "ads_status_idx" ON "ads" USING btree ("status");--> statement-breakpoint
CREATE INDEX "adsense_settings_user_idx" ON "adsense_settings" USING btree ("user_id");--> statement-breakpoint
CREATE UNIQUE INDEX "approval_requests_number_idx" ON "approval_requests" USING btree ("approval_number");--> statement-breakpoint
CREATE INDEX "approval_requests_status_idx" ON "approval_requests" USING btree ("status");--> statement-breakpoint
CREATE INDEX "approval_requests_entity_idx" ON "approval_requests" USING btree ("entity_type","entity_id");--> statement-breakpoint
CREATE INDEX "approval_requests_requested_by_idx" ON "approval_requests" USING btree ("requested_by");--> statement-breakpoint
CREATE INDEX "campaign_geo_rules_campaign_idx" ON "campaign_geo_rules" USING btree ("campaign_id");--> statement-breakpoint
CREATE INDEX "campaign_geo_rules_zone_idx" ON "campaign_geo_rules" USING btree ("zone_id");--> statement-breakpoint
CREATE INDEX "campaign_geo_rules_country_idx" ON "campaign_geo_rules" USING btree ("country_code");--> statement-breakpoint
CREATE INDEX "campaign_logs_campaign_idx" ON "campaign_logs" USING btree ("campaign_id");--> statement-breakpoint
CREATE INDEX "campaign_targeting_rules_campaign_idx" ON "campaign_targeting_rules" USING btree ("campaign_id");--> statement-breakpoint
CREATE INDEX "campaign_targeting_rules_segment_idx" ON "campaign_targeting_rules" USING btree ("segment_id");--> statement-breakpoint
CREATE INDEX "campaign_targeting_rules_type_idx" ON "campaign_targeting_rules" USING btree ("rule_type");--> statement-breakpoint
CREATE INDEX "campaigns_advertiser_idx" ON "campaigns" USING btree ("advertiser_id");--> statement-breakpoint
CREATE INDEX "campaigns_status_idx" ON "campaigns" USING btree ("status");--> statement-breakpoint
CREATE INDEX "clicks_ad_idx" ON "clicks" USING btree ("ad_id");--> statement-breakpoint
CREATE INDEX "clicks_publisher_idx" ON "clicks" USING btree ("publisher_id");--> statement-breakpoint
CREATE INDEX "clicks_campaign_idx" ON "clicks" USING btree ("campaign_id");--> statement-breakpoint
CREATE INDEX "clicks_ip_idx" ON "clicks" USING btree ("ip_address");--> statement-breakpoint
CREATE INDEX "clicks_created_idx" ON "clicks" USING btree ("created_at");--> statement-breakpoint
CREATE INDEX "clicks_status_idx" ON "clicks" USING btree ("status");--> statement-breakpoint
CREATE INDEX "conversions_click_idx" ON "conversions" USING btree ("click_id");--> statement-breakpoint
CREATE INDEX "conversions_campaign_idx" ON "conversions" USING btree ("campaign_id");--> statement-breakpoint
CREATE INDEX "conversions_publisher_idx" ON "conversions" USING btree ("publisher_id");--> statement-breakpoint
CREATE UNIQUE INDEX "country_rates_code_idx" ON "country_rates" USING btree ("country_code");--> statement-breakpoint
CREATE INDEX "deals_conversion_idx" ON "deals" USING btree ("conversion_id");--> statement-breakpoint
CREATE INDEX "deals_campaign_idx" ON "deals" USING btree ("campaign_id");--> statement-breakpoint
CREATE INDEX "deals_publisher_idx" ON "deals" USING btree ("publisher_id");--> statement-breakpoint
CREATE INDEX "dispute_messages_dispute_idx" ON "dispute_messages" USING btree ("dispute_id");--> statement-breakpoint
CREATE INDEX "dispute_messages_sender_idx" ON "dispute_messages" USING btree ("sender_id");--> statement-breakpoint
CREATE INDEX "dispute_messages_created_idx" ON "dispute_messages" USING btree ("created_at");--> statement-breakpoint
CREATE UNIQUE INDEX "disputes_number_idx" ON "disputes" USING btree ("dispute_number");--> statement-breakpoint
CREATE INDEX "disputes_created_by_idx" ON "disputes" USING btree ("created_by");--> statement-breakpoint
CREATE INDEX "disputes_status_idx" ON "disputes" USING btree ("status");--> statement-breakpoint
CREATE INDEX "disputes_priority_idx" ON "disputes" USING btree ("priority");--> statement-breakpoint
CREATE INDEX "disputes_created_at_idx" ON "disputes" USING btree ("created_at");--> statement-breakpoint
CREATE INDEX "fraud_flags_click_idx" ON "fraud_flags" USING btree ("click_id");--> statement-breakpoint
CREATE INDEX "fraud_flags_user_idx" ON "fraud_flags" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "fraud_flags_ip_idx" ON "fraud_flags" USING btree ("ip_address");--> statement-breakpoint
CREATE UNIQUE INDEX "geo_zones_code_idx" ON "geo_zones" USING btree ("code");--> statement-breakpoint
CREATE INDEX "geo_zones_active_idx" ON "geo_zones" USING btree ("active");--> statement-breakpoint
CREATE INDEX "module_activity_logs_module_idx" ON "module_activity_logs" USING btree ("module_key");--> statement-breakpoint
CREATE INDEX "module_activity_logs_user_idx" ON "module_activity_logs" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "module_activity_logs_entity_idx" ON "module_activity_logs" USING btree ("entity_type","entity_id");--> statement-breakpoint
CREATE INDEX "module_activity_logs_created_idx" ON "module_activity_logs" USING btree ("created_at");--> statement-breakpoint
CREATE UNIQUE INDEX "module_feature_settings_key_idx" ON "module_feature_settings" USING btree ("module_key");--> statement-breakpoint
CREATE INDEX "module_feature_settings_status_idx" ON "module_feature_settings" USING btree ("status");--> statement-breakpoint
CREATE INDEX "notifications_user_idx" ON "notifications" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "notifications_read_idx" ON "notifications" USING btree ("read");--> statement-breakpoint
CREATE INDEX "performance_snapshots_campaign_idx" ON "performance_snapshots" USING btree ("campaign_id");--> statement-breakpoint
CREATE INDEX "performance_snapshots_user_idx" ON "performance_snapshots" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "performance_snapshots_period_idx" ON "performance_snapshots" USING btree ("period_start","period_end");--> statement-breakpoint
CREATE INDEX "pixels_campaign_idx" ON "pixels" USING btree ("campaign_id");--> statement-breakpoint
CREATE INDEX "pixels_advertiser_idx" ON "pixels" USING btree ("advertiser_id");--> statement-breakpoint
CREATE UNIQUE INDEX "platform_settings_key_idx" ON "platform_settings" USING btree ("key");--> statement-breakpoint
CREATE INDEX "publisher_sites_user_idx" ON "publisher_sites" USING btree ("user_id");--> statement-breakpoint
CREATE UNIQUE INDEX "publisher_sites_domain_idx" ON "publisher_sites" USING btree ("domain");--> statement-breakpoint
CREATE INDEX "referral_clicks_code_idx" ON "referral_clicks" USING btree ("referral_code");--> statement-breakpoint
CREATE INDEX "referral_clicks_referrer_idx" ON "referral_clicks" USING btree ("referrer_id");--> statement-breakpoint
CREATE INDEX "referral_clicks_created_idx" ON "referral_clicks" USING btree ("created_at");--> statement-breakpoint
CREATE INDEX "referral_earnings_earner_idx" ON "referral_earnings" USING btree ("earner_id");--> statement-breakpoint
CREATE INDEX "referral_earnings_source_idx" ON "referral_earnings" USING btree ("source_user_id");--> statement-breakpoint
CREATE INDEX "referral_earnings_created_idx" ON "referral_earnings" USING btree ("created_at");--> statement-breakpoint
CREATE UNIQUE INDEX "referral_levels_level_idx" ON "referral_levels" USING btree ("level");--> statement-breakpoint
CREATE INDEX "referral_program_settings_enabled_idx" ON "referral_program_settings" USING btree ("enabled");--> statement-breakpoint
CREATE INDEX "sessions_token_idx" ON "sessions" USING btree ("token");--> statement-breakpoint
CREATE INDEX "sessions_user_idx" ON "sessions" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "targeting_segments_owner_idx" ON "targeting_segments" USING btree ("owner_id");--> statement-breakpoint
CREATE INDEX "targeting_segments_type_idx" ON "targeting_segments" USING btree ("segment_type");--> statement-breakpoint
CREATE INDEX "targeting_segments_active_idx" ON "targeting_segments" USING btree ("active");--> statement-breakpoint
CREATE INDEX "transactions_wallet_idx" ON "transactions" USING btree ("wallet_id");--> statement-breakpoint
CREATE INDEX "transactions_user_idx" ON "transactions" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "transactions_type_idx" ON "transactions" USING btree ("type");--> statement-breakpoint
CREATE INDEX "transactions_created_idx" ON "transactions" USING btree ("created_at");--> statement-breakpoint
CREATE INDEX "users_email_idx" ON "users" USING btree ("email");--> statement-breakpoint
CREATE INDEX "users_role_idx" ON "users" USING btree ("role");--> statement-breakpoint
CREATE INDEX "users_referral_code_idx" ON "users" USING btree ("referral_code");--> statement-breakpoint
CREATE INDEX "users_referred_by_idx" ON "users" USING btree ("referred_by");--> statement-breakpoint
CREATE UNIQUE INDEX "wallets_user_idx" ON "wallets" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "withdrawals_user_idx" ON "withdrawals" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "withdrawals_status_idx" ON "withdrawals" USING btree ("status");