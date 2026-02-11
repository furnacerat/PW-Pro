
-- Enable RLS on all tables
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE estimates ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE chemical_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE equipment ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_notes ENABLE ROW LEVEL SECURITY;

-- Clients
CREATE POLICY "Users can manage their own clients" ON clients
    FOR ALL
    USING (auth.uid() = user_id);

-- Jobs
CREATE POLICY "Users can manage their own jobs" ON jobs
    FOR ALL
    USING (auth.uid() = user_id);

-- Estimates
CREATE POLICY "Users can manage their own estimates" ON estimates
    FOR ALL
    USING (auth.uid() = user_id);

-- Invoices
CREATE POLICY "Users can manage their own invoices" ON invoices
    FOR ALL
    USING (auth.uid() = user_id);

-- Chemical Inventory
CREATE POLICY "Users can manage their own inventory" ON chemical_inventory
    FOR ALL
    USING (auth.uid() = user_id);

-- Equipment
CREATE POLICY "Users can manage their own equipment" ON equipment
    FOR ALL
    USING (auth.uid() = user_id);

-- Client Notes
CREATE POLICY "Users can manage their own notes" ON client_notes
    FOR ALL
    USING (auth.uid() = user_id);
