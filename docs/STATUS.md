# STATUS.md — Kanban, roadmap e Índice Fatia ↔ SPEC

Prosa curta. Detalhe histórico vai para `STATUS-ARQUIVO.md`. O **Índice Fatia ↔ SPEC** (§3) é a fonte única da numeração: alocado pelo Cowork, número nunca reaproveitado. Progresso por item é do Code (`DEVELOPMENT.md`); aqui só o estado agregado.

## 1. Agora

| Campo | Valor |
|---|---|
| Marco / MVP ativo | **MVP1 — Arena single-player** (`docs/prd/mvp/MVP-1.md`); MVP0 fechado em 2026-10-09 (ADR-0001: segue Godot) |
| Módulo em foco | `game/` |
| Próximo gate | [GATE] MVP1 — fase 1 completa contra bot, offline |
| Documentação de governança | criada em 2026-10-08 (ADR-0002/0003/0004, arquitetura dos dois módulos) |
| Board | issue-pai [MVP1] #16; `todo`: [FIX] #41; `backlog`: F9–F13, [GATE] #27; `finalizado`: [INFRA] #17 e #34, F6 #18, F7 #19, F31 #20, F8 #21, F34 #38. MVP0 #1–#7 `finalizado` |
| Bloqueios do PI | `RASTREABILIDADE.md` §5 — resolvidos em 2026-10-09: R-PEND-01, 05, 08, 09. R-PEND-11 decidida em 2026-10-09 (paleta e fontes de `docs/prd/telas/`). Abertos: 02, 03, 04, 06, 07, 10 (04 e 06 antes do MVP2) |

## 2. Roadmap (MVP-n = marco M-n do PRD §9.1)

