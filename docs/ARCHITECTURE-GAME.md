# ARCHITECTURE-GAME.md — Módulo Game (partida)

**Normativo.** Vale para `game/` e para a parte de `shared/` que o Game consome. Decisão de origem: [ADR-0002](adr/0002-dois-modulos-launcher-e-game.md). Domínio: `CONVENTION.md`. Números: `docs/prd/GDB.md` ([ADR-0004](adr/0004-gdb-vence-numeros.md)).

## 1. Responsabilidade e fronteira

O Game é **tudo o que acontece entre "conectei ao servidor de partida" e "a partida acabou"**: seleção de heróis, fase 1, transição, fase 2, morte súbita, tela de fim. Um único projeto Godot (`game/`) que roda em dois papéis:

| Papel | Como sobe | Renderiza | Autoridade |
|---|---|---|---|
| **Servidor dedicado** | `game.x86_64 --headless --server --port=7005 --token=...` em Docker | não (`dedicated_server` feature) | **toda** regra de jogo |
| **Cliente** | `game.exe --connect=host:porta --token=...` lançado pelo Launcher | sim | nenhuma: envia input, renderiza estado |
| **Cliente offline (treino)** | `game.exe --offline --bot` | sim | servidor local embutido no mesmo processo (§4) |

**O Game não sabe que o Launcher existe.** Não importa cena, script ou autoload de `launcher/`. Recebe argumentos de linha de comando, lê `user://settings.cfg` (§7) e, ao terminar, encerra o processo. Comunicação com o backend é feita **só pelo servidor dedicado** (validar token, reportar resultado) — o cliente nunca fala com o backend.

Fora do Game (ver `ARCHITECTURE-LAUNCHER.md`): login, fila, histórico, bestiário, forja, configurações, pool de servidores.

## 2. Estrutura de pastas

```
game/
  project.godot                 Forward+; main scene = scenes/boot.tscn; feature dedicated_server no preset servidor
  export_presets.cfg            (ignorado no git) presets: windows-client, linux-server
  shared/ -> ../shared          junction (ADR-0003); nunca editar "dentro" — é a mesma pasta
  addons/                       netfox, netfox.internals, netfox.extras, gut — NUNCA editar
  scenes/
    boot.tscn                   lê LaunchArgs e instancia ServerMain ou ClientMain
    arena/                      arena.tscn, zonas, portões, spawn points
    heroes/                     knight.tscn, ranger.tscn (modelo + Hitbox + RollbackSynchronizer)
    monsters/                   skeleton*.tscn, golem.tscn, skeleton_king.tscn
    projectiles/                arrow.tscn, pool
    world/                      chest.tscn, gate.tscn, zone.tscn
    ui/                         hero_select.tscn, hud_phase1.tscn, hud_phase2.tscn, match_end.tscn, net_debug.tscn
  scripts/
    core/                       regras puras — sem Node, sem rede, 100% GUT (ver §3.1)
    net/                        nodes de rede: player, inputs, projétil, spawner
    match/                      MatchController (FSM da partida), MatchClock, ZoneController, KillTracker
    ai/                         bot_controller.gd (FSM do bot), monster_ai.gd
    items/                      aplicação de atributos (equip/unequip, set bonus) — usa shared/core
    ui/                         hud_controller.gd, hero_select_controller.gd, match_end_controller.gd
    server/                     server_main.gd, backend_client.gd (HTTP interno), result_reporter.gd
    client/                     client_main.gd, follow_camera.gd, local_input.gd
  test/
    unit/                       GUT: core/, match/ (FSM com relógio falso), items/
    net/                        cenários 2 clientes + servidor (manual/semi-automático)
  tools/ (na raiz)              test.ps1, run-server.ps1, run-clients.ps1, soak.ps1
```

`shared/` (consumido pelo Game):

```
shared/
  core/        fórmulas puras compartilhadas com o Launcher: stats.gd (DEF→mitigação, INT→CDR, AGI→velocidade), set_bonus.gd, xp_table.gd, item_rules.gd (regra de substituição)
  data/        heroes/, items/, monsters/, rules/ (match_pacing.tres, xp_table.tres) — GDB §8
  resources/   classes Resource: HeroData, SkillData, ItemData, MonsterData, MatchRules
  assets/      glTF KayKit/Quaternius + cena _alignment.tscn (PRD §11)
  ui/theme/    theme_moba.tres, fontes, StyleBoxes (consumidos pela HUD também)
  test/        GUT das fórmulas de shared/core
```

