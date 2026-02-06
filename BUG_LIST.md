# Bug List & Audit Findings

## Severity Levels
-   **Critical**: App is fundamentally broken or insecure. feature missing entirely.
-   **High**: Major feature malfunction or poor error handling.
-   **Medium**: UX issue or minor bug.
-   **Low**: Polish or optimization needed.

| Severity | Issue | Location | Fix Recommendation | Status |
| :--- | :--- | :--- | :--- | :--- |
| **CRITICAL** | **Backend Disconnection**: Jobs, Estimates, and Invoices use local JSON storage (`StorageManager`) and completely ignore Supabase backend, despite `SupabaseManager` logic existing. | `SchedulingModels.swift`, `EstimateModels.swift`, `InvoiceModels.swift` | Refactor Managers to call `SupabaseManager` methods instead of `StorageManager`. Map local Structs to `*Data` DTOs. | ✅ **FIXED** (Refactored Managers) |
| **High** | **Schema Mismatch**: Local `ScheduledJob` struct differs significantly from Supabase `JobData` struct (e.g. missing `price` in local, `windSpeed` not in DB). | `SchedulingModels.swift` vs `SupabaseManager.swift` | Align schemas. Local structs mapped to match Backend DTOs best-effort. | ✅ **ADDRESSED** |
| **High** | **Error Masking**: `ClientManager` (and likely others) swallows API errors and silently falls back to Mock Data. Users may think they are viewing real data. | `ClientManager.swift` | Remove automatic mock fallback in production. Show error UI to user. Only use mock if explicitly in "Demo Mode" or Preview. | ⚠️ Open |
| **Medium** | **Business Settings Local-Only**: Business logo and settings are stored locally in `settings.json`. Not synced across devices. | `InvoiceModels.swift` | Create `business_profiles` table in Supabase and sync settings. | ⚠️ Local Only |
| **Medium** | **Missing Runtime Validation**: No explicit validation of fields before sending to Supabase (relying on Server response). | `ClientManager.swift` | Add local validation (e.g., regex for email, non-empty name) before making network calls. | ⚠️ Open |
