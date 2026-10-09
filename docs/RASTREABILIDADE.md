# RASTREABILIDADE.md — Matriz normativa de requisitos

Prova para onde cada requisito aprovado foi: **mantido** (implementa na fatia), **transferido** (outro módulo/documento), **adiado** (roadmap, com gatilho em `FORA-DE-ESCOPO.md`) ou **excluído** (com motivo). Requisito ausente daqui **bloqueia aprovação documental**. Mantida pelo Cowork; o Code aponta lacuna por `[FIX]`.

Fontes: `PRD` = `docs/prd/PRD.md` · `GDB` = `docs/prd/GDB.md` · `DV` = `docs/prd/DESIGN-VISUAL-LAUNCHER.md` · `BM` = `docs/prd/REFER.md`.

## 1. PRD

| ID | Requisito | Fonte | Destino | Módulo | MVP | Status |
|---|---|---|---|---|---|---|
| P-01 | Arena hexagonal com Base A, Base B, Centro; portões por time | PRD §3.1 | F7 | game | MVP1 | mantido |
| P-02 | Escala: base→centro ~8 s, arena ~20 s | PRD §3.1 | SPEC-007 §1 | game | MVP1 | **substituído** pelo PI em 2026-10-09: raio 35 u (GDB §7.1) → ~6,3 s / ~12,7 s |
| P-03 | XP/nível 1–10, 1 ponto por nível, Q/E 5 níveis, R nível 6 | PRD §3.2, GDB §3 | F9 | game | MVP1 | mantido |
| P-04 | Baús: 6 por base (comum), 4 no centro (raro), não reabrem | PRD §3.2, GDB §6.2 | F10 | game | MVP1 | mantido |
| P-05 | 4 slots, 12 itens, 2 conjuntos, bônus 3/3 | PRD §6, GDB §6 | F10, F6 | game, shared | MVP1 | mantido (números GDB, ADR-0004) |
| P-06 | Boss aos 3:30, drop épico garantido | PRD §3.2 | F11 | game | MVP1 | mantido |
| P-07 | PvP fase 1 no centro; morte = respawn 8 s, sem kill, XP tier 2 | PRD §3.2 | F15 | game | MVP2 | mantido |
| P-08 | Catch-up +25% XP com 2+ níveis atrás | PRD §3.2 | F9 | game | MVP1 | mantido |
| P-09 | Transição 5:00: portões caem, aviso 5 s, zona cobre a arena | PRD §3.3 | F16, F17 | game | MVP2 | mantido |
| P-10 | Zona encolhe em 4:00; dano fora crescente | PRD §3.4 | F16 | game | MVP2 | mantido (curva GDB §7.1, ADR-0004 N4) |
| P-11 | Meta de kills 1x1 = 5 | PRD §3.4 | F16 | game | MVP2 | mantido |
| P-12 | Respawn 6 s na fase 2 até raio mínimo; depois desliga | PRD §3.4 | F16 | game | MVP2 | mantido |
| P-13 | Fim garantido: aos 5:00 da fase 2 dano dobra a cada 10 s | PRD §3.4 | F16 | game | MVP2 | mantido |
| P-14 | XP por kill na fase 2; monstros não respawnam | PRD §3.4 | F16 | game | MVP2 | mantido (R-PEND-06) |
| P-15 | Ordem de vitória; nunca empate | PRD §3.5 | F16 | game | MVP2 | mantido |
| P-16 | Câmera 3ª pessoa ~45°, distância fixa | PRD §3.6 | F31 | game | MVP1 | mantido |
| P-17 | Teclado/mouse: WASD, mira, LMB, Q/E/R, F, Espaço | PRD §3.6 | F31, F6 | game, shared | MVP1 | mantido |
| P-18 | Gamepad | PRD §3.6 | F31 | game | MVP1 | mantido |
| P-19 | Plano B câmera isométrica + mira assistida | PRD §3.6 | decisão M4 | game | MVP4 | adiado (gatilho: playtest) |
| P-20 | Bot FSM fase 1 e fase 2 | PRD §3.7 | F12, F19 | game | MVP1/2 | mantido |
| P-21 | 2 heróis: Cavaleiro, Arqueira | PRD §4.3 | F8, F14 | game | MVP1/2 | mantido |
| P-22 | Valores de skill em `.tres`, não no doc | PRD §4.3 | F6 | shared | MVP1 | mantido |
| P-23 | 5 monstros incl. boss; tier 3 = **Golem de Pedra** (decisão PI 2026-10-09) | PRD §5 | F9, F11 | game | MVP1 | mantido |
| P-24 | Economia/monetização | PRD §7 | — | launcher/backend | fase B | adiado |
| P-25 | Export cliente Windows e servidor headless | PRD §8.2 | F1, F28 | game, infra | MVP0/3 | mantido |
| P-26 | netfox 30 Hz, predição, rollback, interpolação, lag comp | PRD §8.3 | F3–F5 | game | MVP0 | mantido |
| P-27 | Eventos discretos por RPC confiável; estado contínuo não confiável | PRD §8.3 | F15 | game | MVP2 | mantido |
| P-28 | Auth e-mail/senha, JWT | PRD §8.4 | F21 | launcher (backend) | MVP3 | mantido |
| P-29 | Fila 1x1 FIFO | PRD §8.4 | F22 | launcher (backend) | MVP3 | mantido |
| P-30 | Orquestrador: pool 2–3 containers; token de partida; resultado; repor pool | PRD §8.4 | F22, F23 | launcher (backend), game | MVP3 | mantido |
| P-31 | Dados: usuários, partidas, resultados | PRD §8.4 | F21, F22 | backend | MVP3 | mantido |
| P-32 | VPS com Coolify; compose; UDP 7000–7020 | PRD §8.5 | F28 | infra | MVP3 | mantido |
| P-33 | Observabilidade mínima: logs + ping médio por partida | PRD §8.5 | F29 | backend, game | MVP4 | mantido |
| P-34 | Fora: regiões, autoscaling, anti-cheat, reconexão, host migration | PRD §8.5 | `FORA-DE-ESCOPO.md` | — | — | excluído |
| P-35 | Monorepo `game/ backend/ infra/ docs/` | PRD §8.6 | ADR-0002 (+ `launcher/`, `shared/`) | — | MVP0 | mantido com extensão |
| P-36 | Testes GUT, rede, soak 50 partidas, API | PRD §8.7 | `ARCHITECTURE-*.md` §testes | ambos | MVP0–3 | mantido |
| P-37 | Marcos M0–M4 e critérios | PRD §9.1 | `STATUS.md`, `docs/prd/mvp/` | — | — | mantido (MVP-n = M-n) |
| P-38 | Critérios de sucesso M4 | PRD §9.2 | F29, GATE MVP4 | — | MVP4 | mantido |
| P-39 | Assets KayKit/Quaternius; cena de alinhamento | PRD §11 | F31 | shared | MVP1 | mantido |
| P-40 | Fora de escopo explícito (§12) | PRD §12 | `FORA-DE-ESCOPO.md` | — | — | excluído |

