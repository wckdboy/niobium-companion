# Timing and measurement (placeholder — no device captures yet)

This file records per-device acceptance measurements (brief §14). It is empty of results because
the build environment has no Android arm64 / macOS arm64 / Linux x86_64 hardware and no
microphone/speaker access. **Nothing below is claimed to have been measured.**

## Harness (to run on device)

1. Launch the app and start a 20-minute active conversation/voice session.
2. Record per frame: `delta`, frame time; log memory trend and thermal notes.
3. Measure the latency chain separately:
   - engine/render latency (frame time distribution)
   - network first-token latency
   - first synthesized audio latency
   - playback start latency
   - interruption latency (target: local playback cancellation < ~200 ms)
4. Measure lip-sync offset on each audio route (target ≈ 80 ms); report failures + calibration.

## Fields to fill per device

| Device | OS/arch | Quality preset | frame-time p50/p99 | 20-min mem trend | thermal | first-token | first-audio | interruption | lip-sync offset |
|---|---|---|---|---|---|---|---|---|---|
| (none yet) | — | — | — | — | — | — | — | — | — |

## Rules

- Report measured values only. Do not guess precision.
- Lower shadows/physics/render scale + LOD fallback must preserve identity and disclose
  unavailable features (brief §14).
