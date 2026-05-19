# Fix: Google Sign-In on Android (silent failure)

## Symptom
Tapping **Continue with Google** showed the loading spinner, then nothing happened — no navigation, no error message.

## Root Cause
With `firebase_auth ^6.x` + `google_sign_in ^5.4.x` on Android, `GoogleSignIn()` must be initialized with a `serverClientId` set to the **Web** OAuth client (`client_type: 3` in `google-services.json`). Without it, `googleUser.authentication.idToken` is returned as `null`. The code then called `FirebaseAuth.instance.signInWithCredential(...)` with a null `idToken`, and Firebase rejected the credential silently — leaving the spinner hanging with no snackbar.

Secondary issue: `login.dart::loginwithgoogle()` was silently returning when the user cancelled the Google account picker (no snackbar, no spinner dismissal feedback), making the cancellation case look identical to a real failure.

## Files Changed
- `lib/auth/signup.dart` — `signup_google()`
- `lib/auth/login.dart` — `loginwithgoogle()`

## What Was Changed
1. **`GoogleSignIn(serverClientId: '<web client id>')`** — passes the Web OAuth client ID (type 3) from `android/app/google-services.json`:
   `383298804056-3v7k9oefmo2bbu297s5b8vrb5looiqll.apps.googleusercontent.com`
2. **Null-`idToken` guard** — after `googleUser.authentication`, if `idToken` is null, dismiss the spinner and show a clear error snackbar instead of continuing into Firebase.
3. **Cancellation snackbar in `login.dart`** — mirrors the existing behavior in `signup.dart`, so a cancelled picker no longer looks like a dead button.
4. **`debugPrint` diagnostics** — logs `googleUser.email` and which of `idToken`/`accessToken` came back null, so any future regression is visible in the Flutter console.

## What Was NOT Changed
- `android/app/google-services.json` — already contained both OAuth clients (type 1 + type 3) and the correct SHA-1.
- `android/app/src/main/AndroidManifest.xml` — `INTERNET` permission and cleartext flag were already present.
- `lib/auth/gender.dart`, `lib/auth/age.dart` — unrelated to Google Sign-In.
- `pubspec.yaml` — no package changes needed.

## How To Verify

### Firebase / Google Cloud setup (must already be done)
- **Firebase Console → Authentication → Sign-in method → Google** is **Enabled**.
- **Google Cloud Console → APIs & Services → OAuth consent screen** is configured (User type: External; test users added if app is in Testing mode).
- Debug SHA-1 `A8:37:BA:10:F5:A0:4A:6B:31:B2:77:A4:63:02:DB:51:7C:85:F1:34` is registered on the Firebase Android app (confirmed — it's already in `google-services.json` as `a837ba10f5a04a6b31b277a46302db517c85f134`).

### Run
```bash
flutter clean
flutter pub get
flutter run
```

### Expected behavior
- **Happy path:** Tap "Continue with Google" → pick account → navigate to `GenderPage` (signup) or `Wrapper` (login). Console shows:
  - `Starting Google Sign-In...`
  - `googleUser: <your-email>`
  - `idToken null? false | accessToken null? false`
  - `Google Sign-In successful: <your-email>` (signup only)
- **Cancelled picker:** Orange snackbar — *"Google sign-in was cancelled or failed."*
- **Misconfigured serverClientId / SHA-1:** Red snackbar — *"Missing ID token from Google. Check serverClientId / SHA-1."* (this is the diagnostic that would have caught the original bug immediately).

## If It Still Fails
Watch the debug console for the `idToken null?` line:
- **`idToken null? true`** → `serverClientId` does not match an enabled Web OAuth client in this Firebase project, OR the debug SHA-1 on the machine running the build isn't the one registered in Firebase. Re-check both.
- **`idToken null? false` but no navigation** → check Firebase Console: Google provider not enabled, or OAuth consent screen not configured.
- **PlatformException thrown before `idToken` log** → usually missing Google Play Services on the device/emulator, or the package name mismatch (`com.example.frontend` must match `google-services.json`).
