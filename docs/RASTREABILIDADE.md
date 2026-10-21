# RASTREABILIDADE.md — Matriz normativa de requisitos

Prova para onde cada requisito aprovado foi: **mantido** (implementa na fatia), **transferido** (outro módulo/documento), **adiado** (roadmap, com gatilho em `FORA-DE-ESCOPO.md`) ou **excluído** (com motivo). Requisito ausente daqui **bloqueia aprovação documental**. Mantida pelo Cowork; o Code aponta lacuna por `[FIX]`.

Fontes: `PRD` = `docs/prd/PRD.md` · `GDB` = `docs/prd/GDB.md` · `DV` = `docs/prd/DESIGN-VISUAL-LAUNCHER.md` · `BM` = `docs/prd/REFER.md`.

## 1. PRD

| ID | Requisito | Fonte | Destino | Módulo | MVP | Status |
|---|---|---|---|---|---|---|
| P-01 | Arena hexagonal com Base A, Base B, Centro; portões por time | PRD §3.1 | F7 | game | MVP1 | mantido |
| P-02 | Escala: base→centro ~8 s, arena ~20 s | PRD §3.1 | SPEC-007 §1; SPEC-044 §6 | game | MVP1 / MVP2 | **substituído** pelo PI em 2026-10-09: raio 35 u (GDB §7.1) → ~6,3 s / ~12,7 s; spawn→spawn re-medido no F44 (11,10 s) e de novo no F46 (ADR-0009, previsão ≈ 12 s pela MID) |
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
| P-13 | Fim garantido: aos 5:00 da fase 2 dano dobra a cada 10 s | PRD §3.4 | F16 | game | MVP2 | mantido com mudança — PI 2026-10-10: aos 10:00 resolução imediata por HP% com desempate (GDB §7.2 item 3); o "dobra a cada 10 s" do PRD não se aplica (GDB vence, ADR-0004) |
| P-14 | XP por kill na fase 2; monstros não respawnam | PRD §3.4 | F16 | game | MVP2 | mantido — R-PEND-06 decidida: monstros comuns ficam; Rei Esqueleto vivo aos 5:00 sai sem drop |
| P-15 | Ordem de vitória; nunca empate | PRD §3.5 | F16 | game | MVP2 | mantido |
| P-16 | Câmera 3ª pessoa ~45°, distância fixa | PRD §3.6 | F31, F45 | game | MVP1 | mantido — yaw fixo do time (F31) passa a ser só o inicial; giro 360° com o botão esquerdo (F45, MVP2.5, PI 2026-10-10); **distância deixa de ser fixa** — zoom 9–14 u, padrão 11 u (F67, ADR-0015, PI 2026-10-16) |
| P-17 | Teclado/mouse: WASD, mira, LMB, Q/E/R, F, Espaço | PRD §3.6 | F31, F6, F45, F66 | game, shared | MVP1 | mantido — ataque básico passa ao botão direito (F45, PI 2026-10-10); **"mouse mira" substituído** (ADR-0015, PI 2026-10-16): herói encara o movimento, clique do botão direito trava alvo com auto-ataque em alcance, segurar = contínuo (F66) |
| P-18 | Gamepad | PRD §3.6 | F31, F66 | game | MVP1 | mantido — `RT` toca = trava alvo (F66) |
| P-19 | Plano B câmera isométrica + mira assistida | PRD §3.6 | decisão M4 | game | MVP4 | adiado (gatilho: playtest) |
| P-20 | Bot FSM fase 1 e fase 2 | PRD §3.7 | F12, F19 | game | MVP1/2 | mantido |
| P-21 | 2 heróis: Cavaleiro, Arqueiro | PRD §4.3 | F8, F14 | game | MVP1/2 | mantido — ampliado para 4 pelo PI em 2026-10-11 (ADR-0011): Bárbaro F53, Bruxo de Fogo F54; para 6 em 2026-10-13 (ADR-0013): Ladina F58, Engenheiro F59; para 8 em 2026-10-16 (ADR-0015): Protetor da Selva F74, Berserker F75; e para 10 em 2026-10-18 (ADR-0016): Paladino Radiante F76, Ocultista F77 |
| P-21a | Classe Algoz (Bárbaro) e classe nova Mago (Bruxo de Fogo); elmo não aparece nesses 2 heróis | PRD §4.1, §4.3; ADR-0011 | F53, F54 | game, shared | MVP2 | mantido — requisito novo aprovado pelo PI em 2026-10-11 |
| P-21b | Ladina (Algoz, besta, `Rogue_Hooded` cor original) e classe nova Engenheiro (Adventurers 2.0 Extra); fumaça = moita temporária que não revela ao lançar; Torreta indestrutível 6 s contra heróis e monstros vistos pelo Engenheiro; elmo não aparece nos 2; nome do Ranger = "Arqueiro" | PRD §4.1, §4.3; ADR-0013 | F58, F59; `[FIX]` do Code (nome) | game, shared | MVP2.6 | mantido — requisito novo aprovado pelo PI em 2026-10-13 |
| P-22 | Valores de skill em `.tres`, não no doc | PRD §4.3 | F6 | shared | MVP1 | mantido |
| P-23 | 5 monstros incl. boss; tier 3 = **Golem de Pedra** (decisão PI 2026-10-09) | PRD §5 | F9, F11 | game | MVP1 | mantido — +Lobo e Golem de canto (7 monstros) pelo ADR-0011, F55 |
| P-24 | Economia/monetização | PRD §7 | F90, F92 (loja e skins); sorteios excluídos | launcher/backend | MVP5 | **substituído** pelo PI em 2026-10-19 (ADR-0025): loja só cosmética em reais, sem moeda virtual e sem sorteio pago; passe na 2ª leva |
| P-25 | Export cliente Windows e servidor headless | PRD §8.2 | F1, F28 | game, infra | MVP0/3 | mantido |
| P-26 | netfox 30 Hz, predição, rollback, interpolação, lag comp | PRD §8.3 | F3–F5 | game | MVP0 | mantido |
| P-27 | Eventos discretos por RPC confiável; estado contínuo não confiável | PRD §8.3 | F15 | game | MVP2 | mantido |
| P-28 | Auth e-mail/senha, JWT | PRD §8.4 | F21 | launcher (backend) | MVP3 | mantido — senha mín. 8 com letra e número (PI 2026-10-10) |
| P-29 | Fila 1x1 FIFO | PRD §8.4 | F22 | launcher (backend) | MVP3 | mantido |
| P-30 | Orquestrador: pool 2–3 containers; token de partida; resultado; repor pool | PRD §8.4 | F22, F23 | launcher (backend), game | MVP3 | mantido |
| P-31 | Dados: usuários, partidas, resultados | PRD §8.4 | F21, F22 | backend | MVP3 | mantido |
| P-32 | VPS com Coolify; compose; UDP 7000–7020 | PRD §8.5 | F28 | infra | MVP3 | mantido — pacote ZIP portátil em GitHub Release (PI 2026-10-10) |
| P-33 | Observabilidade mínima: logs + ping médio por partida | PRD §8.5 | F29 | backend, game | MVP4 | mantido |
| P-34 | Fora: regiões, autoscaling, anti-cheat, reconexão, host migration | PRD §8.5 | `FORA-DE-ESCOPO.md` | — | — | excluído |
| P-35 | Monorepo `game/ backend/ infra/ docs/` | PRD §8.6 | ADR-0002 (+ `launcher/`, `shared/`) | — | MVP0 | mantido com extensão |
| P-36 | Testes GUT, rede, soak 50 partidas, API | PRD §8.7 | `ARCHITECTURE-*.md` §testes | ambos | MVP0–3 | mantido |
| P-37 | Marcos M0–M4 e critérios | PRD §9.1 | `STATUS.md`, `docs/prd/mvp/` | — | — | mantido (MVP-n = M-n) |
| P-38 | Critérios de sucesso M4 | PRD §9.2 | F29, GATE MVP4 | — | MVP4 | mantido |
| P-39 | Assets KayKit/Quaternius; cena de alinhamento | PRD §11 | F31 | shared | MVP1 | mantido |
| P-39b | Crédito CC-BY 3.0 do Golem de Pedra antes de qualquer build distribuída | `shared/assets/LICENSES.md` | F24 (aba Créditos em Configurações — PI 2026-10-10) | launcher | MVP3 | mantido |
| P-39a | Blender para criação, acabamento, ajustes e rascunhos; arte própria liberada; `.blend` em `art/`, só glTF em `shared/assets/` (decisão PI 2026-10-09) | PRD §11, ADR-0005 | fatias que tocam asset 3D; `[INFRA]` (gitattributes, import `.blend` off) | shared | MVP1+ | mantido |
| P-40 | Cinemática de abertura 5–8 s (estado `INTRO`) antes da fase 1 | ADR-0015 item 7; CONVENTION §3 | F69 | game | MVP2.7 | mantido — requisito novo do PI (2026-10-16) |
| P-41 | Splash próprio e 3 telas de loading sorteadas (renders reais) | ADR-0015 item 6 | F68 | game, launcher, shared | MVP2.7 | mantido — requisito novo do PI (2026-10-16) |
| P-42 | Fim de partida → lobby com card de resultado; Game fecha em 15 s | ADR-0015 item 8 | F70 | game, launcher | MVP2.7 | mantido — substitui "fim → Histórico" (F26) |
| P-43 | Tela Heróis no Launcher (protótipo `Tela Herois/`) | ADR-0015 item 9; DV/telas | F71 | launcher, shared | MVP2.7 | mantido — sem epíteto/lore (FORA-DE-ESCOPO) |
| P-44 | Silhueta do próprio herói no mato alto (só cliente) | ADR-0015 item 10 | F72 | game, shared | MVP2.7 | mantido — regra de visibilidade (SPEC-032) inalterada |
| P-45 | Acabamento PBR do cenário dentro da ADR-0006; GPU ≤ +1,5 ms | ADR-0015 item 11 | F73 | game, shared | MVP2.7 | mantido — "realista" fora da ADR-0006 excluído |
| P-46 | Protetor da Selva, classe Controle (redesenho do pedido "Suporte") | ADR-0015 item 12; PRD §4.1; GDB §4.7 | F74 | game, shared | MVP2.7 | mantido com mudança — Suporte segue no roadmap |
| P-47 | Berserker, classe nova Lutador, primeira passiva (Frenesi) | ADR-0015 item 13; PRD §4.1; GDB §2.2-E, §4.8 | F75 | game, shared | MVP2.7 | mantido — requisito novo do PI (2026-10-16); **mudança do PI em 2026-10-18 no aceite do F75:** textura `alt_A` e elmo viking de chifres (contra o "elmo não aparece" da spec) |
| P-48 | "Personagens maiores" | pedido do PI 2026-10-16 | F67 (câmera 11 u) | game | MVP2.7 | **transferido** para o zoom da câmera; escala visual adiada (FORA-DE-ESCOPO, gatilho: aceite do F67) |
| P-49 | Paladino Radiante, Tanque reativo (redesenho do pedido "Suporte tanque") | ADR-0016 itens 3–5; PRD §4.1; GDB §4.9 | F76 | game, shared | MVP2.8 | mantido com mudança — kit de time vale só nele no 1x1; aliados no 2x2 (FORA-DE-ESCOPO) |
| P-50 | Ocultista, 2º Mago, dano contínuo + Maldição (−Defesa) | ADR-0016 itens 6–8; PRD §4.1; GDB §2.2-F, §4.10 | F77 | game, shared | MVP2.8 | mantido com mudança — "reduzir resistência" = reduzir Defesa (só existe Defesa) |
| P-51 | Invocação de pequenas unidades (Servos do Vazio) | ADR-0016 item 9; GDB §4.10 | F78 | game, shared | MVP2.8 | mantido — partido em fatia própria por decisão do PI; na verificação visual (2026-10-18) o PI pediu os servos à frente e mais duração: 10 s no R1 e 12 s no R2 (GDB §4.10 atualizado) |
| P-52 | Textura escura do Ocultista e Mage diferente do Bruxo | ADR-0016 item 8 | F77 | game, shared | MVP2.8 | mantido com mudança — não existe Mage escuro no pack: atlas próprio + capuz, exceção à ADR-0006 |
| P-53 | Minimapa fixo (não gira com a câmera) | pedido do PI no F67 (pop-up); SPEC-045 deixava em aberto | F67 | game | MVP2.7 | mantido — requisito novo do PI, feito na mesma PR do zoom (F67) |
| P-54 | 4 moitas de emboscada nos corredores (6 → 10 moitas de mato alto), mesma regra do mato (F32) | pedido do PI em 2026-10-17 | F73 | game, shared | MVP2.7 | mantido — requisito novo do PI; entrou no F73 sem fatia própria |
| P-55 | Fora de escopo explícito (§12) | PRD §12 | `FORA-DE-ESCOPO.md` | — | — | excluído |
| P-57 | Early Access depois do gate do M4, F2P + Pacote de Fundador, no site próprio + itch.io (Steam fora) | pedido do PI em 2026-10-19; ADR-0024 | MVP5 (`[GATE]`), F86 | infra, todos | MVP4/MVP5 | mantido — requisito novo do PI |
| P-58 | Patente de conta 1–10 grátis; 1 herói inicial + 1 por Patente com escolha livre | pedido do PI em 2026-10-19; ADR-0026 | F87 | backend, launcher, game | MVP5 | mantido — requisito novo do PI; supera R-PEND-02 (sem XP de conta) |
| P-59 | Emblemas e molduras como recompensa de Patente e de login diário/semanal/mensal | pedido do PI em 2026-10-19; ADR-0025, ADR-0026 | F88 | backend, launcher | MVP5 | mantido — requisito novo do PI |
| P-60 | Tutorial guiado, obrigatório na 1ª vez e pulável; fila online após tutorial ou 1 vitória vs bot | pedido do PI em 2026-10-19; ADR-0026 | F85 | game, launcher, backend | MVP4 | mantido — requisito novo do PI |
| P-61 | Nível do bot numérico 1..N; bot completa a fila online após 30 s, com aviso | pedido do PI em 2026-10-19; ADR-0027 | F81 (formato), F89 | game, launcher, backend | MVP3/MVP5 | mantido — requisito novo do PI |
| P-62 | Skin visível na partida pelos dois jogadores, posse decidida no backend | ADR-0028 | F91, F92 | backend, game, launcher | MVP5 | mantido — consequência do P-24 aprovada pelo PI |
| P-63 | Spike visual (Cavaleiro + canto SO, estilo Eternal Return) antes do playtest; engine segue Godot | pedido do PI em 2026-10-19; ADR-0024 | F84 (cenário), F93 (herói comissionado) | game, shared, art | MVP4 | mantido — requisito novo do PI |
| P-64 | Arena inteira no estilo do spike (Blender pelo Claude), antes do playtest; mato alto com visual novo e a mesma leitura | pedido do PI em 2026-10-20; ADR-0030 | F94 (bases), F95 (meio do mapa), F96 (borda e vale) | game, shared, art | MVP4 | mantido — requisito novo do PI |
| P-56 | Site público de apresentação (landing "Loot Start"): heróis, arena, roadmap e download, dados extraídos do repositório em build, GitHub Pages | pedido do PI em 2026-10-18; ADR-0017 | PR #218 (sem fatia, fora do board); `docs/SITE.md` | site | — | mantido — requisito novo do PI; o nome "Loot Start" vale só no site (rename do jogo é decisão do PI, `FORA-DE-ESCOPO.md`) |

