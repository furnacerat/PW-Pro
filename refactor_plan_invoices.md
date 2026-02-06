# Refactoring InvoiceManager

## Goal
Connect the `InvoiceManager` to Supabase.

## Changes

### 1. `InvoiceModels.swift`
-   **Modify `InvoiceManager`**:
    -   Remove `StorageManager` / `invoices.json`.
    -   Inject `SupabaseManager`.
    -   Implement `fetchInvoices()` calling `supabase.fetchInvoices()`.
    -   Implement `createInvoice()` calling `supabase.insertInvoice()`.
-   **Data Mapping**:
    -   `InvoiceData` (Supabase) <-> `Invoice` (Local).
    -   Map `items` (array of structs) similarly to Estimates.

### 2. Business Settings
-   **Note**: `BusinessSettings` is currently local-only (`settings.json`).
-   **Plan**: For now, leave `BusinessSettings` as local (UserDefaults/JSON) but note it as a future task to move to a `profiles` table. The focus is on core data (Invoices).

## Verification
-   Create Invoice from Estimate.
-   Check "Invoices" list.
-   Verify persistence.