**Regra de dependência (unidirecional):** `ui` → `match` → `net` → `core`/`shared`. `core` e `shared/core` não importam nada acima. `ai` depende de `match` (lê estado) e `net` (gera input como um `BaseNetInput`). Violação = P1 em revisão.

## 3. Camadas

### 3.1 `core/` e `shared/core/` — regras puras

Funções estáticas ou `RefCounted`, sem `Node`, sem `await`, sem acesso a cena, sem RNG implícito (RNG é parâmetro). Tudo tem teste GUT. Exemplos: `CombatRules.melee_hits(origin, facing, target, arc_deg, range)`, `Stats.mitigated_damage(raw, def)`, `XpTable.level_for(xp)`, `ItemRules.should_auto_replace(current, picked)`, `ZoneRules.radius_at(t)`, `VictoryRules.evaluate(state)`.

O que vai em `shared/core` e não em `game/scripts/core`: o que o Launcher também precisa (simulador da Forja, barras de atributo da Seleção, bestiário). O que é só de partida (arco de ataque, mira, zona, vitória) fica em `game/scripts/core`.

### 3.2 `net/` — simulação com netfox

- Tick fixo **30 Hz** (`NetworkTime.tickrate`). `physics_ticks_per_second` fica no padrão (60) salvo medição contrária; o netfox compensa por `physics_factor`. Confirmar na documentação do addon instalado antes de mudar.
- Cada herói: `CharacterBody3D` + `RollbackSynchronizer` (state: `transform`, `velocity`, `hp`, `cooldowns`, `status_flags`; input: do `BaseNetInput`). Movimento em `_rollback_tick` com `velocity *= NetworkTime.physics_factor` antes de `move_and_slide()`.
- Input só por subclasse de `BaseNetInput` (`PlayerInput` do cliente humano, `BotInput` do bot). Broadcast de input desligado.
- Monstros: `StateSynchronizer`/`TickInterpolator` (não precisam de rollback; o servidor simula, clientes interpolam). Projéteis: `RollbackSynchronizer` com spawn compatível com o addon (confirmar no código do addon antes de implementar — `CLAUDE.md`).
- `@rpc` cru **apenas** para eventos discretos fora da simulação: pick de herói, mudança de fase, kill, baú aberto, level up, fim de partida. Sempre `reliable`, sempre com `tick` no payload.
- **Efeito entre nodes (padrão `HitLedger`, nascido no F4):** `NetworkRollback.mutate` **não** é usado — no netfox 1.35.3 a mudança se perde quando o alvo é ressimulado (`rollback-history-recorder.gd`, ADR-0001). O atacante/sistema registra `{tick, alvo, efeito}` num ledger **fora do estado**, só no servidor; o alvo lê o ledger e aplica no **próprio** `_rollback_tick`. Vale para dano, empurrão (Q do Cavaleiro), lentidão (R da Arqueira), zona e consumíveis. O ledger é idempotente por `tick` para sobreviver a ressimulação.
- Lag compensation de hits com `NetworkRollback` (hitbox no tick do atacante). Compensação só até N ticks (parâmetro em `match_pacing.tres`).
- O servidor valida faixa/NaN de todo input (`InputRules`): o `sanitize` do netfox só confere o dono da propriedade, não o valor.
- `enable_prediction=false` (padrão): node sem input no tick não é simulado nem transmitido. Bots e jogadores desconectados precisam de input (`BotInput` ou input vazio sintetizado pelo servidor) para continuar sendo simulados — ver §6.
- Logging de rede com rate limit; validação de tamanho e faixa de todo campo recebido (`.claude/rules/network-code.md`).

### 3.3 `match/` — ciclo da partida

`MatchController` (um por partida, existe **só no servidor**; clientes recebem o estado por `StateSynchronizer` + RPCs) é uma máquina de estados:

```
LOBBY_WAIT ─(2 jogadores conectados e token válido)─▶ HERO_PICK ─(ambos lock-in ou timeout 24 s)─▶
PHASE1 (5:00) ─(relógio)─▶ TRANSITION (5 s) ─▶ PHASE2 ─(4:00 da fase 2)─▶ SUDDEN_DEATH ─▶ ENDED
                                                   └─(meta de kills)──────────────────────▶ ENDED
```

- `MatchClock`: relógio autoritativo em ticks; `t_match`, `t_phase`. Boss aos 3:30, aviso aos 3:00, portões aos 5:00, zona fecha em 4:00 de fase 2, respawn desliga aos 9:00, colapso aos 10:00 (GDB §7.1).
- `ZoneController`: raio e dano por tempo (tabela GDB §7.1 em `match_pacing.tres`); registra o dano no ledger de cada herói fora do círculo, e cada herói aplica no próprio `_rollback_tick` (padrão `HitLedger`, §3.2).
- `KillTracker` + `VictoryRules`: ordem de avaliação GDB §7.2. Nunca empate.
- `SpawnDirector`: monstros, baús e boss por `arena.tscn` (marcadores) + `.tres`; **seed por partida** vinda do token/servidor para drops determinísticos e auditáveis.
- Eventos públicos (sinais do `MatchController`, consumidos pela UI e pelo `ResultReporter`): `phase_changed(from, to, tick)`, `hero_picked(peer, hero_id)`, `player_leveled(peer, level)`, `player_died(peer, killer, phase)`, `kill_scored(peer, total)`, `item_equipped(peer, slot, item_id)`, `chest_opened(peer, chest_id, drop)`, `zone_updated(radius, dps, t_next)`, `boss_spawned`, `match_ended(winner, reason, stats)`.

### 3.4 `ai/` — bot e monstros

- `BotController` é uma FSM (PRD §3.7) que **produz input** por `BotInput extends BaseNetInput`; não toca em estado. Roda no servidor (treino offline ou preencher vaga no roadmap).
- `MonsterAI`: idle → aggro (alcance) → atacar → reset (leash). Servidor-only; lê `MonsterData.tres`.

### 3.5 `items/`

`Inventory` (4 slots, no servidor) aplica `ItemData` sobre os atributos base usando `shared/core/stats.gd` e `set_bonus.gd`. Regra de substituição (`ItemRules`) decide auto-troca vs pedir confirmação (`F` 0,4 s). Pedido de troca é input (`BaseNetInput.interact_hold`), não RPC.

### 3.6 `ui/` — HUD e telas da partida

- Uma `CanvasLayer` por tela (`hero_select`, `hud_phase1`, `hud_phase2`, `match_end`); `HudController` troca a tela ao receber `phase_changed`.
- A UI **só consome sinais e estado replicado**; nunca chama regra. Nunca calcula dano/XP localmente — exibe o que chegou.
- Theme, tokens e componentes vêm de `shared/ui/` (contrato em `docs/design-system/`). A HUD usa os mesmos componentes do Launcher (`StatBar`, `HotkeyBadge`, `SlotItem`, `PanelCard`).
- `net_debug.tscn`: overlay de RTT/jitter/perda/ticks lido do netfox (nasce no M0, Tarefa 10). **É aqui** que vive a telemetria de netfox — não no Launcher (o Launcher não tem netfox).

### 3.7 `server/` e `client/`

- `ServerMain`: parse args → sobe `ENetMultiplayerPeer` → `BackendClient.validate_token()` (HTTP interno) → espera 2 peers → `MatchController.start()` → ao `match_ended`: `ResultReporter.post()` → encerra processo com código 0. Timeout de espera por jogadores: parâmetro em `match_pacing.tres`; expirou → reporta `abandoned` e encerra.
- `ClientMain`: parse args → conecta → instancia UI → entrega `PlayerInput` ao herói local → ao `match_ended`: mostra `match_end` → botão "Voltar" encerra o processo. "Jogar novamente" também encerra (o Launcher reabre a fila) — o Game não tem fila.

## 4. Modo offline ("Praticar vs Bot")

Mesmo binário, `--offline --bot`: `ClientMain` sobe um `ServerMain` **no mesmo processo** (ENet em `127.0.0.1`, porta efêmera) com `BotInput` no segundo slot. Um único caminho de código para regras; nenhum `if offline` dentro de `match/` ou `net/`. Sem backend: `BackendClient` em modo nulo (token não validado, resultado não reportado). Isso é o que faz o M1 ("arena single-player") já nascer com a arquitetura autoritativa — sem reescrita no M2.

