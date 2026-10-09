# MVP1 — Arena single-player (= marco M1)

**Objetivo:** fase 1 completa contra bot, offline, com a arquitetura autoritativa já em uso (servidor embutido no processo — `ARCHITECTURE-GAME.md` §4).
**Módulos:** `game`, `shared`. **Prazo PRD:** 4 semanas. **Pré-condição:** gate M0 aprovado.
**Critério de pronto:** partida de 5:00 contra bot do início ao fim: Cavaleiro farma, sobe de nível, abre baús, equipa, enfrenta o boss aos 3:30, com HUD. Nenhum número fora de `.tres`.

## Fatias

| Slice | F / SPEC | Entrega | Fontes |
|---|---|---|---|
| 1.1 | F6 / SPEC-006 | `shared/` (junction), Resources, `.tres` de GDB §8, fórmulas em `shared/core`, cena de alinhamento | GDB §2, §3, §4, §5, §6, §8; PRD §11; ADR-0003 |
| 1.2 | F7 / SPEC-007 | arena "Vale Rúnico" conforme [`spec/SPEC-007.md`](spec/SPEC-007.md): raio 35 u, rio com 2 pontes, cratera com 4 entradas, portões, mato (geometria), marcadores | PRD §3.1; GDB §5.1, §6.2, §7.1; SPEC-007 |
| 1.3 | F31 / SPEC-031 | câmera 3ª pessoa (~45°, distância fixa), controles teclado/mouse/gamepad, cena de alinhamento KayKit; **avaliação de câmera pelo PI** (B-02) com a cápsula do M0 | PRD §3.6, §11; DV §3.3; BM §5.1 |
| 1.4 | F8 / SPEC-008 | Cavaleiro: modelo KayKit Knight, ataque básico em arco, Q Investida (empurrão via ledger), E Muralha (escudo/bloqueio), R Terremoto (stun via ledger) — tudo lendo `shared/data/heroes/knight.tres` | PRD §4.3; GDB §4.1 |
| 1.5 | F9 / SPEC-009 | monstros tier 1–3, IA, XP/nível/pontos, catch-up | PRD §3.2, §5; GDB §3, §5 |
| 1.6 | F10 / SPEC-010 | baús, inventário, substituição, conjuntos | PRD §3.2, §6; GDB §6 |
| 1.7 | F11 / SPEC-011 | Rei Esqueleto 3:30, drop épico, relógio de partida | PRD §3.2; GDB §5.1 |
| 1.8 | F12 / SPEC-012 | bot fase 1, modo `--offline --bot` | PRD §3.7 |
| 1.9 | F13 / SPEC-013 | HUD fase 1 + aviso global do boss aos 3:00 (banner + som) + bestiário em partida pela tecla `B` (modal com `CatalogList`/`DetailCard` de `shared/ui`) + componentes base + Theme inicial | DV telas 3 e 5; BM §3.2; `design-system/` |
| gate | `[GATE]` | fase 1 completa contra bot, offline, avaliada pelo PI | PRD §9.1 |
| infra | `[INFRA]` | CI com `lint-gd`, path filter e `shared/test` — **antes de F6** | `CI-PR.md` §2 |

## Herança do MVP0 que este MVP tem de absorver

- `game/scripts/net/player.gd` tem números do spike (`MAX_HP 600`, `SPEED 5.0`, `ATTACK_DAMAGE 120`, cooldown 0,5 s) — **não são o GDB**. F6 cria os `.tres`; F8 faz o Cavaleiro ler deles e remove as constantes. Até lá, I4 (nenhum número fora de `.tres`) está suspenso só para esse arquivo.
- Padrão `HitLedger` (efeito aplicado pelo alvo no próprio `_rollback_tick`) é a regra para todo efeito entre nodes: empurrão do Q, escudo do E, stun do R, dano de monstro, consumível — `ARCHITECTURE-GAME.md` §3.2.
- CI tem só `test-game` + `gate`; `lint-gd` (números literais, I9) e path filter entram por card `[INFRA]` antes de F6.

## Decisões do PI (2026-10-09)

- R-PEND-09: tier 3 é o **Golem de Pedra** (GDB §5.1).
- R-PEND-01: épico cai do boss (garantido) **e** de baú raro a 10 % (GDB §6.2).
- R-PEND-05: aviso global do boss aos 3:00 **entra** (F13).
- R-PEND-08: bestiário em partida pela tecla `B` **entra** (F13); reutiliza componentes de `shared/ui` que o Launcher usará em F27.
- F8 partido: F31 (câmera/controles/alinhamento) sai dele e vem antes.
- Mapa (SPEC-007): escala pelo GDB (raio 35 u, ~6 s / ~12 s); rio bloqueia com 2 pontes; bloqueios = muros + pilares + **mato alto (regra nova, aprovada)**; cratera plana; torres, ouro, aura do boss, orbes de XP, fog, lama e relevo **não entram** (FORA-DE-ESCOPO).

## Pendência ainda aberta que afeta este MVP

Nenhuma. R-PEND-11 foi decidida em 2026-10-09: paleta e fontes de `docs/prd/telas/` (`design-system/TOKENS.md` atualizado) — F13 pode criar o Theme inicial.

## Fora deste MVP

Arqueira, rede entre máquinas, fase 2, pick, fim de partida, launcher.
