# ARCHITECTURE-LAUNCHER.md — Módulo Launcher (cliente meta + backend)

**Normativo.** Vale para `launcher/`, `backend/` e para a parte de `shared/` que o Launcher consome. Decisão de origem: [ADR-0002](adr/0002-dois-modulos-launcher-e-game.md). Contrato de UI: `FRONTEND-LAUNCHER.md` + `docs/design-system/`. Domínio: `CONVENTION.md`.

## 1. Responsabilidade e fronteira

O Launcher é **tudo o que acontece fora da partida**: login, lobby, fila 1x1, lançar o jogo, resultado da partida, histórico, catálogo de heróis, arena & mapa, bestiário, forja (simulador de builds), perfil, configurações. O backend NestJS é parte deste módulo: autentica, enfileira, orquestra servidores de partida e guarda resultados.

**O Launcher não sabe como a partida funciona.** Não tem netfox, ENet, física nem cenas de arena. Conhece o Game por três coisas: o caminho do executável, os argumentos que ele aceita e o código de saída que devolve (§5).

Fora do Launcher (ver `ARCHITECTURE-GAME.md`): seleção de heróis da partida, HUDs, tela de fim de partida, loading do Game, telemetria de netfox. (A tela **Heróis** do Launcher só *mostra* o catálogo de `shared/data`; escolher o herói é do Game.)

## 2. Visão geral

```
┌──────────────────────────────┐   HTTPS/JSON + JWT   ┌──────────────────────────────┐
│ launcher/ (Godot 4.7, PC)    │ ◀──────────────────▶ │ backend/ (NestJS 11 + Postgres)│
│ app → services → screens     │                      │ auth · matchmaking · orchestrator │
│                              │                      │ matches · telemetry             │
└──────────────┬───────────────┘                      └───────────────┬──────────────┘
               │ OS.create_process(game.exe, [--connect, --token])    │ Docker API
               ▼                                                      ▼
┌──────────────────────────────┐   UDP/ENet (netfox)  ┌──────────────────────────────┐
│ game.exe (cliente)           │ ◀──────────────────▶ │ game server (Docker, headless) │
└──────────────────────────────┘                      │ valida token / reporta resultado│
                                                      └──────────────────────────────┘
```

## 3. Cliente Launcher (`launcher/`)

### 3.1 Estrutura

```
launcher/
  project.godot              Forward+ (diorama 3D no lobby); main scene = scenes/app.tscn
  shared/ -> ../shared       junction (ADR-0003)
  addons/gut/                NUNCA editar
  scenes/
    app.tscn                 raiz: barra superior + ScreenStack + rodapé + overlays (toast, modal, loading, partida em andamento, card de resultado, splash)
    screens/                 login.tscn, lobby.tscn, heroes.tscn, arena_map.tscn, bestiary.tscn, forge.tscn, history.tscn, profile.tscn, settings.tscn
    diorama/                 lobby_diorama.tscn (SubViewport, arena hex, herói idle, tochas)
  scripts/
    app/                     app.gd (bootstrap e dono dos serviços), router.gd (rota → cena e menu NAV), screen_stack.gd,
                             app_bar.gd, profile_chip.gd, match_overlay.gd, launcher_screen.gd (base das telas)
    services/                api_client.gd, auth_service.gd, queue_service.gd, game_process.gd, settings_store.gd,
                             history_service.gd, profile_service.gd, avatar_store.gd, avatar_image.gd,
                             nickname_rules.gd, catalog_service.gd
    screens/                 um controller por tela (login_screen.gd, lobby_screen.gd, history_screen.gd, profile_screen.gd,
                             settings_screen.gd + credits_view.gd, match_result_card.gd, match_card.gd, filter_chip.gd, …);
                             pastas por tela grande: heroes/, compendium/ (bestiário + forja), arena/
    diorama/                 lobby_diorama.gd (e ferramenta de arte do login)
    models/                  DTOs tipados espelhando o OpenAPI do backend (AuthTokens, UserProfile, QueueTicket, MatchAssignment,
                             MatchHistory/MatchSummary/…) e os da Forja/Bestiário (ForgeBuild, MonsterSpecies)
  test/unit/                 GUT: services com ApiClient falso, router, settings_store, models, fluxo do App, smoke das cenas
```

