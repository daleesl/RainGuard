# RainGuard Agent Instructions

Use this file as the first stop for any AI assistant or coding agent working in this repository.

## Source of Truth

- Treat this repository as the source of truth for the current RainGuard implementation.
- Treat `AGENTS.md` as the agent behavior and project-context source of truth until a dedicated `/docs` folder exists.
- If a `/docs` folder is added later, read it before changing code and keep it aligned with this file.
- Use the current Flutter app in `lib/` as the implementation source of truth.
- Treat the RainGuard mobile auth and settings Figma concept as the current visual reference for splash, onboarding, login, Google sign-up, and settings screens: https://www.figma.com/design/Zg7npN5AdMrGB3P5aUlOsY
- Before implementing or changing those screens, inspect the matching Figma frame and follow its layout, hierarchy, copy direction, colors, and component treatment closely.
- Do not copy assumptions from other projects. RainGuard is a Flutter/Firebase capstone app for community rain, flood, risk, and safety reporting.
- If code and instructions disagree, stop and update the instructions or ask for clarification before building more behavior.

## Current Product Context

- App name: RainGuard.
- Product purpose: help users monitor weather, view local flood/risk reports on a map, submit community reports, and review report notifications.
- Current primary location context: Calamba, Laguna, with fallback coordinates around Barangay Lingga/Calamba when device location is unavailable.
- Current navigation: Home, Map, Notification, Settings.
- Settings is currently a placeholder.
- A polished Figma concept now exists for Settings and the auth entry flow.
- Sign-up should remain low-friction. Identity verification is optional during initial sign-up.
- Filing reports must require verification. Unverified users may browse the Home, Map, and Notifications surfaces, but report submission must route to the verification flow.
- Verification should confirm user identity with a valid ID. Do not require the ID address to match Barangay Lingga because users may have recently relocated.
- Do not require proof of address or a barangay/address text field unless the user explicitly asks for that later.
- Users must be able to start or manage verification from Settings.
- User-facing copy should stay focused on rainfall, flood safety, community reporting, risk awareness, and emergency readiness.
- Do not introduce unrelated marketplace, hiring, payment, ecommerce, social media, or chat concepts unless explicitly requested.

## Current Technical Stack

- Framework: Flutter.
- Language: Dart.
- Backend/services: Firebase Core, Cloud Firestore, Firebase Storage, Firebase Auth.
- Maps: `flutter_map`, OpenStreetMap tiles, `latlong2`.
- Device location: `geolocator`.
- Image upload: `image_picker` plus Firebase Storage.
- Weather: OpenWeather API through `WeatherService`.
- Reverse geocoding: Nominatim through `GeocodingService`.
- Local caching: `shared_preferences`.
- Environment loading: `flutter_dotenv` from `.env`.
- Typography: Google Fonts Poppins through `google_fonts`.

## Project Structure

- `lib/main.dart` initializes dotenv, Firebase, app theme, and `MainWrapper`.
- `lib/screens/` contains top-level screens and navigation surfaces.
- `lib/widgets/` contains reusable UI pieces such as report modals, report dialogs, and map pins.
- `lib/models/` contains shared app data models such as `Report`.
- `lib/services/` contains API/service classes such as weather and geocoding.
- `lib/utils/` contains helpers such as report icon, label, and risk color mapping.
- Platform folders (`android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/`) should only be changed when the task requires platform configuration.

## Current Data Model

- Firestore collection: `reports`.
- Current report fields:
  - `user_id`
  - `latitude`
  - `longitude`
  - `report_type`
  - `risk_level`
  - `description`
  - `image_url`
  - `flood_level`
  - `created_at`
- Report types currently modeled in Dart: `rain`, `wind`, `brownout`, `flood`.
- Risk levels currently modeled in Dart: `safe`, `risk`, `flood`.
- Keep Firestore field names stable unless a task explicitly requires a data migration or coordinated backend change.
- When changing report data shape, update `lib/models/report_model.dart` and every read/write path together.

## Implementation Scope Rules

- Work in focused vertical slices.
- Do not rewrite unrelated screens, routes, services, models, or platform files.
- Preserve working flows unless the task explicitly asks to change them.
- Keep screens as thin as reasonable.
- Put reusable visual elements in `lib/widgets/`.
- Put backend/API calls and caching logic in `lib/services/`.
- Put shared data structures in `lib/models/`.
- Put mapping/formatting helpers in `lib/utils/`.
- Prefer existing project patterns and Flutter-compatible packages already in `pubspec.yaml`.
- Do not add new dependencies unless they clearly reduce complexity or are required by the task.
- Before editing code, list the files you intend to change and why.

