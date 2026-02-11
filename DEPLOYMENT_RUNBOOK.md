# PW Pro Production Deployment Runbook

## Technical Stack Summary

**Frontend:** SwiftUI iOS App (iOS 17.0+, macOS 14.0+)
**Backend:** Supabase (PostgreSQL + Auth + Storage + Realtime)
**External APIs:** OpenWeatherMap, Google Gemini, RevenueCat
**Build System:** Xcode + Swift Package Manager

---

## 🚀 Installation & Setup Commands

### Prerequisites
```bash
# Required tools
xcode --version  # Xcode 15.0+
swift --version   # Swift 5.9+

# Verify iOS Simulator
xcrun simctl list devices
```

### 1. Install Dependencies
```bash
# Navigate to project directory
cd "/Users/haroldfoster/Developer/PWPRO NEW"

# Swift Package Manager will auto-install dependencies
# Or manually in Xcode: File → Add Package Dependencies
```

### 2. Environment Configuration
```bash
# Create production environment file
cp .env.example .env.production

# Required environment variables
nano .env.production
```

**Required Production Variables:**
```bash
# Supabase Configuration
SUPABASE_URL=https://your-production-project.supabase.co
SUPABASE_ANON_KEY=your-production-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-production-service-role-key
SUPABASE_DB=postgres://user:password@host:5432/prod_db

# External APIs
OPENWEATHER_API_KEY=your-openweather-key
GEMINI_API_KEY=your-gemini-api-key
REVENUECAT_API_KEY=your-revenuecat-key

# App Configuration
APP_ENVIRONMENT=production
BUNDLE_ID=com.yourcompany.pwpro
API_BASE_URL=https://api.pwpro.com
```

### 3. Database Setup (Standard Plan Compatible)
The "Git Push to Deploy" is a Pro feature. For Standard/Free plans, use the CLI:

```bash
# 1. Login to Supabase CLI
supabase login

# 2. Link your local project to the remote instance
# Get your Reference ID from the dashboard URL: https://app.supabase.com/project/<REFERENCE_ID>
supabase link --project-ref lkmazqixrlofyhlrmfuq

# 3. Push your local schema migrations to the remote database
# This applies all SQL files in supabase/migrations/ to the live DB
supabase db push

# 4. (Optional) Run the complete schema script if starting fresh
# psql -h db.lkmazqixrlofyhlrmfuq.supabase.co -U postgres -d postgres -f supabase_complete_schema.sql
```

### 4. Build & Test Commands
```bash
# Clean build
xcodebuild -project "PWProApp.xcodeproj" -scheme "PW Pro" clean

# Build for production
xcodebuild -project "PWProApp.xcodeproj" \
  -scheme "PW Pro" \
  -configuration Release \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build

# Run tests
xcodebuild -project "PWProApp.xcodeproj" \
  -scheme "PW Pro" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  test

# Lint (if using SwiftLint)
swiftlint
```

### 5. Production Build Process
```bash
# Archive for App Store
xcodebuild -project "PWProApp.xcodeproj" \
  -scheme "PW Pro" \
  -configuration Release \
  -archivePath ./build/PWPro.xcarchive \
  archive

# Export to IPA
xcodebuild -exportArchive \
  -archivePath ./build/PWPro.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ExportOptions.plist
```

---

## 📱 iOS App Store Deployment

### 1. App Store Connect Setup
```bash
# 1. Create app in App Store Connect
# 2. Configure app metadata, screenshots, pricing
# 3. Set up in-app purchases (subscriptions)
```

### 2. Build Configuration
**Create `ExportOptions.plist`:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
```

### 3. Upload to App Store
```bash
# Using Application Loader (older) or Xcode Organizer
# 1. Open Xcode Organizer
# 2. Select archive → Distribute App
# 3. Choose "App Store Connect"
# 4. Follow upload wizard
```

---

## 🔒 Security Configuration Checklist

### Remove Development/Debug Code
```swift
// REMOVE from production builds:
#if DEBUG
    // Developer bypass functions
    devBypass()
    enableOfflineMode()
#endif

