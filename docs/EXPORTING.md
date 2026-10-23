# Exporting and signing

Export presets for Android, macOS and Linux are authored in `app/export_presets.cfg`. **No
export has been produced or installed** in the build environment (no Android SDK, no macOS host,
no Linux host, no signing credentials). These are instructions, not a record of a completed
build.

## Prerequisites

1. Godot **4.7.2-stable** (`ed1daf0bf`) editor.
2. Download the matching export templates for each target from the Godot release page, then
   record the exact version + SHA-256 in `docs/DEPENDENCIES.md` **before** exporting.

## Android (sideloadable APK)

```sh
# 1. Install Android SDK/NDK; point Godot at them (Editor > Editor Settings > Export > Android).
# 2. Generate a keystore (keep it OUT of source control):
keytool -genkey -v -keystore ~/niobium.keystore -alias niobium -keyalg RSA -keysize 2048 -validity 10000
# 3. In export preset Android > Keystore, set the release/debug keystore + alias + passwords.
# 4. Export APK (arm64-v8a).
```

- Never commit `*.keystore`, `*.jks`, or passwords. See `.gitignore`.
- Install with `adb install build/android/Niobium.apk`.

## macOS (arm64)

- Build/export on real macOS hardware with the arm64 template.
- Mic permission (`audio_input`) and file access entitlements are pre-declared in the preset.
- Signing + notarization require the owner's Apple Developer credentials — do not pre-fill them.

## Linux (x86_64)

- Export with the x86_64 template (`binary_format/architecture=x86_64`).
- Produce a reproducible package per distribution; document audio/GPU and Wayland/X11 limits.

## Verification

Mark a target as *verified* only after installing and running on real hardware and executing the
scenario matrix in `docs/TESTING.md`. Absent hardware → `unverified` in `docs/CHECKLIST.md`.