## 2. GDB

| ID | Requisito | Fonte | Destino | Status |
|---|---|---|---|---|
| G-01 | Fórmulas DEF/CDR/velocidade/ataque | GDB §2.2 | `shared/core/stats.gd` (F6) | mantido |
| G-02 | Tabela de XP | GDB §3.2 | `shared/data/rules/xp_table.tres` (F6) | mantido |
| G-03 | Catch-up, XP por morte F1/F2 | GDB §3.3 | F9, F16 | mantido |
| G-04 | Heróis (stats, crescimento, skills) | GDB §4 | `shared/data/heroes/*.tres` (F6), F8, F14 | mantido |
| G-05 | Bestiário (5 monstros) | GDB §5.1 | `shared/data/monsters/*.tres` (F6), F9, F11 | mantido |
| G-06 | Itens e conjuntos | GDB §6.1 | `shared/data/items/**` (F6), F10 | mantido |
| G-07 | Baús e regra de substituição; épico 10 % no baú raro | GDB §6.2 | F10 | mantido (decisão PI 2026-10-09) |
| G-08 | Cronograma da fase 2 | GDB §7.1 | `match_pacing.tres` (F6), F16 | mantido |
| G-09 | Regras de vitória | GDB §7.2 | F16 | mantido |
| G-10 | Estrutura `data/` | GDB §8 | `shared/data/` (muda de `game/data` para `shared/data` — ADR-0003) | transferido |
| G-11 | TTK e teto de snowball < 75% | GDB §1.1 | F29 (medição), GATE MVP4 | mantido |

