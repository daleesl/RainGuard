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
- Current primary location context: Calamba, Laguna. Home weather uses the fixed Barangay Lingga/Calamba coordinates, report submission uses actual device GPS, and the map centers on Calamba reports.
- Current navigation: Home, Map, Notification, Settings.
- Entry flow: Splash -> first-time Onboarding -> Login / Sign up -> MainWrapper.
- Onboarding should only appear for first-time users, controlled by `shared_preferences` with `OnboardingScreen.seenPreferenceKey`.
- Auth supports email/password and Google sign-in through Firebase Auth.
- New account creation should create/update the Firebase Auth user and a matching Firestore user profile document.
- Settings is no longer a placeholder. It shows dynamic account data, verification status, notification/location toggles, and logout.
- Logout is available in Settings and should return the user to Login using a route reset.
- A polished Figma concept exists for splash, onboarding, login, sign-up, Google authentication, and settings: https://www.figma.com/design/Zg7npN5AdMrGB3P5aUlOsY
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
- `lib/theme/rainguard_theme.dart` contains shared RainGuard colors, radii, shadows, text styles, and app theme.
- `lib/screens/` contains top-level screens and navigation surfaces.
- `lib/screens/auth/` contains `OnboardingScreen`, `LoginScreen`, and `SignupScreen`.
- `lib/widgets/` contains reusable UI pieces such as app bar, cards, buttons, fields, report modals, report dialogs, and map pins.
- `lib/widgets/settings/` contains reusable Settings components such as profile card, settings tiles, logout tile, and verification sheet.
- `lib/models/` contains shared app data models such as `Report` and `UserProfile`.
- `lib/services/` contains service classes for auth, user profiles, weather, geocoding, location, storage upload, and report submission.
- `lib/utils/` contains helpers and constants such as report icon/label/risk mapping and Calamba/Lingga location constants.
- Platform folders (`android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/`) should only be changed when the task requires platform configuration.

## Current Screen Responsibilities

- `SplashScreen`: shows RainGuard logo briefly, checks Firebase Auth and onboarding preference, then routes to the correct next screen.
- `OnboardingScreen`: introduces RainGuard and stores first-time completion before going to Login.
- `LoginScreen`: email/password login, Google sign-in, and navigation to sign-up.
- `SignupScreen`: first name, last name, email/password account creation, and Google sign-in.
- `MainWrapper`: bottom navigation with Home, Map, Notification, and Settings.
- `HomeScreen`: fixed Lingga/Calamba weather summary, flood risk assessment, quick actions, preparedness tips, and hotlines sheet.
- `MapScreen`: Calamba-centered OpenStreetMap view, Firestore report pins, report details, and add-report bottom sheet.
- `NotificationScreen`: Firestore-based community report alerts, summary metrics, alert cards, and empty state.
- `SettingsScreen`: dynamic profile card, verification entry, app/account settings, and logout flow.

## Current Data Model

- Firestore collection: `reports`.
- Current report fields:
  - `user_id`
  - `reporter_name`
  - `reporter_display_name`
  - `latitude`
  - `longitude`
  - `report_type`
  - `risk_level`
  - `description`
  - `image_url`
  - `image_urls`
  - `flood_level`
  - `created_at`
- Firestore collection: `users`.
- Current user profile fields:
  - `uid`
  - `email`
  - `display_name`
  - `first_name`
  - `last_name`
  - `photo_url`
  - `auth_provider`
  - `verification_status`
  - `created_at`
  - `updated_at`
  - `last_login_at`
- User notification tokens are stored under `users/{uid}/fcm_tokens/{token}` with `token`, `platform`, `created_at`, and `updated_at`.
- Report types currently modeled in Dart: `rain`, `wind`, `brownout`, `flood`; current report UI should prioritize rain and flood unless the product scope changes.
- Risk levels currently modeled in Dart: `safe`, `risk`, `flood`.
- Keep Firestore field names stable unless a task explicitly requires a data migration or coordinated backend change.
- When changing report data shape, update `lib/models/report_model.dart` and every read/write path together.
- When changing user profile shape, update `lib/models/user_profile.dart`, `lib/services/user_profile_service.dart`, and auth write paths together.

