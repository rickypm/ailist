-- ============================================================
-- WELIST - COMPLETE DATABASE SCHEMA
-- Single file - Run this once in Supabase SQL Editor
-- Version:  1.2.0 (Fixed missing RPC functions)
-- ============================================================

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- SECTION 1: CORE TABLES
-- ============================================================

-- 1.1 USERS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    phone TEXT,
    avatar_url TEXT,
    role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'partner', 'admin')),
    city TEXT DEFAULT 'Shillong',
    subscription_plan TEXT NOT NULL DEFAULT 'free' CHECK (subscription_plan IN ('free', 'basic', 'plus', 'pro')),
    unlocks_remaining INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    last_seen_at TIMESTAMP WITH TIME ZONE,
    
    -- Referral fields
    referral_code VARCHAR(10) UNIQUE,
    referred_by_user_id UUID REFERENCES public.users(id),
    referred_by_code VARCHAR(10),
    total_referrals INTEGER DEFAULT 0,
    referral_earnings DECIMAL(10,2) DEFAULT 0,
    signup_reward_claimed BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_users_city ON public.users(city);
CREATE INDEX IF NOT EXISTS idx_users_referral_code ON public.users(referral_code);
CREATE INDEX IF NOT EXISTS idx_users_referred_by ON public.users(referred_by_user_id);
CREATE INDEX IF NOT EXISTS idx_users_subscription ON public.users(subscription_plan);

-- 1.2 CATEGORIES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    slug TEXT NOT NULL UNIQUE,
    description TEXT,
    icon_name TEXT NOT NULL DEFAULT 'category',
    image_url TEXT,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    parent_id UUID REFERENCES public.categories(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_categories_slug ON public.categories(slug);
CREATE INDEX IF NOT EXISTS idx_categories_active ON public.categories(is_active);
CREATE INDEX IF NOT EXISTS idx_categories_order ON public.categories(display_order);

-- 1.3 PROFESSIONALS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.professionals (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
    category_id UUID REFERENCES public.categories(id),
    display_name TEXT NOT NULL,
    profession TEXT NOT NULL,
    description TEXT,
    phone TEXT,
    whatsapp TEXT,
    email TEXT,
    avatar_url TEXT,
    cover_url TEXT,
    city TEXT NOT NULL DEFAULT 'Shillong',
    area TEXT,
    address TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    services JSONB DEFAULT '[]'::jsonb,
    experience_years INTEGER DEFAULT 0,
    working_hours JSONB DEFAULT '{}'::jsonb,
    partner_type TEXT DEFAULT 'individual' CHECK (partner_type IN ('individual', 'group')),
    group_name TEXT,
    group_size INTEGER DEFAULT 1,
    subscription_plan TEXT NOT NULL DEFAULT 'free' CHECK (subscription_plan IN ('free', 'starter', 'business')),
    is_verified BOOLEAN DEFAULT FALSE,
    is_available BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    rating DECIMAL(3,2) DEFAULT 0,
    total_reviews INTEGER DEFAULT 0,
    search_appearances INTEGER DEFAULT 0,
    profile_views INTEGER DEFAULT 0,
    total_messages INTEGER DEFAULT 0,
    response_rate DECIMAL(5,2) DEFAULT 0,
    avg_response_time INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_professionals_user ON public.professionals(user_id);
CREATE INDEX IF NOT EXISTS idx_professionals_category ON public.professionals(category_id);
CREATE INDEX IF NOT EXISTS idx_professionals_city ON public.professionals(city);
CREATE INDEX IF NOT EXISTS idx_professionals_verified ON public.professionals(is_verified);
CREATE INDEX IF NOT EXISTS idx_professionals_available ON public.professionals(is_available);
CREATE INDEX IF NOT EXISTS idx_professionals_subscription ON public.professionals(subscription_plan);

-- 1.4 SHOPS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.shops (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    professional_id UUID REFERENCES public.professionals(id) ON DELETE CASCADE UNIQUE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    logo_url TEXT,
    cover_image_url TEXT,
    phone TEXT,
    whatsapp TEXT,
    email TEXT,
    website TEXT,
    city TEXT NOT NULL DEFAULT 'Shillong',
    address TEXT,
    locality TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    opening_hours JSONB DEFAULT '{}'::jsonb,
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    rating DECIMAL(3,2) DEFAULT 0,
    total_reviews INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_shops_professional ON public.shops(professional_id);
CREATE INDEX IF NOT EXISTS idx_shops_city ON public.shops(city);
CREATE INDEX IF NOT EXISTS idx_shops_active ON public.shops(is_active);

-- 1.5 ITEMS TABLE (Services/Products)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.items (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    shop_id UUID REFERENCES public.shops(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    image_url TEXT,
    price DECIMAL(10, 2),
    price_unit TEXT,
    tags TEXT[] DEFAULT '{}',
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_items_shop ON public.items(shop_id);
CREATE INDEX IF NOT EXISTS idx_items_active ON public.items(is_active);
CREATE INDEX IF NOT EXISTS idx_items_tags ON public.items USING GIN (tags);

-- 1.6 SETTINGS TABLE (NEW - For app configuration)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.settings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    key VARCHAR(100) UNIQUE NOT NULL,
    value TEXT NOT NULL,
    description TEXT,
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_settings_key ON public.settings(key);

-- ============================================================
-- SECTION 2: USER INTERACTIONS
-- ============================================================

-- 2.1 USER UNLOCKS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_unlocks (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    professional_id UUID REFERENCES public.professionals(id) ON DELETE CASCADE NOT NULL,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '30 days'),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, professional_id)
);

CREATE INDEX IF NOT EXISTS idx_unlocks_user ON public.user_unlocks(user_id);
CREATE INDEX IF NOT EXISTS idx_unlocks_professional ON public.user_unlocks(professional_id);
CREATE INDEX IF NOT EXISTS idx_unlocks_active ON public.user_unlocks(is_active);

-- 2.2 CONVERSATIONS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    professional_id UUID REFERENCES public.professionals(id) ON DELETE CASCADE NOT NULL,
    last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_message_preview TEXT,
    user_unread_count INTEGER DEFAULT 0,
    professional_unread_count INTEGER DEFAULT 0,
    is_unlocked BOOLEAN DEFAULT FALSE,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'archived', 'blocked')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, professional_id)
);

CREATE INDEX IF NOT EXISTS idx_conversations_user ON public.conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_conversations_professional ON public.conversations(professional_id);
CREATE INDEX IF NOT EXISTS idx_conversations_last_message ON public.conversations(last_message_at DESC);

-- 2.3 MESSAGES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE NOT NULL,
    sender_id UUID NOT NULL,
    sender_type TEXT NOT NULL CHECK (sender_type IN ('user', 'professional', 'system', 'ai')),
    content TEXT NOT NULL,
    message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file', 'system')),
    is_readable BOOLEAN DEFAULT FALSE,
    is_read BOOLEAN DEFAULT FALSE,
    is_ai_response BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created ON public.messages(created_at DESC);

-- 2.4 REVIEWS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    professional_id UUID REFERENCES public.professionals(id) ON DELETE CASCADE,
    shop_id UUID REFERENCES public.shops(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    is_visible BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CHECK (professional_id IS NOT NULL OR shop_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_reviews_user ON public.reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_professional ON public.reviews(professional_id);
CREATE INDEX IF NOT EXISTS idx_reviews_shop ON public.reviews(shop_id);

-- ============================================================
-- SECTION 3: REFERRAL & COUPONS
-- ============================================================

-- 3.1 REFERRALS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.referrals (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    referrer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    referee_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    referral_code VARCHAR(10) NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'rewarded', 'cancelled')),
    referrer_reward_type TEXT,
    referrer_reward_amount DECIMAL(10,2) DEFAULT 0,
    referee_reward_type TEXT,
    referee_reward_amount DECIMAL(10,2) DEFAULT 0,
    referrer_rewarded_at TIMESTAMP WITH TIME ZONE,
    referee_rewarded_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(referrer_id, referee_id)
);

CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON public.referrals(referrer_id);
CREATE INDEX IF NOT EXISTS idx_referrals_referee ON public.referrals(referee_id);
CREATE INDEX IF NOT EXISTS idx_referrals_code ON public.referrals(referral_code);
CREATE INDEX IF NOT EXISTS idx_referrals_status ON public.referrals(status);

-- 3.2 COUPONS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.coupons (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    description TEXT,
    coupon_type TEXT NOT NULL CHECK (coupon_type IN ('signup_bonus', 'discount', 'free_unlocks', 'subscription_days', 'credits')),
    reward_value DECIMAL(10,2) NOT NULL,
    discount_percentage INTEGER,
    min_purchase_amount DECIMAL(10,2) DEFAULT 0,
    max_uses INTEGER,
    used_count INTEGER DEFAULT 0,
    max_uses_per_user INTEGER DEFAULT 1,
    valid_from TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    valid_until TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES public.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_coupons_code ON public.coupons(code);
CREATE INDEX IF NOT EXISTS idx_coupons_active ON public.coupons(is_active);

-- 3.3 COUPON REDEMPTIONS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.coupon_redemptions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    coupon_id UUID NOT NULL REFERENCES public.coupons(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    coupon_code VARCHAR(20) NOT NULL,
    reward_type TEXT NOT NULL,
    reward_value DECIMAL(10,2) NOT NULL,
    redeemed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(coupon_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_redemptions_coupon ON public.coupon_redemptions(coupon_id);
CREATE INDEX IF NOT EXISTS idx_redemptions_user ON public.coupon_redemptions(user_id);

-- 3.4 REWARDS HISTORY TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.rewards_history (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    reward_type TEXT NOT NULL,
    reward_source TEXT NOT NULL,
    source_id UUID,
    description TEXT,
    unlocks_awarded INTEGER DEFAULT 0,
    credits_awarded DECIMAL(10,2) DEFAULT 0,
    subscription_days_awarded INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rewards_user ON public.rewards_history(user_id);
CREATE INDEX IF NOT EXISTS idx_rewards_type ON public.rewards_history(reward_type);

-- 3.5 REFERRAL SETTINGS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.referral_settings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    setting_key VARCHAR(50) UNIQUE NOT NULL,
    setting_value TEXT NOT NULL,
    description TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_by UUID REFERENCES public.users(id)
);

-- ============================================================
-- SECTION 4: SUBSCRIPTIONS & PAYMENTS
-- ============================================================

-- 4.1 SUBSCRIPTIONS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    owner_id UUID NOT NULL,
    owner_type TEXT NOT NULL CHECK (owner_type IN ('user', 'professional')),
    plan TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired', 'pending')),
    amount DECIMAL(10, 2) NOT NULL,
    currency TEXT NOT NULL DEFAULT 'INR',
    payment_id TEXT,
    order_id TEXT,
    payment_method TEXT,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    end_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT (NOW() + INTERVAL '30 days'),
    auto_renew BOOLEAN NOT NULL DEFAULT TRUE,
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancellation_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_owner ON public.subscriptions(owner_id, owner_type);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON public.subscriptions(status);

-- 4.2 PAYMENT TRANSACTIONS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.payment_transactions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES public.subscriptions(id) ON DELETE SET NULL,
    amount DECIMAL(10, 2) NOT NULL,
    currency TEXT NOT NULL DEFAULT 'INR',
    payment_provider TEXT NOT NULL DEFAULT 'razorpay',
    payment_id TEXT,
    order_id TEXT,
    signature TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'success', 'failed', 'refunded')),
    payment_method TEXT,
    description TEXT,
    metadata JSONB,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_transactions_user ON public.payment_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON public.payment_transactions(status);

-- 4.3 SUBSCRIPTION PLANS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.subscription_plans (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    plan_id VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    plan_type TEXT NOT NULL CHECK (plan_type IN ('user', 'partner')),
    price DECIMAL(10, 2) NOT NULL,
    currency TEXT NOT NULL DEFAULT 'INR',
    duration_days INTEGER NOT NULL DEFAULT 30,
    features JSONB,
    unlocks_included INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    is_popular BOOLEAN DEFAULT FALSE,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- SECTION 5: NOTIFICATIONS
-- ============================================================

-- 5.1 NOTIFICATIONS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    notification_type TEXT NOT NULL DEFAULT 'general',
    action_type TEXT,
    action_id UUID,
    action_data JSONB,
    image_url TEXT,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    is_pushed BOOLEAN DEFAULT FALSE,
    pushed_at TIMESTAMP WITH TIME ZONE,
    read_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON public.notifications(created_at DESC);

-- 5.2 USER DEVICES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_devices (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    device_id VARCHAR(255),
    fcm_token TEXT NOT NULL,
    device_type TEXT NOT NULL CHECK (device_type IN ('android', 'ios', 'web')),
    device_name VARCHAR(255),
    device_model VARCHAR(255),
    os_version VARCHAR(50),
    app_version VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, device_type, device_id)
);

CREATE INDEX IF NOT EXISTS idx_devices_user ON public.user_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_devices_token ON public.user_devices(fcm_token);

-- ============================================================
-- SECTION 6: ANALYTICS & METRICS
-- ============================================================

-- 6.1 SEARCH LOGS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.search_logs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id),
    query TEXT NOT NULL,
    city TEXT,
    category_id UUID REFERENCES public.categories(id),
    results_count INTEGER DEFAULT 0,
    matched_professional_ids UUID[] DEFAULT '{}',
    source TEXT DEFAULT 'search' CHECK (source IN ('search', 'ai_chat', 'category')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_search_logs_user ON public.search_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_search_logs_date ON public.search_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_search_logs_city ON public.search_logs(city);

-- 6.2 AI CHAT LOGS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.ai_chat_logs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id),
    session_id UUID NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    matched_professionals UUID[],
    tokens_used INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_chat_session ON public.ai_chat_logs(session_id);
CREATE INDEX IF NOT EXISTS idx_ai_chat_user ON public.ai_chat_logs(user_id);

-- 6.3 AI USAGE TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.ai_usage (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    usage_date DATE NOT NULL DEFAULT CURRENT_DATE,
    request_count INTEGER NOT NULL DEFAULT 0,
    last_request_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, usage_date)
);

CREATE INDEX IF NOT EXISTS idx_ai_usage_user ON public.ai_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_usage_date ON public.ai_usage(usage_date);

-- 6.4 EVENTS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.events (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id),
    event_type TEXT NOT NULL,
    event_data JSONB DEFAULT '{}'::jsonb,
    session_id TEXT,
    device_info JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_events_type ON public.events(event_type);
CREATE INDEX IF NOT EXISTS idx_events_user ON public.events(user_id);
CREATE INDEX IF NOT EXISTS idx_events_date ON public.events(created_at DESC);

-- 6.5 USER ACTIVITY TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_activity (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    activity_date DATE NOT NULL DEFAULT CURRENT_DATE,
    actions_count INTEGER DEFAULT 1,
    session_duration_seconds INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, activity_date)
);

CREATE INDEX IF NOT EXISTS idx_user_activity_date ON public.user_activity(activity_date);
CREATE INDEX IF NOT EXISTS idx_user_activity_user ON public.user_activity(user_id);

-- 6.6 USER COHORTS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_cohorts (
    user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    cohort_month DATE NOT NULL,
    city TEXT,
    acquisition_channel TEXT DEFAULT 'organic'
);

CREATE INDEX IF NOT EXISTS idx_cohorts_month ON public.user_cohorts(cohort_month);

