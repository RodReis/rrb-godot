# [GATE] MVP4 — Playtest: plano e questionário (rascunho do Cowork)

**Issue:** #255 (issue-pai #246) · **Estado:** `planejado` — **formato e data do playtest em aberto** (decisão do PI em 2026-10-23: "complicado neste momento, pula essa parte"). O resto foi decidido em pop-up na mesma data.
**Fontes:** PRD §9.1–9.2, §3.6 (plano B), R2, R3; ADR-0024 item 1; ADR-0033 (telemetria); SPEC-029; `FORA-DE-ESCOPO.md` (`tools/export-matches.ps1` no MVP4)
**Depende de:** [GATE] MVP3 #87; F30 (#254) antes do playtest.

## 1. Critérios (PRD §9.2) e como medir

| Critério | Medida | Fonte |
|---|---|---|
| Partida termina em ≤ 10 min em 100 % | duração de cada partida `finished` | web-admin (F29) |
| Ping médio ≤ 80 ms no Brasil; nenhum teleporte | ping médio por jogador; teleportes por partida (dado de cliente, não confiável) + relato no questionário | web-admin (F29) + questionário |
| ≥ 7/10 pedem segunda partida espontaneamente | **telemetria:** o jogador entra de novo na fila **até 10 min** depois do fim da partida (ticket da fila × `ended_at`); **questionário** explica o porquê | consulta sobre `queue_tickets` e `matches` (sem campo novo), no relatório do gate |
| Líder de nível ao fim da fase 1 vence < 75 % | `level_at_phase1_end` × vencedor | web-admin (F29) |

## 2. Decisões que saem do gate (ADR novo cada)

Câmera 3ª pessoa × isométrica (R3); duração da fase 1, 5 min × 3–4 min (R2); ir ou não para 3x3; o que volta do `FORA-DE-ESCOPO.md`; abrir ou não o Early Access (só com ≥ 7/10, ADR-0024).

## 3. Em aberto (decisão do PI)

- Formato (remoto/presencial, em pares ou livre), data, convite e quem são as 10+ pessoas.
- Ferramenta de coleta do questionário e o que dela se guarda.

## 4. Questionário (rascunho do Cowork — o PI aprova ou corrige)

Respostas de 1 a 5 (1 = discordo totalmente, 5 = concordo totalmente), salvo onde indicado.

1. Eu jogaria outra partida agora. (1–5)
2. Por quê? (texto livre)
3. A câmera me deixou ver o que eu precisava ver. (1–5)
4. Prefiro câmera mais alta, de cima, mesmo perdendo o controle da mira. (1–5)
5. A fase de preparação (5 min) foi: curta demais / boa / longa demais.
6. Na preparação, eu sempre tinha algo útil para fazer. (1–5)
7. Vi o meu herói ou o do adversário "pular" de lugar durante a partida: nunca / uma vez / várias vezes.
8. Quem estava na frente no fim da preparação ganhou fácil demais. (1–5)
9. Jogaria com mais gente no time (3 contra 3). (1–5)
10. O tutorial me ensinou o que eu precisava para jogar. (1–5)
11. Algum herói pareceu forte ou fraco demais? Qual? (texto livre)
12. O que você mudaria primeiro? (texto livre)