## UI and Product Rules

- Follow the existing RainGuard visual direction unless the user provides a new approved design.
- Current visual language: blue RainGuard header, white content areas, rounded cards, Material icons, Poppins typography, risk colors for safe/risk/flood states.
- Use clear disaster-safety language. Avoid vague labels when a specific safety label is better.
- Keep map pins, report cards, notification cards, and report details visually consistent.
- Do not hardcode one phone size as the layout target.
- Prefer responsive Flutter layout with `Expanded`, `Flexible`, `MediaQuery`, `SafeArea`, `SingleChildScrollView`, or `ListView` where appropriate.
- Forms and bottom sheets should remain usable with the keyboard open.
- Images should scale inside their containers and show sensible loading/error/empty states.
- Long text must wrap or ellipsize cleanly without overflowing.

## Map and Location Rules

- Do not remove fallback coordinates unless replacing them with a better documented fallback.
- Handle denied, disabled, and unavailable location states gracefully.
- Keep OpenStreetMap/Nominatim usage respectful:
  - Include a valid `User-Agent` for Nominatim requests.
  - Cache reverse geocoding results where possible.
  - Avoid unnecessary repeated requests.
- Keep map markers derived from Firestore reports unless a task explicitly changes the source.

## Firebase and Backend Rules

- Do not change Firebase configuration, security rules, indexes, or project setup unless explicitly requested.
- Do not run destructive Firebase commands.
- Do not assume anonymous reports are permanent product policy; preserve the current behavior unless the task changes auth/reporting rules.
- Do not allow unverified users to create community reports once verification gating is implemented.
- Store verification documents in a private/restricted location and expose only verification status to normal client UI.
- Verification statuses should be explicit, such as `unverified`, `pending`, `verified`, and `rejected`.
- Never put Firebase admin credentials, service account keys, database passwords, API secrets, or storage secrets in client code.
- Keep upload paths and Firestore writes predictable and easy to audit.
- When adding backend-dependent behavior, document the required Firestore fields, indexes, Storage rules, or Auth assumptions.

## Environment and Security Rules

- Do not commit `.env`.
- Keep `.env`, `.env.local`, and other local secret files out of Git.
- Use `.env.example` for safe placeholders only.
- `OPENWEATHER_API_KEY` is loaded from `.env`; do not hardcode it.
- Treat all client-side values as public unless proven otherwise.
- If a secret is accidentally committed, remove it from Git tracking and tell the user to rotate the exposed secret.

## Coding Rules

- Follow Dart and Flutter conventions.
- Keep widgets readable and split large widgets when it improves clarity.
- Avoid duplicating large UI blocks; extract shared widgets when the duplication becomes meaningful.
- Prefer `debugPrint` over `print` for diagnostics unless following an existing local pattern.
- Use `const` constructors where practical.
- Dispose controllers in stateful widgets when they are owned by the widget.
- Do not silence errors with empty catch blocks unless there is a deliberate user-safe fallback.
- Keep comments useful and brief. Do not add comments that merely restate the code.

## Verification Rules

- After Dart or Flutter changes, run `flutter analyze` when possible.
- Run `flutter test` when the task touches behavior that has or should have tests.
- For dependency changes, run `flutter pub get`.
- For UI changes, test at least these mobile-like sizes when practical:
  - 360 x 800
  - 390 x 844
  - 430 x 932
- Do not start a long-running Flutter dev server automatically unless the user asks for it.
- If verification cannot be run, explain why in the final response.

## Documentation Rules

- Create or update `/docs` when product scope, data model, architecture, permissions, setup steps, or major UI direction changes.
- Record major product or architecture decisions in docs once a docs folder exists.
- Keep `README.md` useful for human setup and `AGENTS.md` useful for AI/agent behavior.
- After editing, summarize changed files and the verification performed.

## Collaboration Rules

- Ask for clarification when a change could affect data loss, security, Firebase rules, or major product scope.
- Make reasonable local improvements for small code quality issues directly related to the task.
- Do not refactor the whole app during a narrow feature request.
- Protect user work: do not revert changes you did not make unless explicitly asked.
