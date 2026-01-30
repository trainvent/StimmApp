# StimmApp Developer Manual

This document serves as a guide for AI agents and developers working on the StimmApp project. It outlines the project structure, key architectural decisions, common workflows, and known gotchas.

## 1. Project Overview

StimmApp is a Flutter-based mobile application for creating and signing petitions and polls. It uses Firebase for its backend (Auth, Firestore, Storage, Functions).

### Key Technologies
*   **Frontend:** Flutter (Dart)
*   **Backend:** Firebase (Firestore, Auth, Storage, Cloud Functions v2)
*   **State Management:** `ValueNotifier` (Simple, native) & `StreamBuilder`
*   **Dependency Injection:** `get_it` (Service Locator pattern)
*   **Testing:** `flutter_test`, `patrol` (Integration tests)
*   **CI/CD:** GitHub Actions (implied by `.github` folder)

### Environments
*   **Production:** `stimmapp-f0141` (Package: `de.lemarq.stimmapp`)
*   **Development:** `stimmapp-dev` (Package: `de.lemarq.stimmapp.dev`)

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
    *   `notifiers`: Global state notifiers (`AppStateNotifier`).
    *   `config`: App initialization and configuration.

### Initialization Flow
1.  `main.dart`:
    *   Initializes Flutter bindings.
    *   Initializes Firebase.
    *   Sets up Service Locator (`locator`).
    *   Initializes Purchases (RevenueCat).
    *   Runs `MyApp`.
2.  `MyApp` (`lib/main.dart`):
    *   Uses `AppBootstrap` (`lib/core/config/app_bootstrap.dart`) to handle async setup (Theme, Locale, Ads).
    *   Shows `AppLoadingPage` until initialized.
    *   Routing is handled here.
3.  `InitAppLayout` (`lib/app/mobile/layout/init_app_layout.dart`):
    *   Checks for app updates/maintenance mode.
    *   Delegates to `AuthLayout`.
4.  `AuthLayout` (`lib/app/mobile/layout/app_root.dart`):
    *   Listens to Auth State.
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

### Cloud Functions (`functions/src`)
*   **Runtime:** Node.js 22 (Gen 2).
*   **`auth_code.ts`**: Handles sending and verifying email codes.
*   **`user_cleanup.ts`**: Triggered on Auth User Deletion. Recursively wipes all user data (Firestore docs, subcollections, Storage files).
*   **`index.ts`**: Exports functions and handles scheduled tasks (e.g., subscription checks).

### Testing
*   **Integration:** Patrol is used for UI/Integration testing (`integration_test/`).
*   **Note:** Patrol requires specific setup in `build.gradle`.
*   **Clean Code in Tests:** Production code should **NOT** contain test-specific logic or flags (e.g., `if (isTest) ...`). Tests must interact with the app as a real user would (e.g., tapping native dialogs, finding widgets by text/key).

## 4. Common Workflows

### Deploying Cloud Functions
```bash
firebase deploy --only functions
```
*   **Secrets:** SMTP password is stored in Google Cloud Secret Manager (`SMTP_PASSWORD`).
    *   Set/Update: `firebase functions:secrets:set SMTP_PASSWORD`

### Running Integration Tests
```bash
patrol test -t integration_test/simple_flow_test.dart
```

### Adding a New Feature
1.  Define Model in `lib/core/data/models`.
2.  Create Repository in `lib/core/data/repositories`.
3.  Register in `ServiceLocator` if needed (though currently Repos are often instantiated directly or via static `create()`).
4.  Build UI in `lib/app/mobile/pages`.

## 5. Known Flaws & Areas for Improvement

1.  **State Management:** The app relies heavily on `ValueNotifier` and `StreamBuilder`. While simple, this can become hard to manage as the app grows. Consider migrating to `Provider` or `Riverpod` for better scoping and testability.
2.  **Hardcoded Strings:** Some older parts of the app might still have hardcoded strings instead of using `AppLocalizations`. Always use `context.l10n`.
3.  **Error Handling:** While there is a global error logger, individual UI error handling (Snackbars) is sometimes repetitive. A centralized error handler for UI feedback would be beneficial.
4.  **Navigation:** Navigation is mostly `Navigator.push` with `MaterialPageRoute`. Using a named route generator or a routing package (like `go_router`) would improve deep linking and maintenance.
5.  **Dependency Injection:** The `ServiceLocator` is set up but not consistently used for all Repositories (some use `Repository.create()`). Consistent usage would improve testability.
6.  **Cloud Functions Quotas:** Deploying all functions at once can hit Google Cloud API rate limits (`429 Quota Exceeded`). Deploy individual functions if this happens.

## 6. Secrets & Keys
*   **RevenueCat:** Public SDK key in `IConst`. Safe.
*   **Google Places:** API key in `IConst`. **MUST BE RESTRICTED** in Google Cloud Console to the app's package name (`de.lemarq.stimmapp`) and SHA-1 fingerprint.
*   **SMTP Password:** Stored securely in Cloud Secret Manager.

## 7. Release Checklist
*   [ ] Increment `version` in `pubspec.yaml`.
*   [ ] Ensure `IConst.appName` is correct ("StimmApp").
*   [ ] Verify `googlePlacesApiKey` is restricted.
*   [ ] Run integration tests.
*   [ ] check with lightroom.
*   [ ] Build App Bundle: `flutter build appbundle`.