### 3.2 Camadas e regra de dependência

`screens` → `services` → `models`/`shared`. `app` orquestra `screens`. **Tela nunca chama `HTTPRequest` diretamente** — só `services`. **Service nunca toca em nó de tela** — devolve sinal ou valor. Isso é o que permite testar serviços sem cena e trocar telas sem tocar na rede.

| Camada | Responsabilidade | Testável sem cena? |
|---|---|---|
| `app/` | ciclo de vida, pilha de telas (push/pop/replace), overlays globais, leitura de `settings.cfg` no boot | router sim; stack com cena mínima |
| `services/` | HTTP (JSON), token JWT em memória + refresh, polling da fila, lançar/esperar processo, persistir configurações, catálogo de `shared/data` | sim (ApiClient injetado como dublê) |
| `screens/` | binding sinal→nó, formatação, navegação | só com cena (smoke) |
| `models/` | DTOs tipados (`class_name`, `@export`), parsing `from_dict` com validação de tipo | sim |

### 3.3 Serviços (contratos)

- `ApiClient`: `request(method, path, body) -> Response{status, json}`; injeta `Authorization: Bearer` e `X-Client-Version` (versão do pacote, F83); timeout 10 s; 401 numa chamada autenticada tenta `POST /auth/refresh` uma vez e repete; recusado → limpa a sessão e emite `unauthorized` (volta ao login). **Um `HTTPRequest` por chamada** (sem pool — F25). URL por `--api=` (padrão `http://127.0.0.1:3000`) ou embutida no pacote (`build_config.cfg`, F28). `GET /health` sem conta alimenta o chip de status da barra (10 s).
- `AuthService`: `login(email, senha)`, `register(email, senha)` (validação local antes de chamar o backend), `logout()`, `is_logged_in()`; os tokens ficam no `ApiClient` (`AuthTokens`). JWT **em memória** e, opcionalmente, refresh token em `user://session.dat` cifrado com `OS.get_unique_id()` — só se o PI aprovar "lembrar-me" (R-PEND-03 em `RASTREABILIDADE.md`); por padrão, sem persistência.
- `QueueService`: `join() -> QueueTicket`, `leave()`, polling `GET /queue/:ticket` a cada 2 s (sem WebSocket na fatia: backend fino, PRD D10) → sinais `searching(elapsed)`, `matched(MatchAssignment{host, port, token})`, `cancelled`, `failed(reason)`.
- `UpdateService` (F83, ADR-0023): ao abrir, lê o `latest.json` (`[build] update_url` do `build_config.cfg`) por `ApiClient.fetch_json`; versão mais nova (`UpdateRules`, regra pura) barra a fila no Lobby e o App oferece "Atualizar": `ApiClient.download` para `user://update/`, confere o SHA-256 e roda o instalador com `/S /UPDATE` (o App fecha; o instalador reabre o Launcher). Build de dev (versão fora de `vX.Y.Z`) nunca atualiza. `BuildInfo` lê `[build] version` (rodapé) e `update_url`.
- `GameProcess`: `launch(args: PackedStringArray) -> pid`, `is_running()`, sinal `exited(code)` (polling `OS.is_process_running` a 0,5 s). Caminho do executável: `OS.get_executable_path().get_base_dir() + "/game/game.exe"` (layout de instalação, §5.1); sobrescrevível por `--game-path=` para dev.
- `SettingsStore`: lê/escreve `user://settings.cfg` (seções `video`, `audio`, `controls`, `graphics`, `camera`, `training`; contrato em `shared/core/user_settings.gd`); aplica vídeo/áudio no próprio Launcher. Contrato do arquivo em §5.3.
- `HistoryService`: `GET /matches?mine=1` (obrigatório; JWT) → `MatchHistory{totals{wins,losses}, matches[≤50]}` — resultado `win`/`loss`/`interrupted`, `playedAt`, `endReason`, `durationS`, meu lado completo e do oponente **só herói, kills, nível e `#nickname`** (F26/F35); cache em memória por sessão, `clear()` no logout/401/fim de partida online. **F70 (ADR-0015):** `fetch(force)` com espera da partida nova (3 × 1 s) para o card de resultado no lobby.
- `ProfileService` (F35): `GET /users/me` (`nickname` nulo = falta definir → tela Perfil `SETUP`), `PUT /users/me/nickname` (define uma vez; `INVALID_NICKNAME`/`NICKNAME_TAKEN`/`NICKNAME_ALREADY_SET`). Avatar é só local (`AvatarStore`, `user://avatars/`); nada vai ao backend.
- `CatalogService`: carrega `res://shared/data/**` (varre `shared/data/heroes/`: herói novo entra sozinho, sem lista no código) e expõe heróis, itens, monstros, regras — fonte da Tela Heróis, do bestiário, da forja e das barras de atributo; heróis padrão de `MatchRules.default_heroes` primeiro. Usa `shared/core` para o simulador (mesma fórmula do servidor, por construção).

