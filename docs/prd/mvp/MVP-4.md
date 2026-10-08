# MVP4 — Playtest (= marco M4)

**Objetivo:** validar o core loop com 10+ pessoas externas e decidir câmera, duração e ida para 3x3.
**Módulos:** todos. **Prazo PRD:** 2 semanas.
**Critério de pronto (PRD §9.2):** 100 % das partidas ≤ 10 min; ping médio ≤ 80 ms no Brasil, nenhum "teleporte"; ≥ 7/10 pedem segunda partida; líder de nível ao fim da fase 1 vence < 75 %.

## Fatias

| Slice | F / SPEC | Entrega | Fontes |
|---|---|---|---|
| 4.1 | F29 / SPEC-029 | telemetria (ping, duração, líder F1 × vencedor, teleportes reportados), KPIs no histórico, `tools/export-matches.ps1` | PRD §8.5, §9.2; DV tela 9; BM §5 |
| 4.2 | F30 / SPEC-030 | ajustes de balanceamento pós-playtest (só `.tres`) | GDB §1.1 |
| gate | `[GATE]` | playtest executado; questionário; decisões registradas em ADR | PRD §9.1, §3.6 (plano B), R2, R3 |

## Decisões que saem deste gate (ADRs novos)

Câmera 3ª pessoa × isométrica; duração da fase 1 (5 min × 3–4 min, R2); ir ou não para 3x3; o que do `FORA-DE-ESCOPO.md` volta.
