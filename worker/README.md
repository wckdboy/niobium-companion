# Worker (optional desktop/private compute service)

Planned, **not implemented**. Per the brief (§3, §12), the desktop/private-server worker runs
heavier local models, document processing, media jobs or owner-authorized tools, and Android
connects through an authenticated protocol. It is packaged (Docker Compose) **only after direct
application workflows are complete**.

## Guardrails (binding)

- Bind local services conservatively; authenticate remote connections.
- Never expose a public unauthenticated inference/tool endpoint.
- The app must remain useful with direct provider access when the worker is absent (this is the
  current state — the app talks to providers directly).
- LiteLLM is an optional owner-operated gateway, not the only provider path and not a required
  public service.

## Status

`⬜` Not started. Do not treat as a dependency of the direct application workflows.