| MVP | Entrega | Módulos | Critério de pronto | Estado |
|---|---|---|---|---|
| **MVP0** | Spike de netcode: 2 clientes + servidor headless em Docker, cápsula com predição, 1 ataque validado | game, infra | jogável a 100 ms sem "borracha" perceptível | **gate aprovado** — segue Godot (ADR-0001) |
| MVP1 | Arena single-player: mapa 3 zonas, Cavaleiro, monstros, XP/níveis, baús/itens, boss, bot, HUD F1 | game, shared | fase 1 completa contra bot, offline | **gate aprovado** (2026-10-10) |
| MVP2 | Partida em rede: Arqueira, pick, fase 2 (zona, kills, fim garantido), HUD F2, fim de partida | game | 1x1 online termina sempre; soak 50 partidas bot×bot | planejado |
| MVP3 | Meta + deploy: backend, launcher, pool no VPS, build PC | launcher, backend, infra | dois amigos jogam pela internet sem o dev | planejado |
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
| F9 / SPEC-009 | MVP1 | game | Slice 1.5 — Monstros tier 1–3 com IA, XP, níveis, pontos de skill, catch-up | backlog (#22) |
| F10 / SPEC-010 | MVP1 | game | Slice 1.6 — Baús, itens, inventário 4 slots, substituição, bônus de conjunto | backlog (#23) |
| F11 / SPEC-011 | MVP1 | game | Slice 1.7 — Rei Esqueleto aos 3:30, drop épico | backlog (#24) |
| F12 / SPEC-012 | MVP1 | game | Slice 1.8 — Bot FSM fase 1 (`BotInput`), modo offline com servidor embutido | backlog (#25) |
| F13 / SPEC-013 | MVP1 | game, shared | Slice 1.9 — HUD fase 1 + relógio + aviso do boss aos 3:00 + bestiário em partida (`B`) + componentes base do design system | backlog (#26) |
| F34 / SPEC-034 | MVP1 | game, shared | Slice 1.10 — Pilares da cratera e mato alto com assets do Blender (só visual; colisão do F7 intacta) — depois do [INFRA] #34 | finalizado (#38) |
| [GATE] | MVP1 | — | Homologação: fase 1 completa contra bot, offline (PRD M1) | backlog (#27) |
| [INFRA] | MVP1 | ci | CI: `lint-gd` (tipagem, literais em `core/`, I9), path filter por módulo, `shared/test` no `test-game` — antes de F6 | finalizado (#17) |
| [INFRA] | — | infra | Pipeline Blender (ADR-0005): `art/`, `.gitattributes`/`.gitignore`, import de `.blend` desligado — antes do primeiro asset via Blender | finalizado (#34) |
| F14 / SPEC-014 | MVP2 | game | Slice 2.1 — Arqueira: projétil validado no servidor, Q perfurante, E rolamento, R chuva | — |
| F15 / SPEC-015 | MVP2 | game | Slice 2.2 — Ciclo de partida: `MatchController` (FSM), seleção de heróis, PvP fase 1, respawn, eventos por RPC | — |
| F16 / SPEC-016 | MVP2 | game | Slice 2.3 — Fase 2: zona, dano, respawn, kills, morte súbita, regras de vitória | — |
| F17 / SPEC-017 | MVP2 | game | Slice 2.4 — Transição 5:00 + HUD fase 2 + vinheta de zona | — |
| F18 / SPEC-018 | MVP2 | game | Slice 2.5 — Tela de fim de partida com estatísticas | — |
| F19 / SPEC-019 | MVP2 | game | Slice 2.6 — Bot fase 2 + soak 50 partidas headless (`tools/soak.ps1`) | — |
| F20 / SPEC-020 | MVP2 | game | Slice 2.7 — Monstros, baús e boss replicados (2 clientes reais) | — |
| [GATE] | MVP2 | — | Homologação: 1x1 online termina sempre; soak verde | — |
| F21 / SPEC-021 | MVP3 | backend | Slice 3.1 — NestJS: auth e-mail/senha, JWT, usuários, migrações | — |
| F22 / SPEC-022 | MVP3 | backend | Slice 3.2 — Fila 1x1 FIFO + orquestrador (pool Docker, token de partida, heartbeat) | — |
| F23 / SPEC-023 | MVP3 | game | Slice 3.3 — Game server: `--token`, validar no backend, reportar resultado, códigos de saída | — |
| F24 / SPEC-024 | MVP3 | launcher, shared | Slice 3.4 — Shell do launcher: `App`, pilha de telas, Theme completo, galeria de componentes, configurações (vídeo/áudio/controles) e `settings.cfg` | — |
| F25 / SPEC-025 | MVP3 | launcher | Slice 3.5 — Login, lobby com diorama, fila (polling), lançar/esperar o Game, treino vs bot | — |
| F26 / SPEC-026 | MVP3 | launcher, backend | Slice 3.6 — Histórico de partidas (`GET /matches`) | — |
| F27 / SPEC-027 | MVP3 | launcher | Slice 3.7 — Bestiário e Forja (simulador com `shared/core`) | — |
| F33 / SPEC-033 | MVP3 | launcher, shared | Slice 3.9 — Tela Arena & Mapa (DV tela 10): render da arena real, marcadores (POIs), regras das 2 fases pelos números do GDB | — |
| F35 / SPEC-035 | MVP3 | launcher | Slice 3.10 — Perfil de conta: nickname único com prefixo `#` automático; avatar (predefinido ou upload), guardado só local no Launcher; sem XP de conta, sem data de nascimento (R-PEND-02) | — |
| F28 / SPEC-028 | MVP3 | infra | Slice 3.8 — Deploy no VPS (Coolify, compose, UDP 7000–7020), export presets, pacote de instalação (`launcher/` + `game/`) | — |
| [GATE] | MVP3 | — | Dois amigos jogam pela internet sem intervenção do dev | — |
| F29 / SPEC-029 | MVP4 | backend, launcher, game | Slice 4.1 — Telemetria: ping médio, duração, líder de nível F1 × vencedor; painel de KPIs no histórico | — |
| F30 / SPEC-030 | MVP4 | shared | Slice 4.2 — Ajustes de balanceamento pós-playtest (só `.tres`) | — |
| F32 / SPEC-032 | MVP2 | game | Slice 2.8 — Mato alto: herói dentro da moita não é replicado para o adversário (visibilidade no servidor); regra e números em `CONVENTION.md` §4.8 | — |
| [GATE] | MVP4 | — | Playtest 10+ pessoas; critérios PRD §9.2; decisão câmera/duração/3x3 | — |

Próximo número livre: **F36 / SPEC-036**.

## 4. Regras deste índice

- Só o Cowork aloca número. Partir uma fatia = número novo (nunca sufixo). Ex.: F8 partido em 2026-10-09 → F31 (câmera/controles) saiu dele e **entra antes** dele na ordem. Fatia cancelada mantém a linha com estado `cancelada` e motivo em `STATUS-ARQUIVO.md`.
- A issue-pai de cada MVP tem título `[MVPn] <título>`; cada F é sub-issue nativa dela (`GITHUB.md` §9).
- Os próximos 5 cards da ordem ficam em `proplan:todo`.
- `shared` como módulo: a fatia muda `shared/` e, por isso, dispara CI de `game` e `launcher`.
