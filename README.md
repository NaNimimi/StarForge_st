# StarForge Family

A student and parent frontend for the StarForge EDU platform. The application
is built with Flutter and consumes the StarForge EDU API. It provides
role-aware access to schedules, attendance, assignments, academic results,
learning content, messaging, notifications, family information, and school
services.

> The primary validated platform is Web. Android platform sources remain in the
> repository, but APK files and the `build/` directory are not committed to Git.

## Table of contents

- [Features](#features)
- [Role-specific experience](#role-specific-experience)
- [How the application works](#how-the-application-works)
- [Technology stack](#technology-stack)
- [Requirements](#requirements)
- [Quick Web start](#quick-web-start)
- [API configuration](#api-configuration)
- [Testing](#testing)
- [Production build](#production-build)
- [Project structure](#project-structure)
- [Security](#security)
- [Troubleshooting](#troubleshooting)

## Features

### Core application

- API-based `role-login` authentication and session restoration;
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
| Manrope | Primary interface typeface |
| Instrument Serif | Editorial display headings |
| JetBrains Mono | Dates, codes, and numeric labels |

## Requirements

- a Flutter release compatible with the Dart constraint in `pubspec.yaml`;
- Firefox, Chrome, or another modern browser;
- a reachable StarForge EDU API compatible with the contracts used by this
  frontend;
- browser access to the configured API hostname.

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

The local fallback API address is:

```text
http://demo.localhost:8000
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
