# MVP4 — Playtest (= marco M4)

**Objetivo:** validar o core loop com 10+ pessoas externas e decidir câmera, duração e ida para 3x3.
**Módulos:** todos. **Prazo PRD:** 2 semanas.
**Critério de pronto (PRD §9.2):** 100 % das partidas ≤ 10 min; ping médio ≤ 80 ms no Brasil, nenhum "teleporte"; ≥ 7/10 pedem segunda partida; líder de nível ao fim da fase 1 vence < 75 %.
**Estado:** planejado — nenhuma fatia iniciada; depende do `[GATE]` MVP3 #87. Em 2026-10-19 o PI acrescentou o spike visual (F84), o tutorial (F85) e a publicação no itch.io (F86), antes do playtest (ADR-0024, ADR-0026). O balanceamento dos 10 heróis (soaks fora do espelho: Berserker 44/44, Paladino 33/45, Ocultista 8/45) entra no F30.

## Fatias

| Slice | F / SPEC | Entrega | Fontes |
|---|---|---|---|
| 4.1 | F29 / SPEC-029 | telemetria (ping, duração, líder F1 × vencedor, teleportes reportados), KPIs no histórico, `tools/export-matches.ps1` | PRD §8.5, §9.2; DV tela 9; BM §5 |
| 4.2 | F30 / SPEC-030 | ajustes de balanceamento pós-playtest (só `.tres`) | GDB §1.1 |
| 4.3 | F84 / SPEC-084 | spike visual (`game`, `shared`, `art`): 1 herói + 1 canto da arena com arte de qualidade maior, no Godot 4.7 e no pipeline atual; captura lado a lado com o estado de hoje; decide o caminho visual (engine segue Godot) | ADR-0024 item 5; decisão do PI 2026-10-19 ("agora") |
| 4.4 | F85 / SPEC-085 | tutorial guiado offline (`game`, `launcher`, `backend`, `shared`): obrigatório na 1ª vez, pulável; fila online libera após o tutorial ou 1 vitória contra o bot | ADR-0026 itens 5–6 |
| 4.5 | F86 / SPEC-086 | publicação no itch.io (`infra`, `tools`, CI): página do jogo e build enviada a cada Release | ADR-0024 item 2 |
| gate | `[GATE]` | playtest executado; questionário; decisões registradas em ADR | PRD §9.1, §3.6 (plano B), R2, R3 |

## Decisões que saem deste gate (ADRs novos)

Câmera 3ª pessoa × isométrica; duração da fase 1 (5 min × 3–4 min, R2); ir ou não para 3x3; o que do `FORA-DE-ESCOPO.md` volta. O gate também decide a abertura do Early Access (MVP5): só abre com ≥ 7/10 pedindo segunda partida (ADR-0024).

Em aberto antes das SPECs: F84 — qual herói, qual canto, origem da arte (comprada, comissionada ou Blender); F85 — roteiro final (proposta: mover/câmera → alvo e auto-ataque → Q/E/R → monstro e XP → baú `F` e ficha `B` → fase 2); F86 — conta do itch.io do PI e se a build vai como ZIP ou instalador.
