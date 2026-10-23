# ADR-003 — Provider adapters, auth and credential storage

- **Status:** Accepted
- **Date:** 2026-10-23

## Context

The brief requires an extensible adapter system, importable endpoint profiles and an
evidence-backed compatibility matrix — not a promise that every service works through one
protocol. Priority profiles: OpenCode Go, Abliteration.ai, DeepSeek; then OpenAI, Anthropic,
Gemini, xAI, OpenRouter, DeepInfra and other compatible endpoints; local/paired Ollama,
llama.cpp, LM Studio, vLLM.

## Decision

1. **Adapters are per-protocol, profiles are per-service.** An `OpenAICompatibleAdapter`
   implements chat-completions streaming SSE + tools; named profiles (`DeepSeekProfile`,
   `OpenCodeGoProfile`, `AbliterationProfile`, `OpenRouterProfile`, …) only supply base URL,
   model list, auth mode and capability facts. One protocol serves many profiles.
2. **First adapter:** OpenAI-compatible chat completions with streaming SSE, tool-call deltas,
   fragmented UTF-8/SSE handling, retries, cancellation and duplicate-side-effect avoidance.
   Anthropic messages and Gemini native adapters follow behind the same interface.
3. **Capabilities are three-valued:** `discovered` (from profile docs), `configured` (owner set
   it), `verified` (a live connection test passed). UI distinguishes these; a missing credential
   is "not live-tested", never "pass".
4. **Auth modes:** API key, custom header, no-auth local endpoint, and provider-documented
   OAuth/device flow via system browser (redirect/PKCE where supported). We never invent a
   "log in with any subscription" path, never store browser cookies as an adapter, and never
   report OAuth done just because a login page opened.
5. **Credentials:** a `CredentialRef` (provider-scoped ID) is stored in the OS keystore —
   Android Keystore, macOS Keychain, Linux secret-service — never inline, never in logs, crash
   dumps, backups or companion exports. In this environment (no device/keychain), the
   `CredentialStore` interface ships with a clearly-labelled *unavailable* state and an explicit
   locked/failure state; there is no silent plaintext downgrade. A local-only dev vault is
   provided behind an opt-in flag and is clearly marked insecure.
6. **Never silently switch providers.** Every request records its route; rate limits, quota,
   timeout and estimated-vs-actual usage are surfaced distinctly.

## Consequences

- Only OpenAI-compatible transport is exercised by fixtures today; everything else is scaffolded
  and documented as unverified until live credentials are supplied on real hardware.
- Provider documentation is refreshed at implementation time; no permanently-current model
  catalog is hard-coded.