## 2. GDB

| ID | Requisito | Fonte | Destino | Status |
|---|---|---|---|---|
| G-01 | Fórmulas DEF/CDR/velocidade/ataque | GDB §2.2 | `shared/core/stats.gd` (F6) | mantido |
| G-02 | Tabela de XP | GDB §3.2 | `shared/data/rules/xp_table.tres` (F6) | mantido |
| G-03 | Catch-up, XP por morte F1/F2 | GDB §3.3 | F9, F16 | mantido |
| G-04 | Heróis (stats, crescimento, skills) | GDB §4 | `shared/data/heroes/*.tres` (F6), F8, F14, F53, F54, F58, F59 | mantido (GDB §4.3–4.4 novos, ADR-0011; §4.5–4.6 novos, ADR-0013) |
| G-05 | Bestiário (5 monstros) | GDB §5.1 | `shared/data/monsters/*.tres` (F6), F9, F11, F55 | mantido (7 monstros, ADR-0011) |
| G-06 | Itens e conjuntos | GDB §6.1 | `shared/data/items/**` (F6), F10 | mantido |
| G-07 | Baús e regra de substituição; épico 10 % no baú raro | GDB §6.2 | F10 | mantido (decisão PI 2026-10-09) |
| G-08 | Cronograma da fase 2 | GDB §7.1 | `match_pacing.tres` (F6), F16 | mantido |
| G-09 | Regras de vitória | GDB §7.2 | F16 | mantido |
| G-10 | Estrutura `data/` | GDB §8 | `shared/data/` (muda de `game/data` para `shared/data` — ADR-0003) | transferido |
| G-11 | TTK e teto de snowball < 75% | GDB §1.1 | F29 (medição), GATE MVP4 | mantido |
| G-12 | Economia de campo: 4 campos laterais (2 T1 + 1 T2 e 2 baús comuns cada), respawn de monstros não-boss 90 s só na fase 1 | GDB §5, §6.2 | F36 | mantido — requisito novo aprovado pelo PI em 2026-10-10 (corrige economia: mapa somava 1.710 XP, meta nível 8–9 inalcançável) |
| G-13 | Campos de canto NO/SE: Golem de canto (sem item) + 2 Lobos + 2 Baús Reforçados (50 % raro / 50 % comum); aggro golem 4 u, lobos 3 u; moita de lagoa movida | GDB §5.1, §5.2, §6.2; SPEC-055 | F55 | mantido — requisito novo aprovado pelo PI em 2026-10-11 (ADR-0011); boss sem mudança |
| G-14 | Protetor da Selva e Berserker: atributos, kits e Frenesi | GDB §2.2-E, §4.7, §4.8 | F74, F75 | mantido — aprovados pelo PI como proposta em 2026-10-16; ajuste no F30 |
| G-16 | Paladino Radiante e Ocultista: atributos, kits, Maldição e Servos | GDB §2.2-F, §4.9, §4.10, §7.3 | F76, F77, F78 | mantido — aprovados pelo PI como proposta em 2026-10-18; ajuste no F30 |
| G-15 | Alvo travado respeita a visão (moita, fumaça, neblina) e destrava ao sumir | GDB §7.3 | F66 | mantido — invariante de honestidade (CONVENTION §4.6) |