// Replace with production-only code
#if !DEBUG
    // Production logging
    configureCrashlytics()
    configureAnalytics()
#endif
```

### Environment Verification
```bash
# Check for exposed secrets
grep -r "SUPABASE_" Sources/ PWProApp/
grep -r "API_KEY" Sources/ PWProApp/

# Verify no hardcoded URLs
grep -r "http://localhost" Sources/ PWProApp/
grep -r "127.0.0.1" Sources/ PWProApp/
```

---

## 🧪 Testing Commands

### Unit Tests
```bash
# Run all tests
xcodebuild test -project "PWProApp.xcodeproj" -scheme "PW Pro"

# Run specific test class
xcodebuild test -project "PWProApp.xcodeproj" \
  -scheme "PW Pro" \
  -only-testing:PWProTests/AuthenticationManagerTests
```

### UI Tests
```bash
# Run UI tests
xcodebuild test -project "PWProApp.xcodeproj" \
  -scheme "PW Pro" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:PWProUITests
```

### Integration Tests
```bash
# Test Supabase connection
swift test --filter SupabaseManagerTests

# Test offline sync
swift test --filter OfflineSyncManagerTests
```

---

## 📊 Production Monitoring Setup

### 1. Analytics & Crash Reporting
```swift
// Add to AppDelegate/App init
import FirebaseAnalytics
import FirebaseCrashlytics

#if !DEBUG
FirebaseApp.configure()
#endif
```

### 2. Logging Configuration
```swift
// Production logging setup
#if DEBUG
    // Verbose logging for development
    Logger.logLevel = .verbose
#else
    // Error-only logging for production
    Logger.logLevel = .error
    // No PII logging
    Logger.maskPII = true
#endif
```

---

## 🚦 Deployment Validation

### Pre-Launch Checklist
- [ ] All environment variables configured
- [ ] Database schema deployed
- [ ] Supabase RLS policies active
- [ ] API keys secured in keychain
- [ ] No hardcoded secrets in bundle
- [ ] Build configuration set to Release
- [ ] Provisioning profiles valid
- [ ] In-app purchases configured
- [ ] Privacy policy updated
- [ ] App metadata complete

### Post-Launch Verification
- [ ] App downloads and launches
- [ ] User registration works
- [ ] Core features functional
- [ ] Push notifications working
- [ ] Analytics data flowing
- [ ] Error monitoring active
- [ ] Performance metrics normal

---

## 🔄 CI/CD Pipeline Setup

### GitHub Actions Workflow
```yaml
name: Build and Deploy
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build and Test
        run: |
          xcodebuild test -project "PWProApp.xcodeproj" -scheme "PW Pro"
```

---

## 🛠️ Troubleshooting

### Common Issues
1. **Build Fails:** Check Xcode version, clean build folder
2. **Auth Issues:** Verify Supabase URL and keys
3. **Database Errors:** Run schema migration manually
4. **API Failures:** Check API key quotas and permissions
5. **Push Notifications:** Verify APNs certificates

### Debug Commands
```bash
# Check bundle contents
codesign -dv --verbose ./build/PWPro.app

# Verify no secrets in IPA
strings ./build/PWPro.app/PWPro | grep -i "supabase\|api_key"

# Check network calls during testing
# Use Charles Proxy or Xcode Network Link Conditioner
```

---

## 📞 Support & Maintenance

### Monitoring Tools
- **Firebase Crashlytics** (if integrated)
- **Supabase Dashboard** - Database usage
- **App Store Connect** - Crash reports
- **RevenueCat Dashboard** - Subscription metrics

### Backup Strategy
- **Database:** Automatic Supabase backups
- **User Data:** Supabase export functionality
- **Config:** Git version control
- **API Keys:** Secure keychain storage

---

## ⚠️ Critical Security Notes

1. **NEVER** commit `.env.production` or any API keys
2. **ALWAYS** use keychain for secret storage in production
3. **VERIFY** Supabase RLS policies before launch
4. **TEST** with real user accounts, not admin overrides
5. **MONITOR** for unusual API usage patterns
6. **ROTATE** API keys regularly (quarterly)
7. **AUDIT** user access logs monthly