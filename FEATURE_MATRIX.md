# Feature Matrix for PWPro

| Feature Name | UI Location / Route | API / DB Tables | Expected Behavior | Status | Backend Connection |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Authentication** | `LoginView` | Supabase Auth | Login, Signup, Reset Password | Audited | ✅ Connected |
| **Onboarding** | `OnboardingView` | `users`? | Complete profile setup | TBD | ✅ Connected (via Auth) |
| **Dashboard** | `DashboardView` | Aggregates | View stats, upcoming jobs | TBD | ✅ Connected |
| **Calendar** | `CalendarView` | `jobs` | View/Edit scheduled jobs | TBD | ✅ Connected |
| **Estimator** | `EstimatorView` | `estimates` | Create quotes, calc pricing | TBD | ✅ Connected |
| **Invoices** | `InvoiceListView` | `invoices` | Create/Send invoices | TBD | ✅ Connected |
| **Clients** | `ClientListView` | `clients` | Manage customers | TBD | ✅ Connected |
| **Field Tools** | `FieldToolsView` | `chemical_inventory`, `equipment` | Calc mix ratios, track chemicals | TBD | ✅ Connected |
| **Business Suite** | `BusinessSuiteView` | `clients`, `invoices` | Manage business | TBD | ✅ Connected |
| **Subscription** | `PaywallView` | RevenueCat | Upgrade/manage subscription | TBD | ✅ Connected (RevenueCat) |

## Detailed Analysis & Gaps

### 1. Authentication
-   **Files**: `LoginView.swift`, `AuthenticationManager.swift`
-   **Status**: correct usage of `SupabaseManager` for sign in/up.

### 2. Jobs / Calendar
-   **Files**: `SchedulingModels.swift` (Manager), `CalendarView.swift`
-   **Status**: Refactored to use `SupabaseManager.fetchJobs()`.
-   **Notes**: Local `ScheduledJob` maps to `JobData`.

### 3. Estimates
-   **Files**: `EstimateModels.swift` (Manager), `EstimatorView.swift`
-   **Status**: Refactored to use `SupabaseManager.fetchEstimates()`.
-   **Notes**: Local `SavedEstimate` maps to `EstimateData`.

### 4. Invoices
-   **Files**: `InvoiceModels.swift` (Manager), `InvoiceListView.swift`
-   **Status**: Refactored to use `SupabaseManager.fetchInvoices()`.
-   **Notes**: Local `Invoice` maps to `InvoiceData`.

### 5. Clients
-   **Files**: `ClientManager.swift`
-   **Status**: correctly calls `SupabaseManager.fetchClients()`.

### 6. Inventory & Equipment
-   **Files**: `ChemicalInventoryManager.swift`, `EquipmentManager.swift`
-   **Status**: correctly calls `SupabaseManager`.
