# DEVELOPMENT.md — Ordem de execução e status por item

Mantido pelo **Code** a cada entrega (junto com o progresso em `STATUS.md`). Os passos de cada fatia vivem aqui, não na issue. Numeração: `STATUS.md` §3.

## 0. Setup da máquina (uma vez)

```powershell
cd C:\Desenv\Projetos\rrb-godot
powershell -ExecutionPolicy Bypass -File tools\setup-godot-mcp.ps1   # GODOT_PATH, godot-mcp
powershell -ExecutionPolicy Bypass -File tools\link-shared.ps1       # junctions game/shared e launcher/shared (a partir de F6)
docker version                                                        # Docker Desktop (WSL2)
node -v; corepack enable; pnpm -v                                     # backend (a partir de F21)
```

Abrir editor: `& $env:GODOT_PATH -e --path game` ou `--path launcher`.

## 1. Comandos por módulo

| O quê | game | launcher | backend |
|---|---|---|---|
| Testes | `.\tools\test.ps1 -Module game` | `.\tools\test.ps1 -Module launcher` | `pnpm -C backend test` |
| Rodar | `.\tools\run-server.ps1` + `.\tools\run-clients.ps1 -Autopilot` | `& $env:GODOT_PATH --path launcher` | `pnpm -C backend start:dev` |
| Offline/bot | `& $env:GODOT_PATH --path game -- --offline --bot` | — | — |
| Docker | `docker compose -f infra/docker-compose.yml up --build` | — | incluído no compose |
| Soak | `.\tools\soak.ps1 -Matches 50` | — | — |

`tools/test.ps1 -Module X` roda GUT headless em `X/test` **e** `shared/test` (ADR-0003). Até F1, os comandos do M0 valem como estão no plano.

## 2. Ordem de execução

A ordem é a do Índice (`STATUS.md` §3). Dentro de cada MVP, o Code pega o primeiro `todo`. Status: `[ ]` não iniciado · `[~]` em andamento · `[x]` concluído (PR mergeada) · `[-]` cancelado.

### MVP0 — Spike de netcode (`game`, `infra`)

Passo a passo: `docs/superpowers/plans/2026-10-08-m0-spike-netcode.md` (Tarefas 0–12). Mapeamento:

- [x] **F1** — Tarefas 0, 1, 2, 3 (snapshot, `game/`, netfox + GUT, runner `tools/test.ps1`) + CI mínimo (`test-game` + `gate`, `CI-PR.md` §2)
- [x] **F2** — Tarefas 3 (`LaunchArgs`), 4, 5, 6
- [x] **F3** — Tarefas 7, 8 (roteiro: `game/test/net/roteiro-f3-conexao-movimento.md`)
- [x] **F4** — Tarefas 9, 10 (roteiro: `game/test/net/roteiro-f4-ataque-hud-autopilot.md`)
- [x] **F5** — Tarefa 11 (roteiro: `game/test/net/roteiro-f5-docker-netem.md`)
- [x] **[GATE] M0** — Tarefa 12 → ADR-0001 → decisão do PI: **segue Godot** (2026-10-09)

### MVP1 — Arena single-player (`game`, `shared`)