## 3. Design visual (DV)

| ID | Tela / item | Destino | Módulo | Status |
|---|---|---|---|---|
| V-01 | Tela 1 Lobby | F25 | launcher | mantido |
| V-01a | Perfil com nível/XP de conta, avatar, "14V–6D" | F35 | launcher, backend | mantido com mudança — R-PEND-02: sem XP de conta; `#nickname`, avatar local e V–D do histórico |
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
| V-09 | Tela 9 Histórico | F26 | launcher | mantido — "VS INIMIGO" = herói do oponente; F35 acrescenta o `#nickname` (PI 2026-10-10) |
| V-09a | Painel de KPIs do M4 (snowball rate, ping médio, duração) | F29 | launcher + backend | mantido (é o critério PRD §9.2) |
| V-09b | Exportar CSV, SQLite local, `/telemetry/matches` do cliente | — | — | adiado — o backend é a fonte; exportação é ferramenta do dev (script em `tools/`), não tela |
| V-10 | Design system (paleta, tipografia, viewport) | `docs/design-system/` | shared | mantido — paleta de `docs/prd/telas/`; fontes e molduras em revisão (design system v2, ADR-0006, R-PEND-14) |
| V-21 | Fidelidade das telas do Launcher ao protótipo de `docs/prd/telas/` (layout, acabamento, efeitos, animação); aceite lado a lado pelo PI | F24, F25, F26, F27, F33, F35 — `FRONTEND-LAUNCHER.md` §8 | launcher | mantido — requisito novo do PI em 2026-10-10 |
| V-13 | Tela de Login (só em `docs/prd/telas/`, ausente no DV) | F25 | launcher | mantido como função (PRD §8.4); visual de `docs/prd/telas/Tela de Login & Autenticação/` com os tokens de `TOKENS.md` |
| V-14 | "Pop-up Tático In-Game" (só em `docs/prd/telas/`) | — | — | **sem requisito** no PRD (R-PEND-11 decidiu só a fonte visual) |
| V-15 | Conceito "Arena & Mapa — Vale Rúnico": topologia da imagem tática (bases opostas, rio, pontes, cratera) | SPEC-007 → SPEC-044 → **SPEC-046** | game | **substituído de novo** em 2026-10-10 (ADR-0009): a imagem tática volta como referência — quadrado 80×80, rio em S NO–SE, bases SO/NE, 3 rotas, selva nos quadrantes; antes (ADR-0007): a imagem panorâmica (ilha flutuante) vira a referência de layout — bases nos cantos norte, rio N–S + anel, 4 pontes; SPEC-007 §2–3 superada |
| V-16 | Idem: torres rúnicas, ouro 18 g/s, upgrade de skill por ouro, aura do boss, tier lendário, Elo, lama −15 %, relevo −1,8 m, zona 1,5→6 %, câmera isométrica padrão | `FORA-DE-ESCOPO.md` | — | **excluídos/adiados** pelo PI em 2026-10-09 |
| V-17 | Mato alto que esconde (Astro Arena / Brawl Stars) | F7 (geometria), F32 (regra) | game | mantido — requisito novo aprovado pelo PI em 2026-10-09 |
| V-19 | Neblina de guerra: visão (raio 12 u) + explorado; servidor não replica o que está fora da visão; continua na fase 2 com a zona sempre visível | F37 (reusa o filtro do F32) | game | mantido — **revertido** de V-16 pelo PI em 2026-10-10 |
| V-20 | Câmera: pilares e muros tapam o herói (oclusão) | card `planejado` sem MVP (#70); giro da câmera F45 ajuda | game | silhueta/transparência ainda a decidir pelo PI; o PI escolheu o giro 360° (F45) em 2026-10-10 |
| V-22 | Câmera nunca mostra o vazio em volta da arena: arena num vale (faixa externa só visual com floresta, cristas e neblina), cascatas viram riacho, ilhotas saem | F56 (#150) | game, shared | mantido — requisito novo do PI em 2026-10-12 (ADR-0012), depois do F57 e antes do [GATE] do MVP2 |
| V-23 | Centro da arena livre: sem os pilares de obsidiana da cratera | F60 (#164) | game, shared | mantido — requisito novo do PI em 2026-10-13 (ADR-0014) |
| V-24 | Baú: `F` abre menu com 3 itens, clique escolhe 1, baú reservado a quem abriu (substitui a regra de troca da SPEC-047) | F61 (#165) | game, shared | mantido — requisito novo do PI em 2026-10-13 (ADR-0014) |
| V-25 | Tecla `B` mostra a ficha do herói jogado (itens, atributos, habilidades com descrição), com aba Monstros | F62 (#166) | game, shared | mantido — requisito novo do PI em 2026-10-13 (ADR-0014) |
| V-26 | Água realista em movimento: rio, riacho (F63) e fonte de cura remodelada com água caindo (F64) | F63 (#167), F64 (#168) | game, shared | mantido — requisito novo do PI em 2026-10-13 (ADR-0014) |
| V-27 | Minimapa claro e legível, também de noite: imagem pronta do mapa, neblina como véu leve | F65 (#170) | game, shared | mantido — requisito novo do PI em 2026-10-13 (ADR-0014) |
| V-18 | Tela "Arena & Mapa" no Launcher (DV tela 10): render da arena real + POIs + regras das 2 fases com números do GDB; arte conceito como meta visual da arena (decisão PI 2026-10-09) | F33 | launcher, shared | mantido (MVP3) |
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
| ~~R-PEND-02~~ | **Decidido 2026-10-09:** sem nível/XP de conta (só V–D do histórico). Perfil no Launcher (fatia F35): nickname **único**, prefixo `#` **automático** (ex.: `#RodReis`); avatar por imagem predefinida ou upload, **guardado só local no Launcher** (não vai ao backend, não aparece para outros jogadores). **Sem data de nascimento.** **Completado em 2026-10-10:** nickname obrigatório no 1º login, 3–16 `A–Z a–z 0–9 _`, único sem diferenciar maiúsculas; upload PNG/JPG ≤ 1 MB recortado 256×256; F35 entra no gate do MVP3. PRD ainda não editado. **Superado em parte em 2026-10-19 (ADR-0026):** a conta ganha Patente 1–10 no MVP5 | — | — |
| ~~R-PEND-03~~ | **Decidido 2026-10-09:** não — sem "lembrar-me"; JWT só em memória, login a cada abertura | — | — |
| ~~R-PEND-04~~ | **Decidido 2026-10-10:** herói padrão do slot (P1 Cavaleiro, P2 Arqueiro). Espelho permitido no pick | — | — |
| ~~R-PEND-05~~ | **Decidido 2026-10-09:** incluir (F13) | — | — |
| ~~R-PEND-06~~ | **Decidido 2026-10-10:** monstros comuns ficam na fase 2 (sem respawn); o Rei Esqueleto existe até morrer ou até 5:00 — vivo na transição, sai do mapa sem drop | — | — |
| ~~R-PEND-07~~ | **Decidido 2026-10-09:** roadmap — F21 sem recuperação de senha nem verificação de e-mail (fica em `FORA-DE-ESCOPO.md`) | — | — |
| ~~R-PEND-08~~ | **Decidido 2026-10-09:** incluir (F13) | — | — |
| ~~R-PEND-09~~ | **Decidido 2026-10-09:** Golem de Pedra | — | — |
| ~~R-PEND-11~~ | **Decidido 2026-10-09:** `telas/` — paleta e fontes de `docs/prd/telas/` (Space Grotesk / Outfit / JetBrains Mono) substituem as do DV §1.2–1.3; `TOKENS.md` atualizado. ~~A estrutura das telas continua a do DV~~ — **emendado em 2026-10-10:** o protótipo vence o DV na composição e toda tela do Launcher é fiel ao protótipo, com acabamento; conteúdo segue as decisões; imagens viram renders dos assets reais (`FRONTEND-LAUNCHER.md` §8). O Pop-up Tático segue sem requisito | — | — |
| ~~R-PEND-12~~ | **Decidido 2026-10-10:** revelação de 1,5 s; sem revelação por proximidade (GDB §7.3) | — | — |
| ~~R-PEND-13~~ | **Decidido 2026-10-10:** relógio da fase 2 começa às 5:00 (a transição de 5 s conta dentro dela); colapso aos 10:00 com resolução imediata — maior HP%, desempate kills F2 → dano em heróis → sorteio pela seed; os dois desconectados → `abandoned` (GDB §7.1–7.2, `CONVENTION.md` §3) | — | — |
| ~~R-PEND-14~~ | **Decidido 2026-10-11 (pop-up, F43):** HUD v2 com Cinzel (display) / Montserrat (corpo) / Barlow Condensed Bold (contadores, `tnum`), OFL. **Emendado 2026-10-15 (F24):** o Launcher usa as fontes do protótipo (Space Grotesk / Outfit / JetBrains Mono); a HUD segue v2. A fidelidade do F24 (§8) vale para layout, não para a família | — | — |
| R-PEND-10 | Renomear `docs/prd/PRD.md` → `2026-10-08-prd-moba-2-tempos.md` (nome citado no plano M0 e nos agentes) | renomear / manter | links quebrados em `docs/superpowers/plans/` e `.claude/agents/` — `CLAUDE.md` já aponta para `PRD.md` |
