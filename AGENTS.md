# AGENTS.md — Working in this repository

This file is authoritative for anyone (human or agent) modifying Niobium.

## Ground rules

1. **Inspect before editing.** The build brief is the source of truth for scope. Read it, then
   read the current state of the code before changing anything. Preserve useful existing code.
2. **Isolated changes, pinned dependencies.** One logical change per commit where practical.
   Pin engine, plugins and dependency versions. Never introduce a moving/`main` dependency.
3. **Do not fabricate success.** Do not claim packaging, credentials, OAuth, GPU tests, asset
   creation or live integration work that has not actually run. Missing credentials mean
   *not live-tested*, not *pass*. Mocks are for repeatable tests, not live-integration claims.
4. **Honest checklist.** Every gate updates `docs/CHECKLIST.md` with: what works, how it was
   tested, measured results, known gaps, and exact next tasks.
5. **Secrets.** Never write credentials into source, logs, build artifacts or companion exports.
   Signing keystores and `.env` files stay out of source control.
6. **Assets.** Never download a character with unsuitable redistribution/content permissions.
   Temporary engineering fixtures must be clearly labelled and excluded from completion claims.

## Build / verify commands

```sh
# Validate import and parse (headless first run)
godot --headless --path app --editor --quit

# Run the full deterministic test suite (no display, no credentials)
godot --headless --path app --script res://tests/run_all.gd

# Run a single test script
godot --headless --path app --script res://tests/<name>.gd

# Run the app (requires a display/GPU)
godot --path app
```

`godot` here is pinned to **4.7.2-stable** (`ed1daf0bf`).

## Architecture summary

- **Engine:** Godot 4.7 (GDScript, typed). See `docs/ADR-001-engine-and-boundaries.md`.
- **Boundaries:** companion scene, animation controller, speech session, provider adapters,
  storage and agent execution are separate interfaces. Prefer plain data types and
  independently testable logic; avoid one global scene singleton owning everything.
- **Storage:** GDScript JSON document store now; SQLite via a pinned Rust GDExtension core is
  the long-term shared boundary (see `docs/ADR-002-storage.md`). The storage interface is
  stable regardless of backing implementation.
- **Providers:** adapter-per-protocol + named service profiles. OpenAI-compatible chat/SSE is
  the first adapter. See `docs/ADR-003-provider-adapters.md`.
- **Never freeze rendering** awaiting network or database work.

## Where the code lives

```
app/scripts/core/       interfaces, provider adapters, sessions, jobs, persistence, tool policy
app/scripts/animation/  layered animation controller, viseme mapping, performance cues
app/scripts/speech/     ASR/TTS/VAD/audio-playback interfaces and implementations
app/scripts/providers/  protocol adapters + named service profiles
app/scripts/storage/    document store, migrations, indexes
app/scripts/companion/  companion orchestration (speech session, personality, memory glue)
app/scripts/ui/         chat UI, stage UI
app/scenes/             main, companion stage, chat
app/scripts/rig/        the procedural engineering rig (temporary, labelled)
app/tests/              GDScript tests
```

## Test philosophy

Write deterministic tests for streaming parsers, cancellation, migrations, memory isolation,
schema validation and state transitions. Do **not** write tests that merely restate constants or
mirror the implementation. Use rendered/audio/device tests (documented, run on hardware) for
behaviour unit tests cannot establish.

## Definition of done for a feature

- Implemented behind a stable interface.
- Deterministic tests added and passing (`run_all.gd`).
- Checklist entry updated with verification method and evidence.
- No secrets, no fabricated live-integration claims, no untracked large binaries.
