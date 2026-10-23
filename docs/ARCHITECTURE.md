# Architecture

Niobium is a **standalone Godot 4.7 application** with typed GDScript behind stable interfaces.
A Rust GDExtension core is the planned long-term shared boundary (see ADR-001); today the
interfaces live in GDScript so they can be swapped without touching callers.

## Topology

```
┌─────────────────────────────── app (Godot 4.7, GDScript) ───────────────────────────────┐
│                                                                                          │
│  CompanionStage ── AvatarInstance ── AnimationDirector ── RigProfile ── Skeleton3D       │
│        │                  │              (layers A–F, visemes, PerformanceCue)            │
│        │                  └─ CameraRig (portrait/bust/waist/full anchors)                 │
│        │                                                                                 │
│  ChatUI ── SpeechSession ──┬─ ProviderAdapter (OpenAI-compatible SSE, Anthropic, Gemini) │
│                            ├─ TTSProvider ── AudioPlayback (sample-clock sync)           │
│                            ├─ ASRProvider (mic → VAD → transcription)                    │
│                            └─ Cancellation/generation guard                               │
│        │                                                                                 │
│  Store (JSON now, SQLite later) ── indexes / migrations                                   │
│  CredentialStore ── OS keystore (Android/Mac/Linux; unavailable-safe)                     │
│  ToolRegistry ── ToolInvocation ── ApprovalDecision ── MediaJob                           │
└──────────────────────────────────────────────────────────────────────────────────────────┘
        │ HTTPS (owner-chosen provider)          │ authenticated protocol (planned)
        ▼                                        ▼
   LLM / TTS / ASR providers               optional desktop worker / private server
```

## Data flow for a turn

```
mic → VAD → ASR → SpeechSession.new_turn()
        → ProviderAdapter.stream() (incremental SSE)  ── no render freeze ──
        → assistant text (streamed to ChatUI)
        → TTSProvider.synthesize() (chunks) → AudioPlayback
        → sample-clock viseme timeline → AnimationDirector
        → interruption bumps generation, cancels network, drops stale chunks
        → Store.commit(only content actually presented/heard)
```

The **playback sample clock** is the synchronization authority for visemes; network arrival
order is not.

## Module map (brief §15 vs. actual location)

| Brief boundary | Location today | Notes |
|---|---|---|
| `app/` (Godot project) | `app/` | Scene/UI/stage |
| `core/` | `app/scripts/core/` + `providers/` + `storage/` + `speech/` + `companion/` | Kept inside the project so `class_name` resolution and headless tests work without a submodule; interfaces remain stable for the Rust core swap. |
| `native/{android,macos,linux}/` | `native/…/README.md` | Integration points documented; no SDK/hardware in build env. |
| `avatars/` | `avatars/` | Rig profiles, motion maps, manifests, rights metadata. |
| `worker/` | `worker/README.md` | Planned post-direct-workflows; Docker Compose only later. |
| `schemas/` | `schemas/*.json` | Versioned JSON Schema for events/packages/capabilities. |
| `fixtures/` | `fixtures/` | Redacted protocol/audio/animation test data. |
| `tests/` | `app/tests/` | GDScript, run headless. |

## Platform matrix (build environment reality, 2026-10-23)

| Target | Build env support | Application code | Verification state |
|---|---|---|---|
| Windows x86_64 (dev host) | ✅ Godot editor installed | ✅ runs | render/audio untested in CI |
| Android arm64 | ⚠️ SDK+emulator present (x86_64 AVD); no physical arm64 device | ✅ builds | **APK builds + installs + launches on x86_64 emulator; physical arm64 unverified** |
| macOS arm64 | ❌ no macOS host | ⚙️ written | **unverified** |
| Linux x86_64 | ❌ no Linux host | ⚙️ written | **unverified** |

Export presets for all three are authored in `app/export_presets.cfg`. The Android APK has
been built (Gradle/AGP via the pinned export templates, JDK 17) and smoke-tested on an emulator;
macOS/Linux have not been built. This is recorded, not papered over.

## Reference-project audit (brief §2, checked 2026-10-23)

- **AIRI** — closest conceptual reference (VRM/Live2D, voice pipeline, many providers, web/desktop
  + experimental Pocket). Pocket's documented instructions are iOS-oriented; Android production
  readiness is not established by its README. Treat renderer/audio/provider architecture as
  reference, not a monorepo to transplant.
- **Open-LLM-VTuber** — useful for interruptible voice/personas/desktop presentation; primarily
  Live2D; v2 is discussion/planning while v1 receives bug work; bundled sample models have
  separate licenses.
- **SillyTavern** — AGPL-3.0; behaviour reference only, no code copied into an incompatible
  license.
- **godot-vrm (V-Sekai)** — candidate VRM/MToon importer. Key open question: can user-imported
  VRMs load at *runtime in exported apps* (editor import alone is insufficient)? Unproven here.
- **three-vrm** — alternative web renderer; only compared against the same real workload.

## Non-negotiables (recalled from brief)

- No render freeze on network/db work. No LLM in the render loop.
- Interruption < ~200 ms local playback cancellation (measured, reported, not assumed).
- Lip-sync offset ≈ 80 ms on tested audio routes (measured; failures reported with calibration).
- Desktop 60 fps / Android 30 fps baseline targets, measured per device.
- Pause 3D when hidden/backgrounded.
- Secrets never in logs/exports/backups; no silent plaintext downgrade.
