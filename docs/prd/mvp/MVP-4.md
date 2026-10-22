# MVP4 — Playtest (= marco M4)

**Objetivo:** validar o core loop com 10+ pessoas externas e decidir câmera, duração e ida para 3x3.
**Módulos:** todos. **Prazo PRD:** 2 semanas. **Issue-pai:** #246.
**Critério de pronto (PRD §9.2):** 100 % das partidas ≤ 10 min; ping médio ≤ 80 ms no Brasil, nenhum "teleporte"; ≥ 7/10 pedem segunda partida; líder de nível ao fim da fase 1 vence < 75 %.
**Estado:** planejado — nenhuma fatia iniciada; depende do `[GATE]` MVP3 #87. Em 2026-10-19 o PI acrescentou o spike visual (F84), o tutorial (F85) e a publicação no itch.io (F86), antes do playtest (ADR-0024, ADR-0026). O balanceamento dos 10 heróis (soaks fora do espelho: Berserker 44/44, Paladino 33/45, Ocultista 8/45) entra no F30.

## Fatias

| Slice | F / SPEC | Entrega | Fontes |
|---|---|---|---|
| 4.1 | F29 / SPEC-029 | telemetria (ping, duração, líder F1 × vencedor, teleportes reportados), KPIs no histórico, `tools/export-matches.ps1` | PRD §8.5, §9.2; DV tela 9; BM §5 |
| 4.2 | F30 / SPEC-030 | ajustes de balanceamento pós-playtest (só `.tres`) | GDB §1.1 |
| 4.3 | F84 / SPEC-084 | spike visual, parte 1 (`game`, `shared`, `art`): canto SO (base A + pátio) no estilo Eternal Return, feito pelo Claude no Blender, em cena variante jogável com o Cavaleiro atual; frame time medido; arena oficial intacta | ADR-0024 item 5; `spec/SPEC-084.md` |
| 4.4 | F85 / SPEC-085 | tutorial guiado offline (`game`, `launcher`, `backend`, `shared`): obrigatório na 1ª vez, pulável; fila online libera após o tutorial ou 1 vitória contra o bot | ADR-0026 itens 5–6; ADR-0029; `spec/SPEC-085.md` |
| 4.5 | F86 / SPEC-086 | publicação no itch.io (`infra`, `tools`, `launcher`, CI): página do jogo e build enviada a cada Release | ADR-0024 item 2 |
| 4.6 | ~~F93 / SPEC-093~~ | ~~spike visual, parte 2: Cavaleiro comissionado~~ — **cancelada em 2026-10-21**, substituída pelo F98 (ADR-0032) | ADR-0032 |
| 4.7 | F94 / SPEC-094 | arena nova, parte 1 (`game`, `shared`, `art`): bases A e B e pátios da arena oficial com o kit do F84 (cor do time B dourada), folhagem com vento; sai a variante do spike | ADR-0030; `spec/SPEC-094.md` |
| 4.8 | F95 / SPEC-095 | arena nova, parte 2 (`game`, `shared`, `art`): meio do mapa — rio, lagoas, pontes, centro, rochas, selva, mato alto (mesma área e leitura) e chão | ADR-0030; `spec/SPEC-095.md` |
| 4.9 | F96 / SPEC-096 | arena nova, parte 3 (`game`, `shared`, `art`): borda da ilha (floresta, tochas, cristais, defesas, bastiões e cascatas) e vale | ADR-0030; `spec/SPEC-096.md` |
| 4.10 | F97 / SPEC-097 | escala da interface do jogo (`game`, `launcher`, `shared`): `[ui] hud_scale` de 70 a 100 %, padrão 85 %, no Launcher e no ⚙ da partida | ADR-0031; `spec/SPEC-097.md` |
| 4.11 | F98 / SPEC-098 | Carrasco, 11º herói (`game`, `shared`, `art`): Tanque com Couraça, Dor, Espinhos, Penitência e Correntes do Julgamento; modelo realista gerado no Tripo (plano pago) com rig e animações Mixamo, nada do KayKit; bot; VFX | ADR-0032; GDB §4.11; `spec/SPEC-098.md` |
| gate | `[GATE]` | playtest executado; questionário; decisões registradas em ADR | PRD §9.1, §3.6 (plano B), R2, R3 |

## Decisões que saem deste gate (ADRs novos)

Câmera 3ª pessoa × isométrica; duração da fase 1 (5 min × 3–4 min, R2); ir ou não para 3x3; o que do `FORA-DE-ESCOPO.md` volta. O gate também decide a abertura do Early Access (MVP5): só abre com ≥ 7/10 pedindo segunda partida (ADR-0024).

Decidido pelo PI em 2026-10-19 para o spike: Cavaleiro, base SO + pátio, referência Eternal Return, cena separada e jogável, orçamento até ~2× medido; cenário no Blender pelo Claude (F84) e herói comissionado (F93), com o F84 partido em dois. F85 decidido pelo PI em 2026-10-19 (SPEC-085). Em 2026-10-20, depois de jogar o F84, o PI aprovou o cenário e decidiu levar a arte nova à arena inteira antes do playtest, no Blender pelo Claude, em 3 fatias por região, F94 a F96 (ADR-0030). Em 2026-10-21, na verificação do F95, o PI achou o HUD grande e escolheu escala configurável, de 70 a 100 % com padrão de 85 % (o teto de 120 % caiu porque a seleção de heróis quebrava acima de 100 %), no Launcher e na partida (F97, ADR-0031). F86 decidido pelo PI em 2026-10-22 (SPEC-086): ZIP portátil via butler, página restrita por senha até o playtest, PI cria a conta e grava o segredo, Launcher sem atualizador próprio no canal itch.