### 3.4 Telas e navegação

| Tela | Rota | Entra por | Sai para |
|---|---|---|---|
| Login | `login` | boot sem sessão; 401 | `lobby` |
| Lobby | `lobby` | login (com nickname); volta de qualquer tela; fim do processo do Game (com card de resultado se online — F70) | fila (overlay no próprio lobby), `heroes`, `bestiary`, `forge`, `arena_map`, `history`, `settings`, `profile`, sair |
| Bestiário | `bestiary` | lobby | lobby |
| Forja | `forge` | lobby | lobby |
| Histórico | `history` | lobby; ~~automático após `GameProcess.exited(0)`~~ → **F70 (ADR-0015):** o fim de partida online volta ao **lobby** com o card "Resultado da partida"; o Histórico abre pelo card ("Ver histórico") ou pela barra | lobby |
| Heróis | `heroes` | lobby (item HERÓIS) — **F71 (ADR-0015)**, fiel a `docs/prd/telas/Tela Herois/`; dados de `CatalogService` | lobby |
| Perfil | `profile` | 1º login sem nickname (`SETUP`, sem voltar); chip do cabeçalho (`EDIT`, só avatar) — F35 | lobby |
| Configurações | `settings` | lobby (item AJUSTES) | lobby — abas Controles & Câmera (inclui o zoom, F67), Gráficos & Performance (vídeo e os 4 toggles de `[graphics]`), Áudio e **Créditos** (licenças de `shared/assets/LICENSES.md`, CC-BY obrigatório; decisão do PI 2026-10-10; `credits_view.gd`) |
| Arena & Mapa | `arena_map` | lobby | lobby ("Praticar vs Bot" = mesma ação do lobby) — DV tela 10; mapa é imagem estática (`shared/assets/ui/arena_map.png`), nunca cena de arena |

Menu da barra superior (`Router.NAV`, na ordem): LOBBY · HERÓIS · ARENA & MAPA · GUIA & BESTIÁRIO · HISTÓRICO · AJUSTES; a Forja é aba do Guia & Bestiário (e o destaca no menu) e o Perfil abre pelo chip do cabeçalho. A rota `gallery` (galeria do design system) só abre com `--gallery` e fica fora do menu. **Splash (F68):** `BootSplash` (marca "Loot Start", F82) cobre a janela até a 1ª checagem do backend (teto de 2 s). Pilha simples: lobby é a raiz; as demais são `push`; `Esc` = `pop`. Fila é um estado do lobby (card direito), não tela. Enquanto o Game roda, o Launcher mostra overlay (`MatchOverlay`: "Partida em andamento" ou "Treino em andamento") com botão "Encerrar jogo" (mata o processo) e bloqueia navegação.

### 3.5 Lobby: diorama 3D

`SubViewport` com arena hexagonal reduzida, herói idle e tochas, de `shared/assets`. Limitar a 30 fps e desligar quando a janela perde foco (`NOTIFICATION_APPLICATION_FOCUS_OUT`). É o único 3D do Launcher; se pesar, vira imagem (decisão do PI, `DEBITO.md`).

