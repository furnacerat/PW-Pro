# PWPro Smoke Test Checklist

**Estimated Time**: 10 Minutes
**Goal**: Verify core functionality after a new build/deploy.

## 1. Environment Check
- [ ] App launches without crashing.
- [ ] Network status is Online (if applicable).
- [ ] "Morning, Harold" (or similar) appears on Dashboard.

## 2. Authentication
- [ ] **Sign Out** (if logged in): Go to Settings -> Sign Out.
- [ ] **Sign In**: Use test credentials `test@example.com` / `password123`.
    -   *Pass*: Redirects to Dashboard.
- [ ] **Sign Up** (optional): Create a new random user.
    -   *Pass*: Account created, redirects to Onboarding/Dashboard.

## 3. Client Management (Backend Connected)
- [ ] Navigate to **Business Suite** -> **Clients**.
- [ ] Tap **+** to add a Client.
- [ ] Enter "Test Client [Date]".
- [ ] Save.
- [ ] *Verify*: Client appears in list.
- [ ] *Verify Backend*: Check Supabase Dashboard `clients` table (if possible).
- [ ] **Edit**: Change name to "Test Client Edited".
- [ ] **Delete**: Swipe to delete.

## 4. Estimates (Local Only - Known Issue)
- [ ] Navigate to **Estimator**.
- [ ] Create new Estimate for "Test Client".
- [ ] Add Item: "House Wash", 2000 sq ft.
- [ ] Save/Send.
- [ ] Navigate to **Estimates List** (in Dashboard or Business Suite).
- [ ] *Verify*: Estimate appears locally.
- [ ] *Note*: Will NOT appear in Supabase `estimates` table.

## 5. Jobs & Scheduling (Local Only - Known Issue)
- [ ] Open **Calendar**.
- [ ] Tap **+** to add Job.
- [ ] Select Client, set Date.
- [ ] Save.
- [ ] *Verify*: Job appears on Calendar.
- [ ] *Note*: Will NOT appear in Supabase `jobs` table.

## 6. Field Tools
- [ ] Open **Field Tools** -> **Chem Calc**.
- [ ] Adjust slider. Verify "Mix Ratio" updates.

## 7. Verification of Fixes (If Applied)
- [ ] [ ] Backend connection for Estimates (TBD)
- [ ] [ ] Backend connection for Jobs (TBD)
