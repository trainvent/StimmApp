# StimmApp Developer Manual

This document serves as a guide for AI agents and developers working on the StimmApp project. It outlines the project structure, key architectural decisions, common workflows, and known gotchas.

## 1. Project Overview

StimmApp is a Flutter-based mobile application for creating and signing petitions and polls. It uses Firebase for its backend (Auth, Firestore, Storage, Functions).

### Key Technologies
*   **Frontend:** Flutter (Dart)
*   **Backend:** Firebase (Firestore, Auth, Storage, Cloud Functions v2)
*   **State Management:** **Riverpod** (Migrated from ValueNotifier/StreamBuilder)
*   **Dependency Injection:** `get_it` (Service Locator pattern) & Riverpod Providers
*   **Testing:** `flutter_test`, `patrol` (Integration tests)
*   **CI/CD:** **GitLab CI/CD** (Migrated from GitHub Actions)
*   **Sandbox:** a seperate enviroment which mirrors the content and User. Existing Users all get assigned the same Password.


## 2. Architecture

The app follows a clean architecture approach, separated into layers:

*   **`lib/app`**: UI Layer (Pages, Widgets, Layouts).
    *   `mobile/pages`: Screen implementations.
    *   `mobile/widgets`: Reusable UI components.
    *   `mobile/layout`: Root layouts (e.g., `AuthLayout`, `InitAppLayout`).
*   **`lib/core`**: Core logic and infrastructure.
    *   `data/models`: Data classes (e.g., `UserProfile`, `Petition`).
    *   `data/repositories`: Data access logic (Firestore interactions).
    *   `data/services`: Business logic services (`AuthService`, `ProfilePictureService`).
    *   `providers`: Riverpod providers (`auth_provider.dart`).
    *   `config`: App initialization and configuration.


### Initialization Flow
1.  `app_entry.dart`:
    *   Initializes Flutter bindings.
    *   Initializes Firebase.
    *   Sets up Service Locator (`locator`).
    *   Initializes Purchases (RevenueCat).
    *   Runs `MyApp` wrapped in `ProviderScope`.
2.  `MyApp` (`lib/app_entry.dart`):
    *   Uses `AppBootstrap` (`lib/core/config/app_bootstrap.dart`) to handle async setup (Theme, Locale, Ads).
    *   Shows `AppLoadingPage` until initialized.
    *   **LayoutBuilder:** Enforces a max width/aspect ratio (2/3) for web/tablet compatibility.
    *   Routing is handled here.
3.  `InitAppLayout` (`lib/app/mobile/layout/init_app_layout.dart`):
    *   Checks for app updates/maintenance mode.
    *   Delegates to `AuthLayout`.
4.  `AuthLayout` (`lib/app/mobile/layout/app_root.dart`):
    *   **Riverpod Consumer:** Listens to `authStateProvider` and `userProfileProvider`.
    *   **Crucial Flow:**
        *   Not Logged In -> `WelcomePage`
        *   Logged In ->
            *   Email Not Verified -> `EmailConfirmationPage`
            *   Email Verified ->
                *   No Profile Doc -> `SetUserDetailsPage`
                *   Profile Exists -> `WidgetTree` (Main App)

## 3. Key Features & Implementation Details

### Authentication
*   **Service:** `AuthService` (`lib/core/data/services/auth_service.dart`)
*   **Mechanism:** Firebase Auth (Email/Password).
*   **Verification:** Custom 6-digit code flow via Cloud Functions (`sendVerificationCode`, `verifyCode`).
    *   **Backend:** `functions/src/auth_code.ts` (Uses Nodemailer + IONOS SMTP).
    *   **Frontend:** `EmailConfirmationPage`.

### Data Management
*   **Firestore:** Primary database.
*   **Repositories:** Encapsulate Firestore queries (e.g., `UserRepository`, `PetitionRepository`).
*   **Security:** `firestore.rules` defines access control.
*   **Sync (Prod -> Dev):** `functions/src/data_sync.ts` copies Prod data to Dev daily.
    *   **User Relinking:** Automatically links synced user data to Dev Auth accounts if emails match.

### Cloud Functions (`functions/src`)
*   **Runtime:** Node.js 22 (Gen 2).
*   **`auth_code.ts`**: Handles sending and verifying email codes. Uses `defineSecret` for SMTP credentials.
*   **`user_cleanup.ts`**: Triggered on Auth User Deletion. Recursively wipes all user data.
*   **`data_sync.ts`**: Handles scheduled sync from Prod to Dev environment.
*   **`index.ts`**: Exports functions and handles scheduled tasks (e.g., subscription checks).

### Testing
*   **Integration:** Patrol is used for UI/Integration testing (`integration_test/`).
*   **Note:** Patrol requires specific setup in `build.gradle`.

## 4. Common Workflows

### Deploying Cloud Functions
```bash
firebase deploy --only functions
```
*   **Secrets:** SMTP password is stored in Google Cloud Secret Manager (`SMTP_PASSWORD`).
    *   Set/Update: `firebase functions:secrets:set SMTP_PASSWORD`
    *   **Note:** Secrets are project-specific. Must be set for both Prod and Dev projects.

### Running Integration Tests
```bash
patrol test -t integration_test/simple_flow_test.dart
```

### Adding a New Feature
1.  Define Model in `lib/core/data/models`.
2.  Create Repository in `lib/core/data/repositories`.
3.  Create/Update Riverpod Provider in `lib/core/providers`.
4.  Build UI in `lib/app/mobile/pages` using `ConsumerWidget`.

## 5. Known Flaws & Areas for Improvement

1.  **State Management:** Migration to **Riverpod** is underway (Auth is done). Continue migrating other parts of the app from `StreamBuilder`/`ValueNotifier`.
2.  **Hardcoded Strings:** Most strings are now localized using `AppLocalizations` (`context.l10n`), but vigilance is needed for new features.
3.  **Error Handling:** While there is a global error logger, individual UI error handling (Snackbars) is sometimes repetitive.
4.  **Navigation:** Navigation is mostly `Navigator.push` with `MaterialPageRoute`. Consider `go_router` for better deep linking.
5.  **Cloud Functions Quotas:** Deploying all functions at once can hit Google Cloud API rate limits. Deploy individual functions if this happens.

## 6. Secrets & Keys
*   **RevenueCat:** Public SDK key in `IConst`. Safe.
*   **Google Places:** API key in `IConst`. **MUST BE RESTRICTED** in Google Cloud Console.
*   **SMTP Password:** Stored securely in Cloud Secret Manager (`SMTP_PASSWORD`).

## 7. Release Checklist
*   [ ] Increment `version` in `pubspec.yaml`.
*   [ ] Ensure the selected flavor and entrypoint match the target brand.
*   [ ] StimmApp prod: `flutter build appbundle --release --flavor prod -t lib/main.dart`
*   [ ] Verify `googlePlacesApiKey` is restricted.
*   [ ] Run integration tests.
*   [ ] Functions deploy target is correct: `firebase deploy --only functions --project <alias>`

## 8. Firebase Aliases
*   `dev` -> `stimmapp-dev`
*   `prod` -> `stimmapp-f0141`

# CI / iOS build hints:
# - Ensure CI runs: `flutter pub get` before any `pod install`.
# - To reproduce failing archive locally:
#     flutter pub get
#     flutter build ios --no-codesign
#     cd ios && pod install --repo-update
#     (then run the exact xcodebuild command from your CI to see detailed logs)
# - Use the included debug helper: ios/ci_debug.sh
#   make it executable: chmod +x ios/ci_debug.sh
#   run locally or as an extra Xcode Cloud step to collect xcresult and logs.
