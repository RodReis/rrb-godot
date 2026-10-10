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
| 2.9 | F36 / SPEC-036 | economia de campo: 4 campos laterais (2 T1 + 1 T2 e 2 baús comuns cada), respawn de monstros não-boss 90 s na fase 1 | GDB §5, §6.2; `CONVENTION.md` §4.1; SPEC-007 |
| 2.10 | F37 / SPEC-037 | neblina de guerra: visão 12 u + explorado, filtro de replicação por peer (generaliza o F32), minimapa, continua na fase 2 | `CONVENTION.md` §4.9; GDB §7.3 |
| 2.8 | F32 / SPEC-032 | mato alto: herói dentro da moita deixa de ser replicado para o adversário (filtro de visibilidade no servidor); revela ao atacar | `CONVENTION.md` §4.7; GDB §7.3; SPEC-007 §2 |
| 2.11 | F44 / SPEC-044 | arena "Ilha Flutuante Arcana" — **layout novo, greybox jogável**: espelho N–S, bases nos cantos norte, rio N–S + anel, 4 pontes (2 por metade), campos do centro em 0°/180°; builder, colisão, marcadores (reposiciona os campos do F36), portões, mato, navmesh; sem arte nova | ADR-0007; SPEC-044; GDB §5.1, §6.2, §7.1 |
| gate | `[GATE]` | homologação: online termina sempre; soak verde | PRD §9.1 |

## Ordem de implementação (decisão do PI em 2026-10-10)

**F15 → F36 → F20 → F14 → F16 → F44 (#92) → F17 → F18 → F32 → F37 → F19 → [GATE].**

**Revisão do PI em 2026-10-10 (ADR-0007):** F44 (layout da arena, #92) entra logo após o F16 (que já estava em `doing` quando a decisão foi tomada) e antes do F17, para F16/F17/F32/F37 (minimapa) e o soak do F19 já nascerem na ilha. F36 e F20 já estavam mergeados; o F44 reposiciona os marcadores dos campos laterais.

Motivo: o maior risco técnico herdado do MVP0 (replicação sob perda — tabela abaixo) está no F20; ele vem cedo, logo depois da FSM e da economia de campo (F36), para medir a replicação já com monstros nascendo e morrendo durante a partida. F32 e F37 (visão) vêm antes do soak (F19) para o bot já respeitar moita e neblina (invariante de honestidade). A numeração das Slices não muda.

## Decisões do PI que entram nas fatias (2026-10-10)

| Tema | Decisão | Fatia |
|---|---|---|
| Espelho no pick | permitido — os dois podem escolher o mesmo herói | F15 |
| Timeout do pick (R-PEND-04) | herói padrão do slot: P1 Cavaleiro, P2 Arqueira | F15 |
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
