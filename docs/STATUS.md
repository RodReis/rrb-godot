# STATUS.md — Kanban, roadmap e Índice Fatia ↔ SPEC

Prosa curta. Detalhe histórico vai para `STATUS-ARQUIVO.md`. O **Índice Fatia ↔ SPEC** (§3) é a fonte única da numeração: alocado pelo Cowork, número nunca reaproveitado. Progresso por item é do Code (`DEVELOPMENT.md`); aqui só o estado agregado.

## 1. Agora

| Campo | Valor |
|---|---|
| Marco / MVP ativo | **MVP2 — Partida em rede** (`docs/prd/mvp/MVP-2.md`), cards criados em 2026-10-10. MVP1 com gate aprovado pelo PI em 2026-10-10 (`STATUS-ARQUIVO.md` §Gates). MVP0 fechado em 2026-10-09 (ADR-0001: segue Godot) |
| Módulo em foco | `game/` |
| Próximo gate | [GATE] MVP2 — 1x1 online termina sempre; soak verde. MVP2.5 (bloco visual, #99) e MVP3 (#76): cards criados em 2026-10-10 |
| Documentação de governança | criada em 2026-10-08 (ADR-0002/0003/0004, arquitetura dos dois módulos); ADR-0006 (direção visual) e ADR-0007 (layout da arena) em 2026-10-10 |
| Board | issue-pai [MVP2] #57 — ordem F15 → F36 → F20 → F14 → F16 → **F44 #92** → F17 → F18 → F32 → F37 → F19 → [GATE] (ADR-0007; F16 já estava em `doing`); `done`: F15 #58; `todo`: F36 #59, F20 #60, F14 #62, F16 #63, F17 #64; `backlog`: F18 #65, F32 #66, F37 #67, F19 #68, [GATE] #69. Issue-pai [MVP2.5] **#99** (bloco visual, ADR-0006; depois do [GATE] MVP2 e antes do MVP3) — ordem **F45 #103 → F38 #93 → F39 #94 → F40 #95 → F41 #96 → F42 #97 → F43 #98**, todos `backlog`; `[INFRA]` #100 (roadmap público reconhecer MVP2.5). Issue-pai [MVP3] #76 — ordem F21 → F22 → F23 → F24 → F25 → F28 → F26 → F27 → F33 → F35 → [GATE], todos `backlog` (#77–#87). Sem MVP, `planejado`: oclusão #70 (câmera #47 fechada, substituída pelo F45 #103). MVP1 (#16): `done` [FIX] #52; demais `finalizado`. MVP0 #1–#7 `finalizado` |
| Bloqueios do PI | `RASTREABILIDADE.md` §5 — resolvidos em 2026-10-09: R-PEND-01, 05, 08, 09. R-PEND-11 decidida em 2026-10-09 (paleta e fontes de `docs/prd/telas/`). R-PEND-02 (completada), 04, 06, 12 e 13 decididas em 2026-10-10; 03 e 07 em 2026-10-09; R-PEND-11 emendada em 2026-10-10 (protótipo vence o DV na estrutura). Abertos: 10, 14 (fontes do design system v2 — trava só o F43) |

## 2. Roadmap (MVP-n = marco M-n do PRD §9.1)

| MVP | Entrega | Módulos | Critério de pronto | Estado |
|---|---|---|---|---|
| **MVP0** | Spike de netcode: 2 clientes + servidor headless em Docker, cápsula com predição, 1 ataque validado | game, infra | jogável a 100 ms sem "borracha" perceptível | **gate aprovado** — segue Godot (ADR-0001) |
| MVP1 | Arena single-player: mapa 3 zonas, Cavaleiro, monstros, XP/níveis, baús/itens, boss, bot, HUD F1 | game, shared | fase 1 completa contra bot, offline | **gate aprovado** (2026-10-10) |
| MVP2 | Partida em rede: Arqueira, pick, fase 2 (zona, kills, fim garantido), HUD F2, fim de partida, economia de campo (laterais + respawn), mato alto e neblina de guerra | game, shared | 1x1 online termina sempre; soak 50 partidas bot×bot | **em andamento** (#57) |
| MVP2.5 | Bloco visual: giro 360° da câmera (F45), iluminação e pós, toon/outline, arte da ilha, VFX, vegetação, HUD v2 (ADR-0006) | game, shared | 6 fatias aceitas pelo PI + critério de netcode do ADR-0006 item 7 | backlog (#99) |
| MVP3 | Meta + deploy: backend, launcher, pool no VPS, build PC | launcher, backend, infra | dois amigos jogam pela internet sem o dev | backlog (#76) |
| MVP4 | Playtest: telemetria, 10+ pessoas, ajuste de números | todos | decisão câmera/duração/3x3; critérios PRD §9.2 | planejado |

## 3. Índice Fatia ↔ SPEC (fonte única)

`F<n>` = `SPEC-<nnn>`, sempre iguais. Uma fatia = uma issue. `[GATE]` não tem F/SPEC. Coluna **Mód.**: `game`, `launcher`, `backend`, `shared`, `infra`. Estado: `—` (sem issue), `planejado`, `backlog`, `todo`, `doing`, `done`, `finalizado`.

| F / SPEC | MVP | Mód. | Fatia (Slice do MVP) | Estado |
|---|---|---|---|---|
| F1 / SPEC-001 | MVP0 | game, infra | Slice 0.1 — Reestruturar em `game/`, addons netfox + GUT, runner de testes | finalizado (#2) |
| F2 / SPEC-002 | MVP0 | game | Slice 0.2 — Regras puras: `LaunchArgs`, `CombatRules`, `AimMath`, `InputActions` (TDD) | finalizado (#3) |
| F3 / SPEC-003 | MVP0 | game | Slice 0.3 — Arena, cena principal, conexão servidor/cliente, player com rollback | finalizado (#4) |
| F4 / SPEC-004 | MVP0 | game | Slice 0.4 — Ataque corpo a corpo validado no servidor, HUD de rede, autopilot | finalizado (#5) |
| F5 / SPEC-005 | MVP0 | infra | Slice 0.5 — Servidor em Docker com latência/perda simuladas | finalizado (#6) |
| [GATE] | MVP0 | — | Protocolo do gate M0 e ADR-0001 | finalizado (#7) |
| F6 / SPEC-006 | MVP1 | shared | Slice 1.1 — `shared/` por junction; classes Resource; `.tres` de heróis, itens, monstros, regras (GDB §8); `stats.gd`, `xp_table.gd`, `set_bonus.gd`, `item_rules.gd`; cena de alinhamento | finalizado (#18) |
| F7 / SPEC-007 | MVP1 | game | Slice 1.2 — Arena "Vale Rúnico": layout da `spec/SPEC-007.md`, rio + 2 pontes, cratera com pilares, portões, mato (geometria), marcadores | finalizado (#19) |
| F31 / SPEC-031 | MVP1 | game, shared | Slice 1.3 — Câmera 3ª pessoa, controles teclado/mouse/gamepad, cena de alinhamento KayKit (avaliação de câmera B-02 pelo PI) | finalizado (#20) |
| F8 / SPEC-008 | MVP1 | game | Slice 1.4 — Cavaleiro: modelo KayKit, ataque básico, Q Investida, E Muralha, R Terremoto, lendo `shared/data` | finalizado (#21) |
| F9 / SPEC-009 | MVP1 | game | Slice 1.5 — Monstros tier 1–3 com IA, XP, níveis, pontos de skill, catch-up | finalizado (#22) |
| F10 / SPEC-010 | MVP1 | game | Slice 1.6 — Baús, itens, inventário 4 slots, substituição, bônus de conjunto | finalizado (#23) |
| F11 / SPEC-011 | MVP1 | game | Slice 1.7 — Rei Esqueleto aos 3:30, drop épico | finalizado (#24) |
| F12 / SPEC-012 | MVP1 | game | Slice 1.8 — Bot FSM fase 1 (`BotInput`), modo offline com servidor embutido | finalizado (#25) |
| F13 / SPEC-013 | MVP1 | game, shared | Slice 1.9 — HUD fase 1 + relógio + aviso do boss aos 3:00 + bestiário em partida (`B`) + componentes base do design system | finalizado (#26) |
| F34 / SPEC-034 | MVP1 | game, shared | Slice 1.10 — Pilares da cratera e mato alto com assets do Blender (só visual; colisão do F7 intacta) — depois do [INFRA] #34 | finalizado (#38) |
| [GATE] | MVP1 | — | Homologação: fase 1 completa contra bot, offline (PRD M1) | finalizado (#27) |
| [INFRA] | MVP1 | ci | CI: `lint-gd` (tipagem, literais em `core/`, I9), path filter por módulo, `shared/test` no `test-game` — antes de F6 | finalizado (#17) |
| [INFRA] | — | infra | Pipeline Blender (ADR-0005): `art/`, `.gitattributes`/`.gitignore`, import de `.blend` desligado — antes do primeiro asset via Blender | finalizado (#34) |
| F14 / SPEC-014 | MVP2 | game | Slice 2.1 — Arqueira: projétil validado no servidor, Q perfurante, E rolamento, R chuva | done (#62) |
| F15 / SPEC-015 | MVP2 | game | Slice 2.2 — Ciclo de partida: `MatchController` (FSM), seleção de heróis, PvP fase 1, respawn, eventos por RPC | done (#58) |
| F16 / SPEC-016 | MVP2 | game | Slice 2.3 — Fase 2: zona, dano, respawn, kills, morte súbita, regras de vitória | done (#63) |
| F17 / SPEC-017 | MVP2 | game | Slice 2.4 — Transição 5:00 + HUD fase 2 + vinheta de zona | done (#64) |
| F18 / SPEC-018 | MVP2 | game | Slice 2.5 — Tela de fim de partida com estatísticas | done (#65) |
| F19 / SPEC-019 | MVP2 | game | Slice 2.6 — Bot fase 2 + soak 50 partidas headless (`tools/soak.ps1`) | backlog (#68) |
| F20 / SPEC-020 | MVP2 | game | Slice 2.7 — Monstros, baús e boss replicados (2 clientes reais) | finalizado (#60) |
| F36 / SPEC-036 | MVP2 | game, shared | Slice 2.9 — Economia de campo: 4 campos laterais (2 T1 + 1 T2 e 2 baús comuns cada), respawn de monstros não-boss 90 s na fase 1 (GDB §5, §6.2) | finalizado (#59) |
| F37 / SPEC-037 | MVP2 | game, shared | Slice 2.10 — Neblina de guerra: visão 12 u + explorado, filtro de replicação por peer (generaliza o F32), minimapa (`CONVENTION.md` §4.9) | done (#67) |
| [GATE] | MVP2 | — | Homologação: 1x1 online termina sempre; soak verde | backlog (#69) |
| F21 / SPEC-021 | MVP3 | backend | Slice 3.1 — NestJS: auth e-mail/senha, JWT, usuários, migrações | backlog (#77) |
| F22 / SPEC-022 | MVP3 | backend | Slice 3.2 — Fila 1x1 FIFO + orquestrador (pool Docker, token de partida, heartbeat) | backlog (#78) |
| F23 / SPEC-023 | MVP3 | game | Slice 3.3 — Game server: `--token`, validar no backend, reportar resultado, códigos de saída | backlog (#79) |
| F24 / SPEC-024 | MVP3 | launcher, shared | Slice 3.4 — Shell do launcher: `App`, pilha de telas, Theme completo, galeria de componentes, configurações (vídeo/áudio/controles, aba Créditos) e `settings.cfg` | backlog (#80) |
| F25 / SPEC-025 | MVP3 | launcher | Slice 3.5 — Login, lobby com diorama, fila (polling), lançar/esperar o Game, treino vs bot | backlog (#81) |
| F26 / SPEC-026 | MVP3 | launcher, backend | Slice 3.6 — Histórico de partidas (`GET /matches`) | backlog (#83) |
| F27 / SPEC-027 | MVP3 | launcher | Slice 3.7 — Bestiário e Forja (simulador com `shared/core`) | backlog (#84) |
| F33 / SPEC-033 | MVP3 | launcher, shared | Slice 3.9 — Tela Arena & Mapa (DV tela 10): render da arena real, marcadores (POIs), regras das 2 fases pelos números do GDB | backlog (#85) |
| F35 / SPEC-035 | MVP3 | launcher, backend | Slice 3.10 — Perfil de conta: nickname único obrigatório no 1º login (3–16 `A–Z a–z 0–9 _`, prefixo `#` de exibição); avatar predefinido ou upload ≤ 1 MB, só local; sem XP de conta, sem data de nascimento (R-PEND-02) | backlog (#86) |
| F38 / SPEC-038 | MVP2.5 | game | Slice 2.5.1 — Iluminação e pós: `WorldEnvironment`, `Sun`, `LightmapGI`, warm-up de shaders, baseline do profiler, toggles em `settings.cfg` (ADR-0006) | backlog (#93) |
| F39 / SPEC-039 | MVP2.5 | game, shared | Slice 2.5.2 — Toon + outline por pós-import | backlog (#94) |
| F40 / SPEC-040 | MVP2.5 | game, shared | Slice 2.5.3 — Arte da ilha sobre a SPEC-044: ilha + abismo, castelos, rio de mana e cachoeiras, cratera de magma, cristais, skybox, ilhotas; shaders de água/magma/cristal/sky (ADR-0007) | backlog (#95) |
| F41 / SPEC-041 | MVP2.5 | game | Slice 2.5.4 — Arquitetura VFX + VFX do Cavaleiro e da Arqueira | backlog (#96) |
| F42 / SPEC-042 | MVP2.5 | game, shared | Slice 2.5.5 — Vegetação (grama `MultiMesh`, distinta do mato alto) | backlog (#97) |
| F43 / SPEC-043 | MVP2.5 | game, shared | Slice 2.5.6 — HUD v2 (ghost bar, ícones, molduras, fontes R-PEND-14, 3 pontos) | backlog (#98) |
| F28 / SPEC-028 | MVP3 | infra | Slice 3.8 — Deploy no VPS (Coolify, compose, UDP 7000–7020), export presets, pacote de instalação (`launcher/` + `game/`) | backlog (#82) |
| F45 / SPEC-045 | MVP2.5 | game, shared | Slice 2.5.7 — Câmera: giro 360° com o botão esquerdo segurado; ataque básico no botão direito (só cliente; substitui #47) | backlog (#103) |
| [INFRA] | MVP2.5 | infra | Roadmap público (`build-roadmap.mjs`) e `GITHUB.md` passam a aceitar o marco `MVP2.5` — antes da 1ª fatia do marco ser entregue | backlog (#100) |
| [GATE] | MVP3 | — | Dois amigos jogam pela internet sem intervenção do dev | backlog (#87) |
| F29 / SPEC-029 | MVP4 | backend, launcher, game | Slice 4.1 — Telemetria: ping médio, duração, líder de nível F1 × vencedor; painel de KPIs no histórico | — |
| F30 / SPEC-030 | MVP4 | shared | Slice 4.2 — Ajustes de balanceamento pós-playtest (só `.tres`) | — |
| F32 / SPEC-032 | MVP2 | game | Slice 2.8 — Mato alto: herói dentro da moita não é replicado para o adversário (visibilidade no servidor); regra em `CONVENTION.md` §4.7, números em GDB §7.3 (revelação 1,5 s) | done (#66) |
| F44 / SPEC-044 | MVP2 | game, shared | Slice 2.11 — Arena "Ilha Flutuante Arcana": layout novo (espelho N–S, rio N–S + anel, 4 pontes), builder, colisão, marcadores, navmesh **+ a arte do F40 no mesmo card** (decisão do PI 2026-10-10: kits Blender, shaders de rio/magma/cristal/céu, baú novo) | doing (#92) |
| [GATE] | MVP4 | — | Playtest 10+ pessoas; critérios PRD §9.2; decisão câmera/duração/3x3 | — |

Próximo número livre: **F46 / SPEC-046**.

## 4. Regras deste índice

- Só o Cowork aloca número. Partir uma fatia = número novo (nunca sufixo). Ex.: F8 partido em 2026-10-09 → F31 (câmera/controles) saiu dele e **entra antes** dele na ordem. Fatia cancelada mantém a linha com estado `cancelada` e motivo em `STATUS-ARQUIVO.md`.
- A issue-pai de cada MVP tem título `[MVPn] <título>`; cada F é sub-issue nativa dela (`GITHUB.md` §9).
- Os próximos 5 cards da ordem ficam em `proplan:todo`.
- `shared` como módulo: a fatia muda `shared/` e, por isso, dispara CI de `game` e `launcher`.
