# MVP0 — Spike de netcode (= marco M0 do PRD §9.1)

**Objetivo:** provar que Godot 4.7 + netfox entrega movimento com predição e um ataque validado no servidor jogáveis a 100 ms de RTT. É o gate Godot × Unity (PRD §10.3, R1).
**Módulos:** `game`, `infra`. **Prazo PRD:** 2 semanas. **Passo a passo:** `docs/superpowers/plans/2026-10-08-m0-spike-netcode.md`.
**Critério de pronto:** 2 clientes + servidor headless em Docker local; cápsula com predição; 1 ataque validado no servidor; jogável a 100 ms simulados sem "borracha" perceptível (avaliação do PI).

## Fatias

| Slice | F / SPEC | Entrega | Tarefas do plano |
|---|---|---|---|
| 0.1 | F1 / SPEC-001 | `game/` reestruturado, netfox + GUT instalados, `tools/test.ps1` | 0, 1, 2, 3 (runner) |
| 0.2 | F2 / SPEC-002 | `LaunchArgs`, `CombatRules`, `AimMath`, `InputActions` com GUT | 3, 4, 5, 6 |
| 0.3 | F3 / SPEC-003 | arena gerada em código, conexão servidor/cliente, player com rollback | 7, 8 |
| 0.4 | F4 / SPEC-004 | ataque corpo a corpo validado no servidor, HUD de rede, autopilot | 9, 10 |
| 0.5 | F5 / SPEC-005 | servidor em Docker com `tc netem` (+100 ms, 2 %) | 11 |
| gate | `[GATE]` | protocolo do gate executado, ADR-0001 escrito, decisão do PI | 12 |

## Fora deste MVP

Qualquer conteúdo (heróis, monstros, itens), `shared/`, launcher, backend. Se o gate reprovar, nada disso é construído em Godot.
