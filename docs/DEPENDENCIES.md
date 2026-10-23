# Dependencies, licenses and checksums

Every external dependency is pinned. Nothing is fetched at build time from a moving branch.

## Engine

| Component | Version | Commit / build | License | Verification |
|---|---|---|---|---|
| Godot (editor + runtime) | **4.7.2-stable** | `ed1daf0bf` | MIT | Editor binary downloaded 2026-10-23 and checksummed (below) |

- Windows editor zip SHA-256: `731980F9608D61333E5BAF54A2EF17210ACC7A538446C0CB9969F002ACA1E953`
- Windows editor exe SHA-256: `AB1824F85BFD8E0E4128182C000C4003A3E042245B2967848D089B2A04B22424`

Export templates for Android/macOS/Linux are **not yet downloaded** (no target SDK/hardware in the
build environment). When added, record their exact version + SHA-256 here before any export claim.

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
| Java (Adoptium) | JDK 25 | present; Android SDK/NDK **absent** |
| Rust | **absent** | blocks GDExtension proof today (ADR-001) |
| Python | **stub (Store alias)** | absent as a real interpreter |

No API keys, OAuth secrets or signing keystores are stored in this repository.
