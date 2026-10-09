---
paths:
  - "game/scripts/net/**"
  - "backend/**"
  - "infra/**"
---

# Network Code Rules

- Server is AUTHORITATIVE for all gameplay-critical state — never trust the client
- All network messages must be versioned for forward/backward compatibility
- Client predicts locally, reconciles with server — implement rollback for mispredictions
- Handle disconnection gracefully (reconnection is out of scope for the vertical slice; there is no host migration — dedicated server)
- Rate-limit all network logging to prevent log flooding
- All networked values must specify replication strategy: reliable/unreliable, frequency, interpolation
- Bandwidth budget: define and track per-message-type bandwidth usage
- Security: validate all incoming packet sizes and field ranges

## Project-specific (rrb-godot)

- Gameplay state lives in netfox `RollbackSynchronizer` state properties and is simulated in `_rollback_tick`; never mutate it in `_process`/`_physics_process`.
- Do NOT rely on `NetworkRollback.mutate(node)` for cross-node effects (netfox 1.35.3 loses the change when the target is resimulated). Record the effect in a server-only ledger outside rollback state (`HitLedger`) and let the TARGET apply it in its own `_rollback_tick`.
- Client input goes only through `BaseNetInput` subclasses (input broadcast disabled). Raw `@rpc` only for discrete, non-simulated events (UI, match lifecycle).
- Pure rules (damage, ranges, loot) go in `game/scripts/core/` with GUT tests; network scripts call them.
