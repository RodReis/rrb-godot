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
- [~] **F13** — `hud_phase1.tscn`; aviso do boss aos 3:00 (banner `PanelCard accent=PURPLE` + som + pista no portal); modal de bestiário por `B` (`CatalogList` + `DetailCard` + `MonsterPreview3D`, pausa **não** — a partida continua); componentes `PanelCard`, `StatBar`, `SlotItem`, `SkillButton`, `TimerLabel`, `HotkeyBadge`, `Toast`, `Minimap` em `shared/ui/components` + `_gallery.tscn`; Theme inicial (`TOKENS.md` §6). Paleta e fontes de `docs/prd/telas/` (R-PEND-11 decidida em 2026-10-09). Entrega em 3 PRs no mesmo card (PI 2026-10-09): **PR 1** Theme (`theme_moba.tres` gerado por `ThemeBuilder` a partir de `UiTokens`), fontes OFL variáveis, `PanelCard`, `HotkeyBadge`, `StatBar`, `TimerLabel`, `SkillButton` (recarga radial, pedido do PI na #26), `SlotItem` + `ItemTooltip`, `Toast`, `_gallery.tscn`; viewport 1920×1080 `canvas_items/expand` com janela de dev 1280×720. **PR 2** `hud_phase1.tscn` (`HudPhase1`, só lê estado replicado; contas em `HudMath`), `Minimap` (`SubViewport` ortográfico, marcadores por cima), `WorldHealthBar` (quad billboard com shader, verde = local, vermelho = inimigo/monstro) no lugar do texto de HP; oferta de troca do baú saiu do `Label3D` para a HUD; `SetBonusData.display_name`. Verificação visual aprovada pelo PI; bug do bot visto nela virou [FIX] #52. PR 3: aviso do boss (som CC0 Kenney) + bestiário (`CatalogList`, `DetailCard`, `MonsterPreview3D`).
- [ ] **[GATE] MVP1** — partida de 5:00 contra bot do início ao fim; PI avalia.

### MVP2 — Partida em rede (`game`)

- [ ] **F14** — `ranger.tscn`, `arrow.tscn` com pool compatível com netfox, Q/E/R.
- [ ] **F15** — `MatchController` FSM, `hero_select.tscn`, PvP fase 1, respawn, RPCs discretos; `LOBBY_WAIT` com timeout; overlay de respawn da HUD da fase 1 (DV tela 3), vindo do F13 (PI 2026-10-09).
- [ ] **F16** — `ZoneController`, `KillTracker`, `VictoryRules`, morte súbita, colapso; testes I1–I3.
- [ ] **F17** — transição 5 s, `hud_phase2.tscn`, `ZoneRadar`, `ScoreBanner`, vinheta.
- [ ] **F18** — `match_end.tscn`, estatísticas acumuladas no servidor (`MatchStats`).
- [ ] **F19** — bot fase 2; `tools/soak.ps1`; CI nightly `soak`.
- [ ] **F20** — monstros/baús/boss replicados; teste com 2 clientes reais + `tc netem`.
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