## 3. Design visual (DV)

| ID | Tela / item | Destino | Módulo | Status |
|---|---|---|---|---|
| V-01 | Tela 1 Lobby | F25 | launcher | mantido |
| V-01a | Perfil com nível/XP de conta, avatar, "14V–6D" | — | — | **R-PEND-02** (não está no PRD; PRD §1.3 "sem economia", sem progressão de conta) |
| V-01b | Rodapé "Pool de servidores: 3 ativos", "Netfox 30 Hz" | F25 (só status do backend) | launcher | mantido parcialmente — tick do netfox é do Game |
| V-02 | Tela 2 Seleção de Heróis (timer 24 s, oponente) | F15 | game | transferido (ADR-0002) |
| V-03 | Tela 3 HUD fase 1 | F13 | game | mantido |
| V-03a | Tecla `B` abre bestiário em partida | F13 | game, shared | mantido — aprovado pelo PI em 2026-10-09 (requisito novo, fora do PRD) |
| V-04 | Tela 4 HUD fase 2 | F17 | game | mantido |
| V-05 | Tela 5 Bestiário | F27 | launcher | mantido |
| V-06 | Tela 6 Forja / simulador | F27 | launcher | mantido (I5: mesma fórmula do servidor) |
| V-07 | Tela 7 Fim de partida | F18 | game | transferido (ADR-0002) |
| V-07a | "Hash de auditoria", "Audit token" | — | — | **excluído** (sem requisito no PRD; o `match_id` do backend cumpre o papel) |
| V-08 | Tela 8 Configurações: vídeo, áudio, controles | F24 | launcher | mantido |
| V-08a | Aba Rede & Netfox com telemetria RTT/jitter/rollback | `net_debug.tscn` (F4) | game | transferido — Launcher não tem netfox; o Launcher mostra só ping HTTP ao backend |
| V-08b | Exportar log de rede `.txt`, "aplicar ajustes de netfox" | — | — | adiado (`FORA-DE-ESCOPO.md`) |
| V-09 | Tela 9 Histórico | F26 | launcher | mantido |
| V-09a | Painel de KPIs do M4 (snowball rate, ping médio, duração) | F29 | launcher + backend | mantido (é o critério PRD §9.2) |
| V-09b | Exportar CSV, SQLite local, `/telemetry/matches` do cliente | — | — | adiado — o backend é a fonte; exportação é ferramenta do dev (script em `tools/`), não tela |
| V-10 | Design system (paleta, tipografia, viewport) | `docs/design-system/` | shared | mantido (conflito de paleta com `docs/prd/telas/` — R-PEND-11) |
| V-13 | Tela de Login (só em `docs/prd/telas/`, ausente no DV) | F25 | launcher | mantido como função (PRD §8.4); design pendente — R-PEND-11 |
| V-14 | "Pop-up Tático In-Game" (só em `docs/prd/telas/`) | — | — | **sem requisito** no PRD — R-PEND-11 |
| V-15 | Conceito "Arena & Mapa — Vale Rúnico": topologia da imagem tática (bases opostas, rio, pontes, cratera) | SPEC-007 | game | mantido como layout |
| V-16 | Idem: torres rúnicas, ouro 18 g/s, upgrade de skill por ouro, aura do boss, tier lendário, Elo, fog of war, lama −15 %, relevo −1,8 m, zona 1,5→6 %, câmera isométrica padrão | `FORA-DE-ESCOPO.md` | — | **excluídos/adiados** pelo PI em 2026-10-09 |
| V-17 | Mato alto que esconde (Astro Arena / Brawl Stars) | F7 (geometria), F32 (regra) | game | mantido — requisito novo aprovado pelo PI em 2026-10-09 |
| V-11 | Mapa de controles §3.3 | `shared/core/input_actions.gd` | shared | mantido |
| V-12 | `scripts/ui/m4_audit_tracker.gd` no cliente | backend `telemetry/` | — | transferido |

