# Refactoring SchedulingManager

## Goal
Connect the `SchedulingManager` to Supabase to enable cloud persistence for Jobs. Currently, it uses local JSON storage.

## Changes

### 1. `SchedulingModels.swift`
-   **Modify `SchedulingManager`**:
    -   Remove `StorageManager` usage.
    -   Inject `SupabaseManager`.
    -   Implement `loadJobs()` using `await SupabaseManager.shared.fetchJobs()`.
    -   Implement `addJob()` using `await SupabaseManager.shared.insertJob()`.
-   **Data Mapping**:
    -   Convert `JobData` (Supabase) to `ScheduledJob` (Local UI Model).
    -   Note: `windSpeed` and `rainChance` are transient weather data and will be re-fetched/mocked on load.
    -   Note: `status` string from DB will map to `JobStatus` enum.

### 2. `SupabaseManager.swift`
-   Ensure `JobData` struct is public and accessible (it is).

## Verification
-   Run the app.
-   Create a Job.
-   Restart app.
-   Verify Job persists (via Supabase fetch).
