# MVP2 — Partida em rede (= marco M2)

**Objetivo:** 1x1 online completo (duas máquinas, servidor dedicado) que **sempre** termina em ≤ 10 min.
**Módulos:** `game`. **Prazo PRD:** 4 semanas.
**Critério de pronto:** 1x1 online termina sempre; 50 partidas bot × bot headless sem travar e todas ≤ 10 min (I1); nunca empate (I2).

## Fatias

| Slice | F / SPEC | Entrega | Fontes |
|---|---|---|---|
| 2.1 | F14 / SPEC-014 | Arqueira: projétil validado, Q/E/R | PRD §4.3; GDB §4.2 |
| 2.2 | F15 / SPEC-015 | `MatchController` FSM, seleção de heróis, PvP fase 1, respawn, RPCs | PRD §3.2, §8.3; DV tela 2; `CONVENTION.md` §3 |
| 2.3 | F16 / SPEC-016 | zona, dano, respawn, kills, morte súbita, vitória | PRD §3.4, §3.5; GDB §7 |
| 2.4 | F17 / SPEC-017 | transição, HUD fase 2, vinheta | PRD §3.3; DV tela 4 |
| 2.5 | F18 / SPEC-018 | fim de partida com estatísticas | DV tela 7 |
| 2.6 | F19 / SPEC-019 | bot fase 2, soak 50 partidas | PRD §3.7, §8.7 |
| 2.7 | F20 / SPEC-020 | monstros/baús/boss replicados para 2 clientes reais | PRD §8.3 |
| gate | `[GATE]` | homologação: online termina sempre; soak verde | PRD §9.1 |

## Pendências do PI

R-PEND-04 (herói padrão no timeout), R-PEND-06 (monstros na fase 2). **Bloqueiam F15 e F16** se não decididas.

## Fora deste MVP

Backend, launcher, token de partida (o servidor aceita qualquer peer até F23).
