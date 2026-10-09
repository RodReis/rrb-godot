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
- [x] **F6** — `shared/` + junction + `tools/link-shared.ps1`; `shared/resources/*.gd` (`HeroData`, `SkillData`, `ItemData`, `MonsterData`, `MatchRules`, `SetBonusData`, `XpCurve`); `.tres` de GDB §8; `shared/core/{stats,hero_attributes,xp_table,set_bonus,item_rules,ids,input_actions}.gd` com GUT; fixture I5. `_alignment.tscn` ficou com F31 (escopo da issue #18). (#18)
- [ ] **F7** — `arena.tscn` conforme `docs/prd/mvp/spec/SPEC-007.md`: tiles KayKit a 3 u, raio 35 u, rio (colisão) + 2 pontes, cratera com 8 pilares/4 entradas, muros, moitas (`Area3D` `tall_grass`, só geometria), portões por time, `SpawnMarker`; testes de simetria, contagem, raycast e tempos (6,3 s / 12,7 s).
- [ ] **F31** — `follow_camera` 3ª pessoa 45° distância fixa; `InputActions` completo (teclado/mouse/gamepad, nomes de `CONVENTION.md` §6); `shared/assets/_alignment.tscn` com Knight ≈ 1,8 u; **PI avalia a câmera com a cápsula** (B-02) — resultado no comentário de encerramento.
- [ ] **F8** — `knight.tscn` (KayKit Knight + animações); ataque básico, Q (empurrão via ledger), E (escudo absorve + bloqueia projétil — hitbox de bloqueio), R (stun via ledger) lendo `knight.tres`; remove as constantes de spike de `player.gd`.
- [ ] **F9** — `monster_ai.gd`, 4 monstros não-boss com `.tres`; XP, nível, pontos de skill, catch-up (`XpTable` GUT); `SpawnDirector`.
- [ ] **F10** — `chest.tscn`, `Inventory`, `ItemRules` (auto/`F` 0,4 s), bônus de conjunto; teste I5 (servidor = Forja) com fixture.
- [ ] **F11** — Rei Esqueleto aos 3:30, drop épico, `MatchClock` com eventos de tempo.
- [ ] **F12** — `BotInput` + FSM fase 1; `--offline --bot` com servidor embutido (`ARCHITECTURE-GAME.md` §4).
- [ ] **F13** — `hud_phase1.tscn`; aviso do boss aos 3:00 (banner `PanelCard accent=PURPLE` + som + pista no portal); modal de bestiário por `B` (`CatalogList` + `DetailCard` + `MonsterPreview3D`, pausa **não** — a partida continua); componentes `PanelCard`, `StatBar`, `SlotItem`, `SkillButton`, `TimerLabel`, `HotkeyBadge`, `Toast`, `Minimap` em `shared/ui/components` + `_gallery.tscn`; Theme inicial (`TOKENS.md` §6). **Bloqueado por R-PEND-11** até o PI decidir a paleta.
- [ ] **[GATE] MVP1** — partida de 5:00 contra bot do início ao fim; PI avalia.

### MVP2 — Partida em rede (`game`)

- [ ] **F14** — `ranger.tscn`, `arrow.tscn` com pool compatível com netfox, Q/E/R.
- [ ] **F15** — `MatchController` FSM, `hero_select.tscn`, PvP fase 1, respawn, RPCs discretos; `LOBBY_WAIT` com timeout.
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
- [ ] **F24** — `launcher/`: `App`, `ScreenStack`, `Router`, `SettingsStore` + `settings.cfg` compartilhado, tela Configurações, Theme completo, galeria.
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
