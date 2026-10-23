# Linux integration

Target: **x86_64** first. This directory is reserved for Linux-specific integration (secret
service, microphone/file access, GPU compatibility, selectable audio devices, Wayland/X11).

## Status (honest)

- Application code targets Linux (see `app/export_presets.cfg`).
- **Unverified:** the build host is Windows; no Linux distribution has been built or tested.

## Requirements to complete Gate 6 (Linux)

1. Build/run on a chosen distribution (record which + GPU/driver).
2. Microphone + file access; selectable audio devices.
3. Linux secret-service credential storage (`LINUX_SECRET_SERVICE` backend).
4. Wayland/X11 limitations for optional transparent/always-on-top companion window
   (not guaranteed by a generic engine export — document explicitly).

See `docs/EXPORTING.md`.
