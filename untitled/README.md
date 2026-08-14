# Babby Care

A feature-first Flutter/Material 3 Android client for fast, shared newborn-care tracking. Firebase Authentication owns sessions; Firestore stores `families/{familyId}/members`, `babies`, and each baby's `events`. Event documents keep a small common envelope and a typed `data` map, making future event types additive.

## Firebase setup

1. Create a Firebase project, enable Email/Password authentication, and register the Android application.
2. Place the downloaded `google-services.json` in `android/app/`, then run `flutterfire configure` for each desired platform.
3. Deploy `firestore.rules` and `firestore.indexes.json` with `firebase deploy --only firestore`.
4. Run `flutter pub get` and `flutter run`.

Firestore disk persistence is explicitly enabled with an unlimited cache. Writes therefore complete against the local cache while offline and sync when connectivity returns. Documents store UTC Firestore timestamps and use `updatedAt`/`updatedBy` for deliberately simple last-write-wins conflict handling.

The collection-group history query requires the included `familyId ASC, startDateTime DESC` index. Security rules independently validate family membership and parent baby identity rather than trusting client paths or fields.
