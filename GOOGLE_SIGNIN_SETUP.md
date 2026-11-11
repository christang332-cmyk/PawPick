# Google Sign-In setup

## What was fixed in the app

The project resolves `google_sign_in` to **6.3.0** and `firebase_auth` to
**7.0.1**, so it uses the classic `GoogleSignIn(...).signIn()` API. The
7.x-only `GoogleSignIn.instance.initialize()` / `authenticate()` API is not
used. The Google button now has a loading state, prevents double taps, handles
cancellation/network/configuration errors with friendly messages, creates a
Firestore profile with `pawPoints: 0` on first Google login, and links Google
to the currently signed-in email account when the email addresses match.

The Web OAuth server client ID is injected through `AppConfig`:

```powershell
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
```

Find that value in Google Cloud Console > APIs & Services > Credentials under
the OAuth 2.0 Client ID whose application type is **Web application**.

## Current project diagnosis

The checked-in Android configuration currently has both `oauth_client` and
`other_platform_oauth_client` as empty arrays in
`android/app/google-services.json`. That file cannot provide the OAuth client
needed for a Firebase ID token, so Google sign-in will not complete until it is
replaced with a freshly downloaded configuration.

## Firebase Console

1. Open Firebase Console > Authentication > Sign-in method.
2. Enable **Google** and set a support email.
3. Keep **Email/Password** enabled for normal registration.
4. Open Project settings > Your apps > Android.
5. Add the debug SHA-1 and SHA-256 fingerprints.
6. Re-download `google-services.json` after adding fingerprints and enabling
   Google, then replace `android/app/google-services.json`.
7. Confirm the Android package name is `com.example.pawpick`.
8. Add local and production domains under Authentication > Settings >
   Authorized domains.

To print the Android debug fingerprints:

```bash
cd android && ./gradlew signingReport
```

On Windows PowerShell, use:

```powershell
Set-Location android
.\gradlew signingReport
```

Paste the SHA-1 and SHA-256 values into Firebase Console > Project settings >
Your apps > Android.

## Android checks

- `minSdk` is 24, which satisfies Google Sign-In and Firestore.
- Use an emulator image with Google Play Services, not a bare AOSP image.
- Confirm the device has internet access.
- The Google services Gradle plugin is applied in
  `android/app/build.gradle`.

## iOS checks

1. Download the current `GoogleService-Info.plist` into `ios/Runner/`.
2. Add it to the Runner target in Xcode.
3. Add its `REVERSED_CLIENT_ID` as a URL scheme in Runner target >
   Info > URL Types.
4. Confirm the iOS bundle ID matches the Firebase iOS app.
