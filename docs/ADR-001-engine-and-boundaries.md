# ADR-001 — Engine and module boundaries

- **Status:** Accepted
- **Date:** 2026-10-23
- **Decision owner:** engineering agent (per build brief §3)

## Context

Niobium needs a real-time, fully rendered companion (face/eyes/head/body, speech animation),
a rich chat/creation UI, and a large provider/tool surface across Android, macOS and Linux.

The brief rules out piling Flutter + Godot + web renderer + Electron at once, and rules out a
Python daemon on Android. It defaults to a standalone Godot 4 application and permits a Rust core
via GDExtension as the *long-term* shared boundary, but only after that boundary is proven to
build/load on Android arm64, macOS arm64 and Linux x86_64.

## Decision

1. **Engine: Godot 4.7.2-stable** (`ed1daf0bf`), GDScript with full type hints, used as the
   application window on all three platforms initially. Pinned with its export templates and any
   plugins. No Flutter, no Electron, no web renderer in the primary app path.
2. **Renderer:** Forward+ on desktop; Mobile (Compatibility) profile for Android, with quality
   presets and measured fallback (see §14 of the brief).
3. **Initial boundaries are implemented in typed GDScript** behind stable interfaces, because
   the build environment has no Rust toolchain (`cargo`/`rustc` absent) and no Android NDK, so a
   GDExtension core cannot be *proven* to build/load on all three targets today. This is the
   explicitly sanctioned path in the brief ("implement the initial interfaces in typed GDScript
   and keep the boundary stable").
4. **Rust GDExtension core is the planned long-term shared boundary** for provider networking,
   persistent storage and durable jobs. It is introduced only after a build/load proof on
   Android arm64, macOS arm64 and Linux x86_64. The GDScript interfaces are designed so the
   backing implementation can be swapped without changing callers.
5. **No rendering freeze:** network/database work is asynchronous; the render loop never awaits
   it. Provider streaming is incremental (SSE), never a blocking full-body fetch.

## Module boundaries

Each is a `class_name` type with a narrow interface, plain data records in/out:

| Boundary | Responsibility | Key types |
|---|---|---|
| Companion scene | Stage, camera anchors, avatar instance | `CompanionStage`, `AvatarInstance` |
| Animation | Layered controller A–F, visemes, cues | `AnimationDirector`, `PerformanceCue`, `RigProfile` |
| Speech session | Turn lifecycle, interruption, sequencing | `SpeechSession`, `Turn`, `SpeechSegment` |
| Providers | Protocol adapters + service profiles | `ProviderAdapter`, `ProviderProfile`, `ModelCapability` |
| Storage | Durable JSON document store + migrations | `Store`, `Conversation`, `Message`, `MemoryRecord` |
| Agent/tools | Planner/executor, approvals, action log | `ToolInvocation`, `ApprovalDecision`, `ToolRegistry` |

`core/` (the brief's suggested tree) currently maps to `app/scripts/core/`; see
`docs/ARCHITECTURE.md` for the exact mapping and rationale for keeping logic inside the Godot
project for now.

## Engine/UI decision gate (brief §3)

Godot is not assumed to be a native productivity UI. The following must be validated on device
before chat depth expands, and a web-based (AIRI/Three.js) comparison is only made against the
same real character/device/audio workload:

- long chat lists, selectable rich text, code blocks
- international text input / IME
- Android keyboard resizing + safe area
- file dialogs, scaling, keyboard navigation alongside the avatar

Any migration recommendation will be backed by concrete evidence, not a quiet rewrite.

## Consequences

- We accept GDScript's relative immaturity for heavy text UI now, and track the gate above.
- We defer SQLite (see ADR-002) and native credential stores (see ADR-003) to platform work
  that cannot be verified in this environment, keeping interfaces stable.
