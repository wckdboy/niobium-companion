# macOS integration

Target: **arm64** first. This directory is reserved for native macOS integration (Keychain,
mic/file permission entitlements, audio-device routing, notarization).

## Status (honest)

- Application code targets macOS (see `app/export_presets.cfg`).
- **Unverified:** no macOS hardware in this environment. A cross-export is NOT a verified release.

## Requirements to complete Gate 6 (macOS)

1. On real macOS hardware, install Godot 4.7.2 and the macOS export template (record SHA-256).
2. Build + run; verify microphone + file access via entitlements (`audio_input`, file access).
3. Keychain-backed credential storage (`MACOS_KEYCHAIN` backend in `CredentialStore`).
4. Audio device change handling; high-DPI layout; keyboard shortcuts.
5. Signing + notarization with the owner's Apple credentials (documented, not pre-filled).

See `docs/EXPORTING.md`.