## 4. Backend (`backend/`)

### 4.1 Stack e estrutura

NestJS 11 + TypeScript estrito, Postgres 16, ORM **Drizzle** (schema em código, migrações versionadas), validação com `zod` (DTOs), `@nestjs/jwt`, Dockerode para o orquestrador, Pino para log. pnpm. Jest para testes.

```
backend/
  src/
    main.ts, app.module.ts
    auth/          POST /auth/register, /auth/login, /auth/refresh; JWT (access 15 min, refresh 7 d)
    users/         entidade usuário (e-mail, hash argon2id, criado_em)
    matchmaking/   POST /queue, DELETE /queue/:ticket, GET /queue/:ticket — fila FIFO 1x1 em memória + Postgres como fallback
    orchestrator/  pool de N containers pré-aquecidos; aloca ip:porta; gera token de partida; heartbeat
    matches/       POST /internal/matches/:id/validate (servidor), POST /internal/matches/:id/result (servidor), GET /matches (jogador)
    telemetry/     ping médio, duração, líder de nível F1 × vencedor (MVP4)
    common/        guards (JwtGuard, InternalGuard por segredo compartilhado), filtros, zod pipe
  drizzle/         schema.ts, migrations/
  test/            unit (services com repositórios falsos) + e2e (supertest, Postgres em container)
  openapi.json     gerado no build; o Launcher gera `models/` a partir dele (script em tools/)
```

### 4.2 Fluxo de partida

1. Launcher `POST /queue` → `QueueTicket` (`426 CLIENT_OUTDATED` se `X-Client-Version` < `MIN_CLIENT_VERSION`, F83).
2. Matchmaker pareia os dois primeiros tickets → pede ao orquestrador um servidor do pool.
3. Orquestrador: escolhe container ocioso (ou sobe um se o pool estiver vazio), gera `match_token` (JWT interno com `match_id`, `player_ids`, `exp` 2 min), grava `matches` (`status=assigned`), devolve `host:porta`.
4. `GET /queue/:ticket` passa a responder `matched` com `MatchAssignment` **e `matchId`** (o `abandon` precisa dele — F25).
5. Launcher lança `game.exe -- --connect=host:porta --token=<match_token>` (argumentos do Game **depois de `--`** — F25). **Um token por jogador** (F23, decisão do PI 2026-10-15): o backend assina um JWT por conta (`sub` = conta, mesmo `match_id`), `token_hash` em `match_players`.
6. Game server recebe os dois peers, `POST /internal/matches/:id/validate` com o token → `status=running`.
7. Fim: `POST /internal/matches/:id/result` com `MatchResult` → `status=finished`, estatísticas gravadas. Container volta ao pool (ou é recriado — decidir no M3 pelo custo).
8. Launcher detecta `exited(0)` → `GET /matches?mine=1` (espera a partida nova, 3 × 1 s) → **lobby com card "Resultado da partida"** (F70, ADR-0015; antes: histórico).

Heartbeat: game server `POST /internal/matches/:id/heartbeat` a cada 10 s; 3 faltas → `status=aborted`, container reciclado.

### 4.3 Dados (Postgres)

`users(id, email unique, password_hash, nickname unique case-insensitive nullable até o 1º login (F35), created_at)` · `matches(id, status, server_host, server_port, token_hash, created_at, started_at, ended_at, winner_user_id, end_reason, duration_s, seed)` · `match_players(match_id, user_id, hero_id, kills, deaths, final_level, damage_dealt, damage_taken, monsters_killed, chests_opened, boss_kill bool, set_active, level_at_phase1_end, avg_ping_ms)` · `queue_tickets(id, user_id, created_at, status, match_id)`.

Inventário, moedas, gemas, skins: **não existem** na fatia (PRD §7). Quando existirem, ficam aqui, nunca no cliente.

### 4.4 Segurança mínima da fatia

