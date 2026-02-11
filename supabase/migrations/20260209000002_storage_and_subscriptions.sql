-- Storage Buckets
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('job-photos', 'job-photos', false) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('documents', 'documents', false) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('receipts', 'receipts', false) ON CONFLICT (id) DO NOTHING;

-- Storage Policies (RLS)

-- Avatars: Public read, Authenticated upload/update for own avatar
CREATE POLICY "Avatar images are publicly accessible." ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
CREATE POLICY "Users can upload their own avatar." ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid() = owner);
CREATE POLICY "Users can update their own avatar." ON storage.objects FOR UPDATE USING (bucket_id = 'avatars' AND auth.uid() = owner);

-- Job Photos: Authenticated read (if pro?), owner upload
CREATE POLICY "Job photos are accessible by authenticated users." ON storage.objects FOR SELECT USING (bucket_id = 'job-photos' AND auth.role() = 'authenticated');
CREATE POLICY "Users can upload job photos." ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'job-photos' AND auth.uid() = owner);
CREATE POLICY "Users can update own job photos." ON storage.objects FOR UPDATE USING (bucket_id = 'job-photos' AND auth.uid() = owner);

-- Documents: Owner only
CREATE POLICY "Users can view own documents." ON storage.objects FOR SELECT USING (bucket_id = 'documents' AND auth.uid() = owner);
CREATE POLICY "Users can upload own documents." ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'documents' AND auth.uid() = owner);

-- Receipts: Owner only
CREATE POLICY "Users can view own receipts." ON storage.objects FOR SELECT USING (bucket_id = 'receipts' AND auth.uid() = owner);
CREATE POLICY "Users can upload own receipts." ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'receipts' AND auth.uid() = owner);

-- Subscriptions Support
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS subscription_tier text DEFAULT 'free' CHECK (subscription_tier IN ('free', 'pro', 'enterprise')),
ADD COLUMN IF NOT EXISTS subscription_status text DEFAULT 'active' CHECK (subscription_status IN ('active', 'past_due', 'canceled', 'trialing')),
ADD COLUMN IF NOT EXISTS stripe_customer_id text,
ADD COLUMN IF NOT EXISTS current_period_end timestamptz;
