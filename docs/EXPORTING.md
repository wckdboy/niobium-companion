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

Verified working 2026-10-23 (build + install on local emulator). Exact procedure:

1. **JDK 17** (required — Gradle 8.11.1 cannot run on JDK 25). Set Godot's
   `export/android/java_sdk_path` to a JDK 17 install (Temurin 17 works).
2. **Export templates** installed at `%APPDATA%\Godot\export_templates\4.7.2.stable\`.
3. **Android build template** installed into the project (`res://android/build/`), i.e. extract
   `android_source.zip` from the templates and write a `.build_version` file (content
   `4.7.2.stable`) at `res://android/.build_version`. This is the "Install Android Build
   Template" step; `app/android/` is gitignored (reproducible from the pinned templates).
4. **ETC2/ASTC** texture compression enabled (`rendering/textures/vram_compression/import_etc2_astc=true`).
5. Debug keystore at `~/.android/debug.keystore` (alias `androiddebugkey`, password `android`).
6. Build:

   ```sh
   godot --headless --path app --export-debug "Android" "build/android/Niobium.apk"
   ```

7. Install: `adb install -r build/android/Niobium.apk`.

Notes:
- First build downloads Gradle/AGP/Maven deps (~minutes). Gradle `clean` can fail to delete its
  `android/build/build` output when the repo lives under **OneDrive** (Files On-Demand). Fix:
  `attrib +P /S /D` then `cmd /c rmdir /s /q` on the stale dir.
- **Required:** a `.gdignore` file at `res://android/.gdignore` (empty) so Godot's import scanner
  skips the build template. Without it, Godot imports the generated `icon.webp` launcher icons
  and writes `.webp.import` files that break AAPT ("file name must end with .xml or .png").
- Emulator: `-gpu host` is required (SwiftShader's GL uniform limit breaks Godot's canvas shader);
  `-no-window` mode does not update the `screencap` framebuffer — use a window, or the emulator
  console `adb emu screenrecord screenshot <hostpath>` for a live capture.
- The keystore and its password stay **out of source control**. See `.gitignore`.

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
