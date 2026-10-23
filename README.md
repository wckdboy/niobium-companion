# Niobium

A private, single-owner AI companion and creation workbench. Local-first applications for
Android, macOS and Linux, with optional owner-operated services. No mandatory account, hosted
SaaS dependency, subscription system, marketing site, social network, marketplace or
multi-tenant administration.

The central experience is a fully rendered companion — expressive face, eyes, head, shoulders,
hands and full body — with convincing speech animation, a consistent personality, controllable
memory, real conversation, useful tools and multimodal creation. The owner chooses the model,
provider, voice, character and compute location independently.

> **Status:** active engineering. This repository is being built as a working vertical slice
> first, then broadened. See [`docs/CHECKLIST.md`](docs/CHECKLIST.md) for the honest feature
> matrix and [`docs/ADR-001-engine-and-boundaries.md`](docs/ADR-001-engine-and-boundaries.md)
> for the architecture decision record.

## What this is (and is not)

- **Is:** a private companion + creation workbench you run yourself.
- **Is not:** a public service, a marketplace, a social network, a subscription wall, or
  "Autobot". The application is named **Niobium**.

## Layout

```
app/                 Godot 4 project (UI, stage, scene orchestration) — the primary app
core/                Provider interfaces, sessions, jobs, persistence, tool policy (currently
                     implemented in GDScript inside app/scripts/core; see ADR-001)
native/android/      Android integration notes and build glue
native/macos/        macOS integration notes
native/linux/        Linux integration notes
avatars/             Manifests, rig profiles, motion maps, rights-cleared assets
worker/              Optional desktop/private compute service (planned, post direct workflows)
schemas/             Versioned JSON schemas (events, companion packages, provider capabilities)
fixtures/            Recorded/redacted protocol/audio/animation test data
tests/               Cross-component and platform checks (GDScript, run headless)
docs/                Architecture decisions, setup, asset requirements, validation
```

## Quick start (development)

1. Install **Godot 4.7.2** (stable). The editor binary is not committed.
2. Open `app/project.godot` in the editor, or run from the CLI:

   ```sh
   godot --headless --path app --editor --quit        # validate import / first-run
   godot --headless --path app --script res://tests/run_all.gd   # run the test suite
   godot --path app                                   # run the app (needs a display)
   ```

3. The first-run scene loads an engineering rig (a procedurally built humanoid) because no
   final authored character asset is committed yet. See [`docs/ASSETS.md`](docs/ASSETS.md).

## Verifying a build

There is **no fabricated "it works"** here. Everything that can be checked headlessly is checked
by the test suite. Rendering, microphone, speaker and device behaviour require real hardware
(Android arm64, macOS arm64, Linux x86_64) that is not available in the build environment; those
items are explicitly listed as *unverified* in the checklist rather than marked complete.

## License / provenance

Niobium is the owner's private application. Third-party dependencies and any bundled assets are
tracked with pinned versions, licenses and checksums in
[`docs/DEPENDENCIES.md`](docs/DEPENDENCIES.md). No character with unsuitable redistribution or
content permissions is ever downloaded silently.
