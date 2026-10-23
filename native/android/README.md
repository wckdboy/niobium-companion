# Android integration

Target: **arm64** first. This directory is reserved for Kotlin/Android glue that requires the
Android SDK/NDK — which is **not present in the build environment**, so no APK has been
produced or installed.

## Status (honest)

- Application code targets Android (see `app/export_presets.cfg`, Mobile/GL Compatibility renderer).
- **Unverified:** no Android SDK, no ADB, no arm64 device in this environment.

## Requirements to complete Gate 6 (Android)

1. Install Android SDK + NDK and configure Godot's Android export.
2. Download the matching Godot 4.7.2 Android export template (record SHA-256 in
   `docs/DEPENDENCIES.md`).
3. Set `gradle_build/use_gradle_build=true`; verify a debug APK builds.
4. Real device checks (scenario matrix in `docs/TESTING.md`):
   - microphone permission + runtime request
   - audio focus loss, Bluetooth route change, headphone unplug, phone call
   - backgrounding/foregrounding; pause 3D rendering offscreen
   - safe-area + keyboard resize + IME (international text input)
   - process recreation resumes cleanly
   - 30 fps baseline, thermal/power observations over a 20-minute session
5. Credential storage via **Android Keystore** (see `CredentialStore`; the `ANDROID_KEYSTORE`
   backend is stubbed and must be implemented with a GDExtension or Android plugin).

## Signing

Sideloadable APK requires a keystore. Keep the keystore and its password **out of source
control**. See `docs/EXPORTING.md`.

## What is NOT claimed

No APK, no keystore, no device test, no "Android ready" statement. Continuous background
companion rendering is explicitly out of scope (brief §7).