## Current Service Responsibilities

- `AuthService`: email/password auth, Google sign-in, user profile creation/update, and sign-out.
- `UserProfileService`: streams and reads the current Firebase user's Firestore profile.
- `LocationService`: location permission and current GPS position handling.
- `StorageService`: Firebase Storage upload behavior for report images.
- `ReportService`: report submission orchestration, including GPS, optional image upload, current user/profile info, and Firestore writes.
- `NotificationTokenService`: Firebase Cloud Messaging permission, token registration, token refresh persistence, and logout cleanup.
- `WeatherService`: OpenWeather API calls for the fixed Lingga/Calamba weather context.
- `GeocodingService`: Nominatim reverse geocoding with a valid User-Agent and respectful request behavior.

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
- Current typography direction is intentionally compact and calm:
  - Page titles around 20.
  - Dialog titles around 14.
  - Card/tile titles around 12.
  - Descriptions around 8.
  - Section labels/chips around 10-10.5.
  - Keep brand text, splash logo text, and important data metrics readable when they are intentionally emphasized.
- Use clear disaster-safety language. Avoid vague labels when a specific safety label is better.
- Keep map pins, report cards, notification cards, and report details visually consistent.
- Do not hardcode one phone size as the layout target.
- Prefer responsive Flutter layout with `Expanded`, `Flexible`, `MediaQuery`, `SafeArea`, `SingleChildScrollView`, or `ListView` where appropriate.
- Forms and bottom sheets should remain usable with the keyboard open.
- Images should scale inside their containers and show sensible loading/error/empty states.
- Long text must wrap or ellipsize cleanly without overflowing.

## Map and Location Rules

- Do not remove fallback coordinates unless replacing them with a better documented fallback.
- Keep Calamba/Lingga coordinates centralized in `lib/utils/location_constants.dart`.
- Home weather should use Lingga/Calamba fixed coordinates for capstone scope consistency.
- Report submission should use actual GPS coordinates when the device provides them.
- The map should center on Calamba by default and display reports from Firestore.
- Handle denied, disabled, and unavailable location states gracefully.
- Keep OpenStreetMap/Nominatim usage respectful:
  - Include a valid `User-Agent` for Nominatim requests.
  - Cache reverse geocoding results where possible.
  - Avoid unnecessary repeated requests.
- Keep map markers derived from Firestore reports unless a task explicitly changes the source.

## Firebase and Backend Rules

- Do not change Firebase configuration, security rules, indexes, or project setup unless explicitly requested.
- Do not run destructive Firebase commands.
- Reports should include the current authenticated user's ID and display/reporter name when available.
- Do not store user passwords in Firestore. Firebase Auth owns password authentication.
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
- Do not commit IDE-local state such as `.idea/`.
- `AGENTS.md` should be committed when it contains project instructions and no secrets, because it helps future agents and collaborators understand the app.
- Treat all client-side values as public unless proven otherwise.
- If a secret is accidentally committed, remove it from Git tracking and tell the user to rotate the exposed secret.

## Current Refactor Status

- Done: reusable app bar in `lib/widgets/rainguard_app_bar.dart`.
- Done: reusable card in `lib/widgets/rainguard_card.dart`.
- Done: reusable primary/Google buttons in `lib/widgets/rainguard_button.dart`.
- Done: reusable auth/form text field in `lib/widgets/rainguard_text_field.dart`.
- Done: Settings components extracted into `lib/widgets/settings/`.
- Done: location, storage upload, and report submission services extracted.
- Done: compact typography pass across major screens and shared widgets.
- Still good future candidates: auth shared layout widgets, map component extraction, notification component extraction, report modal component extraction, validation helpers, auth error helper, and route constants.

## Agent Startup Checklist

- Read `AGENTS.md` first.
- Check `git status --short` before editing.
- Do not touch `.idea/` or local secret/config files.
- For UI work, preserve compact RainGuard typography unless the user asks to change it.
- For Figma-driven auth/settings work, inspect the relevant Figma frame before implementing.
- For design inspiration or new UI flows, use the Refero MCP/design skill when available.
- For Dart changes, run `flutter analyze` when practical and report if it cannot be run.

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