Senha com argon2id; JWT assinado (HS256, segredo por ambiente); endpoints `/internal/*` protegidos por segredo compartilhado com o game server (variável de ambiente, nunca no cliente); rate limit em `/auth/*` e `/queue`; CORS fechado (cliente não é browser). Cada game server é preso à sua partida: o orquestrador dá a ele `SLOT_PORT` (a porta pública do slot) e o servidor a manda no cabeçalho `x-slot-port` em `validate`, `heartbeat` e `result`; o backend recusa (401 `TOKEN_INVALID` no `validate`, `SLOT_MISMATCH` nos outros) se não for o `server_port` da partida — quem varre as portas UDP não sequestra o container de outra partida com o token da sua (#181). Segredo por container (HMAC do `INTERNAL_SECRET` com a porta) fica para quando um container comprometido entrar no modelo de ameaça. TLS termina no proxy do Coolify. Nada além disso na fatia — anti-cheat é fora de escopo (PRD §8.5).

## 5. Contrato Launcher ↔ Game

Este é o **único** lugar onde os dois módulos se tocam. Mudar aqui exige ADR.

### 5.1 Layout de instalação

```
<instalação>/                         (instalador do F83: %LOCALAPPDATA%\Programs\Loot Start, ADR-0023)
  LootStart.exe + LootStart.pck     (nome do F82, ADR-0022)
  game/game.exe + game.pck
  Desinstalar.exe
```

### 5.2 Argumentos e códigos de saída

| Launcher chama | Significado |
|---|---|
| `game.exe -- --connect=<host>:<porta> --token=<match_token>` | partida online (argumentos do Game depois de `--`; F25) |
| `game.exe -- --offline --tutorial` | tutorial roteirizado com o Cavaleiro; não combina com `--bot` (F85, ADR-0029) |
| `game.exe -- --offline --bot [--bot-difficulty=<n>]` | treino contra bot; `<n>` de 1 a N níveis do Resource (hoje 1 Fácil, 2 Médio, 3 Difícil); ausente ou fora da faixa = `2` (F81, ADR-0021, formato do ADR-0027) |
| `--game-path=` (no launcher) | dev: outro caminho do executável (com `--game-project=<pasta>`, o Launcher chama `<exe> --path <pasta> -- …`, para rodar o Godot em vez do `game.exe`) |

Só esses argumentos (`--connect`, `--token`, `--offline`, `--bot`, `--bot-difficulty`, `--tutorial`) fazem parte do contrato; os demais de `game/scripts/core/launch_args.gd` (`--server`, `--port`, `--autopilot`, `--bots`, `--bot-hero`, `--daynight`, `--no-backend`, `--probe`…) são de dev/servidor e o Launcher nunca os envia.

Códigos de saída do Game (definidos em `ARCHITECTURE-GAME.md` §6): `0` normal → Launcher volta ao lobby com o card de resultado se a partida era online (F70; treino: lobby sem card; o Game fecha sozinho 15 s depois do fim da partida ou pelo botão "Voltar ao lobby"); `1` argumentos; `2` autenticação → Launcher mostra erro, oferece nova fila e volta ao lobby; `3` resultado não reportado → Launcher avisa "resultado pode demorar a aparecer" (sem card; o histórico é recarregado); `4` interno → erro genérico. Processo morto pelo usuário → Launcher trata como `4`, com aviso neutro "Jogo encerrado."

### 5.3 `user://settings.cfg` (compartilhado)

Ambos os projetos: `application/config/use_custom_user_dir=true`, `custom_user_dir_name="rrb-moba"`.

```ini
[video]   window_mode="windowed"|"borderless"|"exclusive"  width=int  height=int  vsync=bool  fps_cap=int   ; padrão borderless (ADR-0019); fullscreen=bool só é lido (legado) se window_mode faltar: true→borderless, false→windowed; width/height só valem em windowed
[audio]   master=float  music=float  sfx=float  voice=float   ; 0.0–1.0
[controls] move_forward="W" ... skill_q="Q" ... interact="F"   ; nomes de ação do InputMap = os de shared/core/input_actions.gd
          mouse_sensitivity=float  gamepad=bool
[graphics] fog=bool  ssil=bool  ssao=bool  grass=bool   ; padrão true; Game só desliga o que a arena traz ligado (F38, ADR-0006 item 8; grass = grama decorativa, F42)
[training] bot_difficulty=int   ; último nível do bot do treino (1..N de shared/data/rules/bot_levels.tres); o Launcher manda `--bot-difficulty`, o Game não lê a chave (F81, ADR-0021/0027); inválido → 2
[camera]  distance=float   ; 9.0–14.0 u, padrão 11.0; fora da faixa → padrão (F67, ADR-0015 item 5)
[meta]    schema=1
```

Launcher escreve; Game lê no boot. **Exceção (F67):** o Game grava só `[camera] distance` quando o jogador dá zoom (relê o arquivo antes, para não desfazer o que o Launcher salvou). Teclas `camera_zoom_in`/`camera_zoom_out` (padrão `=`/`-`, além da roda do mouse) entram em `[controls]` como as demais. Chave desconhecida é ignorada; `schema` diferente → Game usa padrões e loga.

### 5.4 `user://offline_result.cfg` (Game grava, Launcher lê e apaga — ADR-0029)

Ao terminar um treino ou o tutorial, o Game grava na pasta de dados comum (`rrb-moba`) a seção `[result]`: `kind` = `tutorial` | `bot`; `outcome` = `completed` | `win` | `loss` | `quit`; `bot_difficulty` (só `kind=bot`); `finished_at` (ISO 8601). O Launcher lê ao fim do processo do Game, apaga, e com sessão envia `tutorial/completed` ou `bot/win` ao backend para liberar a fila (F85, ADR-0026). Aditivo: códigos de saída não mudam.

### 5.5 O que **não** faz parte do contrato

Resultado da partida (vai pelo backend), configuração de rede do netfox (é do Game), escolha de herói (é do Game), qualquer arquivo além de `settings.cfg`.

## 6. Resiliência e falhas

| Situação | Comportamento |
|---|---|
| Backend fora | Login/fila mostram erro com retry; "Praticar vs Bot" continua funcionando (não depende de backend). |
| Fila > 3 min sem par | Mantém procurando; mostra tempo; usuário cancela. Sem bot automático na fila (PRD: bot só em treino). |
| `matched` mas Game não abre (executável ausente) | Erro "instalação incompleta"; backend recebe `DELETE /queue/:ticket`-equivalente `POST /matches/:id/abandon` → container liberado. |
| Game encerra com código ≠ 0 | Tabela §5.2. |
| Token expira antes do jogo conectar (2 min) | Servidor recusa (código 2); Launcher oferece nova fila. |
| Pool vazio | Orquestrador sobe container sob demanda (até limite); fila espera. |
| Servidor cai no meio | Heartbeat falha → `aborted`; histórico mostra "partida interrompida"; sem rejogo. |

## 7. Testes

| Alvo | Ferramenta | Quando |
|---|---|---|
| `services/`, `models/`, `router` | GUT com `ApiClient` falso | toda PR (`gate-launcher`) |
| Telas | smoke: instanciar cada `.tscn`, sem erro de nó; cada tela com seu teste (estados, filtros, teclado); `test_app_flow` cobre o fluxo do `App` (login → lobby → fila → Game → card de resultado) | toda PR |
| Backend unit | Jest, repositórios falsos | toda PR (`gate-backend`) |
| Backend e2e | supertest + Postgres em container; orquestrador com Docker mock | toda PR |
| Fluxo completo | 2 launchers + backend + pool local (`infra/docker-compose.yml`) | gate do MVP3, manual |

## 8. O que este documento não decide

- Steam, ranked, amigos, economia, skins (roadmap, PRD §1.3).
- "Lembrar-me"/persistência de sessão (R-PEND-03).
- Nível/XP de conta do design visual (R-PEND-02: não). Perfil decidido em 2026-10-10: nickname no backend, avatar só local (F35, `CONVENTION.md` §4.8).
- WebSocket em vez de polling (reavaliar se o polling pesar; registrado em `DEBITO.md`).
