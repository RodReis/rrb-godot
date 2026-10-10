# ARCHITECTURE-LAUNCHER.md — Módulo Launcher (cliente meta + backend)

**Normativo.** Vale para `launcher/`, `backend/` e para a parte de `shared/` que o Launcher consome. Decisão de origem: [ADR-0002](adr/0002-dois-modulos-launcher-e-game.md). Contrato de UI: `FRONTEND-LAUNCHER.md` + `docs/design-system/`. Domínio: `CONVENTION.md`.

## 1. Responsabilidade e fronteira

O Launcher é **tudo o que acontece fora da partida**: login, lobby, fila 1x1, lançar o jogo, histórico, bestiário, forja (simulador de builds), configurações. O backend NestJS é parte deste módulo: autentica, enfileira, orquestra servidores de partida e guarda resultados.

**O Launcher não sabe como a partida funciona.** Não tem netfox, ENet, física nem cenas de arena. Conhece o Game por três coisas: o caminho do executável, os argumentos que ele aceita e o código de saída que devolve (§5).

Fora do Launcher (ver `ARCHITECTURE-GAME.md`): seleção de heróis, HUDs, fim de partida, telemetria de netfox.

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
    app.tscn                 raiz: ScreenStack + overlays (toast, modal, loading)
    screens/                 login.tscn, lobby.tscn, bestiary.tscn, forge.tscn, history.tscn, settings.tscn, arena_map.tscn
    components/              instâncias dos componentes do design system (shared/ui/components)
    diorama/                 lobby_diorama.tscn (SubViewport, arena hex, herói idle, tochas)
  scripts/
    app/                     app.gd (bootstrap), screen_stack.gd, router.gd (nomes de tela → cena)
    services/                api_client.gd, auth_service.gd, queue_service.gd, game_process.gd,
                             settings_store.gd, history_service.gd, catalog_service.gd
    screens/                 um controller por tela (login_screen.gd, lobby_screen.gd, …)
    models/                  DTOs tipados espelhando o OpenAPI do backend (Session, QueueTicket, MatchSummary)
  test/unit/                 GUT: services com ApiClient falso, router, settings_store, models
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

- `ApiClient`: `request(method, path, body) -> Response{status, json}`; injeta `Authorization: Bearer`; timeout 10 s; 401 → emite `unauthorized` (volta ao login). Um único `HTTPRequest` por chamada, pool de 4.
- `AuthService`: `login(email, senha)`, `logout()`, `session: Session`. JWT **em memória** e, opcionalmente, refresh token em `user://session.dat` cifrado com `OS.get_unique_id()` — só se o PI aprovar "lembrar-me" (R-PEND-03 em `RASTREABILIDADE.md`); por padrão, sem persistência.
- `QueueService`: `join() -> QueueTicket`, `leave()`, polling `GET /queue/:ticket` a cada 2 s (sem WebSocket na fatia: backend fino, PRD D10) → sinais `searching(elapsed)`, `matched(MatchAssignment{host, port, token})`, `cancelled`, `failed(reason)`.
- `GameProcess`: `launch(args: PackedStringArray) -> pid`, `is_running()`, sinal `exited(code)` (polling `OS.is_process_running` a 0,5 s). Caminho do executável: `OS.get_executable_path().get_base_dir() + "/game/game.exe"` (layout de instalação, §5.1); sobrescrevível por `--game-path=` para dev.
- `SettingsStore`: lê/escreve `user://settings.cfg` (seções `video`, `audio`, `controls`); aplica vídeo/áudio no próprio Launcher. Contrato do arquivo em §5.3.
- `HistoryService`: `GET /matches?mine=1` → `Array[MatchSummary]`; cache em memória por sessão.
- `CatalogService`: carrega `res://shared/data/**` e expõe heróis, itens, monstros, regras — fonte do bestiário, da forja e das barras de atributo. Usa `shared/core` para o simulador (mesma fórmula do servidor, por construção).

### 3.4 Telas (5) e navegação

| Tela | Rota | Entra por | Sai para |
|---|---|---|---|
| Login | `login` | boot sem sessão; 401 | `lobby` |
| Lobby | `lobby` | login; volta de qualquer tela; fim do processo do Game | fila (overlay no próprio lobby), `bestiary`, `forge`, `arena_map`, `history`, `settings`, sair |
| Bestiário | `bestiary` | lobby | lobby |
| Forja | `forge` | lobby | lobby |
| Histórico | `history` | lobby; automático após `GameProcess.exited(0)` | lobby |
| Configurações | `settings` | lobby | lobby — inclui a aba **Créditos** (licenças de `shared/assets/LICENSES.md`, CC-BY obrigatório; decisão do PI 2026-10-10) |
| Arena & Mapa | `arena_map` | lobby | lobby ("Praticar vs Bot" = mesma ação do lobby) — DV tela 10; mapa é imagem estática (`shared/assets/ui/arena_map.png`), nunca cena de arena |

