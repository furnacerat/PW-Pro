-- Supabase / Postgres schema for PW Pro chemicals
-- Enables pgcrypto for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS public.chemicals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  short_description text,
  uses text,
  precautions text,
  mixing_note text,
  sds_url text,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_chemicals_name ON public.chemicals USING btree (lower(name));

-- Example insert (for reference; import JSON via Supabase UI or CLI for bulk data)
-- INSERT INTO public.chemicals (name, short_description, uses, precautions, mixing_note, sds_url)
-- VALUES ('Sodium Hypochlorite (Bleach)', 'Chlorine-based oxidizing bleach...', 'Mildew removal', 'Corrosive...', 'Dilute per label', NULL);
