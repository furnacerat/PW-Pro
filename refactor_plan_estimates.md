# Refactoring EstimateManager

## Goal
Connect the `EstimateManager` to Supabase.

## Changes

### 1. `EstimateModels.swift`
-   **Modify `EstimateManager`**:
    -   Remove `UserDefaults` local storage.
    -   Inject `SupabaseManager`.
    -   Implement `fetchEstimates()` calling `supabase.fetchEstimates()`.
    -   Implement `saveEstimate()` calling `supabase.insertEstimate()`.
    -   Implement `updateStatus()` using `supabase.updateEstimate()`.
-   **Data Mapping**:
    -   `EstimateData` (Supabase) <-> `SavedEstimate` (Local).
    -   Need to handle the `items` array mapping (JSONB or separate table?).
    -   `EstimateData` struct in `SupabaseManager.swift` expects `items: [EstimateItemData]`. `SavedEstimate` uses `Estimate` struct which has `items: [EstimateItem]`.
    -   Need to map between `EstimateItemData` and `EstimateItem`.

## Verification
-   Create an Estimate in UI.
-   Check "Sent Estimates" list.
-   Verify persistence.
