# PWPro Runbook

## 1. Prerequisites
- **Xcode**: Version 15.0 or later (required for iOS 17+ support).
- **iOS SDK**: iOS 17.0+.
- **Supabase Account**: You have the project reference `lkmazqixrlofyhlrmfuq`.

## 2. Installation
1.  **Clone/Open Repository**:
    ```bash
    cd "/Users/haroldfoster/Developer/PWPRO NEW"
    open PWProApp/PWProApp.xcodeproj
    ```
2.  **Dependencies**:
    -   The project uses Swift Package Manager (SPM). Xcode should automatically resolve dependencies upon opening.
    -   **Note**: A `Pods` directory exists, but no `Podfile` was found. If build errors occur related to pods, ensure you are opening the `.xcodeproj` (or `.xcworkspace` if it exists, though none was seen).
3.  **Configuration**:
    -   Ensure `PWProApp/PWProApp/Config.plist` exists and contains valid `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
    -   The project also uses `Config2.plist` as a fallback.
    -   **Required Keys**:
        -   `SUPABASE_URL`
        -   `SUPABASE_ANON_KEY`
        -   `GEMINI_API_KEY`

## 3. Running the App
1.  Select the **PWPro** scheme in Xcode.
2.  Select a Simulator (e.g., iPhone 15 Pro) or a connected physical device.
3.  Press `Cmd + R` to Build and Run.

## 4. Running Tests
-   **Unit/UI Tests**: Press `Cmd + U` in Xcode to run the test suite.
-   *Note: Check the Test Navigator (Cmd + 6) to see available tests.*

## 5. Environment Variables
The app uses `Config.plist` for environment secrets.
| Key | Description |
| :--- | :--- |
| `SUPABASE_URL` | URL for the Supabase project. |
| `SUPABASE_ANON_KEY` | Public anonymous key for Supabase Auth/DB. |
| `GEMINI_API_KEY` | API Key for Gemini AI features. |

**Security Note**: Ensure `Config.plist` is NOT committed to public version control if this project becomes public.

## 6. Troubleshooting
-   **Missing Module 'Supabase'**: 
    -   File > Packages > Reset Package Caches.
    -   File > Packages > Resolve Package Versions.
-   **Build Failed**: Check the Issue Navigator (Cmd + 5) for specific errors.
