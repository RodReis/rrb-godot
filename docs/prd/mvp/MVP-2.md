# MVP2 — Partida em rede (= marco M2)

**Objetivo:** 1x1 online completo (duas máquinas, servidor dedicado) que **sempre** termina em ≤ 10 min.
**Módulos:** `game`. **Prazo PRD:** 4 semanas.
**Critério de pronto:** 1x1 online termina sempre (com os 4 heróis — ADR-0011); 50 partidas bot × bot headless sem travar e todas ≤ 10 min (I1); nunca empate (I2).

## Fatias

| Slice | F / SPEC | Entrega | Fontes |
|---|---|---|---|
| 2.1 | F14 / SPEC-014 | Arqueiro: projétil validado, Q/E/R | PRD §4.3; GDB §4.2 |
| 2.2 | F15 / SPEC-015 | `MatchController` FSM, seleção de heróis, PvP fase 1, respawn, RPCs | PRD §3.2, §8.3; DV tela 2; `CONVENTION.md` §3 |
| 2.3 | F16 / SPEC-016 | zona, dano, respawn, kills, morte súbita, vitória | PRD §3.4, §3.5; GDB §7 |
| 2.4 | F17 / SPEC-017 | transição, HUD fase 2, vinheta | PRD §3.3; DV tela 4 |
| 2.5 | F18 / SPEC-018 | fim de partida com estatísticas | DV tela 7 |
| 2.6 | F19 / SPEC-019 | bot fase 2, soak 50 partidas | PRD §3.7, §8.7 |
| 2.7 | F20 / SPEC-020 | monstros/baús/boss replicados para 2 clientes reais | PRD §8.3 |
| 2.9 | F36 / SPEC-036 | economia de campo: 4 campos laterais (2 T1 + 1 T2 e 2 baús comuns cada), respawn de monstros não-boss 90 s na fase 1 | GDB §5, §6.2; `CONVENTION.md` §4.1; SPEC-007 |
| 2.10 | F37 / SPEC-037 | neblina de guerra: visão 12 u + explorado, filtro de replicação por peer (generaliza o F32), minimapa, continua na fase 2 | `CONVENTION.md` §4.9; GDB §7.3 |
| 2.8 | F32 / SPEC-032 | mato alto: herói dentro da moita deixa de ser replicado para o adversário (filtro de visibilidade no servidor); revela ao atacar | `CONVENTION.md` §4.7; GDB §7.3; SPEC-007 §2 |
| 2.11 | F44 / SPEC-044 | arena "Ilha Flutuante Arcana" — **layout novo, greybox jogável**: espelho N–S, bases nos cantos norte, rio N–S + anel, 4 pontes (2 por metade), campos do centro em 0°/180°; builder, colisão, marcadores (reposiciona os campos do F36), portões, mato, navmesh; sem arte nova | ADR-0007; SPEC-044; GDB §5.1, §6.2, §7.1 |
| 2.12 | F46 / SPEC-046 | arena "Rift Medieval adaptado" — relayout da Ilha: **borda quadrada 80×80**, rio em S NO–SE (anel + braços em arco + lagoas), bases SO/NE (rotação 180°), 2 pontes na MID, 3 corredores livres de 8 u, selva (4 campos do F36) nos quadrantes; builder, chassi Blender, colisão, marcadores, navmesh; kits do F44 reposicionados, sem kit novo | ADR-0009; SPEC-046; GDB §5.1, §6.2, §7.1 |
| 2.13 | F47 / SPEC-047 | baú: `F` só para item melhor (vazio, raridade maior, lateral de conjunto), nada automático, regra por herói no servidor, item recusado fica no baú; card de comparação na HUD ancorado ao baú; bot segura `F` | SPEC-047; GDB §6.2 |
| 2.14 | F48 / SPEC-048 | equipamento visível: armas (3 tiers por herói) e armaduras Guarda/Caçador (3 slots × 3 raridades) modeladas no Blender, presas a ossos; ícones dos itens no `SlotItem` | ADR-0010; SPEC-048; GDB §6.1 |
| 2.15 | F49 / SPEC-049 | ciclo dia/noite pelo relógio (0–600 s), sentido 50/50 pela seed, dia claro × noite do F40, lightmap sem sol, `--daynight` | ADR-0010; SPEC-049 |
| 2.16 | F50 / SPEC-050 | pátio da base com construções do Medieval Village MegaKit (Quaternius, CC0) adaptadas no Blender ao castelo do F46; só complementa, fora dos corredores | #131; ADR-0005, ADR-0006 |
| 2.17 | F51 / SPEC-051 | seleção de heróis fiel ao protótipo novo; layout fiel, só dado real (2 heróis, atributos do `HeroData`) | #132; `docs/prd/telas/Seleção de Heróis/` |
| 2.18 | F52 / SPEC-052 | vitória/derrota fiel ao protótipo novo; layout fiel, só o `MatchStats` do F18 | #133; `docs/prd/telas/Destaques da Tela de Fim de Partida/` |
| 2.19 | F53 / SPEC-053 | Bárbaro (Algoz): Machado, Salto Brutal, Rodopio, Execução; pick, bot, VFX, machado visível; elmo não aparece | ADR-0011; SPEC-053; GDB §4.3 |
| 2.20 | F54 / SPEC-054 | Bruxo de Fogo (Mago): Bola de Fogo, Explosão de Chamas, Anel de Fogo, Meteoro; pick, bot, VFX de fogo, cajado visível; elmo não aparece | ADR-0011; SPEC-054; GDB §4.4 |
| 2.21 | F55 / SPEC-055 | campos de canto NO/SE: Golem de canto + 2 Lobos + 2 Baús Reforçados (50/50 raro/comum); moita de lagoa movida; 35 monstros, 28 baús | ADR-0011; SPEC-055; GDB §5, §6.2 |
| gate | `[GATE]` | homologação: online termina sempre; soak verde | PRD §9.1 |
| 2.22 | F56 / SPEC-056 | arena num vale: faixa externa só visual (floresta densa, encostas, cristas rochosas, neblina de distância) para a câmera nunca mostrar o vazio; cascatas NO/SE viram riacho; ilhotas saem | ADR-0012; #150 |

