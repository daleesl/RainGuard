# RainGuard Project Context

Use this file to give ChatGPT, groupmates, or future contributors a quick and accurate overview of the RainGuard capstone project without pasting the whole codebase.

## Project Overview

RainGuard is a Flutter/Firebase mobile app with a React/Vite admin dashboard for community rain and flood reporting, local risk monitoring, user verification, safety alerts, and barangay decision support.

Current location focus: Barangay Quiling, Talisay, Batangas, Philippines.

Main users:
- Residents use the mobile app to view weather, see reports on a map, receive alerts, and submit verified community reports.
- Barangay/admin users use the dashboard to monitor reports, verify users, manage alerts, and review community activity.

## Tech Stack

Mobile app:
- Flutter and Dart
- Firebase Auth, Cloud Firestore, Firebase Storage, Firebase Cloud Messaging
- OpenWeather API through a Firebase Functions proxy
- OpenStreetMap with `flutter_map` and `flutter_map_marker_cluster`
- `geolocator` for GPS
- `image_picker` and `flutter_image_compress` for report images
- `shared_preferences` and local app storage for preferences and offline report drafts

Admin dashboard:
- React + Vite
- JavaScript
- Firebase client SDK
- Leaflet / React Leaflet
- Tailwind CSS is being introduced gradually
- Some normal CSS remains for maps, Leaflet, modals, and responsive edge cases

Backend/support:
- Firebase Firestore rules, Storage rules, indexes, and Cloud Functions
- Cloud Functions send push notifications for published safety alerts and new community reports

## Main Mobile Screens

- Splash: checks auth and onboarding state.
- Onboarding: first-time introduction.
- Login / Sign up: Firebase email/password authentication. Google sign-in is currently hidden from the auth UI while it is unavailable.
- Home: Quiling/Talisay weather, current flood-risk assessment, source reason, last-updated time, quick actions, and tips.
- Map: Quiling-centered report map with report pins, clusters, filters, selected report preview, and report submission.
- Notifications: community report alerts and safety alerts.
- Settings: account info, verification, password reset, help, emergency info, and logout.

## Main Admin Dashboard Pages

- Admin Login
- Dashboard
- Live Risk Map
- Reports Management
- Verification Review
- Alerts Management
- Users Management
- Analytics
- Settings

## Firebase Data Model

Main collections:
- `reports`
- `users`
- `users/{uid}/fcm_tokens`
- `alerts`

Important `reports` fields:
- `user_id`
- `reporter_name`
- `reporter_display_name`
- `latitude`
- `longitude`
- `location_name`
- `location_source`
- `report_type`
- `risk_level`
- `description`
- `image_url`
- `image_urls`
- `flood_level`
- `rain_intensity`
- `status`
- `created_at`

Current report types:
- `rain`
- `flood`

Current risk levels:
- `safe`
- `risk`
- `flood`

Rain reports may include `rain_intensity`. Flood reports may include `flood_level`, displayed to users as estimated flood water.

Important `users` fields:
- `uid`
- `email`
- `display_name`
- `first_name`
- `last_name`
- `photo_url`
- `auth_provider`
- `verification_status`
- `role`
- `notification_preference`
- `notification_latitude`
- `notification_longitude`
- `notification_radius_km`
- `created_at`
- `updated_at`
- `last_login_at`

Important `users/{uid}/fcm_tokens` fields:
- `token`
- `platform`
- `notification_preference`
- `notification_latitude`
- `notification_longitude`
- `notification_radius_km`
- `created_at`
- `updated_at`

Admin accounts:
- Admin users sign in through Firebase Auth.
- Their Firestore document must be `users/{adminAuthUid}`.
- The user document needs `role: "admin"`.
- Passwords stay in Firebase Auth, not Firestore.

## Product Rules

- Unverified residents can browse Home, Map, Notifications, and Settings.
- Report submission requires identity verification.
- Verification uses a valid ID photo. Selfie is not required.
- Do not require the ID address to match Barangay Quiling.
- Do not store passwords in Firestore.
- Do not delete old reports just to declutter the map. Filter or hide them from default views instead.
- User map should show active/recent reports by default.
- Admin map should default to active/recent reports and allow filters for older/resolved/rejected/all reports.
- Reports/history views should still allow admins to review older data.
- Home current risk uses unresolved community flood reports from the last 6 hours and published official watch/warning alerts from the last 24 hours, refreshing periodically and when the app resumes.
- Offline report retries reuse the permanent draft ID for the Firestore report and deterministic image paths, preventing duplicate submissions and reusing images already uploaded by an earlier attempt.

## Current Design Direction

- RainGuard blue and white visual identity.
- Compact, calm, disaster-safety interface.
- Rounded cards, soft borders, readable chips, and Poppins typography.
- Mobile map should feel close to Google Maps: large map, minimal overlays, compact filters, and clear report details.
- Admin dashboard should work well at 100% browser zoom on common laptop widths.

## Recent Improvements

- Admin dashboard pages are connected to Firebase data.
- Admin login is implemented.
- Reports can be verified, resolved, hidden as duplicate, and viewed in detail.
- Verification Review shows real user verification records and uploaded ID images.
- Alerts Management supports manual alert creation.
- Cloud Functions send push notifications for published alerts.
- Users Management excludes admin accounts from resident counts.
- Shared admin components were added.
- Tailwind was installed and is being migrated gradually.
- Flutter report logic was split into smaller services.
- Flutter notification feed and report feed services were improved.
- Mobile map report filters were added.
- The app currently centers on Barangay Quiling coordinates. No verified Quiling boundary polygon is active yet.
- Shared Flutter state widgets were added for empty, loading, error, and section header states.
- Lightweight tests were added for parsing and duplicate helper logic.
- Home flood risk no longer counts historical/resolved reports as current danger and now includes current official alerts.
- Offline report retries are idempotent across automatic and manual retry triggers.

## Recommended Improvements Before Machine Learning

Highest priority:
- Firestore pagination for reports, alerts, and admin tables.
- Firestore indexes for filtered and ordered queries.
- More shared admin table/action components.
- More Tailwind migration for repeated admin UI, while keeping Leaflet/map CSS where needed.

Mobile polish:
- Map selected report preview and details polish.
- Notification UX polish.
- Settings UX polish.
- Offline draft retry UX.
- Friendly Firebase error messages.
- Image upload reliability and clearer retry behavior.

Code quality:
- Keep large Flutter screens and services split into focused widgets/services.
- Add lightweight tests for helpers, parsing, and filter logic.
- Avoid large rewrites while the app is already working.

## Machine Learning Plan Later

Planned capstone ML direction:
- Random Forest for rainfall forecasting and localized flood-risk classification.
- Possible outputs: Low, Moderate, High, Critical.
- Possible inputs: rainfall, humidity, temperature, wind speed, pressure, water level if available, and historical flood/hazard data.

Possible data/API sources:
- OpenWeather API through Firebase Functions for near real-time weather without exposing the API key in the mobile app.
- PAGASA/public weather data if accessible.
- UP NOAH hazard maps/data if accessible.
- Kaggle datasets only as supporting data, because generic datasets may not match Barangay Quiling conditions.

Recommended order:
1. Finish and stabilize the mobile app and admin dashboard.
2. Gather local or Philippines-relevant flood/rainfall data.
3. Train and evaluate the Random Forest model.
4. Connect model output to alerts, admin dashboard indicators, and resident warnings.
