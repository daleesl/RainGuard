# RainGuard Firebase Backend

This setup keeps the mobile app, admin dashboard, Firestore, Storage, and Cloud Functions aligned.

## What Is Included

- `firestore.rules` protects users, reports, and alerts.
- `storage.rules` lets users upload report photos and verification IDs while allowing admins to review verification images.
- `firestore.indexes.json` defines the alert/report/user indexes used by the app and dashboard.
- `functions/index.js` sends push notifications for new community reports and newly published safety alerts.

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
