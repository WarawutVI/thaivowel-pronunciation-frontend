# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter frontend for a Thai vowel pronunciation learning app. Users can practice pronunciation, take lessons, and track progress. Firebase handles auth; a Node.js/Express backend at `http://10.0.2.2:3000` (Android emulator localhost) stores user profiles.

## Commands

```bash
# Run on connected device or emulator
flutter run

# Run on specific platform
flutter run -d chrome
flutter run -d windows

# Build
flutter build apk
flutter build web

# Lint
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Update Firebase config (requires FlutterFire CLI)
flutterfire configure
```

## Architecture

**State management & navigation:** GetX (`get: ^4.7.3`). Navigation uses `Get.to()` / `Get.offAll()` directly — no named routes are defined.

**Auth flow:**
1. `main.dart` → initializes Firebase, sets root to `Wrapper`
2. `wrapper.dart` → `StreamBuilder` on `FirebaseAuth.instance.authStateChanges()` — routes to `Homepage` if logged in, `Login` otherwise
3. Login/signup support email+password and Google Sign-In
4. After signup: email → `Signup` → `Gender` → `Age` → POSTs to `/users` → `Homepage`

**Bilingual UI (EN/TH):** Each page holds a local `bool isEnglish` state variable and uses a helper `t(String en, String th) => isEnglish ? en : th` inline. The `intl` package is imported but not used for this; it's a simple toggle.

**Backend integration:** `Age` page posts user data (email, name, age, gender) to `http://10.0.2.2:3000/users` via `http` package. `10.0.2.2` is the Android emulator's alias for localhost; adjust this for real devices or other platforms.

**Assets:** Feature images live in `assets/picture/` and are declared in `pubspec.yaml`.

**Firebase:** Config is auto-generated in `lib/firebase_options.dart` — do not hand-edit. Re-run `flutterfire configure` if Firebase settings change.

## Current Development State

`lib/pages/lessonspage.dart`, `practicepage.dart`, and `progreespage.dart` are all stubs (just `Placeholder()` widgets). The core auth flow (`lib/auth/`) is complete. The three main feature pages are the primary area of active development.

## Color Scheme

Green theme: primary `#1A7A50`, dark variant `#1A6B45`, accent `#2A9B6A`. Configured as a MaterialApp seed color.
