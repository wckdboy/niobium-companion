# ADR-002 — Storage and persistence

- **Status:** Accepted
- **Date:** 2026-10-23

## Context

The brief requires durable local storage with a migration strategy, lexical search first
(embeddings optional), memory records with provenance/edit/delete/opt-out, and transactional jobs
whose states are queued/running/awaiting-approval/succeeded/failed/cancelled/interrupted.

SQLite is the requested backing store. Godot 4 has no built-in SQLite, and the build environment
has no Rust toolchain to build the planned GDExtension core, so SQLite cannot be *proven* here.

## Decision

1. Define a stable `Store` interface (typed, async-friendly) now, implemented by a **JSON
   document store** (`JsonStore`): one append-friendly document per record type with a
   write-ahead journal and an in-memory index rebuilt on open. Writes are atomic
   (write-temp → rename).
2. Keep **SQLite as the target backing implementation**, delivered through the Rust GDExtension
   core once it builds/loads on all three targets (see ADR-001). The `Store` interface is the
   stable boundary; `JsonStore` and a future `SqliteStore` are interchangeable implementations.
3. **Schema + migrations from day one:** a `schema_version` field and a versioned migration list.
   Missing/unknown migrations are surfaced, never silently ignored.
4. **Lexical search first:** a normalized token index over message/memory text. Embeddings are a
   separate, provider-configured feature and are never required for basic operation.
5. **Memory isolation:** identity, conversation history, explicit preferences, episodic memory,
   retrieved documents and transient emotional/performance state are separate record types. A
   temporary expression is never written as memory.
6. **Attachments by reference:** stores reference + provenance + content hash, not repeated
   binary blobs in message rows.

## Record types (initial)

`Conversation`, `Message`, `MemoryRecord`, `ToolInvocation`, `MediaJob`, `CompanionManifest`,
`ProviderProfile` (with `CredentialRef` pointing at the OS keystore, never inline secrets),
`DeviceProfile`, `JobLogEntry`.

## Consequences

- JSON store is simple and auditable, adequate for the single-owner scale of early gates; it is
  not a lie about SQLite because the target is documented and the interface is the contract.
- Deletion semantics (memory delete invalidating derived search records) are implemented at the
  index layer and covered by tests.
