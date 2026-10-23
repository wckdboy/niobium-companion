# Testing and acceptance

## Two tiers

1. **Deterministic (headless)** — run on every change, no display, no credentials:
   `godot --headless --path app --script res://tests/run_all.gd`

   Covers: SSE streaming parser (fragmentation, UTF-8, tool deltas), cancellation/generation
   guards, turn sequencing, storage migrations, memory isolation, schema validation, performance
   cue validation/clamping, state transitions, and import validation-report logic.

2. **Rendered / audio / device** — cannot run in the CI environment; documented and executed on
   real hardware. These are the only evidence for the acceptance targets (frame time, memory,
   lip-sync offset, AEC, interruption latency).

## Required acceptance scenarios (brief §18)

Tracked in `docs/CHECKLIST.md`. Scenarios 1–16 are mapped to tests/harness where possible:

| # | Scenario | Deterministic coverage | Device coverage |
|---|---|---|---|
| 1 | Clean install → provider → synced response | fixtures | device/live |
| 2 | Switch model/provider mid-thread, identity stable | `unit` | device |
| 3 | Interrupt audio, no old audio/cues return | `unit` (generation guard) | device |
| 4 | Late/out-of-order TTS chunks stay sequenced | `unit` (sequencer) | device |
| 5 | Speaker playback without self-trigger | — | device (AEC) |
| 6 | Audio route change, mic revoke, background/restart | — | device (Android) |
| 7 | Bust/full switch while speaking, no reset | `unit` (state) | device |
| 8 | Invalid avatar import; current survives | `unit` (report) | device |
| 9 | Expression+blink+speech no overdrive | `unit` (morph clamp) | device |
| 10 | Long chat + media jobs don't freeze UI | — | device |
| 11 | Rate limit/expired key/offline/quota recoverable | fixtures (error states) | device/live |
| 12 | Delete/edit memory; gone from derived index | `unit` | — |
| 13 | Crash/cancel tool; no duplicate side effect | `unit` (job idempotency) | device |
| 14 | Export/import companion/project without credentials | `unit` | — |
| 15 | Local-only run, inspect for stray network | — | device |
| 16 | Install/build/run all platforms | — | device (absent hardware → unverified) |

## Device test harness

`docs/TIMING.md` (once captured) will record, per device: frame-time distribution over a
20-minute active test, memory trend, energy/thermal notes, quality preset, first-token latency,
first-audio latency, playback-start latency, interruption latency, and lip-sync offset.

## What "pass" means

- **Fixture/unit pass** — the code path is exercised deterministically. This is a real test, but
  it is not a live-integration or hardware claim.
- **Live pass** — needs owner-supplied, locally-configured credentials.
- **Device pass** — needs the actual Android arm64 / macOS arm64 / Linux x86_64 target.

Nothing is marked done on the basis of a mock unless explicitly a repeatable fixture test.
