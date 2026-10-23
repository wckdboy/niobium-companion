# Dependencies, licenses and checksums

Every external dependency is pinned. Nothing is fetched at build time from a moving branch.

## Engine

| Component | Version | Commit / build | License | Verification |
|---|---|---|---|---|
| Godot (editor + runtime) | **4.7.2-stable** | `ed1daf0bf` | MIT | Editor binary downloaded 2026-10-23 and checksummed (below) |

- Windows editor zip SHA-256: `731980F9608D61333E5BAF54A2EF17210ACC7A538446C0CB9969F002ACA1E953`
- Windows editor exe SHA-256: `AB1824F85BFD8E0E4128182C000C4003A3E042245B2967848D089B2A04B22424`
- Export templates (`Godot_v4.7.2-stable_export_templates.tpz`) SHA-256:
  `F298490B8D44D934BE425A5A65A51BF15F422428B229A06A6E11D9FFEA248011`

The Android Gradle build (from the pinned `android_source.zip` template) pins **Gradle 8.11.1**
and **AGP 8.6.1**, with `compileSdk 36`, `buildTools 36.1.0`, `ndk 29.0.14206865`, `minSdk 24`,
`targetSdk 36`, Kotlin 2.1.21, and **Java 17 minimum**.

## Godot plugins / addons

None committed yet. Candidates under evaluation (audit before adoption):

| Plugin | Purpose | License | Status |
|---|---|---|---|
| V-Sekai `godot-vrm` | VRM/MToon import | (check repo) | ⬜ not yet adopted; runtime-load-in-exported-app unproven |
| `godot-sqlite` (or Rust core) | SQLite backing | (check repo) | ⬜ deferred to ADR-002/001 |

## Third-party assets

| Asset | Provenance | License | Rights cleared | Status |
|---|---|---|---|---|
| Engineering rig (procedural, GDScript-generated) | authored in-repo | MIT (repo) | ✅ | temporary, labelled |
| Final character | — | — | — | **not created** (outstanding art task) |

## Reference projects (reuse policy, not dependencies)

| Project | License | Policy |
|---|---|---|
| AIRI (moeru-ai/airi) | check repo | architecture/renderer/audio reference; not transplanted |
| Open-LLM-VTuber | check repo | reference; bundled sample models have separate licenses |
| SillyTavern | AGPL-3.0 | behaviour reference only; no code copied into an incompatible license |
| godot-vrm / three-vrm | check repo | import/render candidates, audit first |

## Toolchain (build environment)

| Tool | Version | Notes |
|---|---|---|
| git | 2.56.0.windows.2 | |
| Node.js | available (`pi-node`) | for optional `worker/` later |
| Java (Temurin) | **JDK 17.0.20.1** | Downloaded 2026-10-23; required — Gradle 8.11.1 cannot run on JDK 25 |
| Java (Adoptium, present) | JDK 25 | Too new for the pinned Gradle; unused |
| Android SDK | platform-tools 37.0.1, platform android-37, build-tools 36.0.0, NDK 30.0.16248370 | Android Studio install at `%LOCALAPPDATA%\Android\Sdk` |
| Android emulator | AVD `Medium_Phone_API_37.0` (x86_64) | Used for install/launch smoke test |
| Rust | **absent** | blocks GDExtension proof today (ADR-001) |
| Python | **stub (Store alias)** | absent as a real interpreter |

No API keys, OAuth secrets or signing keystores are stored in this repository.
