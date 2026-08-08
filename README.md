# StarForge Family

A student and parent frontend for the StarForge EDU platform. The application
is built with Flutter and consumes the StarForge EDU API. It provides
role-aware access to schedules, attendance, assignments, academic results,
learning content, messaging, notifications, family information, and school
services.

> Web and Android are validated in GitHub Actions. The iOS release pipeline is
> defined for Codemagic because signed Apple builds require macOS and protected
> Apple Developer credentials. Generated binaries and `build/` are not committed.

## Table of contents

- [Features](#features)
- [Role-specific experience](#role-specific-experience)
- [How the application works](#how-the-application-works)
- [Technology stack](#technology-stack)
- [Requirements](#requirements)
- [Quick Web start](#quick-web-start)
- [API configuration](#api-configuration)
- [Firebase push configuration](#firebase-push-configuration)
- [Codemagic iOS release](#codemagic-ios-release)
- [Testing](#testing)
- [Continuous integration](#continuous-integration)
- [Production build](#production-build)
- [Project structure](#project-structure)
- [Security](#security)
- [Troubleshooting](#troubleshooting)

## Features

### Core application

- API-based `/api/v1/auth/login/` authentication with a deployed-tenant
  compatibility fallback and secure session restoration;
- mandatory temporary-password replacement;
- responsive navigation for desktop, tablet, and mobile layouts;
- separate student and parent portals;
- lazy loading and manual refresh for individual data domains;
- permission-aware navigation based on API `permission_codes`;
- explicit loading, error, empty, and populated states;
- light theme, dark theme, larger text, and high-contrast support;
- opaque session storage through `flutter_secure_storage`.

### Learning

- assignments, deadlines, and submission states;
- text submissions and file uploads through presigned upload grants;
- submission history and published teacher grades;
- schedules, academic terms, lesson types, and recurrence rules;
- attendance history with status distribution;
- subjects, published exams, grades, and academic transcripts;
- interactive attendance and performance charts;
- libraries, courses, modules, lessons, folders, files, and materials;
- protected download links for learning resources.

### Communication

- direct and group conversations;
- modern master/detail messenger layout;
- thread search;
- unread counters and read markers;
- per-thread notification muting;
- emoji picker;
- message copying;
- file and voice-message attachments;
- new conversations created from the permitted contact list.

### Family and school services

- full student profile and enrollment history;
- parent profile;
- verified guardian relationships;
- authorized student pickup contacts;
- dynamic forms, consents, and surveys;
- achievements;
- rules, acknowledgements, and disciplinary records;
- notifications and delivery preferences;
- native Firebase push notifications with sound and background delivery;
- student card and wallet;
- read-only family finance summary;
- active device list and device revocation.

## Role-specific experience

The student and parent experiences are intentionally different. The role comes
from the authenticated API session, while available destinations are built
from `permission_codes` returned by the API.

| Area | Student | Parent |
| --- | --- | --- |
| Home | Personal route, upcoming lessons, tasks, and results | Family overview, child status, attendance, and payments |
| Profile | Personal information and enrollment history | Family, child, guardian, and pickup information |
| Assignments | View and submit work | Hidden unless the API grants the required permission |
| Schedule | Personal schedule | Schedule of the linked child |
| Attendance | Personal attendance history | Attendance of the selected child |
| Results | Personal exams, grades, and transcripts | Published academic results of the linked child |
| Content | Libraries and files available to the student | Content explicitly available to the family account |
| Messaging | Teachers and permitted group conversations | Communication with teachers and the school |
| Finance | Student card and wallet projection | Read-only invoices and outstanding balance |

A parent receives data only for children returned by the family API. Knowing
another student's identifier is not enough: server-side selectors and
permissions scope every request.

## How the application works

```text
User
  │
  ▼
Flutter Web UI
  │  role + permission_codes
  ▼
PortalController
  │  HTTPS / JSON / Bearer session
  ▼
StarForge EDU API
```

Design principles:

1. The API is the source of truth for roles, permissions, and family links.
2. The production UI does not provide a local role-switching shortcut.
3. Each page loads only the domain data it needs.
4. A failure in one section must not erase data already loaded elsewhere.
5. Files are transferred through temporary upload and download URLs.
6. Records belonging to another tenant must never be accessible by identifier
   or URL manipulation.

## Technology stack

| Component | Purpose |
| --- | --- |
| Flutter / Dart | UI, navigation, and application state |
| Material 3 | Base components and accessibility |
| `http` | REST communication with StarForge API |
| `flutter_secure_storage` | Protected session storage |
| `file_picker` | Assignment and message file selection |
| `record` | Voice-message recording |
| `url_launcher` | Downloads and external links |
| Firebase Messaging | Native Android/iOS push delivery |
| Local Notifications | Foreground and data-only alerts with sound |
| Manrope | Primary interface typeface |
| Instrument Serif | Editorial display headings |
| JetBrains Mono | Dates, codes, and numeric labels |

## Requirements

- a Flutter release compatible with the Dart constraint in `pubspec.yaml`;
- Firefox, Chrome, or another modern browser;
- a reachable StarForge EDU API compatible with the contracts used by this
  frontend;
- browser access to the configured API hostname.
- Java 17 and an Android SDK for Android builds;
- a Firebase project configuration for real device push delivery.

Check the local Flutter installation:

```bash
flutter doctor -v
flutter --version
```

## Quick Web start

Install dependencies:

```bash
flutter pub get
```

Start the Flutter web server:

```bash
flutter run -d web-server \
  --web-hostname 127.0.0.1 \
  --web-port 8081
```

Open the application in Firefox:

```text
http://127.0.0.1:8081
```

To connect to a different API at compile time:

```bash
flutter run -d web-server \
  --web-hostname 127.0.0.1 \
  --web-port 8081 \
  --dart-define=API_BASE_URL=https://center.example.com
```

The API address can also be changed from the `Markaz serveri` option on the
sign-in screen.

## API configuration

This repository contains the Flutter frontend only. It does not include an API
server, database, seed data, or account-management tools. Use an API environment
and user account provided by your StarForge EDU deployment.

The default API address bundled with the frontend is:

```text
https://starforge.78.111.91.113.nip.io
```

The API base URL is resolved in this order:

1. the center address saved from the sign-in screen;
2. `API_BASE_URL` supplied through `--dart-define`;
3. the local default address.

The API client automatically:

- removes trailing slashes;
- prevents duplicate `/api/v1` suffixes;
- allows local `http` for `localhost` and `*.localhost`;
- requires `https` for external hosts;
- adds `Authorization: Bearer <session>` after authentication;
- accepts list, envelope, and paginated response contracts;
- applies request timeouts;
- clears the local session after `401 Unauthorized`.

Authentication always starts with `/api/v1/auth/login/`. A fallback to
`/api/v1/auth/role-login/` is used only when the canonical route is absent
(`404` or `405`), never after an invalid password or another authentication
error.

## Firebase push configuration

The Android and iOS applications are ready for Firebase Cloud Messaging. Push tokens are
registered after login through `/api/v1/users/devices/`. The notification
channel is `starforge_messages`, matching the backend sender, with maximum
importance, vibration, and sound. Notification messages are displayed by the
operating system while the app is backgrounded; foreground and data-only
messages are displayed through the local notification bridge.

Use either configuration method:

1. Download the Android app configuration from Firebase and place it at
   `android/app/google-services.json` (the file is ignored by Git).
2. Supply the configuration through `--dart-define`:

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://center.example.com \
  --dart-define=STARFORGE_FIREBASE_ANDROID_API_KEY=... \
  --dart-define=STARFORGE_FIREBASE_ANDROID_APP_ID=... \
  --dart-define=STARFORGE_FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=STARFORGE_FIREBASE_PROJECT_ID=... \
  --dart-define=STARFORGE_FIREBASE_STORAGE_BUCKET=...
```

If neither configuration is present, the application still starts and its API
notification inbox remains available, but native push delivery is disabled.
The backend must also have valid Firebase service-account credentials for the
same Firebase project. Never commit `google-services.json`, service-account
keys, API sessions, or user passwords.

### Native platform requirements

- Android declares `POST_NOTIFICATIONS` and `VIBRATE`, creates the
  `starforge_messages` high-priority channel, and requests notification
  permission after a user signs in.
- iOS declares the Push Notifications entitlement, enables the
  `remote-notification` background mode, requests alert/badge/sound permission,
  and registers the APNs-backed FCM token after sign-in.
- The backend sender and client application must use the same Firebase project.
  The Firebase project must contain an APNs authentication key for iOS.

## Codemagic iOS release

The repository root contains `codemagic.yaml`. Its `ios-release` workflow
formats, audits, analyzes, and tests the frontend, restores Firebase securely,
fetches App Store signing files, and produces a signed IPA for bundle identifier
`com.starforge.starforgeStudent`.

Create these encrypted variable groups in Codemagic before the first build:

| Group | Variable | Value |
| --- | --- | --- |
| `starforge_firebase_ios` | `IOS_FIREBASE_SECRET` | Complete contents of `GoogleService-Info.plist` |
| `appstore_credentials` | `APP_STORE_CONNECT_KEY_IDENTIFIER` | App Store Connect API key ID |
| `appstore_credentials` | `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect issuer ID |
| `appstore_credentials` | `APP_STORE_CONNECT_PRIVATE_KEY` | Complete `.p8` private key contents |
| `appstore_credentials` | `CERTIFICATE_PRIVATE_KEY` | Private key for the Apple distribution certificate |

In Codemagic, mark every value as **Secret**. The workflow validates the plist,
extracts its Firebase identifiers without printing them, saves them in the
temporary build environment, and supplies them to Flutter through
`--dart-define`. Apple Developer Portal must have the App ID and Push
Notifications capability enabled for this bundle identifier before the first
signed build.

## Testing

Run these checks before a pull request or push:

```bash
flutter pub get
flutter analyze
flutter test
```

The test suite covers:

- API contracts and envelope/cursor normalization;
- authentication and session restoration;
- student and parent data loading;
- atomic child switching;
- messages and attachment upload contracts;
- role-specific profiles and pages;
- persistent user interactions;
- mobile and desktop navigation;
- 320 px layouts and 200–230% text scaling;
- light, dark, and high-contrast themes;
- visual regression through golden files.

Update golden files only after an intentional design change:

```bash
flutter test --update-goldens
```

## Continuous integration

The repository includes two GitHub Actions workflows:

- `Flutter CI` runs on every push to `main`, every pull request, and manual
  dispatch. It verifies formatting, audits every frontend API call against the
  committed OpenAPI contract, runs static analysis and tests with coverage,
  builds the Web release, builds a debug Android APK, validates the merged
  Android permissions, and uploads Web, APK, and coverage artifacts.
- `Live Student and Parent API Smoke` is a manual, read-only integration check.
  It signs in through both roles, validates each `/users/me/` projection, checks
  the student dashboard/report and the parent's linked-child report, then probes
  every API domain allowed by each account's `permission_codes`.

The OpenAPI snapshot used by CI is stored at
`contracts/starforge-openapi.json`. Routes implemented by the deployed API but
missing from the generated snapshot are reviewed explicitly in
`contracts/openapi-extensions.json`; the audit fails when an override becomes
stale or unused.

Configure the four account secrets before running the live workflow. The
repository variable is optional and overrides the default API address:

| Type | Name | Purpose |
| --- | --- | --- |
| Variable | `STARFORGE_API_BASE_URL` | Optional tenant API origin override, without `/api/v1` |
| Secret | `STARFORGE_STUDENT_USERNAME` | Dedicated student smoke account |
| Secret | `STARFORGE_STUDENT_PASSWORD` | Student smoke password |
| Secret | `STARFORGE_PARENT_USERNAME` | Dedicated parent smoke account |
| Secret | `STARFORGE_PARENT_PASSWORD` | Parent smoke password |

The parent smoke account must have at least one active linked child. Credentials
and opaque session keys are never printed or committed.

For Firebase-enabled CI builds, configure these optional repository secrets:

| Secret | Purpose |
| --- | --- |
| `STARFORGE_GOOGLE_SERVICES_JSON_B64` | Base64-encoded Android Firebase config |
| `STARFORGE_FIREBASE_ANDROID_API_KEY` | Android Firebase API key for dart-define setup |
| `STARFORGE_FIREBASE_ANDROID_APP_ID` | Android Firebase application ID |
| `STARFORGE_FIREBASE_MESSAGING_SENDER_ID` | FCM sender number |
| `STARFORGE_FIREBASE_PROJECT_ID` | Firebase project ID |
| `STARFORGE_FIREBASE_STORAGE_BUCKET` | Optional Firebase storage bucket |

## Production build

Build an optimized Web release:

```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://center.example.com
```

The generated site is written to:

```text
build/web/
```

Build an Android APK:

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://center.example.com
```

Unsigned release builds require protected Android signing configuration. For a
local functional check that does not publish an artifact, use
`flutter build apk --debug`.

Serve the release locally for a smoke test:

```bash
python3 -m http.server 8081 --bind 127.0.0.1 --directory build/web
```

Do not open `build/web/index.html` directly through `file://`. Browser origin
and asset-loading restrictions can break the application.

Production checklist:

- use HTTPS for both frontend and API;
- configure an explicit CORS origin allowlist;
- allow only the intended production origins;
- add CSP and security headers at the reverse proxy;
- never commit passwords, session tokens, or `.env` files;
- smoke-test both roles against a production-like tenant.

## Project structure

```text
lib/
├── main.dart                    connected application entry point
├── portal_app.dart              sign-in, responsive shell, and navigation
├── portal_state.dart            session, permissions, and domain loading
├── push_notification_service.dart Firebase Messaging and device registration
├── notification_service.dart    native notification channel and sound
├── starforge_api.dart           HTTP client and secure session storage
├── portal_pages.dart            learning and service pages
├── portal_identity_pages.dart   separate student and family profiles
├── portal_visuals.dart          metric charts and visualizations
├── theme.dart                   colors, themes, and typography
├── widgets.dart                 shared UI components
├── app_state.dart               deterministic preview state
├── family_data.dart             preview data models
├── family_messaging.dart        preview messaging state
├── redesign_app.dart            deterministic design preview
├── screens.dart                 preview screens
├── features.dart                local feature catalog
├── more_features.dart           additional preview features
└── toolkit.dart                 local toolkit used by widget tests

test/
├── portal_api_test.dart
├── connected_portal_responsive_test.dart
├── family_contract_test.dart
├── family_profile_test.dart
├── fixed_interactions_test.dart
├── interaction_contract_test.dart
├── responsive_test.dart
├── rich_navigation_test.dart
├── toolkit_test.dart
├── visual_test.dart
└── goldens/

web/                              Web manifest, icons, and loader
android/                          Android platform wrapper
assets/fonts/                     bundled fonts
contracts/                        pinned OpenAPI contract and reviewed extensions
tool/                             contract audit and live role smoke checks
.github/workflows/                automated quality and integration workflows
```

The regular `main()` function starts the connected API portal. The local preview
remains available for deterministic widget and golden tests and does not replace
production data.

## Security

- Real usernames, passwords, and tokens must not be committed.
- The frontend never stores the user's password.
- The session is opaque and can be revoked by the API.
- Permissions are enforced by the API; hiding a button is only an
  additional UX layer.
- Upload and download links should be short-lived.
- Parent access is determined by the family relationships returned by the API.
- Family access to exams is restricted to published records in linked cohorts.
- Family AI features must not bypass staff-only RBAC.
- Every new endpoint must be reviewed for tenant isolation.

## Troubleshooting

### The page is empty after sign-in

Confirm that the account has the expected role, permissions, and profile. Then
inspect `/api/v1/users/me/` and the domain endpoint used by the page.

### A parent cannot see a child

Verify that the family endpoint returns the expected linked child. Two
independent profiles do not grant family access by themselves.

### The profile exists but schedule or grades are empty

Check active cohort membership, the academic term, exam publication status, and
record visibility rules.

### A file is listed but cannot be downloaded

Check that the API returned a valid download URL, that the URL is reachable from
the browser, and that a temporary link has not expired.

### Web cannot connect to the API

Confirm that the configured API address opens in the same browser, uses the
correct scheme and port, and permits the frontend origin through CORS.

### Frontend changes are not visible

Restart `flutter run` in development. For a release deployment, rebuild
`build/web` and reload without a stale browser cache.

### APK files are missing from GitHub

This is expected. `build/` is ignored by Git. Running `git push` does not delete
local APK files, but those artifacts are not uploaded to the repository. Publish
release artifacts separately through CI or GitHub Releases when needed.

## Working with changes

Recommended checks before publishing changes:

```bash
git status
flutter analyze
flutter test
git diff --check
git diff -- README.md lib test
```

Do not commit:

- `.env` files;
- session tokens;
- real user credentials;
- `build/` output;
- temporary browser profiles;
- private API keys or signing material.

When adding a page, update all relevant layers:

1. `PortalSection`;
2. permission-aware navigation;
3. the domain loader in `PortalController`;
4. loading, error, empty, and populated UI states;
5. responsive and interaction tests;
6. this README when the user-facing workflow changes.
