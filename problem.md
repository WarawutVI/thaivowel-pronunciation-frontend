# Problem: Google Sign-In Not Working on Android

## Symptom
Tapping "Continue with Google" shows the loading spinner then nothing happens — no navigation, no error message.

## Environment
- Flutter (Android emulator / physical device)
- Firebase project: `thesisproject-f33a2`
- Package: `com.example.frontend`
- Google Sign-In via `google_sign_in` + `firebase_auth` packages

## What Has Been Verified

| Check | Status |
|-------|--------|
| `INTERNET` permission in AndroidManifest | ✅ Added |
| `android:usesCleartextTraffic="true"` | ✅ Added |
| Debug SHA-1 in Firebase Console | ✅ `A8:37:BA:10:F5:A0:4A:6B:31:B2:77:A4:63:02:DB:51:7C:85:F1:34` |
| SHA-1 in `google-services.json` (`certificate_hash`) | ✅ Present |
| OAuth client type 1 (Android) in `google-services.json` | ✅ Present |
| OAuth client type 3 (Web) in `google-services.json` | ✅ Present |

## Root Cause Candidates

### 1. `googleSignIn.signIn()` returns null silently
The code does:
```dart
if (googleUser == null) {
  Get.back();
  return;  // ← silent return, no error shown
}
```
If the Google account picker is dismissed OR the sign-in fails internally, it returns null with no feedback.

**Fix:** Show a message when `googleUser == null`:
```dart
if (googleUser == null) {
  Get.back();
  Get.snackbar("Cancelled", "Google sign-in was cancelled or failed");
  return;
}
```

### 2. Google Sign-In not enabled in Firebase Console
Even with SHA-1 registered, the Google provider must be **enabled** in Firebase.

**Check:** Firebase Console → Authentication → Sign-in method → Google → must be **Enabled**

### 3. OAuth consent screen not configured
If the Google Cloud OAuth consent screen is not set up, sign-in fails silently on fresh projects.

**Check:** Google Cloud Console → APIs & Services → OAuth consent screen → must be configured

### 4. SHA-1 registered but `google-services.json` not re-downloaded
If SHA-1 was added after the file was last downloaded, the file won't have the new entry.

**Current state:** SHA-1 IS present in `google-services.json` → this is NOT the issue.

### 5. `PlatformException` swallowed by generic catch
`GoogleSignIn` throws `PlatformException`, not `FirebaseAuthException`. The generic `catch (e)` should catch it, but the snackbar might not show if `Get.back()` was already called.

## Diagnostic Steps

1. Add logging inside `signup_google()` to see exactly where it fails:
```dart
print("Starting Google Sign-In...");
final googleUser = await googleSignIn.signIn();
print("googleUser: $googleUser");
```

2. Run with `flutter run` and watch the debug console for the print output.

3. Check Firebase Console → Authentication → Sign-in method → Google is **Enabled**.

4. Check Google Cloud Console → APIs & Services → OAuth consent screen is configured.

## Files Changed So Far
- `lib/auth/signup.dart` — Firebase account creation moved here, error handling added
- `lib/auth/gender.dart` — `password` replaced with `uid`
- `lib/auth/age.dart` — uses `widget.uid` directly, Firebase import removed
- `android/app/src/main/AndroidManifest.xml` — INTERNET permission + cleartext flag added
