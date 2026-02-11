-- Fix chemical_inventory table to match Swift model expectations
-- The Swift app expects: chemical_name, chemical_type, current_stock, min_stock_level, last_ordered
-- The DB currently has: chemical_id, quantity_on_hand, reorder_level, last_restocked

-- Add the missing columns the Swift model expects
ALTER TABLE public.chemical_inventory
ADD COLUMN IF NOT EXISTS chemical_name text,
ADD COLUMN IF NOT EXISTS chemical_type text DEFAULT 'general',
ADD COLUMN IF NOT EXISTS current_stock decimal(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS min_stock_level decimal(10,2),
ADD COLUMN IF NOT EXISTS last_ordered date;

-- Migrate data from old columns to new columns where possible
UPDATE public.chemical_inventory
SET current_stock = COALESCE(quantity_on_hand, 0),
    min_stock_level = reorder_level,
    last_ordered = last_restocked
WHERE current_stock IS NULL OR current_stock = 0;

-- Back-fill chemical_name from the chemicals reference table
UPDATE public.chemical_inventory ci
SET chemical_name = c.name
FROM public.chemicals c
WHERE ci.chemical_id = c.id
  AND ci.chemical_name IS NULL;
