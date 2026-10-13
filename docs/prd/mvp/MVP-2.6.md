# MVP2.6 — Heróis 5 e 6: Ladina e Engenheiro (= marco M2.6)

**Objetivo:** pôr na partida a Ladina (Algoz, besta) e o Engenheiro (classe nova Engenheiro), completos: servidor autoritativo, equipamento visível, animações, VFX, seleção e bot (ADR-0013).
**Módulos:** `game`, `shared`. **Prazo PRD:** sem prazo definido pelo PI.
**Posição:** depois do `[GATE]` do MVP2 (#69, aprovado em 2026-10-13) e **antes** do MVP3 (decisão do PI em 2026-10-13: "Marco novo MVP2.6").
**Critério de pronto:** as 2 fatias aceitas pelo PI por verificação visual; o soak de cada herói verde (50 partidas bot × bot com o herói novo em todas, ≤ 10 min, nunca empate — SPEC-058/059 §8); o critério de netcode do ADR-0006 item 7 em cada uma.

> Numeração: as fatias deste marco usam `Slice 2.6.n` (três componentes), para não colidir com a Slice 2.6 do MVP2 (F19).

## Fatias

| Slice | F / SPEC | Entrega | Fontes |
|---|---|---|---|
| 2.6.1 | F58 / SPEC-058 | Ladina (Algoz): Virote, Rajada em Leque, Bomba de Fumaça (moita temporária, lançar não revela), Emboscada; `Rogue_Hooded` cor original; besta visível; animações; VFX; seleção; bot | ADR-0013; SPEC-058; GDB §4.5, §7.3 |
| 2.6.2 | F59 / SPEC-059 | Engenheiro (classe Engenheiro): Bacamarte, Garra Mecânica (puxa herói), Torreta (indestrutível, 6 s, heróis e monstros), Caixa de Dinamite; `Engineer` do Extra; bacamarte visível; animações; VFX; seleção; bot | ADR-0013; SPEC-059; GDB §4.6, §7.3 |

## Ordem e issues

Issue-pai **[MVP2.6]** (número no `STATUS.md` §1). Ordem: **`[INFRA]` (roadmap público aceita o marco MVP2.6) → F58 → F59**.

Dependências: F58 e F59 dependem do F48 (equipamento visível), do F41 (arquitetura de VFX), do F32/F37 (filtro de visão) e do F51 (seleção) — todos entregues. O F59 reusa a área temporária e o evento de VFX por visão criados no F58.

## Pendências do PI

- **Gate do MVP2.6:** não foi criado card `[GATE]` (mesmo caso do MVP2.5); cada fatia tem aceite visual do PI e soak próprio. Se quiser um gate de marco, é decisão do PI.
- **`[FIX]` do nome do Arqueiro** (ADR-0013 item 9): o Code abre o card para `ranger.tres` e telas; não bloqueia este marco.

## Fora deste MVP

Torreta destrutível ou com visão própria, textura alternativa do Extra, Druida e `BARBARIAN_LARGE`, dano contínuo (veneno, queimadura), passivas — `FORA-DE-ESCOPO.md`.