-- 6.7 DAILY METRICS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.daily_metrics (
    metric_date DATE PRIMARY KEY,
    total_users INTEGER DEFAULT 0,
    active_users INTEGER DEFAULT 0,
    new_signups INTEGER DEFAULT 0,
    paying_users INTEGER DEFAULT 0,
    mrr DECIMAL(10,2) DEFAULT 0,
    total_searches INTEGER DEFAULT 0,
    total_messages INTEGER DEFAULT 0,
    total_unlocks INTEGER DEFAULT 0,
    total_referrals INTEGER DEFAULT 0,
    total_ai_requests INTEGER DEFAULT 0,
    k_factor DECIMAL(5,2) DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6.8 METRIC SNAPSHOTS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.metric_snapshots (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    snapshot_date DATE NOT NULL,
    snapshot_type TEXT NOT NULL CHECK (snapshot_type IN ('daily', 'weekly', 'monthly')),
    total_users INTEGER DEFAULT 0,
    dau INTEGER DEFAULT 0,
    wau INTEGER DEFAULT 0,
    mau INTEGER DEFAULT 0,
    dau_mau_ratio DECIMAL(5,2),
    mrr DECIMAL(10,2) DEFAULT 0,
    arr DECIMAL(12,2) DEFAULT 0,
    new_mrr DECIMAL(10,2) DEFAULT 0,
    churned_mrr DECIMAL(10,2) DEFAULT 0,
    signups INTEGER DEFAULT 0,
    activations INTEGER DEFAULT 0,
    conversions INTEGER DEFAULT 0,
    churn INTEGER DEFAULT 0,
    searches INTEGER DEFAULT 0,
    unlocks INTEGER DEFAULT 0,
    messages INTEGER DEFAULT 0,
    ai_requests INTEGER DEFAULT 0,
    referrals_sent INTEGER DEFAULT 0,
    referrals_converted INTEGER DEFAULT 0,
    k_factor DECIMAL(5,2),
    total_partners INTEGER DEFAULT 0,
    active_partners INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(snapshot_date, snapshot_type)
);

CREATE INDEX IF NOT EXISTS idx_snapshots_date ON public.metric_snapshots(snapshot_date);
CREATE INDEX IF NOT EXISTS idx_snapshots_type ON public.metric_snapshots(snapshot_type);

-- 6.9 REFERRAL METRICS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.referral_metrics (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    metric_date DATE NOT NULL UNIQUE,
    total_users INTEGER DEFAULT 0,
    users_who_referred INTEGER DEFAULT 0,
    total_referrals_sent INTEGER DEFAULT 0,
    successful_referrals INTEGER DEFAULT 0,
    avg_invites_per_user DECIMAL(5,2) DEFAULT 0,
    referral_conversion_rate DECIMAL(5,2) DEFAULT 0,
    k_factor DECIMAL(5,2) DEFAULT 0,
    referral_ltv DECIMAL(10,2) DEFAULT 0,
    organic_ltv DECIMAL(10,2) DEFAULT 0,
    total_rewards_given INTEGER DEFAULT 0,
    reward_cost DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_referral_metrics_date ON public.referral_metrics(metric_date);

-- 6.10 GEOGRAPHIC METRICS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.geographic_metrics (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    metric_date DATE NOT NULL,
    city VARCHAR(100) NOT NULL,
    total_users INTEGER DEFAULT 0,
    new_users INTEGER DEFAULT 0,
    active_users INTEGER DEFAULT 0,
    paying_users INTEGER DEFAULT 0,
    total_partners INTEGER DEFAULT 0,
    active_partners INTEGER DEFAULT 0,
    verified_partners INTEGER DEFAULT 0,
    searches INTEGER DEFAULT 0,
    unlocks INTEGER DEFAULT 0,
    messages INTEGER DEFAULT 0,
    supply_demand_ratio DECIMAL(5,2),
    mrr DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(metric_date, city)
);

CREATE INDEX IF NOT EXISTS idx_geographic_date ON public.geographic_metrics(metric_date);
CREATE INDEX IF NOT EXISTS idx_geographic_city ON public.geographic_metrics(city);

-- ============================================================
-- SECTION 7: FUNCTIONS
-- ============================================================

-- 7.1 Update Timestamp Function
-- ============================================================
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7.2 Generate Referral Code Function
-- ============================================================
CREATE OR REPLACE FUNCTION public.generate_referral_code(length INTEGER DEFAULT 8)
RETURNS VARCHAR AS $$
DECLARE
    chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    result VARCHAR := '';
    i INTEGER;
BEGIN
    FOR i IN 1..length LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::INTEGER, 1);
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- 7.3 Assign Referral Code Function
-- ============================================================
CREATE OR REPLACE FUNCTION public.assign_referral_code()
RETURNS TRIGGER AS $$
DECLARE
    new_code VARCHAR(10);
    code_exists BOOLEAN;
BEGIN
    IF NEW.referral_code IS NULL THEN
        LOOP
            new_code := public.generate_referral_code(8);
            SELECT EXISTS(SELECT 1 FROM public.users WHERE referral_code = new_code) INTO code_exists;
            EXIT WHEN NOT code_exists;
        END LOOP;
        NEW.referral_code := new_code;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7.4 Handle New User Function
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, name, role, city)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'role', 'user'),
        COALESCE(NEW.raw_user_meta_data->>'city', 'Shillong')
    );
    
    -- Create professional profile if partner
    IF NEW.raw_user_meta_data->>'role' = 'partner' THEN
        INSERT INTO public.professionals (user_id, display_name, profession, city)
        VALUES (
            NEW.id,
            COALESCE(NEW.raw_user_meta_data->>'name', 'Professional'),
            COALESCE(NEW.raw_user_meta_data->>'profession', 'Not specified'),
            COALESCE(NEW.raw_user_meta_data->>'city', 'Shillong')
        );
    END IF;
    
    -- Add to cohort
    INSERT INTO public.user_cohorts (user_id, cohort_month, city, acquisition_channel)
    VALUES (
        NEW.id,
        DATE_TRUNC('month', NOW()),
        COALESCE(NEW.raw_user_meta_data->>'city', 'Shillong'),
        COALESCE(NEW.raw_user_meta_data->>'channel', 'organic')
    );
    
    -- Track signup event
    INSERT INTO public.events (user_id, event_type, event_data)
    VALUES (NEW.id, 'signup', jsonb_build_object(
        'role', COALESCE(NEW.raw_user_meta_data->>'role', 'user'),
        'email', NEW.email
    ));
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7.5 Decrement User Unlocks Function
-- ============================================================
CREATE OR REPLACE FUNCTION public.decrement_user_unlocks(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    remaining INTEGER;
BEGIN
    UPDATE public.users
    SET unlocks_remaining = unlocks_remaining - 1,
        updated_at = NOW()
    WHERE id = p_user_id AND unlocks_remaining > 0
    RETURNING unlocks_remaining INTO remaining;
    
    RETURN COALESCE(remaining, 0);
END;
$$ LANGUAGE plpgsql;

-- 7.6 Increment Search Appearances Function
-- ============================================================
CREATE OR REPLACE FUNCTION public.increment_search_appearances(professional_ids UUID[])
RETURNS VOID AS $$
BEGIN
    UPDATE public.professionals
    SET search_appearances = search_appearances + 1
    WHERE id = ANY(professional_ids);
END;
$$ LANGUAGE plpgsql;

-- 7.7 Increment Profile Views Function
-- ============================================================
CREATE OR REPLACE FUNCTION public.increment_profile_views(p_professional_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE public.professionals 
    SET profile_views = profile_views + 1
    WHERE id = p_professional_id;
END;
$$ LANGUAGE plpgsql;

-- 7.8 Update Conversation on Message Function
-- ============================================================
CREATE OR REPLACE FUNCTION public.update_conversation_on_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.conversations
    SET 
        last_message_at = NEW.created_at,
        last_message_preview = LEFT(NEW.content, 100),
        user_unread_count = CASE 
            WHEN NEW.sender_type = 'professional' THEN user_unread_count + 1 
            ELSE user_unread_count 
        END,
        professional_unread_count = CASE 
            WHEN NEW.sender_type = 'user' THEN professional_unread_count + 1 
            ELSE professional_unread_count 
        END
    WHERE id = NEW.conversation_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7.9 Process Referral Reward Function
-- ============================================================
CREATE OR REPLACE FUNCTION public.process_referral_reward(p_referral_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_referral RECORD;
    v_referrer_reward INTEGER := 2;
    v_referee_reward INTEGER := 1;
BEGIN
    SELECT * INTO v_referral FROM public.referrals WHERE id = p_referral_id AND status = 'completed';
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Get settings
    SELECT setting_value::INTEGER INTO v_referrer_reward 
    FROM public.referral_settings WHERE setting_key = 'referrer_reward_unlocks';
    
    SELECT setting_value::INTEGER INTO v_referee_reward 
    FROM public.referral_settings WHERE setting_key = 'referee_reward_unlocks';
    
    v_referrer_reward := COALESCE(v_referrer_reward, 2);
    v_referee_reward := COALESCE(v_referee_reward, 1);
    
    -- Award referrer
    UPDATE public.users 
    SET unlocks_remaining = unlocks_remaining + v_referrer_reward,
        total_referrals = total_referrals + 1,
        referral_earnings = referral_earnings + v_referrer_reward,
        updated_at = NOW()
    WHERE id = v_referral.referrer_id;
    
    -- Award referee
    UPDATE public.users 
    SET unlocks_remaining = unlocks_remaining + v_referee_reward,
        signup_reward_claimed = TRUE,
        updated_at = NOW()
    WHERE id = v_referral.referee_id;
    
    -- Update referral
    UPDATE public.referrals 
    SET status = 'rewarded',
        referrer_reward_type = 'unlocks',
        referrer_reward_amount = v_referrer_reward,
        referee_reward_type = 'unlocks',
        referee_reward_amount = v_referee_reward,
        referrer_rewarded_at = NOW(),
        referee_rewarded_at = NOW()
    WHERE id = p_referral_id;
    
    -- Record rewards
    INSERT INTO public.rewards_history (user_id, reward_type, reward_source, source_id, description, unlocks_awarded)
    VALUES 
        (v_referral.referrer_id, 'referral_bonus', 'referral', p_referral_id, 'Referral reward', v_referrer_reward),
        (v_referral.referee_id, 'signup_bonus', 'referral', p_referral_id, 'Signup with referral bonus', v_referee_reward);
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- 7.10 Redeem Coupon Function
-- ============================================================
CREATE OR REPLACE FUNCTION public.redeem_coupon(p_user_id UUID, p_coupon_code VARCHAR)
RETURNS JSON AS $$
DECLARE
    v_coupon RECORD;
    v_user_redemption_count INTEGER;
BEGIN
    SELECT * INTO v_coupon FROM public.coupons 
    WHERE code = UPPER(p_coupon_code) 
    AND is_active = TRUE
    AND (valid_from IS NULL OR valid_from <= NOW())
    AND (valid_until IS NULL OR valid_until >= NOW());
    
    IF NOT FOUND THEN
        RETURN json_build_object('success', FALSE, 'error', 'Invalid or expired coupon code');
    END IF;
    
    IF v_coupon.max_uses IS NOT NULL AND v_coupon.used_count >= v_coupon.max_uses THEN
        RETURN json_build_object('success', FALSE, 'error', 'Coupon has reached maximum redemptions');
    END IF;
    
    SELECT COUNT(*) INTO v_user_redemption_count 
    FROM public.coupon_redemptions 
    WHERE coupon_id = v_coupon.id AND user_id = p_user_id;
    
    IF v_user_redemption_count >= v_coupon.max_uses_per_user THEN
        RETURN json_build_object('success', FALSE, 'error', 'You have already used this coupon');
    END IF;
    
    -- Apply reward
    IF v_coupon.coupon_type IN ('free_unlocks', 'signup_bonus') THEN
        UPDATE public.users 
        SET unlocks_remaining = unlocks_remaining + v_coupon.reward_value::INTEGER,
            updated_at = NOW()
        WHERE id = p_user_id;
    END IF;
    
    -- Record redemption
    INSERT INTO public.coupon_redemptions (coupon_id, user_id, coupon_code, reward_type, reward_value)
    VALUES (v_coupon.id, p_user_id, v_coupon.code, v_coupon.coupon_type, v_coupon.reward_value);
    
    -- Update coupon
    UPDATE public.coupons SET used_count = used_count + 1, updated_at = NOW() WHERE id = v_coupon.id;
    
    -- Record reward
    INSERT INTO public.rewards_history (user_id, reward_type, reward_source, source_id, description, unlocks_awarded)
    VALUES (p_user_id, 'coupon_redemption', 'coupon', v_coupon.id, 'Coupon: ' || v_coupon.code, 
            CASE WHEN v_coupon.coupon_type IN ('free_unlocks', 'signup_bonus') THEN v_coupon.reward_value::INTEGER ELSE 0 END);
    
    RETURN json_build_object(
        'success', TRUE, 
        'reward_type', v_coupon.coupon_type,
        'reward_value', v_coupon.reward_value,
        'message', 'Coupon redeemed successfully!'
    );
END;
$$ LANGUAGE plpgsql;

-- 7.11 Track User Activity Function
-- ============================================================
CREATE OR REPLACE FUNCTION public.track_user_activity()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.user_id IS NOT NULL THEN
        INSERT INTO public.user_activity (user_id, activity_date)
        VALUES (NEW.user_id, CURRENT_DATE)
        ON CONFLICT (user_id, activity_date) 
        DO UPDATE SET actions_count = public.user_activity.actions_count + 1;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7.12 Check AI Usage Limit Function
-- ============================================================
CREATE OR REPLACE FUNCTION public.check_ai_usage_limit(
    p_user_id UUID,
    p_daily_limit INTEGER DEFAULT 3
)
RETURNS JSON AS $$
DECLARE
    v_user RECORD;
    v_usage RECORD;
    v_is_paid BOOLEAN;
    v_remaining INTEGER;
    v_can_use BOOLEAN;
BEGIN
    -- Get user subscription plan
    SELECT subscription_plan, role INTO v_user
    FROM public.users
    WHERE id = p_user_id;

    IF NOT FOUND THEN
        RETURN json_build_object(
            'canUse', FALSE,
            'remaining', 0,
            'limit', p_daily_limit,
            'isPaid', FALSE,
            'error', 'User not found'
        );
    END IF;

    -- Check if user is on paid plan (user or partner)
    v_is_paid := v_user.subscription_plan IN ('basic', 'plus', 'pro', 'starter', 'business');

    -- Paid users have unlimited access
    IF v_is_paid THEN
        RETURN json_build_object(
            'canUse', TRUE,
            'remaining', -1,
            'limit', -1,
            'isPaid', TRUE,
            'error', NULL
        );
    END IF;

    -- Get today's usage for free users
    SELECT request_count INTO v_usage
    FROM public.ai_usage
    WHERE user_id = p_user_id AND usage_date = CURRENT_DATE;

    IF NOT FOUND THEN
        -- No usage today
        v_remaining := p_daily_limit;
        v_can_use := TRUE;
    ELSE
        v_remaining := GREATEST(0, p_daily_limit - v_usage.request_count);
        v_can_use := v_remaining > 0;
    END IF;

    RETURN json_build_object(
        'canUse', v_can_use,
        'remaining', v_remaining,
        'limit', p_daily_limit,
        'isPaid', FALSE,
        'error', CASE WHEN NOT v_can_use THEN 'Daily AI chat limit reached' ELSE NULL END
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7.13 Increment AI Usage Function
-- ============================================================
CREATE OR REPLACE FUNCTION public.increment_ai_usage(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    v_new_count INTEGER;
BEGIN
    -- Upsert usage record
    INSERT INTO public.ai_usage (user_id, usage_date, request_count, last_request_at)
    VALUES (p_user_id, CURRENT_DATE, 1, NOW())
    ON CONFLICT (user_id, usage_date)
    DO UPDATE SET 
        request_count = public.ai_usage.request_count + 1,
        last_request_at = NOW(),
        updated_at = NOW()
    RETURNING request_count INTO v_new_count;

    RETURN json_build_object(
        'success', TRUE,
        'newCount', v_new_count,
        'date', CURRENT_DATE
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7.14 Get AI Usage Stats Function
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_ai_usage_stats(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    v_today INTEGER;
    v_this_week INTEGER;
    v_this_month INTEGER;
    v_total INTEGER;
BEGIN
    -- Today's usage
    SELECT COALESCE(request_count, 0) INTO v_today
    FROM public.ai_usage
    WHERE user_id = p_user_id AND usage_date = CURRENT_DATE;

    -- This week
    SELECT COALESCE(SUM(request_count), 0) INTO v_this_week
    FROM public.ai_usage
    WHERE user_id = p_user_id 
    AND usage_date >= DATE_TRUNC('week', CURRENT_DATE);

    -- This month
    SELECT COALESCE(SUM(request_count), 0) INTO v_this_month
    FROM public.ai_usage
    WHERE user_id = p_user_id 
    AND usage_date >= DATE_TRUNC('month', CURRENT_DATE);

    -- Total
    SELECT COALESCE(SUM(request_count), 0) INTO v_total
    FROM public.ai_usage
    WHERE user_id = p_user_id;

    RETURN json_build_object(
        'today', COALESCE(v_today, 0),
        'thisWeek', v_this_week,
        'thisMonth', v_this_month,
        'total', v_total
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- SECTION 7.15: NEW RPC FUNCTIONS (MISSING FUNCTIONS ADDED)
-- ============================================================

-- 7.15 Search Professionals Function
-- ============================================================
CREATE OR REPLACE FUNCTION public.search_professionals(search_term TEXT)
RETURNS SETOF public.professionals AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM public.professionals
    WHERE is_available = TRUE
    AND (
        display_name ILIKE '%' || search_term || '%'
        OR profession ILIKE '%' || search_term || '%'
        OR description ILIKE '%' || search_term || '%'
        OR services::TEXT ILIKE '%' || search_term || '%'
        OR area ILIKE '%' || search_term || '%'
    )
    ORDER BY is_featured DESC, rating DESC, total_reviews DESC
    LIMIT 50;
END;
$$ LANGUAGE plpgsql;

-- 7.16 Search Items Function
-- ============================================================
CREATE OR REPLACE FUNCTION public.search_items(search_term TEXT)
RETURNS SETOF public.items AS $$
BEGIN
    RETURN QUERY
    SELECT i.* FROM public.items i
    JOIN public.shops s ON i.shop_id = s.id
    WHERE i.is_active = TRUE
    AND s.is_active = TRUE
    AND (
        i.name ILIKE '%' || search_term || '%'
        OR i.description ILIKE '%' || search_term || '%'
        OR search_term = ANY(i.tags)
    )
    ORDER BY i.is_featured DESC, i.display_order
    LIMIT 50;
END;
$$ LANGUAGE plpgsql;

-- 7.17 Get Featured Items Function
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_featured_items(p_city TEXT DEFAULT NULL)
RETURNS TABLE (
    id UUID,
    shop_id UUID,
    name TEXT,
    description TEXT,
    image_url TEXT,
    price DECIMAL,
    price_unit TEXT,
    tags TEXT[],
    is_active BOOLEAN,
    is_featured BOOLEAN,
    display_order INTEGER,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    shop_name TEXT,
    shop_city TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        i.id,
        i.shop_id,
        i.name,
        i.description,
        i.image_url,
        i.price,
        i.price_unit,
        i.tags,
        i.is_active,
        i.is_featured,
        i.display_order,
        i.created_at,
        i.updated_at,
        s.name AS shop_name,
        s.city AS shop_city
    FROM public.items i
    JOIN public.shops s ON i.shop_id = s.id
    WHERE i.is_featured = TRUE 
    AND i.is_active = TRUE
    AND s.is_active = TRUE
    AND (p_city IS NULL OR p_city = '' OR s.city ILIKE '%' || p_city || '%')
    ORDER BY i.display_order, i.created_at DESC
    LIMIT 20;
END;
$$ LANGUAGE plpgsql;

-- 7.18 Get or Create Conversation Function
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_or_create_conversation(
    p_user_id UUID,
    p_professional_id UUID
)
RETURNS SETOF public.conversations AS $$
DECLARE
    v_conversation_id UUID;
    v_is_unlocked BOOLEAN;
BEGIN
    -- Check if user has unlocked the professional
    SELECT EXISTS(
        SELECT 1 FROM public.user_unlocks 
        WHERE user_id = p_user_id 
        AND professional_id = p_professional_id
        AND is_active = TRUE
    ) INTO v_is_unlocked;

    -- Check if conversation exists
    SELECT id INTO v_conversation_id
    FROM public.conversations
    WHERE user_id = p_user_id AND professional_id = p_professional_id;
    
    -- Create if not exists
    IF v_conversation_id IS NULL THEN
        INSERT INTO public.conversations (user_id, professional_id, is_unlocked)
        VALUES (p_user_id, p_professional_id, v_is_unlocked)
        RETURNING id INTO v_conversation_id;
    ELSE
        -- Update unlock status if changed
        UPDATE public.conversations
        SET is_unlocked = v_is_unlocked
        WHERE id = v_conversation_id AND is_unlocked != v_is_unlocked;
    END IF;
    
    RETURN QUERY
    SELECT c.* FROM public.conversations c WHERE c.id = v_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7.19 Send Message Function
-- ============================================================
CREATE OR REPLACE FUNCTION public.send_message(
    p_conversation_id UUID,
    p_sender_id UUID,
    p_sender_type TEXT,
    p_content TEXT
)
RETURNS SETOF public.messages AS $$
DECLARE
    v_message_id UUID;
    v_professional_id UUID;
BEGIN
    -- Insert the message
    INSERT INTO public.messages (conversation_id, sender_id, sender_type, content)
    VALUES (p_conversation_id, p_sender_id, p_sender_type, p_content)
    RETURNING id INTO v_message_id;
    
    -- Update professional's total_messages count
    SELECT professional_id INTO v_professional_id
    FROM public.conversations WHERE id = p_conversation_id;
    
    IF v_professional_id IS NOT NULL THEN
        UPDATE public.professionals
        SET total_messages = total_messages + 1
        WHERE id = v_professional_id;
    END IF;
    
    RETURN QUERY
    SELECT * FROM public.messages WHERE id = v_message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7.20 Mark Messages as Read Function
-- ============================================================
CREATE OR REPLACE FUNCTION public.mark_as_read(
    p_conversation_id UUID,
    p_reader_type TEXT
)
RETURNS VOID AS $$
BEGIN
    -- Reset unread count for the reader
    IF p_reader_type = 'user' THEN
        UPDATE public.conversations
        SET user_unread_count = 0
        WHERE id = p_conversation_id;
    ELSIF p_reader_type = 'professional' THEN
        UPDATE public.conversations
        SET professional_unread_count = 0
        WHERE id = p_conversation_id;
    END IF;
    
    -- Mark individual messages as read
    UPDATE public.messages
    SET is_read = TRUE, read_at = NOW()
    WHERE conversation_id = p_conversation_id
    AND sender_type != p_reader_type
    AND is_read = FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7.21 Unlock Professional Function
-- ============================================================
CREATE OR REPLACE FUNCTION public.unlock_professional(
    p_user_id UUID,
    p_professional_id UUID
)
RETURNS JSON AS $$
DECLARE
    v_unlocks_remaining INTEGER;
    v_already_unlocked BOOLEAN;
BEGIN
    -- Check if already unlocked
    SELECT EXISTS(
        SELECT 1 FROM public.user_unlocks 
        WHERE user_id = p_user_id 
        AND professional_id = p_professional_id
        AND is_active = TRUE
    ) INTO v_already_unlocked;
    
    IF v_already_unlocked THEN
        RETURN json_build_object('success', TRUE, 'message', 'Already unlocked');
    END IF;

    -- Check user has unlocks remaining
    SELECT unlocks_remaining INTO v_unlocks_remaining
    FROM public.users WHERE id = p_user_id;
    
    IF v_unlocks_remaining IS NULL OR v_unlocks_remaining <= 0 THEN
        RETURN json_build_object('success', FALSE, 'error', 'No unlocks remaining');
    END IF;
    
    -- Create unlock record
    INSERT INTO public.user_unlocks (user_id, professional_id)
    VALUES (p_user_id, p_professional_id)
    ON CONFLICT (user_id, professional_id) 
    DO UPDATE SET is_active = TRUE, unlocked_at = NOW();
    
    -- Decrement user unlocks
    UPDATE public.users
    SET unlocks_remaining = unlocks_remaining - 1,
        updated_at = NOW()
    WHERE id = p_user_id;
    
    -- Update conversation unlock status if exists
    UPDATE public.conversations
    SET is_unlocked = TRUE
    WHERE user_id = p_user_id AND professional_id = p_professional_id;
    
    RETURN json_build_object('success', TRUE, 'message', 'Professional unlocked successfully');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7.22 Get Partner Dashboard Stats Function
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_partner_dashboard_stats(p_professional_id UUID)
RETURNS JSON AS $$
DECLARE
    v_stats JSON;
    v_today_views INTEGER;
    v_week_views INTEGER;
    v_total_conversations INTEGER;
    v_active_conversations INTEGER;
BEGIN
    -- Get today's profile views (approximate from events if available)
    SELECT COUNT(*) INTO v_today_views
    FROM public.events
    WHERE event_type = 'profile_view'
    AND event_data->>'professional_id' = p_professional_id::TEXT
    AND created_at >= CURRENT_DATE;

    -- Get this week's views
    SELECT COUNT(*) INTO v_week_views
    FROM public.events
    WHERE event_type = 'profile_view'
    AND event_data->>'professional_id' = p_professional_id::TEXT
    AND created_at >= DATE_TRUNC('week', CURRENT_DATE);

    -- Get conversation counts
    SELECT COUNT(*) INTO v_total_conversations
    FROM public.conversations
    WHERE professional_id = p_professional_id;

    SELECT COUNT(*) INTO v_active_conversations
    FROM public.conversations
    WHERE professional_id = p_professional_id
    AND last_message_at >= NOW() - INTERVAL '7 days';

    SELECT json_build_object(
        'profile_views', COALESCE(p.profile_views, 0),
        'search_appearances', COALESCE(p.search_appearances, 0),
        'total_messages', COALESCE(p.total_messages, 0),
        'rating', COALESCE(p.rating, 0),
        'total_reviews', COALESCE(p.total_reviews, 0),
        'response_rate', COALESCE(p.response_rate, 0),
        'avg_response_time', p.avg_response_time,
        'is_verified', COALESCE(p.is_verified, FALSE),
        'subscription_plan', p.subscription_plan,
        'today_views', COALESCE(v_today_views, 0),
        'week_views', COALESCE(v_week_views, 0),
        'total_conversations', COALESCE(v_total_conversations, 0),
        'active_conversations', COALESCE(v_active_conversations, 0)
    ) INTO v_stats
    FROM public.professionals p
    WHERE p.id = p_professional_id;
    
    RETURN COALESCE(v_stats, '{}'::JSON);
END;
$$ LANGUAGE plpgsql;

-- 7.23 Get Total Unread Count Function
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_total_unread_count(
    p_user_id UUID,
    p_user_type TEXT
)
RETURNS INTEGER AS $$
DECLARE
    v_message_count INTEGER := 0;
    v_notification_count INTEGER := 0;
BEGIN
    -- Get unread messages
    IF p_user_type = 'professional' THEN
        SELECT COALESCE(SUM(professional_unread_count), 0) INTO v_message_count
        FROM public.conversations
        WHERE professional_id = p_user_id;
    ELSE
        SELECT COALESCE(SUM(user_unread_count), 0) INTO v_message_count
        FROM public.conversations
        WHERE user_id = p_user_id;
    END IF;
    
    -- Get unread notifications
    SELECT COUNT(*) INTO v_notification_count
    FROM public.notifications
    WHERE user_id = p_user_id AND is_read = FALSE;
    
    RETURN v_message_count + v_notification_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- SECTION 8: TRIGGERS
-- ============================================================

-- Drop existing triggers first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS trigger_assign_referral_code ON public.users;
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
DROP TRIGGER IF EXISTS update_professionals_updated_at ON public.professionals;
DROP TRIGGER IF EXISTS update_shops_updated_at ON public.shops;
DROP TRIGGER IF EXISTS update_items_updated_at ON public.items;
DROP TRIGGER IF EXISTS update_settings_updated_at ON public.settings;
DROP TRIGGER IF EXISTS on_message_created ON public.messages;
DROP TRIGGER IF EXISTS trigger_activity_on_event ON public.events;

-- Create triggers
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE TRIGGER trigger_assign_referral_code
    BEFORE INSERT ON public.users
    FOR EACH ROW EXECUTE FUNCTION public.assign_referral_code();

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_professionals_updated_at
    BEFORE UPDATE ON public.professionals
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_shops_updated_at
    BEFORE UPDATE ON public.shops
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_items_updated_at
    BEFORE UPDATE ON public.items
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_settings_updated_at
    BEFORE UPDATE ON public.settings
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER on_message_created
    AFTER INSERT ON public.messages
    FOR EACH ROW EXECUTE FUNCTION public.update_conversation_on_message();

CREATE TRIGGER trigger_activity_on_event
    AFTER INSERT ON public.events
    FOR EACH ROW EXECUTE FUNCTION public.track_user_activity();

-- ============================================================
-- SECTION 9: VIEWS
-- ============================================================

-- 9.1 VC Dashboard View
-- ============================================================
CREATE OR REPLACE VIEW public.v_vc_dashboard AS
SELECT 
    (SELECT COUNT(*) FROM public.users) AS total_users,
    (SELECT COUNT(*) FROM public.users WHERE role = 'user') AS customers,
    (SELECT COUNT(*) FROM public.professionals) AS partners,
    (SELECT COUNT(DISTINCT user_id) FROM public.user_activity WHERE activity_date = CURRENT_DATE) AS dau,
    (SELECT COUNT(DISTINCT user_id) FROM public.user_activity WHERE activity_date >= CURRENT_DATE - 6) AS wau,
    (SELECT COUNT(DISTINCT user_id) FROM public.user_activity WHERE activity_date >= CURRENT_DATE - 29) AS mau,
    (SELECT COALESCE(SUM(
        CASE subscription_plan WHEN 'basic' THEN 99 WHEN 'plus' THEN 199 WHEN 'pro' THEN 299 ELSE 0 END
    ), 0) FROM public.users WHERE subscription_plan != 'free') AS user_mrr,
    (SELECT COALESCE(SUM(
        CASE subscription_plan WHEN 'starter' THEN 199 WHEN 'business' THEN 499 ELSE 0 END
    ), 0) FROM public.professionals WHERE subscription_plan != 'free') AS partner_mrr,
    (SELECT COUNT(*) FROM public.users WHERE subscription_plan != 'free') AS paying_users,
    (SELECT COUNT(*) FROM public.referrals WHERE status = 'rewarded') AS successful_referrals,
    (SELECT COALESCE(SUM(request_count), 0) FROM public.ai_usage WHERE usage_date = CURRENT_DATE) AS ai_requests_today;

-- 9.2 Referral Tree View
-- ============================================================
CREATE OR REPLACE VIEW public.v_referral_tree AS
SELECT 
    r.id,
    r.referrer_id,
    referrer.name AS referrer_name,
    referrer.email AS referrer_email,
    referrer.referral_code AS referrer_code,
    referrer.total_referrals,
    r.referee_id,
    referee.name AS referee_name,
    referee.email AS referee_email,
    r.status,
    r.referrer_reward_amount,
    r.referee_reward_amount,
    r.created_at,
    r.referrer_rewarded_at
FROM public.referrals r
JOIN public.users referrer ON r.referrer_id = referrer.id
JOIN public.users referee ON r.referee_id = referee.id
ORDER BY r.created_at DESC;

-- 9.3 Referral Leaderboard View
-- ============================================================
CREATE OR REPLACE VIEW public.v_referral_leaderboard AS
SELECT 
    u.id,
    u.name,
    u.email,
    u.referral_code,
    u.total_referrals,
    u.referral_earnings,
    u.created_at
FROM public.users u
WHERE u.total_referrals > 0
ORDER BY u.total_referrals DESC;

-- 9.4 Coupon Summary View
-- ============================================================
CREATE OR REPLACE VIEW public.v_coupon_summary AS
SELECT 
    c.id,
    c.code,
    c.description,
    c.coupon_type,
    c.reward_value,
    c.max_uses,
    c.used_count,
    c.is_active,
    c.valid_from,
    c.valid_until,
    CASE 
        WHEN c.valid_until IS NOT NULL AND c.valid_until < NOW() THEN 'expired'
        WHEN c.max_uses IS NOT NULL AND c.used_count >= c.max_uses THEN 'exhausted'
        WHEN c.is_active = FALSE THEN 'disabled'
        ELSE 'active'
    END AS status,
    c.created_at
FROM public.coupons c
ORDER BY c.created_at DESC;

-- 9.5 AI Usage Summary View
-- ============================================================
CREATE OR REPLACE VIEW public.v_ai_usage_summary AS
SELECT 
    u.id AS user_id,
    u.name,
    u.email,
    u.subscription_plan,
    COALESCE(au.request_count, 0) AS today_requests,
    CASE 
        WHEN u.subscription_plan IN ('basic', 'plus', 'pro', 'starter', 'business') THEN 'unlimited'
        ELSE (3 - COALESCE(au.request_count, 0))::TEXT
    END AS remaining_today,
    u.subscription_plan IN ('basic', 'plus', 'pro', 'starter', 'business') AS is_paid
FROM public.users u
LEFT JOIN public.ai_usage au ON u.id = au.user_id AND au.usage_date = CURRENT_DATE
ORDER BY COALESCE(au.request_count, 0) DESC;

-- ============================================================
-- SECTION 10: ROW LEVEL SECURITY
-- ============================================================

-- Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.professionals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_unlocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupon_redemptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rewards_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referral_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.search_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_chat_logs ENABLE ROW LEVEL SECURITY;

-- Users policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Enable insert for auth" ON public.users;
CREATE POLICY "Users can view own profile" ON public.users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Enable insert for auth" ON public.users FOR INSERT WITH CHECK (auth.uid() = id);

-- Categories (public read)
DROP POLICY IF EXISTS "Anyone can view categories" ON public.categories;
CREATE POLICY "Anyone can view categories" ON public.categories FOR SELECT USING (is_active = TRUE);

-- Professionals (public read active)
DROP POLICY IF EXISTS "Anyone can view active professionals" ON public.professionals;
DROP POLICY IF EXISTS "Users can manage own professional" ON public.professionals;
CREATE POLICY "Anyone can view active professionals" ON public.professionals FOR SELECT USING (is_available = TRUE);
CREATE POLICY "Users can manage own professional" ON public.professionals FOR ALL USING (user_id = auth.uid());

-- Shops
DROP POLICY IF EXISTS "Anyone can view active shops" ON public.shops;
DROP POLICY IF EXISTS "Professionals can manage own shop" ON public.shops;
CREATE POLICY "Anyone can view active shops" ON public.shops FOR SELECT USING (is_active = TRUE);
CREATE POLICY "Professionals can manage own shop" ON public.shops FOR ALL 
    USING (professional_id IN (SELECT id FROM public.professionals WHERE user_id = auth.uid()));

-- Items
DROP POLICY IF EXISTS "Anyone can view active items" ON public.items;
DROP POLICY IF EXISTS "Shop owners can manage items" ON public.items;
CREATE POLICY "Anyone can view active items" ON public.items FOR SELECT USING (is_active = TRUE);
CREATE POLICY "Shop owners can manage items" ON public.items FOR ALL 
    USING (shop_id IN (SELECT s.id FROM public.shops s JOIN public.professionals p ON s.professional_id = p.id WHERE p.user_id = auth.uid()));

-- Settings (public can read public settings)
DROP POLICY IF EXISTS "Anyone can view public settings" ON public.settings;
CREATE POLICY "Anyone can view public settings" ON public.settings FOR SELECT USING (is_public = TRUE);

-- Unlocks
DROP POLICY IF EXISTS "Users can view own unlocks" ON public.user_unlocks;
DROP POLICY IF EXISTS "Users can create unlocks" ON public.user_unlocks;
CREATE POLICY "Users can view own unlocks" ON public.user_unlocks FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can create unlocks" ON public.user_unlocks FOR INSERT WITH CHECK (user_id = auth.uid());

-- Conversations
DROP POLICY IF EXISTS "Users can view own conversations" ON public.conversations;
DROP POLICY IF EXISTS "Users can create conversations" ON public.conversations;
DROP POLICY IF EXISTS "Participants can update conversations" ON public.conversations;
CREATE POLICY "Users can view own conversations" ON public.conversations FOR SELECT 
    USING (user_id = auth.uid() OR professional_id IN (SELECT id FROM public.professionals WHERE user_id = auth.uid()));
CREATE POLICY "Users can create conversations" ON public.conversations FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Participants can update conversations" ON public.conversations FOR UPDATE 
    USING (user_id = auth.uid() OR professional_id IN (SELECT id FROM public.professionals WHERE user_id = auth.uid()));

-- Messages
DROP POLICY IF EXISTS "Participants can view messages" ON public.messages;
DROP POLICY IF EXISTS "Participants can send messages" ON public.messages;
CREATE POLICY "Participants can view messages" ON public.messages FOR SELECT 
    USING (conversation_id IN (SELECT id FROM public.conversations WHERE user_id = auth.uid() OR professional_id IN (SELECT id FROM public.professionals WHERE user_id = auth.uid())));
CREATE POLICY "Participants can send messages" ON public.messages FOR INSERT 
    WITH CHECK (conversation_id IN (SELECT id FROM public.conversations WHERE user_id = auth.uid() OR professional_id IN (SELECT id FROM public.professionals WHERE user_id = auth.uid())));

-- Reviews
DROP POLICY IF EXISTS "Anyone can view reviews" ON public.reviews;
DROP POLICY IF EXISTS "Users can create reviews" ON public.reviews;
CREATE POLICY "Anyone can view reviews" ON public.reviews FOR SELECT USING (is_visible = TRUE);
CREATE POLICY "Users can create reviews" ON public.reviews FOR INSERT WITH CHECK (user_id = auth.uid());

-- Referrals
DROP POLICY IF EXISTS "Users can view own referrals" ON public.referrals;
CREATE POLICY "Users can view own referrals" ON public.referrals FOR SELECT USING (referrer_id = auth.uid() OR referee_id = auth.uid());

-- Coupons (public read active)
DROP POLICY IF EXISTS "Anyone can view active coupons" ON public.coupons;
CREATE POLICY "Anyone can view active coupons" ON public.coupons FOR SELECT USING (is_active = TRUE);

-- Coupon redemptions
DROP POLICY IF EXISTS "Users can view own redemptions" ON public.coupon_redemptions;
CREATE POLICY "Users can view own redemptions" ON public.coupon_redemptions FOR SELECT USING (user_id = auth.uid());

-- Rewards
DROP POLICY IF EXISTS "Users can view own rewards" ON public.rewards_history;
CREATE POLICY "Users can view own rewards" ON public.rewards_history FOR SELECT USING (user_id = auth.uid());

-- Referral settings (public read)
DROP POLICY IF EXISTS "Anyone can view referral settings" ON public.referral_settings;
CREATE POLICY "Anyone can view referral settings" ON public.referral_settings FOR SELECT USING (TRUE);

-- Subscriptions
DROP POLICY IF EXISTS "Users can view own subscriptions" ON public.subscriptions;
CREATE POLICY "Users can view own subscriptions" ON public.subscriptions FOR SELECT USING (owner_id = auth.uid());

-- Notifications
DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
CREATE POLICY "Users can view own notifications" ON public.notifications FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can update own notifications" ON public.notifications FOR UPDATE USING (user_id = auth.uid());

-- Search logs
DROP POLICY IF EXISTS "Users can create search logs" ON public.search_logs;
DROP POLICY IF EXISTS "Users can view own searches" ON public.search_logs;
CREATE POLICY "Users can create search logs" ON public.search_logs FOR INSERT WITH CHECK (TRUE);
CREATE POLICY "Users can view own searches" ON public.search_logs FOR SELECT USING (user_id = auth.uid() OR user_id IS NULL);

-- Events
DROP POLICY IF EXISTS "Users can create events" ON public.events;
CREATE POLICY "Users can create events" ON public.events FOR INSERT WITH CHECK (TRUE);

-- AI Usage
DROP POLICY IF EXISTS "Users can view own AI usage" ON public.ai_usage;
DROP POLICY IF EXISTS "Users can insert own AI usage" ON public.ai_usage;
DROP POLICY IF EXISTS "Users can update own AI usage" ON public.ai_usage;
CREATE POLICY "Users can view own AI usage" ON public.ai_usage FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can insert own AI usage" ON public.ai_usage FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own AI usage" ON public.ai_usage FOR UPDATE USING (user_id = auth.uid());

-- AI Chat Logs
DROP POLICY IF EXISTS "Users can view own chat logs" ON public.ai_chat_logs;
DROP POLICY IF EXISTS "Users can create chat logs" ON public.ai_chat_logs;
CREATE POLICY "Users can view own chat logs" ON public.ai_chat_logs FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can create chat logs" ON public.ai_chat_logs FOR INSERT WITH CHECK (user_id = auth.uid() OR user_id IS NULL);

-- ============================================================
-- SECTION 11: SEED DATA
-- ============================================================

-- Categories
INSERT INTO public.categories (name, slug, icon_name, display_order) VALUES
    ('Electrician', 'electrician', 'flash', 1),
    ('Plumber', 'plumber', 'drop', 2),
    ('Carpenter', 'carpenter', 'ruler', 3),
    ('Painter', 'painter', 'brush', 4),
    ('AC Repair', 'ac-repair', 'wind', 5),
    ('Home Cleaning', 'cleaning', 'broom', 6),
    ('Tutoring', 'tutoring', 'book', 7),
    ('Beauty & Salon', 'beauty', 'scissor', 8),
    ('Mechanic', 'mechanic', 'car', 9),
    ('Legal Services', 'legal', 'briefcase', 10),
    ('Medical', 'medical', 'health', 11),
    ('IT & Tech', 'it-tech', 'cpu', 12),
    ('Photography', 'photography', 'camera', 13),
    ('Catering', 'catering', 'cooking', 14),
    ('Event Planning', 'event-planning', 'calendar', 15),
    ('Pest Control', 'pest-control', 'bug', 16)
ON CONFLICT (slug) DO NOTHING;

-- Subscription Plans
INSERT INTO public.subscription_plans (plan_id, name, description, plan_type, price, duration_days, unlocks_included, is_popular, display_order) VALUES
    ('user_free', 'Free', 'Basic access', 'user', 0, 36500, 0, FALSE, 1),
    ('user_basic', 'Basic', '3 unlocks/month', 'user', 99, 30, 3, FALSE, 2),
    ('user_plus', 'Plus', '8 unlocks/month', 'user', 199, 30, 8, TRUE, 3),
    ('user_pro', 'Pro', '15 unlocks/month', 'user', 499, 30, 15, FALSE, 4),
    ('partner_free', 'Free', 'Basic listing', 'partner', 0, 36500, 0, FALSE, 1),
    ('partner_starter', 'Starter', 'Read messages', 'partner', 199, 30, 0, FALSE, 2),
    ('partner_business', 'Business', 'Full features', 'partner', 499, 30, 0, TRUE, 3)
ON CONFLICT (plan_id) DO NOTHING;

-- Referral Settings
INSERT INTO public.referral_settings (setting_key, setting_value, description) VALUES
    ('referrer_reward_unlocks', '2', 'Unlocks given to referrer'),
    ('referee_reward_unlocks', '1', 'Unlocks given to new user'),
    ('signup_bonus_unlocks', '1', 'Bonus for new signups'),
    ('referral_program_active', 'true', 'Is referral program active'),
    ('max_referrals_per_user', '100', 'Max referrals per user'),
    ('free_ai_daily_limit', '3', 'Daily AI chat limit for free users'),
    ('paid_ai_daily_limit', '-1', 'Daily AI chat limit for paid users (-1 = unlimited)')
ON CONFLICT (setting_key) DO NOTHING;

-- App Settings (including Razorpay key)
INSERT INTO public.settings (key, value, description, is_public) VALUES
    ('razorpay_key_id', 'rzp_test_YOUR_KEY_HERE', 'Razorpay Public Key ID', TRUE),
    ('app_version', '1.0.0', 'Current app version', TRUE),
    ('maintenance_mode', 'false', 'Is app in maintenance mode', TRUE),
    ('min_app_version', '1.0.0', 'Minimum required app version', TRUE)
ON CONFLICT (key) DO NOTHING;

-- Sample Coupons
INSERT INTO public.coupons (code, description, coupon_type, reward_value, max_uses, is_active) VALUES
    ('WELCOME2024', 'Welcome bonus - 2 free unlocks', 'free_unlocks', 2, 1000, TRUE),
    ('LAUNCH50', 'Launch special - 5 free unlocks', 'free_unlocks', 5, 100, TRUE),
    ('FRIENDS3', 'Friend bonus - 3 unlocks', 'free_unlocks', 3, NULL, TRUE)
ON CONFLICT (code) DO NOTHING;

-- ============================================================
-- SECTION 12: ENABLE REALTIME
-- ============================================================

DO $$
BEGIN
    -- Add messages to realtime if not already added
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND tablename = 'messages'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
    END IF;

    -- Add conversations to realtime if not already added
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND tablename = 'conversations'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;
    END IF;

    -- Add notifications to realtime if not already added
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND tablename = 'notifications'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
    END IF;
END $$;

-- ============================================================
-- DONE! Your database is ready.
-- Version 1.2.0 - Fixed all missing RPC functions
-- ============================================================