## Ordem de implementação (decisão do PI em 2026-10-10)

**F15 → F36 → F20 → F14 → F16 → F17 → F18 → F32 → F37 → F44 (#92) → F46 (#110) → F19 → [GATE].**

**Depois do [GATE] deste MVP vem o MVP2.5 (bloco visual F38–F43, `MVP-2.5.md`), antes do MVP3.**

**Revisão do PI em 2026-10-10 (ADR-0007):** F44 (layout da arena, #92) entra logo após o F16 (que já estava em `doing` quando a decisão foi tomada) e antes do F17, para F16/F17/F32/F37 (minimapa) e o soak do F19 já nascerem na ilha. F36 e F20 já estavam mergeados; o F44 reposiciona os marcadores dos campos laterais.

**Revisão do PI em 2026-10-10 (ADR-0008, supera a ordem acima do ADR-0007):** F16, F17, F18 e F32 foram mergeados e o F37 entrou em `doing` no layout antigo antes do F44. O F37 termina; o F44 entra **depois do F37 e antes do F19** e confere no layout novo as moitas do F32 e a neblina/minimapa do F37. O F44 gera a Ilha em cena nova (`ilha_arcana.tscn`); o Vale Rúnico fica congelado em `game/scenes/arena/legacy/` + tag `arena-vale-runico` (fora do fluxo, sem teste).

**Revisão do PI em 2026-10-10 (ADR-0009):** F44 mergeado (#109). O F46 (relayout "Rift Medieval adaptado", #110) entra **logo depois do F44 e antes do F19**, para o soak nascer no layout final. Regera `ilha_arcana.tscn` no lugar; Ilha v1 preservada só pela tag `arena-ilha-arcana`.

**Revisão do PI em 2026-10-11 (ADR-0010):** F47 (regra do baú + card), F48 (equipamento visível) e F49 (dia/noite) entram no MVP2 — decisão do PI: "colocar no MVP2" — **depois do F46 e antes do F19**: **… → F46 → F47 → F48 → F49 → F19 → [GATE]**. O F47 vem antes do soak porque muda o comportamento do bot no baú.

**Pedido do PI em 2026-10-11:** [FIX] #130 (muralha do pátio da base), F50 (pátio com MegaKit), F51 (seleção) e F52 (vitória/derrota) entram **depois do F49 e antes do F19**: **… → F49 → [FIX] #130 → F50 → F51 → F52 → F19 → [GATE]**. Issues criadas pelo Code por ordem do PI; specs formais não escritas, o corpo de cada issue vale como spec.

**Decisão do PI em 2026-10-11 (ADR-0011):** Bárbaro (F53 #135), Bruxo de Fogo (F54 #136) e campos de canto (F55 #137) entram no MVP2 **depois do F50 e antes do F51**: **… → F50 → F53 → F54 → F55 → F51 → F52 → F19 → [GATE]**. A seleção (F51) nasce com 4 heróis; o soak (F19) cobre os 4. O Rei Esqueleto não muda (risco aceito pelo PI — ADR-0011, Consequências).

**Pedido do PI em 2026-10-12 (ADR-0012):** F56 (arena num vale, sem abismo) entra **depois do [GATE]**. **Revisto pelo PI no mesmo dia:** F56 #150 vem logo depois do F57 #151 e **antes do [GATE]**: **… → F57 #151 → F56 #150 → [GATE] #69**; o gate homologa a arena já no vale; issue criada pelo Code por ordem do PI, o corpo da issue vale como spec.

Motivo: o maior risco técnico herdado do MVP0 (replicação sob perda — tabela abaixo) está no F20; ele vem cedo, logo depois da FSM e da economia de campo (F36), para medir a replicação já com monstros nascendo e morrendo durante a partida. F32 e F37 (visão) vêm antes do soak (F19) para o bot já respeitar moita e neblina (invariante de honestidade). A numeração das Slices não muda.

## Decisões do PI que entram nas fatias (2026-10-10)

| Tema | Decisão | Fatia |
|---|---|---|
| Espelho no pick | permitido — os dois podem escolher o mesmo herói | F15 |
| Timeout do pick (R-PEND-04) | herói padrão do slot: P1 Cavaleiro, P2 Arqueiro | F15 |
| Monstros vivos aos 5:00 (R-PEND-06) | monstros comuns ficam na fase 2, sem respawn; o **Rei Esqueleto** existe até morrer ou até 5:00 — se vivo na transição, sai do mapa sem drop | F16, F20 |
| Relógio da fase 2 | a transição de 5 s conta dentro da fase 2: `t_phase2` começa às 5:00; morte súbita às 9:00; colapso às 10:00 (GDB §7.1) | F16, F17 |
| Colapso aos 10:00 | resolução imediata: maior HP% vence; desempate: mais kills na fase 2 → mais dano causado em heróis → sorteio pela seed da partida; os dois desconectados → `abandoned` (GDB §7.2) | F16 |
| Economia de campo (achado do PI no print do gate MVP1: aos 3:44 todos os baús abertos e só o boss vivo) | 4 campos laterais (NO e SE, um de cada lado do rio): 2 Esqueletos T1 + 1 Guerreiro T2 e 2 baús comuns cada; respawn de monstros não-boss 90 s só na fase 1; total 24 baús (GDB §5, §6.2) | F36 |
| Neblina de guerra (reverte exclusão de 2026-10-09) | visão + explorado, raio 12 u; servidor não replica o que está fora da visão; continua na fase 2 com a zona sempre visível; minimapa mostra posição, explorado e visão atual | F37 |
| Mato alto (R-PEND-12) | revelação de 1,5 s ao atacar/usar skill de dentro da moita; **sem** revelação por proximidade — só vê quem está na mesma moita (GDB §7.3) | F32 |

## Riscos herdados do MVP0 (ADR-0001) — entram no critério de aceite das fatias

| Risco | Fatia que resolve | Critério |
|---|---|---|
| Jogador desconectado deixa de ser simulado (`enable_prediction=false`) e fica imune a zona/dano | F15 | servidor sintetiza input vazio; teste: peer desconectado morre pela zona |
| Diff states descartados sob perda com jitter (`Reference tick missing`); remoto congela | F20 | cenário C do ADR-0001 com ≤ 30 % de frames parados do remoto (hoje 79 %) ou decisão registrada de que C está fora da meta |
| ~20 % de frames parados do remoto no cenário B, imperceptível com 1 cápsula | F14, F20 | medir de novo com projéteis e monstros replicados; meta ≤ 20 % no B |
| RPC de estado chega antes do spawn (`Node not found`) sob perda | F20 | spawn confiável antes do primeiro estado; 0 ocorrências em 10 min no B |

## Pendências do PI

Nenhuma. R-PEND-04, R-PEND-06 e R-PEND-12 decididas em 2026-10-10 (tabela acima; `RASTREABILIDADE.md` §5).

## Fora deste MVP

Backend, launcher, token de partida (o servidor aceita qualquer peer até F23).