## 4. Benchmark (BM)

| ID | Recomendação | Destino | Status |
|---|---|---|---|
| B-01 | Aviso global aos 3:00 do boss | F13 | mantido — aprovado pelo PI em 2026-10-09 |
| B-02 | Testar câmera no M1 | F31 (critério de aceite inclui avaliação do PI) | mantido |
| B-03 | Pistas visuais no portal aos 3:00 | F13 | mantido, junto de B-01 |
| B-04 | Métrica anti-snowball no M4 | F29 | mantido |
| B-05 | Seeds de baús no servidor, itens por ID inteiro | `ARCHITECTURE-GAME.md` §3.3/§5 | mantido |

## 5. Pendências de decisão do PI

Nenhum agente decide estas. Até decisão, o Code implementa o que o PRD diz; se o PRD não diz, bloqueia (caso 1 do `GITHUB.md`).

| ID | Pendência | Opções | Impacto se não decidir |
|---|---|---|---|
| ~~R-PEND-01~~ | **Decidido 2026-10-09:** GDB — baú raro 10 % | — | — |
| R-PEND-02 | Perfil de conta com nível/XP/avatar no lobby (DV) | incluir no PRD / excluir | F25 sem perfil (só e-mail/nome) |
| R-PEND-03 | "Lembrar-me" / sessão persistida no Launcher | sim / não | sem persistência: login a cada abertura |
| R-PEND-04 | Timeout de pick sem escolha → herói padrão por slot? | padrão / aleatório / abandono | F15 bloqueia |
| ~~R-PEND-05~~ | **Decidido 2026-10-09:** incluir (F13) | — | — |
| R-PEND-06 | Monstros vivos ao entrar na fase 2: ficam ou somem? | ficam / somem | F16 bloqueia |
| R-PEND-07 | Recuperação de senha / verificação de e-mail | fatia / roadmap | F21 sem ambos |
| ~~R-PEND-08~~ | **Decidido 2026-10-09:** incluir (F13) | — | — |
| ~~R-PEND-09~~ | **Decidido 2026-10-09:** Golem de Pedra | — | — |
| R-PEND-11 | `docs/prd/telas/` (10 pastas com `DESIGN.md`, `code.html`, `screen.png`) tem **duas telas que não estão no DV** ("Tela de Login & Autenticação" e "Pop-up Tático In-Game") e uma **paleta diferente** da do DV §1.2 (surface `#0b1326`, primary `#ffc174`, tokens Material; fontes Space Grotesk/Outfit/JetBrains Mono). Qual é a fonte visual: DV ou `telas/`? | DV / telas / DV com paleta de telas | **Bloqueia F13** (Theme inicial) |
| R-PEND-12 | Mato alto: duração da revelação ao atacar/usar skill de dentro da moita; raio de visão dentro da moita | números no GDB | F32 bloqueia (MVP2) |
| R-PEND-10 | Renomear `docs/prd/PRD.md` → `2026-10-08-prd-moba-2-tempos.md` (nome citado no plano M0 e nos agentes) | renomear / manter | links quebrados em `docs/superpowers/plans/` e `.claude/agents/` — `CLAUDE.md` já aponta para `PRD.md` |