## 5. Dados e balanceamento

- Todo número de balanceamento vem de `shared/data/**/*.tres` (GDB §8). Número literal em script = defeito.
- Classes `Resource` em `shared/resources/` com `@export` tipado. Carregadas pelo servidor na partida; o cliente carrega as mesmas para exibir (ícones, nomes, descrições) — nunca para calcular.
- IDs de itens/heróis/monstros são `StringName` estáveis (`&"sword_t2"`), enviados em RPC como `int` via tabela `shared/core/ids.gd` (PRD benchmark §4: "IDs inteiros correspondentes aos .tres").

## 6. Resiliência e falhas

| Situação | Comportamento |
|---|---|
| Cliente desconecta na partida | Servidor marca `disconnected` e passa a **sintetizar input vazio** para o herói (senão o netfox para de simulá-lo e ele fica imune a zona e dano — §3.2); herói fica parado e morre normalmente; sem reconexão (PRD §8.5). Partida termina pelas regras normais; resultado reportado. |
| Servidor cai | Clientes recebem `server_disconnected` → tela de erro → encerram. Backend marca partida `aborted` por timeout do heartbeat (ver `ARCHITECTURE-LAUNCHER.md` §6). |
| Token inválido | Servidor recusa peer no handshake; cliente encerra com código 2. |
| Backend indisponível ao reportar | `ResultReporter` retenta 3× com backoff; falhou → grava `user://results/<match_id>.json` e encerra com código 3; o orquestrador coleta pelo volume. |
| Segundo jogador nunca chega | Timeout → `abandoned` → encerra. |
| Pacote fora de faixa | Descartado e logado (rate-limited); 3 ocorrências → peer desconectado. |

Códigos de saída do processo: `0` normal, `1` erro de argumentos, `2` autenticação, `3` resultado não reportado, `4` erro interno. O Launcher lê o código (§5.2 do launcher).

## 7. Configuração do jogador

Vídeo/áudio/controles são **escritos pelo Launcher** e **lidos pelo Game** em `user://settings.cfg` (`ConfigFile`). Os dois projetos usam `application/config/use_custom_user_dir=true` e `custom_user_dir_name="rrb-moba"` para compartilhar o `user://`. O Game aplica no boot e **não tem tela de configurações**; `Esc` em partida abre só "voltar ao jogo / abandonar".

## 8. Testes (por camada)

| Camada | Ferramenta | Onde | Quando roda |
|---|---|---|---|
| `core`, `shared/core`, `items`, `match` (FSM com relógio injetado) | GUT | `game/test/unit`, `shared/test` | toda PR (`gate-game`) |
| `net` | 2 clientes + servidor local, `tools/run-clients.ps1`, latência via Docker `tc netem` | `game/test/net` (roteiros) | manual, obrigatório em card de `net/` — resultado na PR |
| Soak | `tools/soak.ps1`: bot × bot headless, 50 partidas, falha se alguma > 10 min ou sem vencedor | `game/test/soak` | gate do MVP2 e nightly |
| Verificação visual | janelas do jogo | — | do PI; o Code para e pede |

Cobertura mínima de `core`/`shared/core`: 100% de função pública testada (não %, função). Sem teste de regra pura = PR não mergeia.

## 9. Performance

- Alvo cliente: 60 fps em 1080p Forward+ com dois heróis, 17 monstros, 10 baús, zona e partículas. Medir com o profiler antes de otimizar (`CLAUDE.md` regra 5).
- Servidor headless: ≤ 1 núcleo e ≤ 256 MB por partida (medido no M3; R7 do PRD).
- Pooling: projéteis, VFX, números de dano. Nada mais sem número do profiler.

## 10. O que este documento não decide

- Câmera 3ª pessoa × isométrica (PRD §3.6, decidido no M4).
- Reconexão, host migration, anti-cheat além da autoridade (fora de escopo, `FORA-DE-ESCOPO.md`).
- Nomes de propriedades do netfox: ler o addon instalado antes de afirmar.