Pilha simples: lobby é a raiz; as demais são `push`; `Esc` = `pop`. Fila é um estado do lobby (card direito), não tela. Enquanto o Game roda, o Launcher mostra overlay "Partida em andamento" com botão "Encerrar jogo" (mata o processo) e bloqueia navegação.

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

1. Launcher `POST /queue` → `QueueTicket`.
2. Matchmaker pareia os dois primeiros tickets → pede ao orquestrador um servidor do pool.
3. Orquestrador: escolhe container ocioso (ou sobe um se o pool estiver vazio), gera `match_token` (JWT interno com `match_id`, `player_ids`, `exp` 2 min), grava `matches` (`status=assigned`), devolve `host:porta`.
4. `GET /queue/:ticket` passa a responder `matched` com `MatchAssignment`.
5. Launcher lança `game.exe --connect=host:porta --token=<match_token>`.
6. Game server recebe os dois peers, `POST /internal/matches/:id/validate` com o token → `status=running`.
7. Fim: `POST /internal/matches/:id/result` com `MatchResult` → `status=finished`, estatísticas gravadas. Container volta ao pool (ou é recriado — decidir no M3 pelo custo).
8. Launcher detecta `exited(0)` → `GET /matches?mine=1` → histórico.

Heartbeat: game server `POST /internal/matches/:id/heartbeat` a cada 10 s; 3 faltas → `status=aborted`, container reciclado.

### 4.3 Dados (Postgres)

`users(id, email unique, password_hash, nickname unique case-insensitive nullable até o 1º login (F35), created_at)` · `matches(id, status, server_host, server_port, token_hash, created_at, started_at, ended_at, winner_user_id, end_reason, duration_s, seed)` · `match_players(match_id, user_id, hero_id, kills, deaths, final_level, damage_dealt, damage_taken, monsters_killed, chests_opened, boss_kill bool, set_active, level_at_phase1_end, avg_ping_ms)` · `queue_tickets(id, user_id, created_at, status, match_id)`.

Inventário, moedas, gemas, skins: **não existem** na fatia (PRD §7). Quando existirem, ficam aqui, nunca no cliente.

### 4.4 Segurança mínima da fatia

Senha com argon2id; JWT assinado (HS256, segredo por ambiente); endpoints `/internal/*` protegidos por segredo compartilhado com o game server (variável de ambiente, nunca no cliente); rate limit em `/auth/*` e `/queue`; CORS fechado (cliente não é browser). TLS termina no proxy do Coolify. Nada além disso na fatia — anti-cheat é fora de escopo (PRD §8.5).

## 5. Contrato Launcher ↔ Game

Este é o **único** lugar onde os dois módulos se tocam. Mudar aqui exige ADR.

### 5.1 Layout de instalação

```
<instalação>/
  launcher.exe + launcher.pck
  game/game.exe + game.pck
```

### 5.2 Argumentos e códigos de saída

| Launcher chama | Significado |
|---|---|
| `game.exe --connect=<host>:<porta> --token=<match_token>` | partida online |
| `game.exe --offline --bot` | treino contra bot |
| `--game-path=` (no launcher) | dev: outro caminho do executável |

Códigos de saída do Game (definidos em `ARCHITECTURE-GAME.md` §6): `0` normal → Launcher vai ao histórico; `1` argumentos; `2` autenticação → Launcher mostra erro e volta ao lobby; `3` resultado não reportado → Launcher avisa "resultado pode demorar a aparecer"; `4` interno → erro genérico. Processo morto pelo usuário → Launcher trata como `4`.

### 5.3 `user://settings.cfg` (compartilhado)

Ambos os projetos: `application/config/use_custom_user_dir=true`, `custom_user_dir_name="rrb-moba"`.

```ini
[video]   fullscreen=bool  width=int  height=int  vsync=bool  fps_cap=int
[audio]   master=float  music=float  sfx=float  voice=float   ; 0.0–1.0
[controls] move_forward="W" ... skill_q="Q" ... interact="F"   ; nomes de ação do InputMap = os de shared/core/input_actions.gd
          mouse_sensitivity=float  gamepad=bool
[meta]    schema=1
```

Launcher escreve; Game lê no boot. Chave desconhecida é ignorada; `schema` diferente → Game usa padrões e loga.

### 5.4 O que **não** faz parte do contrato

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
| Telas | smoke: instanciar cada `.tscn`, sem erro de nó | toda PR |
| Backend unit | Jest, repositórios falsos | toda PR (`gate-backend`) |
| Backend e2e | supertest + Postgres em container; orquestrador com Docker mock | toda PR |
| Fluxo completo | 2 launchers + backend + pool local (`infra/docker-compose.yml`) | gate do MVP3, manual |

## 8. O que este documento não decide

- Steam, ranked, amigos, economia, skins (roadmap, PRD §1.3).
- "Lembrar-me"/persistência de sessão (R-PEND-03).
- Nível/XP de conta do design visual (R-PEND-02: não). Perfil decidido em 2026-10-10: nickname no backend, avatar só local (F35, `CONVENTION.md` §4.8).
- WebSocket em vez de polling (reavaliar se o polling pesar; registrado em `DEBITO.md`).
