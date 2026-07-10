# RainGuard Firebase Backend

This setup keeps the mobile app, admin dashboard, Firestore, Storage, and Cloud Functions aligned.

## What Is Included

- `firestore.rules` protects users, reports, and alerts.
- `storage.rules` lets users upload report photos and verification IDs while allowing admins to review verification images.
- `firestore.indexes.json` defines the alert/report/user indexes used by the app and dashboard.
- `functions/index.js` sends push notifications for new community reports and newly published safety alerts, and proxies weather requests to OpenWeather without exposing the API key to the mobile app.

## Home Current-Risk Query

The mobile Home screen calculates current flood risk from:

- unresolved community flood reports created within the last 6 hours
- published official alerts with `risk_level` watch/warning/critical and `published_at` within the last 24 hours

Resolved, rejected, and `duplicate_hidden` reports remain in history but do not contribute to current Home risk.
The Home assessment refreshes every five minutes, when the app resumes, and when the user pulls to refresh so expired sources do not remain active on screen.

The query uses these composite indexes from `firestore.indexes.json`:

```text
reports: report_type ASC, created_at DESC
alerts: status ASC, published_at DESC
```

## Idempotent Offline Report Retry

Each report submission receives a permanent client draft/submission ID. RainGuard uses that ID as the Firestore report document ID:

```text
reports/{draftId}
```

Report images use deterministic Storage paths:

```text
reports/{draftId}/image-{index}
```

Automatic and manual draft retries share a single in-flight retry operation, and each draft ID can have only one active submission in the app process. Before uploading images, the app checks whether `reports/{draftId}` already exists for the current user and reuses any images already uploaded at the deterministic paths. A successful retry removes the local draft only after the Firestore document is confirmed.

Deploy the updated Storage rules and Firestore indexes before relying on these paths and Home risk queries:

```powershell
firebase deploy --only firestore:indexes
firebase deploy --only storage
```

## Required Admin Account

The admin dashboard must be signed in with a Firebase Auth account whose Firestore user document has:

```text
users/{adminAuthUid}
email: "rainguardadmin@gmail.com"
display_name: "Barangay Safety Desk"
role: "admin"
verification_status: "verified"
```

The document ID must match the Firebase Auth UID. Passwords stay in Firebase Auth only, not in Firestore.

## Deploy Order

Cloud Functions deploys require the Firebase Blaze plan. Firestore rules, Storage rules, and indexes can still be deployed from the same project setup.

Set the OpenWeather API key as a Firebase Functions secret before deploying the weather proxy:

```powershell
firebase functions:secrets:set OPENWEATHER_API_KEY
```

Run these from the project root when you are ready to update Firebase:

```powershell
firebase deploy --only firestore:rules,firestore:indexes
firebase deploy --only storage
firebase deploy --only functions
```

If Firebase asks to create an index from the console, create it there or deploy `firestore.indexes.json`.

## Alert Push Behavior

When an admin creates or updates an alert with `status: "published"`, Cloud Functions sends a push notification to all registered device tokens under:

```text
users/{uid}/fcm_tokens/{tokenId}
```

The function writes these tracking fields back to the alert:

```text
push_sent_at
push_token_count
push_failure_count
```

Draft and resolved alerts do not send pushes.

## FCM Token Preference Fields

Device tokens stay under:

```text
users/{uid}/fcm_tokens/{tokenId}
```

Each token document stores the token and a copy of the receiving user's notification preference so Cloud Functions can decide report recipients without reading every user profile:

```text
token
platform
notification_preference
notification_latitude
notification_longitude
notification_radius_km
created_at
updated_at
```

`notification_latitude`, `notification_longitude`, and `notification_radius_km` are only kept for the `nearby_only` preference. Older token documents may not have these fields yet, so report push functions still fall back to the user profile when token-level preference fields are missing or incomplete.

## Weather API Proxy

The mobile app does not call OpenWeather directly. `WeatherService` calls:

```text
https://us-central1-{projectId}.cloudfunctions.net/getWeather?lat={lat}&lon={lon}
```

The `getWeather` Cloud Function reads the server-side `OPENWEATHER_API_KEY` secret, calls OpenWeather, and returns only the compact fields the app needs:

```text
temp
description
location
```

Do not put `OPENWEATHER_API_KEY` in Flutter assets or client code. For the RainGuard Firebase project, deploy the weather Function with:

```powershell
firebase deploy --only functions:getWeather
```
