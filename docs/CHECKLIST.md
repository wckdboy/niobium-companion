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
| Load a legitimately usable rigged 3D character | ✅ | Procedural engineering rig (`app/scripts/rig/`), labelled temporary (not final art). `unit`: 21 bones, 8 face blend shapes, 4 camera anchors. **Rendered**: local Vulkan (RTX 5070 Ti) + Android emulator (x86_64) show the lit violet character. |
| Bust ↔ full-body camera switch, one identity | 🟡 | Camera anchors + `set_camera_mode` implemented; `unit`-checked anchors exist; device render unverified. |
| Blend breathing, blinking, gaze, a gesture, one expression | 🟡 | Layered `AnimationDirector`; `unit`: morph clamp [0,1], gesture lifecycle→neutral, blink L==R. Render unverified. |
| Real provider credential → streamed response | 🟡 | OpenAI-compatible SSE adapter; `fixture`: parser fragmentation/UTF-8/tool deltas/errors. `live` unverified (no credentials). |
| Speak response via real TTS | 🟡 | TTS interface + offline `TestTTS` (labelled dev synth); `unit`: session produces segments. `live` TTS unverified. |
| Drive mouth from played audio timeline | 🟡 | Sample-clock viseme mapping; `unit`: `VisemeTimeline` interpolation. Audio route unverified. |
| Interrupt speech, discard stale output | 🟡 | Cancellation/generation guard + sequencer; `unit`: interrupt stores only pre-interrupt content, drops stale. |
| Save + restore conversation across restart | 🟡 | JSON store; `unit`: persistence + search index rebuild across reopen. |
| Timing/frame-time/memory evidence | ⬜ | Requires device capture; harness in `docs/TIMING.md`. |

**Slice status:** the app boots headless-clean (10-frame smoke test, no errors), the offline
pipeline (LLM stream → TTS → sequenced audio → sample-clock visemes → interruption →
persistence) is exercised end-to-end by fixtures, and the **character renders on Android**
(emulator x86_64) and on local Vulkan. What remains unverified is **audio output, microphone,
speaker/AEC, and physical-arm64 device behaviour** — none of which this environment can produce,
and none of which is claimed.

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
| Android arm64 lifecycle/mic/safe-area/APK | 🟡 | APK builds (Gradle/JDK17), installs + launches + **renders the character** on emulator (x86_64). Physical arm64 device, mic, audio-routing, AEC still unverified. |
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

1. Device/live verification of Gate 1 (Android arm64 + one desktop): real credential stream,
   real TTS, speaker + AEC test, lip-sync offset, interruption latency, frame-time/memory
   capture. See `docs/TESTING.md` + `docs/TIMING.md`.
2. Wire the live `OpenAICompatibleAdapter` (already implemented) into `main.gd` behind a
   provider picker + `CredentialStore`, replacing the scripted demo for credentialed runs.
3. Anthropic + Gemini adapters (interfaces exist; `ProviderCatalog` marks their protocols).
4. Authored character asset (outstanding art task, `docs/ASSETS.md`) or a reviewed VRM/glTF
   import path with runtime-load-in-exported-app proof.
5. Rich chat (markdown/code highlight, branch/edit/regenerate, attachments) behind the UI gate.
