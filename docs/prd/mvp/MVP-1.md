# MVP1 — Arena single-player (= marco M1)

**Objetivo:** fase 1 completa contra bot, offline, com a arquitetura autoritativa já em uso (servidor embutido no processo — `ARCHITECTURE-GAME.md` §4).
**Módulos:** `game`, `shared`. **Prazo PRD:** 4 semanas. **Pré-condição:** gate M0 aprovado.
**Critério de pronto:** partida de 5:00 contra bot do início ao fim: Cavaleiro farma, sobe de nível, abre baús, equipa, enfrenta o boss aos 3:30, com HUD. Nenhum número fora de `.tres`.

## Fatias

| Slice | F / SPEC | Entrega | Fontes |
|---|---|---|---|
| 1.1 | F6 / SPEC-006 | `shared/` (junction), Resources, `.tres` de GDB §8, fórmulas em `shared/core`, cena de alinhamento | GDB §2, §3, §4, §5, §6, §8; PRD §11; ADR-0003 |
| 1.2 | F7 / SPEC-007 | arena hexagonal 3 zonas, portões, marcadores | PRD §3.1 |
| 1.3 | F8 / SPEC-008 | Cavaleiro completo, câmera 3ª pessoa, controles | PRD §3.6, §4.3; GDB §4.1; DV §3.3 |
| 1.4 | F9 / SPEC-009 | monstros tier 1–3, IA, XP/nível/pontos, catch-up | PRD §3.2, §5; GDB §3, §5 |
| 1.5 | F10 / SPEC-010 | baús, inventário, substituição, conjuntos | PRD §3.2, §6; GDB §6 |
| 1.6 | F11 / SPEC-011 | Rei Esqueleto 3:30, drop épico, relógio de partida | PRD §3.2; GDB §5.1 |
| 1.7 | F12 / SPEC-012 | bot fase 1, modo `--offline --bot` | PRD §3.7 |
| 1.8 | F13 / SPEC-013 | HUD fase 1 + componentes base + Theme inicial | DV tela 3; `design-system/` |

## Herança do MVP0 que este MVP tem de absorver

- `game/scripts/net/player.gd` tem números do spike (`MAX_HP 600`, `SPEED 5.0`, `ATTACK_DAMAGE 120`, cooldown 0,5 s) — **não são o GDB**. F6 cria os `.tres`; F8 faz o Cavaleiro ler deles e remove as constantes. Até lá, I4 (nenhum número fora de `.tres`) está suspenso só para esse arquivo.
- Padrão `HitLedger` (efeito aplicado pelo alvo no próprio `_rollback_tick`) é a regra para todo efeito entre nodes: empurrão do Q, escudo do E, stun do R, dano de monstro, consumível — `ARCHITECTURE-GAME.md` §3.2.
- CI tem só `test-game` + `gate`; `lint-gd` (números literais, I9) e path filter entram por card `[INFRA]` antes de F6.

## Pendências do PI que afetam este MVP

R-PEND-01 (épico em baú raro), R-PEND-05 (aviso 3:00), R-PEND-08 (`B` em partida), R-PEND-09 (Golem × Aranha). Sem decisão: F10 segue GDB; F13 sem aviso e sem `B`; F9 bloqueia no asset do tier 3.

## Fora deste MVP

Arqueira, rede entre máquinas, fase 2, pick, fim de partida, launcher.
