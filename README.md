# StarForge Family

A student and parent web portal for the StarForge EDU platform. The application
is built with Flutter and connects to a separate multi-tenant backend. It
provides role-aware access to schedules, attendance, assignments, academic
results, learning content, messaging, notifications, family information, and
school services.

> The primary validated platform is Web. Android platform sources remain in the
> repository, but APK files and the `build/` directory are not committed to Git.

## Table of contents

- [Features](#features)
- [Role-specific experience](#role-specific-experience)
- [How the application works](#how-the-application-works)
- [Technology stack](#technology-stack)
- [Requirements](#requirements)
- [Quick Web start](#quick-web-start)
- [Backend setup](#backend-setup)
- [Demo data](#demo-data)
- [Adding students and parents](#adding-students-and-parents)
- [API configuration](#api-configuration)
- [Testing](#testing)
- [Production build](#production-build)
- [Project structure](#project-structure)
- [Security](#security)
- [Troubleshooting](#troubleshooting)

## Features

### Core application

- backend `role-login` authentication and session restoration;
- mandatory temporary-password replacement;
- responsive navigation for desktop, tablet, and mobile layouts;
- separate student and parent portals;
- lazy loading and manual refresh for individual data domains;
- permission-aware navigation based on backend `permission_codes`;
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
from the authenticated backend session, while available destinations are built
from `permission_codes` returned by the server.

| Area | Student | Parent |
| --- | --- | --- |
| Home | Personal route, upcoming lessons, tasks, and results | Family overview, child status, attendance, and payments |
| Profile | Personal information and enrollment history | Family, child, guardian, and pickup information |
| Assignments | View and submit work | Hidden unless the backend grants the required permission |
| Schedule | Personal schedule | Schedule of the linked child |
| Attendance | Personal attendance history | Attendance of the selected child |
| Results | Personal exams, grades, and transcripts | Published academic results of the linked child |
| Content | Libraries and files available to the student | Content explicitly available to the family account |
| Messaging | Teachers and permitted group conversations | Communication with teachers and the school |
| Finance | Student card and wallet projection | Read-only invoices and outstanding balance |

A parent receives data only for children connected through an active guardian
relationship on the backend. Knowing another student's identifier is not
enough: backend selectors and permissions scope every request.

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
  │
  ├── tenant schema
  ├── PostgreSQL
  ├── MinIO / S3
  ├── Redis / Channels
  └── background tasks
```

Design principles:

1. The backend is the source of truth for roles, permissions, and family links.
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

The backend is maintained in a separate repository:
[MythicalCosmic/starforge_edu](https://github.com/MythicalCosmic/starforge_edu).

## Requirements

Frontend requirements:

- a Flutter release compatible with the Dart constraint in `pubspec.yaml`;
- Firefox, Chrome, or another modern browser;
- a running StarForge EDU backend;
- browser access to the backend tenant hostname;
- an available MinIO or S3 service for file workflows.

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

## Backend setup

This repository does not contain the API server, database, or user passwords.
The backend must run separately.

Example local backend setup:

```bash
git clone https://github.com/MythicalCosmic/starforge_edu.git
cd starforge_edu
cp .env.example .env

docker compose -f docker/docker-compose.yml up -d postgres redis minio
uv sync --all-groups
uv run python manage.py migrate_schemas --shared
uv run python scripts/seed_dev.py
uv run python manage.py runserver 127.0.0.1:8000
```

By default, the frontend expects the local tenant API at:

```text
http://demo.localhost:8000
```

Backend API documentation is available locally at:

```text
http://demo.localhost:8000/api/schema/swagger-ui/
```

If the UI opens but all requests fail, verify that:

- the backend is listening on the expected port;
- the tenant hostname exists;
- the frontend origin is allowed by CORS;
- the API is reachable from the same browser;
- the `http` or `https` scheme is correct;
- PostgreSQL, Redis, and MinIO are running.

## Demo data

The backend provides idempotent seed scripts for a populated local environment.
They may be run repeatedly: known showcase records are updated instead of being
duplicated.

```bash
cd starforge_edu
PYTHONPATH=. uv run python scripts/seed_showcase.py
uv run python scripts/seed_family_portal.py
```

The family portal seed creates connected data needed for a complete Web review:

- student, parent, and guardian relationship;
- complete profiles, emergency contacts, and enrollment history;
- past and upcoming lessons;
- multiple attendance states;
- assignments, submissions, and a teacher grade;
- subjects, exams, results, grades, and a transcript;
- libraries, courses, modules, and learning materials;
- real files and PDF documents stored in MinIO;
- forms and answer fields;
- achievements;
- rules, acknowledgements, and penalties;
- cards, wallet balance, and transactions;
- invoice and outstanding balance;
- family group chat, messages, and an attachment;
- notifications, preferences, and devices.

The seed is restricted to a local `DEBUG` environment and the `demo` tenant. It
must not be used as a production migration.

## Adding students and parents

New accounts can sign in to this Web application after they have been created
correctly on the backend. Adding only a row to a student or parent table is not
enough.

A student account requires:

1. an active authentication identity;
2. a password stored through Django's password hasher;
3. a `StudentProfile`;
4. a student role or account type with the required permissions;
5. a branch;
6. an active cohort membership when schedule, assignments, and results are
   expected;
7. related domain records such as lessons, attendance, grades, and content.

A parent account requires:

1. an active authentication identity;
2. a password stored through Django's password hasher;
3. a `ParentProfile`;
4. a parent role or account type with the required permissions;
5. an active `Guardian` relationship with at least one student;
6. optional pickup authorizations and child finance records when those sections
   are required.

Create accounts through Django Admin, official backend APIs, or backend service
functions. Do not write a plain password directly into a database column:
Django must generate the password hash. Family relationships must also be
created and validated on the backend rather than being simulated in the client.

After creation, the user can sign in through the normal application screen. The
backend returns the role and permissions, and the frontend automatically builds
the correct portal. A parent sees only linked children; a student sees only the
student's own academic projection.

For an account in another tenant, enter that center's hostname on the sign-in
screen. Accounts and data in different tenant schemas are isolated.

## API configuration

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
- do not use wildcards in production `ALLOWED_HOSTS` or CORS settings;
- configure the real S3 or MinIO endpoint;
- configure lifecycle cleanup for temporary upload objects;
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

The regular `main()` function starts the connected backend portal. The local
preview remains available for deterministic widget and golden tests and does
not replace production data.

## Security

- Real usernames, passwords, and tokens must not be committed.
- The frontend never stores the user's password.
- The session is opaque and can be revoked by the backend.
- Permissions are enforced by the backend; hiding a button is only an
  additional UX layer.
- Upload and download links should be short-lived.
- Parent access is determined by backend `Guardian` relationships.
- Family access to exams is restricted to published records in linked cohorts.
- Family AI features must not bypass staff-only RBAC.
- Every new endpoint must be reviewed for tenant isolation.

## Troubleshooting

### The page is empty after sign-in

Confirm that the account has the expected role, permissions, and profile. Then
inspect `/api/v1/users/me/` and the domain endpoint used by the page.

### A parent cannot see a child

Verify the active `Guardian` relationship and the family endpoint response. Two
independent profiles do not grant family access without a backend link.

### The profile exists but schedule or grades are empty

Check active cohort membership, the academic term, exam publication status, and
record visibility rules.

### A file is listed but cannot be downloaded

Check that the object exists in MinIO or S3, bucket CORS is configured, the
public endpoint is correct, and the presigned URL has not expired.

### Web cannot connect to a local backend

The backend must be reachable through the tenant hostname, not only through a
bare IP address. Confirm that the local tenant hostname opens in the same
browser.

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
- local database dumps;
- MinIO or S3 access keys.

When adding a page, update all relevant layers:

1. `PortalSection`;
2. permission-aware navigation;
3. the domain loader in `PortalController`;
4. loading, error, empty, and populated UI states;
5. responsive and interaction tests;
6. this README when the user-facing workflow changes.
