# Niobium — Feature checklist and evidence log

One source of truth for scope. Each row carries a status and, once worked, the verification
method and evidence. Statuses:

- `✅` done and verified
- `🟡` partially done / scaffolded
- `⬜` not started
- `🚫` deliberately not applicable now (documented)

**Verification legend:** `unit` = deterministic headless test; `fixture` = recorded/redacted test
data; `device` = real hardware (Android arm64 / macOS arm64 / Linux x86_64); `live` = owner
credentials against a real provider. Anything not `device`/`live` is not a completion claim.

Last updated: **2026-10-23**

---

## Gate 0 — Repository and dependency audit

| Item | Status | Verification / evidence |
|---|---|---|
| Existing-code map | ✅ | Workspace was empty; fresh repo established (`git init`), no prior code to preserve. |
| Pinned dependency proposal | ✅ | `docs/DEPENDENCIES.md` (Godot 4.7.2-stable `ed1daf0bf`, downloaded + checksummed). |
| Engine/UI decision record | ✅ | `docs/ADR-001-engine-and-boundaries.md`. |
| Platform build matrix | ✅ | `docs/ARCHITECTURE.md` § "Platform matrix" (targets vs. build-env reality). |
| Real model/asset inventory | ✅ | `docs/ASSETS.md` (engineering rig only; no authored character yet). |
| Full feature checklist | ✅ | This file. |
| AIRI / godot-vrm audit vs. target | 🟡 | Notes in `docs/ARCHITECTURE.md`; runtime VRM load in exported apps not yet proven (needs device). |

## Gate 1 — Animated conversation slice (brief §4)

| Item | Status | Verification / evidence |
|---|---|---|
| Load a legitimately usable rigged 3D character | 🟡 | Procedural engineering rig (`app/assets/rig/`), labelled temporary. Not final art. |
| Bust ↔ full-body camera switch, one identity | 🟡 | Camera anchors implemented; device render unverified. |
| Blend breathing, blinking, gaze, a gesture, one expression | 🟡 | Layered `AnimationDirector`; `unit`-tested state math, render unverified. |
| Real provider credential → streamed response | 🟡 | OpenAI-compatible SSE adapter + fixtures; `live` unverified (no credentials). |
| Speak response via real TTS | 🟡 | TTS interface + offline test synth; `live` TTS unverified. |
| Drive mouth from played audio timeline | 🟡 | Sample-clock viseme mapping; `unit`-tested timing math. |
| Interrupt speech, discard stale output | 🟡 | Cancellation/generation guard; `unit`-tested. |
| Save + restore conversation across restart | 🟡 | JSON store; `unit`-tested. |
| Timing/frame-time/memory evidence | ⬜ | Requires device capture; harness documented in `docs/TESTING.md`. |

## Gate 2 — Production character and voice

| Item | Status | Verification / evidence |
|---|---|---|
| Layered animation A–F, no double-driving | 🟡 | Controller skeleton; hair/cloth secondary N/A for primitive rig. |
| Robust audio interruption + AEC/speaker tests | ⬜ | `device`. |
| Expressive lip-sync | 🟡 | Viseme profile + audio-driven inference; `device` unverified. |
| Camera modes, materials, motion library | 🟡 | Camera anchors + motion slots; authored materials not yet. |
| Importer validation (malformed avatar survives) | 🟡 | Validation report type + glTF path; `unit` for report logic. |
| Character source assets | 🚫 | None authored; outstanding art task in `docs/ASSETS.md`. |

## Gate 3 — Provider and conversation depth

| Item | Status | Verification / evidence |
|---|---|---|
| Priority providers (OpenCode Go, Abliteration, DeepSeek) | 🟡 | Profiles + OpenAI-compatible transport; `live` unverified. |
| Protocol adapters (OpenAI SSE/tools, Anthropic, Gemini) | 🟡 | OpenAI SSE implemented; Anthropic/Gemini scaffolded. |
| Capability-driven settings, model switching | 🟡 | `ModelCapability` 3-valued model; UI partial. |
| Rich conversations (branch/edit/regenerate/search/pins/attachments) | ⬜ | |
| Projects, durable storage, native credential protection | 🟡 | Store + `CredentialStore` interface; native keystore needs device. |

## Gate 4 — Companion creation and memory

| Item | Status | Verification / evidence |
|---|---|---|
| Hatch (name/identity/traits/avatar/voice/motion) | ⬜ | |
| Identity/voice/appearance editing | ⬜ | |
| Inspectable memory (edit/delete/opt-out/export) | 🟡 | `MemoryRecord` + store; UI not yet. |
| Portable companion packages | ⬜ | |

## Gate 5 — Creation studio and agents

| Item | Status | Verification / evidence |
|---|---|---|
| Media jobs (image/TTS/video, durable IDs, progress, cancel) | 🟡 | `MediaJob` type; executor not yet. |
| Tools + permissions + approvals + action log | 🟡 | `ToolInvocation`/`ApprovalDecision` types; registry scaffold. |
| Paired-machine execution, diff review | ⬜ | |
| MCP transport (stdio desktop / remote Android) | ⬜ | |

## Gate 6 — Cross-platform completion

| Item | Status | Verification / evidence |
|---|---|---|
| Android arm64 lifecycle/mic/safe-area/APK | ⬜ | No Android SDK/device in build env. |
| macOS arm64 native export/signing | ⬜ | No macOS hardware. |
| Linux x86_64 package/audio/GPU | ⬜ | No Linux target in build env (Windows host). |
| Optional private sync / worker | ⬜ | |

---

## Explicit non-goals / guardrails

- No Autobot naming, no public registration, no marketplace, no analytics/ads/monetization.
- No continuous background companion rendering claim.
- No "any subscription login" or cookie-as-adapter auth.
- No silent plaintext credential downgrade.
- No fabricated device/live/GPU/asset/signing claims.

## Next tasks (ordered)

1. Finish procedural rig + `AnimationDirector` and get the app scene running headless-clean.
2. Wire SSE streaming + offline test TTS into the `SpeechSession` turn lifecycle.
3. Chat UI: streamed markdown, interrupt button, save/restore.
4. Grow `run_all.gd` to cover each added unit; keep it green.
5. Produce a device-test harness + exact "what remains unverified" list for Gate 1.