- [x] **[INFRA] CI** — `lint-gd` (gdlint/gdformat, tipagem compilando no Godot, literais em `core/`, I9), `changes` com path filter, `shared/test` no `test-game` (`CI-PR.md` §2–§4). Antes de F6. (#17, PR #28)
- [x] **[INFRA] Pipeline Blender** — `art/` com README; `*.glb`/`*.blend` binários; `*.blend1`/`*.blend2` ignorados; `filesystem/import/blender/enabled=false` no `game/project.godot` (ADR-0005). (#34)
- [x] **F6** — `shared/` + junction + `tools/link-shared.ps1`; `shared/resources/*.gd` (`HeroData`, `SkillData`, `ItemData`, `MonsterData`, `MatchRules`, `SetBonusData`, `XpCurve`); `.tres` de GDB §8; `shared/core/{stats,hero_attributes,xp_table,set_bonus,item_rules,ids,input_actions}.gd` com GUT; fixture I5. `_alignment.tscn` ficou com F31 (escopo da issue #18). (#18)
- [x] **F7** — `arena.tscn` conforme `docs/prd/mvp/spec/SPEC-007.md` (gerada por `tools/arena/build_arena.gd`): tiles KayKit a 3 u, raio 35 u, rio (colisão) + 2 pontes, cratera com 8 pilares/4 entradas, muros, moitas (`Area3D` `tall_grass`, só geometria), portões por time, `SpawnMarker`; testes de simetria, contagem, raycast e tempos (6,08 s / 12,16 s). Spawn em (−24, +24) e campos do centro em 45°/225° (PI 2026-10-09). (#19)
- [x] **F31** — `follow_camera` 3ª pessoa 45° distância fixa, yaw fixo do time; `InputActions` completo (teclado/mouse/gamepad, DV §3.3, esquiva no A); `shared/assets/_alignment.tscn` com Knight ≈ 1,8 u; **B-02: PI manteve a 3ª pessoa** (2026-10-09, `STATUS-ARQUIVO.md`). (#20)
- [x] **F8** — `knight.tscn` (KayKit Knight + animações); ataque básico, Q (empurrão via ledger), E (escudo absorve + bloqueia projétil — hitbox de bloqueio), R (stun via ledger) lendo `knight.tres`; remove as constantes de spike de `player.gd`. Entregue: `Hero` genérico + `knight.tscn`; `--level` de dev até o F9 (PI 2026-10-09). (#21)
- [x] **F34** — pilares da cratera e mato alto com os assets do Blender (`shared/assets/rrb/arena/*.glb`, fonte `art/arena/crater_props.blend`); só visual, colisão do F7 mantida; captura no roadmap. (#38)
- [x] **[FIX] Docker sem `shared/`** — a imagem do servidor copiava só `game/` e `game/shared` (junction) virava symlink quebrado: `hero.gd` não compilava e a arena perdia nós. `Dockerfile` copia `shared/` para `/game/shared`; `.dockerignore` ignora as junctions e `art/`. (#42)
- [x] **[FIX] Rollback no portão/muro** — perto de muro a despenetração mexia no y e o encaixe no chão do `move_and_slide()` dependia de `is_on_floor()` do tick anterior (fora do rollback); `Hero` com `axis_lock_linear_y`; `test_hero_rollback.gd`; roteiro `game/test/net/roteiro-fix41-portao-muro.md` (100 ms: 4 → 0 correções). (#41)
- [x] **F9** — `Monster` (`scripts/ai/monster.gd`, FSM pura em `MonsterRules`: parado → persegue → leash), 4 monstros não-boss com `.tres` (aggro 6, leash 10, 4 u/s, corpo a corpo 1,8, área do Golem 2,5 — PI 2026-10-09); `SpawnDirector` (um por marcador, sem respawn); XP por abate com catch-up, nível pelo XP (curva: nível 3 em 225, PI 2026-10-09), pontos por `Ctrl+Q/E/R` (`SkillRules.learn`); Golem de Pedra de "Lava Golem" (vladimirmejia, CC-BY) adaptado no Blender (`art/monsters/golem.blend`). (#22)
- [x] **F10** — `chest.tscn` (blockout) + `Chest`, `ChestRules` (sorteio com RNG injetado: comum 70 % item / 30 % cura; raro 65/25/10, épico só armadura), drops pré-sorteados pelo `SpawnDirector` com seed (`--seed`); `Inventory` (4 slots como ids no estado de rollback, atributos por `Stats.attributes`, I5 provado no `Hero`); `F` toque abre a ≤ 1,5 u, item de raridade igual/menor fica no baú até um `F` novo segurado 0,4 s, antigo some; cura e item pelo ledger; `ItemCatalog` em `shared/` (PI 2026-10-09). (#23)
- [x] **F11** — `MatchClock` (ticks; 3:00 aviso, 3:30 boss, 5:00 fim da fase 1; início replicado e eventos no mesmo tick nos dois lados; `--time` de dev); Rei Esqueleto (`skeleton_king_boss.tscn`: `Skeleton_Minion` 1,35 + coroa própria `art/monsters/crown.blend`), aggro 7 / leash 8 / 3,5 u/s / corpo a corpo 2,2 / área 3,0 / empurrão 2,5 (PI 2026-10-09); ao morrer, 550 XP e baú dourado com um dos 7 épicos (PI 2026-10-09); portões caem aos 5:00; empurrão em herói virou deslize no estado de rollback (0,25 s). (#24)
- [x] **F12** — `--offline` = **modo host** (o processo é servidor ENet em `127.0.0.1`, porta efêmera, e jogador local peer 1 — o netfox tem um papel por processo; PI 2026-10-09); `--bot` = herói bot no time B, entra com o 1º jogador e ocupa a vaga (também no servidor dedicado). `BotInput` (extends `PlayerInput`, input do servidor) + FSM pura `BotRules` (Recuar > Lutar > Contestar > Farmar a base > Saquear a base > Farmar o centro; limiares em `shared/data/rules/bot_profile.tres`, PI 2026-10-09); `ArenaNav` assa o navmesh em runtime dos colisores (portão do adversário vira parede). Aceite headless: 5:00 sem erro, bot no Nv 5–6. (#25)
- [x] **F13** — `hud_phase1.tscn`; aviso do boss aos 3:00 (banner `PanelCard accent=PURPLE` + som + pista no portal); modal de bestiário por `B` (`CatalogList` + `DetailCard` + `MonsterPreview3D`, pausa **não** — a partida continua); componentes `PanelCard`, `StatBar`, `SlotItem`, `SkillButton`, `TimerLabel`, `HotkeyBadge`, `Toast`, `Minimap` em `shared/ui/components` + `_gallery.tscn`; Theme inicial (`TOKENS.md` §6). Paleta e fontes de `docs/prd/telas/` (R-PEND-11 decidida em 2026-10-09). Entrega em 3 PRs no mesmo card (PI 2026-10-09): **PR 1** Theme (`theme_moba.tres` gerado por `ThemeBuilder` a partir de `UiTokens`), fontes OFL variáveis, `PanelCard`, `HotkeyBadge`, `StatBar`, `TimerLabel`, `SkillButton` (recarga radial, pedido do PI na #26), `SlotItem` + `ItemTooltip`, `Toast`, `_gallery.tscn`; viewport 1920×1080 `canvas_items/expand` com janela de dev 1280×720. **PR 2** `hud_phase1.tscn` (`HudPhase1`, só lê estado replicado; contas em `HudMath`), `Minimap` (`SubViewport` ortográfico, marcadores por cima), `WorldHealthBar` (quad billboard com shader, verde = local, vermelho = inimigo/monstro) no lugar do texto de HP; oferta de troca do baú saiu do `Label3D` para a HUD; `SetBonusData.display_name`. Verificação visual aprovada pelo PI; bug do bot visto nela virou [FIX] #52. **PR 3** aviso do boss aos 3:00 (banner `PanelCard` roxo central 3 s, `jingles_STEEL07` CC0 da Kenney, `BossPortal` roxo no marcador BOSS até 3:30; quem entra tarde não recebe banner atrasado) + bestiário por `B` (`CatalogList`, `DetailCard`, `MonsterPreview3D`; lista montada na 1ª abertura; não pausa, herói parado por `PlayerInput.suspended`; preview só com o nó `Model` da cena, sem criar monstro). Ficha mostra só dados do `.tres` (sem texto de descrição/dicas do DV tela 5).
- [x] **[FIX] Bot gira sem alvo** — `BotInput._go` normalizava o resto minúsculo do caminho ao chegar no ponto e invertia a direção a cada tick; agora para (< `WAYPOINT_REACHED`). Decisão do PI (2026-10-09): portões caídos (5:00) e nada do próprio lado → o bot farma o que sobrou na base do jogador e, sem monstro, vai até ele; `main.gd` refaz o navmesh sem portões em `phase1_ended`. 3 testes em `test_bot.gd`. (#52)
- [x] **[FIX] Empurrão do boss intermitente no teste** — `test_boss` movia o herói contra a cratera no mesmo frame em que a arena entrou na árvore (~1 falha em 4 rodadas da suíte); agora espera 2 frames de física. 6/6 rodadas verdes. (#71)
- [x] **[GATE] MVP1** — partida de 5:00 contra bot do início ao fim; **aprovado pelo PI em 2026-10-10** (`STATUS-ARQUIVO.md` §Gates). (#27)

### MVP2 — Partida em rede (`game`)

- [x] **F14** — `ranger.tscn`: Ranger do KayKit Adventurers **2.0** (o 1.0 não tem Ranger) + arco `bow_withString` no `handslot.l` + 7 animações do `Knight.glb` 1.0 (rig idêntico: 23 ossos, mesmos nomes e repouso), montado por `art/heroes/build_ranger.py` → `art/heroes/ranger.blend` → `shared/assets/rrb/heroes/ranger.glb`; flecha `arrow_bow.gltf` do pack como vem. `Hero` vira base genérica (avanço, escudo, lentidão, invulnerabilidade) e as habilidades vão para `Knight` e `Ranger`. **Projétil:** o netfox 1.35.3 não tem spawn dentro do rollback, então a flecha é um pool fixo de 4 `Arrow` filhos do herói, com estado no `RollbackSynchronizer` dele (`ARCHITECTURE-GAME.md` §3.2): o cliente prevê o disparo e o servidor decide o acerto pelo ledger. Flecha para em muro, pilar, rocha, portão que barra a Arqueira e na Muralha ativa do inimigo, não no rio (PI 2026-10-10). Q usa velocidade e raio do básico (PI 2026-10-10) e perde 15 % por alvo, piso 40 % (linear). E: 4,2 u cravados em 11 ticks, 9 ticks sem dano (só dano, GDB §4.2), reseta o básico. R: área no ponto do cursor até 8 u (input novo `aim_distance`, gamepad = alcance máximo; PI 2026-10-10), 6 pulsos (0, 0,5…2,5 s), lentidão de 25 % em herói **e monstro** (PI 2026-10-10) até o pulso seguinte. Avanço agora conta depois de andar (a Investida do Cavaleiro anda os 6 u inteiros; antes, 5,6 u) e empurrão/atordoamento o interrompem. Bot: Q em linha até 11 u, R com a mira no alvo, Rolamento fora; só atira com linha de tiro livre. Regras puras em `RangerRules` e `CombatRules` (segmento × corpo, segmento × Muralha). Offline 5:00 (bot de Arqueira): 0 `ERROR`, bot **Nv 10, 4510 XP**, limpa a metade, o centro e o boss. Rede B: ver roteiro `game/test/net/roteiro-f14-arqueira.md`. (#62)
- [x] **F15** — `MatchController` (`scripts/match/`): FSM `LOBBY_WAIT → HERO_PICK → PHASE1 → TRANSITION` sobre o `MatchClock` (que agora começa na PHASE1); estados em `MatchState`, regras puras `PickRules` e `KillRules` (kill só na fase 2; XP do abate reusa `XpTable.pvp_kill_xp`). `match_pacing.tres` ganhou `lobby_wait_timeout` (120 s, escolha do Code — nenhum documento fixa o valor), `hero_pick_duration` (24 s) e `default_heroes` (P1 Cavaleiro, P2 Arqueira). Lógica só no servidor; nos clientes o nó só repassa os eventos `@rpc` reliable com tick (`phase_changed`, `hero_picked`, `player_died`, `player_leveled`, `chest_opened`, `match_ended`). `hero_select.tscn` (DV tela 2): `1`/`2`, `Espaço`, Arqueira indisponível até haver cena (`Hero.SCENE_PATH`), espelho aceito, bot confirma o padrão na hora; botão Voltar do DV fica fora (sem destino até o launcher). Morte: `hp 0` → inerte, sem colisão, fora de alcance de monstro e bot; renasce na base em `respawn_seconds` (8 s na fase 1, 6 s a partir da TRANSITION) com os itens; 80 XP ao matador pelo ledger. Overlay "VOCÊ FOI ABATIDO!" na HUD e animação `Death_A`. Desconexão: `Hero.mark_disconnected` passa o input ao servidor (input vazio + `process_authority`), herói segue simulado e sofrendo dano; log `[net]` a cada 5 s. Sem entrada tardia (só entra no `LOBBY_WAIT`): `send_state` de relógio, baús e boss removidos. Servidor dedicado encerra no `match_ended`. (#58)
- [x] **[FIX] Bot morre em loop no Rei Esqueleto** — com a morte do F15 o bot contestava o boss, recuava sem se curar e voltava (706 mortes numa sessão ociosa). Regra do PI (2026-10-10): só contesta com HP ≥ 70 % (`contest_hp_pct` em `bot_profile.tres`, `BotRules.wants_contest`); abaixo farma e saqueia. **Fonte de vida na base** (escopo ampliado pelo PI no mesmo card, 2026-10-10): uma por base no canto esquerdo (`(-30,4; 14,8)` e espelho), modelo próprio `art/arena/fountain.blend` → `shared/assets/rrb/arena/fountain.glb` (144 tri, atlas KayKit); cura o time dono em 1 % do HP máx./s, só na fase 1, raio 2,5 u, dano pausa 3 s (`fountain_*` em `match_pacing.tres`, `FountainRules`, `Hero._drink` no servidor, `heal_pause_ticks` no estado de rollback; `MatchController` liga na PHASE1); bot recua até a fonte e fica até 70 %. (#74)
- [x] **F36** — 4 campos laterais no builder da arena (cantos NO e SE, um de cada lado do rio; 2 T1 + 1 T2 + 2 baús comuns cada; espelho em `l` dentro da metade = mesma distância do spawn, 35,5 u; rotação de 180° entre metades): 29 monstros e 24 baús. Marcadores com o time da metade, então o bot conta base + laterais como "a própria metade" (GDB §5.2). Fontes do #88 passam a sair do builder (estavam só no `.tscn`). Respawn: `MatchRules.monster_respawn_phase1` = 90 s; `SpawnDirector.update(tick)` revive no mesmo node (`Monster.revive`: HP, posição e colisão; HP/posição já replicam), `stop_respawns` em `phase1_ended` cancela pendentes; boss não renasce. Bot: revida monstro no alcance enquanto recua e monstro parado não conta como perigo (o T1 da base renasce perto da fonte e prendia o bot em RETREAT). Offline vs bot 5:00 (seed 36): bot **Nv 5, 900 XP** (só a própria metade; não pegou centro nem boss); jogador em autopilot Nv 1. (#59)
- [ ] **F16** — `ZoneController`, `KillTracker`, `VictoryRules`, morte súbita, colapso; testes I1–I3.
- [ ] **F44** (#92) — `tools/arena/build_arena.gd`: simetria por espelho em `x`, spawns `(∓24, −24)`, portões `(∓15, −15)`, canal do rio N–S (`|x| ≤ 2`, `r > 18`) + anel, 4 pontes nos azimutes 45°/135°/225°/315°, campos do centro em 0°/180°, mato (4 + 2), marcadores dos campos laterais do F36 reposicionados (O/SO e L/SE); regerar `arena.tscn`; `ArenaNav` inalterado (conferir as 4 pontes); bot escolhe a ponte mais próxima. Aceite SPEC-044 §6 (tempos medidos, 12 pontos de rio, espelho GUT, 3 partidas offline com bot). Screenshot de cima no roadmap. Sem arte (F40).
- [ ] **F17** — transição 5 s, `hud_phase2.tscn`, `ZoneRadar`, `ScoreBanner`, vinheta.
- [ ] **F18** — `match_end.tscn`, estatísticas acumuladas no servidor (`MatchStats`).
- [ ] **F19** — bot fase 2; `tools/soak.ps1`; CI nightly `soak`.
- [x] **F20** — Spawn confiável antes do estado: `SpawnAck` (`scripts/net/`) deixa o `RollbackSynchronizer` do herói sem destinatário no servidor até o cliente confirmar por RPC confiável que já tem o node (fim do `Node not found` do F5). Nenhum monstro nasce/some no meio da partida: o Rei Esqueleto existe desde o load fora do mapa (`Monster.present`, replicado), entra às 3:30 e, vivo às 5:00, sai sem drop nem XP (`SpawnDirector.dismiss_boss`, R-PEND-06); painel da HUD mostra "SAIU DO MAPA" (texto aprovado pelo PI). Baús: `opened_tick` do servidor nos dois lados. Medição: `NetProbe` (`--probe`: remoto parado, checkpoints de monstros/baús pelo histórico do `StateSynchronizer`, throttle do ENet), `--autopilot=bot` (o `BotInput` joga pelo herói local do cliente), `tools/net-measure.ps1` (Docker + netem + 2 clientes + banda) e `tools/net-probe-report.ps1`. B (10 min): remoto parado 6,2 % / 2,7 %, checkpoints 60/60 nos dois clientes, 0 `Node not found`, servidor envia 1,3 Mbit/s para 2 clientes. C fora da meta (decisão do PI, 2026-10-10) — investigação em `game/test/net/roteiro-f20-replicacao.md`. (#60)
- [ ] **[GATE] MVP2** — 1x1 online termina sempre; soak 50/50.

### MVP3 — Meta + deploy (`backend`, `launcher`, `infra`, `game`)

- [ ] **F21** — `backend/`: NestJS 11, Drizzle + Postgres, `auth`, `users`, zod, Pino; e2e com Postgres em container; `openapi.json`.
- [ ] **F22** — `matchmaking`, `orchestrator` (Dockerode, pool, token, heartbeat), `matches` internos.
- [ ] **F23** — Game server: `--token`, `BackendClient`, `ResultReporter`, códigos de saída (`ARCHITECTURE-GAME.md` §6).
- [ ] **F24** — `launcher/`: `App`, `ScreenStack`, `Router`, `SettingsStore` + `settings.cfg` compartilhado, tela Configurações, Theme completo, galeria. **Obrigação de licença:** créditos do jogo com o Golem de Pedra ("Lava Golem", vladimirmejia, CC-BY 3.0 — `shared/assets/LICENSES.md`) antes de qualquer build distribuída; fatia que leva a tela de créditos a confirmar pelo Cowork (registrado pelo PI em 2026-10-09).
- [ ] **F25** — `AuthService`, `ApiClient`, `QueueService`, `GameProcess`; telas Login e Lobby (diorama); treino vs bot.
- [ ] **F26** — `HistoryService`, tela Histórico, `GET /matches`.
- [ ] **F27** — `CatalogService`, Bestiário, Forja com simulador (`shared/core`).
- [ ] **F28** — `infra/` para VPS (Coolify, compose com `backend`, `postgres`, `gameserver`), export presets, pacote `launcher/ + game/`, UDP 7000–7020.
- [ ] **F38** — `arena.tscn`: `WorldEnvironment` (ACES, SSAO, SSIL, glow 1.05, fog 0.008) + `Sun` (4 splits, blur 1.8) + `LightmapGI` bakeado (`tools/bake-lightmap.ps1`); `scripts/client/shader_warmup.gd` antes do `connect`; baseline do profiler em `docs/roadmap/`; chaves `graphics.*` em `settings.cfg`. Critério 3/3 sync a 100 ms (ADR-0006 item 7).
- [ ] **F39** — `shared/assets/post_import_toon.gd` (`EditorScenePostImport`), `shared/resources/materials/toon_base.tres` + `outline_pass.tres`; sem editar glTF. Critério 3/3; delta de frame time.
- [ ] **F40** — Blender: `art/arena/{ilha,castelo,cratera,pontes,props}.blend` → `shared/assets/rrb/arena/*.glb` (UV 0..1, UV2 com AO/curvatura) sobre o layout da SPEC-044; `game/shaders/{arcane_river,volcanic_lava,arcane_crystal,abyss_sky}.gdshader` (rio: `water_depth = linear_depth + VERTEX.z`, `NORMAL_MAP`, `NoiseTexture2D`); cachoeiras e brasas (`GPUParticles3D`, cliente); colisão do F44 intacta; cena de alinhamento. Critério 3/3; delta; roadmap.
- [ ] **F41** — `game/scenes/vfx/`, `scripts/vfx/vfx_pool.gd`, `vfx_spawner.gd` (cliente, `is_fresh`, sinal do `HitLedger`), teste GUT de spawn único; VFX de básico/Q/E/R do Cavaleiro e da Arqueira; trail da flecha com interpolação visual separada do estado. Servidor headless sem nós de VFX. Vídeo no roadmap.
- [ ] **F42** — `game/scenes/arena/vegetation.tscn` (`MultiMeshInstance3D`), `game/shaders/grass_wind.gdshader` (fase por instância), máscara de distribuição longe do mato alto. Aceite visual do PI: grama ≠ mato.
- [ ] **F43** — `stat_bar.gd` ghost bar (tipado), ícones Q/E/R + badge, `StyleBoxTexture`, fontes (R-PEND-14) com outline, 3 pontos em `hero_select.tscn` e `monster_preview_3d.tscn`; `_gallery.tscn` atualizada.
- [ ] **[GATE] MVP3** — dois amigos jogam pela internet sem o dev.

### MVP4 — Playtest

- [ ] **F29** — telemetria (ping médio, duração, líder F1 × vencedor, "teleportes" reportados) no backend; painel de KPIs no Histórico; `tools/export-matches.ps1`.
- [ ] **F30** — ajustes de balanceamento (só `.tres`).
- [ ] **[GATE] MVP4** — critérios PRD §9.2; decisões câmera/duração/3x3.

## 3. Definição de pronto de uma fatia

1. PR com CI verde (`gate`), squash na `main`, `mergedAt` confirmado.
2. Testes da camada tocada (`ARCHITECTURE-*.md` §testes) com saída real na PR.
3. Regra pura nova → GUT. UI nova → prova por tela (`FRONTEND-LAUNCHER.md` §6). Rede nova → roteiro em `game/test/net` executado.
4. `DEVELOPMENT.md` (este) e progresso em `STATUS.md` atualizados **na mesma PR**.
5. Comentário de encerramento na issue (`fechar-card`) → `proplan:done`. Aceite (`finalizado`) é do PI.
