# Firebase setup

The app is already initialized with the generated configuration in
`lib/firebase_options.dart`. Email/password authentication, Google OAuth,
Firestore user profiles, and Firestore order writes are wired in the app.

## Firebase Console

In Firebase Console for project `pawpick-72e4b`:

1. Enable **Authentication > Sign-in method > Email/Password**.
2. Enable **Authentication > Sign-in method > Google**.
3. Add every development and production app domain under
   **Authentication > Settings > Authorized domains**.
4. Create a Firestore database in production mode.
5. Deploy [firestore.rules](./firestore.rules).

For Android Google sign-in, add the app's SHA-1 and SHA-256 fingerprints to the
Android app in Project Settings and download the generated
`google-services.json` into `android/app/`. For iOS, configure the reversed
client ID from GoogleService-Info.plist in the Runner URL schemes. Web Google
sign-in uses the authorized Firebase domain.

## CLI deployment

```bash
firebase login
firebase use pawpick-72e4b
firebase deploy --only firestore:rules
```

The app validates email syntax, password length, and the required
letter-and-number password rule before calling Firebase Auth. Firebase then
performs the authoritative account and email uniqueness checks.

The cart and favorites remain local-first. Signed-in profiles and placed orders
are written to `users/{uid}` and `users/{uid}/orders/{orderNumber}`. Never store
passwords, access tokens, or full card numbers in Firestore.
