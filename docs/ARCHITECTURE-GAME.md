# ARCHITECTURE-GAME.md — Módulo Game (partida)

**Normativo.** Vale para `game/` e para a parte de `shared/` que o Game consome. Decisão de origem: [ADR-0002](adr/0002-dois-modulos-launcher-e-game.md). Domínio: `CONVENTION.md`. Números: `docs/prd/GDB.md` ([ADR-0004](adr/0004-gdb-vence-numeros.md)).

## 1. Responsabilidade e fronteira

O Game é **tudo o que acontece entre "conectei ao servidor de partida" e "a partida acabou"**: seleção de heróis, cinemática de abertura (`INTRO`), fase 1, transição, fase 2, morte súbita, tela de fim. Um único projeto Godot (`game/`) que roda em dois papéis:

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
  project.godot                 Forward+; main scene = scenes/main.tscn; feature dedicated_server no preset servidor
  export_presets.cfg            (ignorado no git) presets: windows-client, linux-server
  shared/ -> ../shared          junction (ADR-0003); nunca editar "dentro" — é a mesma pasta
  addons/                       netfox, netfox.internals, netfox.extras, gut — NUNCA editar
  scenes/
    main.tscn                   bootstrap único: main.gd lê LaunchArgs e sobe servidor dedicado, cliente ou host (--offline)
    arena/                      ilha_arcana.tscn (arena e marcadores), valley_forest.tscn (vale), vegetation.tscn
    heroes/                     um .tscn por herói (10) e void_servant.tscn (Servo do Vazio)
    monsters/                   skeleton*, golem*, wolf_t2, skeleton_king_boss
    world/                      chest, gate, fountain e shaders da neblina e da zona
    vfx/                        efeitos de combate (F41): one-shots do pool, efeitos por herói, shaders — só cliente
    ui/                         hero_select, hud (hud_phase1/2), hero_plate, match_end (+ match_end_card), bestiary
  scripts/
    main.gd                     Main: bootstrap, ligação de sinais e spawns; follow_camera.gd, intro_camera.gd
    core/                       regras puras — sem Node, sem rede, 100% GUT (ver §3.1)
    net/                        Combatant, Hero e as 10 subclasses, PlayerInput, Arrow, Concealment, VisionDirector, ImpactRelay, PeerAuth, NetProbe
    match/                      MatchController (FSM da partida), MatchClock, ZoneController, KillTracker, SpawnDirector, MatchStats
    ai/                         BotInput + ArenaNav (navmesh do bot), Monster, VoidServant e os visuais deles
    items/                      Inventory: aplicação de atributos (equip, set bonus) — usa shared/core
    ui/                         HUDs, seleção, loading, intro_overlay, fim de partida, conexão perdida — só consomem sinais
    server/                     ServerSession (AuthSession, Heartbeat, ResultReporter) e o cliente HTTP do backend
    client/                     shader_warmup.gd, equipment_lineup.gd
    vfx/                        VfxSpawner, VfxPool, HeroVfx (um por herói), TrailRibbon — só cliente (§3.8)
    world/                      arena, vale, vegetação, baús, portões, fonte, neblina, dia/noite
  test/
    unit/                       GUT: core/, match/ (FSM com relógio falso), items/, heróis, bot, UI
    net/                        roteiros de 2 clientes + servidor (manual/semi-automático)
  tools/ (na raiz)              test.ps1, run-server.ps1, run-clients.ps1, soak.ps1
```

`shared/` (consumido pelo Game):

```
shared/
  core/        fórmulas puras compartilhadas com o Launcher: stats.gd (DEF→mitigação, INT→CDR, AGI→velocidade), skill_rules.gd, hero_attributes.gd, set_bonus.gd, xp_table.gd, item_rules.gd, ids.gd, input_actions.gd, user_settings.gd
  data/        heroes/ (10), servants/, items/, monsters/, rules/ (match_pacing.tres, xp_table.tres, bot_profile.tres), ui/, visual/ — GDB §8
  resources/   classes Resource: HeroData, SkillData, PassiveData, ServantData, ItemData, MonsterData, MatchRules
  assets/      glTF: KayKit/Quaternius como vêm do pack; ajustes e arte própria exportados do Blender em .glb; cena _alignment.tscn (PRD §11, ADR-0005)
  ui/theme/    theme_moba.tres, fontes, StyleBoxes (consumidos pela HUD também)
  test/        GUT das fórmulas de shared/core
```

Fonte dos assets 3D: `art/` na raiz (arquivos `.blend`, nunca importados pelo Godot; importação de `.blend` desligada no `project.godot`). Em `shared/assets/` só entra glTF (ADR-0005).

**Regra de dependência (unidirecional):** `ui` → `match` → `net` → `core`/`shared`. `core` e `shared/core` não importam nada acima. `ai` depende de `match` (lê estado) e `net`: o `BotInput` gera input como um `PlayerInput` (que é `BaseNetInput`); `Monster` e `VoidServant` são `Combatant` (de `net/`). Violação = P1 em revisão.

## 3. Camadas

### 3.1 `core/` e `shared/core/` — regras puras

Funções estáticas ou `RefCounted`, sem `Node`, sem `await`, sem acesso a cena, sem RNG implícito (RNG é parâmetro). Tudo tem teste GUT. Exemplos: `CombatRules.melee_hits(origin, facing, target, arc_deg, range)`, `Stats.mitigated_damage(raw, def)`, `XpTable.level_for(xp)`, `ZoneRules.radius_at(t)`, `VictoryRules.evaluate(state)`; do controle e das habilidades, `TargetRules`, `FacingRules`, `IntroRules`, `BerserkerRules`, `PaladinRules`, `OccultistRules`, `VoidServantRules`.

O que vai em `shared/core` e não em `game/scripts/core`: o que o Launcher também precisa (simulador da Forja, barras de atributo da Seleção, bestiário). O que é só de partida (arco de ataque, mira, zona, vitória) fica em `game/scripts/core`.

### 3.2 `net/` — simulação com netfox

- Tick fixo **30 Hz** (`NetworkTime.tickrate`). `physics_ticks_per_second` fica no padrão (60) salvo medição contrária; o netfox compensa por `physics_factor`. Confirmar na documentação do addon instalado antes de mudar.
- **`Combatant`** (`net/combatant.gd`, `CharacterBody3D`) é o que pode ser golpeado: `Hero`, `Monster` e `VoidServant`. Interface: `receive_hit`/`cancel_hit`, `is_alive`, `effective_damage`, `missing_hp`, `combat_id`, `seen_by`, `is_shown`; grupo `combatants` e `team` (monstro é neutro). `combat_id` é o `peer_id` do herói e um uid negativo para monstro e servo, e é o que o alvo travado (`target_id`) e o golpe direto (`striker_id`) guardam.
- Cada herói: `Hero` + `RollbackSynchronizer` (state: `transform`, `velocity`, `hp`, `xp`, `ranks`, recargas, controle — `stun_ticks`, `slow_*`, `knockback_*` —, `invuln_ticks`, `cc_immune_ticks`, `target_id`, `face_ticks`, `reveal_ticks`, `curse_*`, `dot_*`, mais o que cada subclasse declara em `_extra_state_properties`; input: `PlayerInput`, com `target_id`/`target_clear` e `chest_pick`). Movimento em `_rollback_tick` com `velocity *= NetworkTime.physics_factor` antes de `move_and_slide()`. Orientação e alvo (F66): o herói encara o movimento (`FacingRules`); `_plan_attack` valida o `target_id` no servidor (`TargetRules`: vivo, adversário, visto por `seen_by`) e liga o auto-ataque em alcance, sem perseguir. `input_locked` (INTRO) zera a simulação do herói.
- Input só por subclasse de `BaseNetInput`: `PlayerInput` (cliente humano; os campos de alvo e baú ficam nele porque `BaseNetInput` está em `addons/`) e `BotInput`, que herda dele. Broadcast de input desligado.
- Monstros e Servos do Vazio (F78): `StateSynchronizer`/`TickInterpolator` (não precisam de rollback; o servidor simula, clientes interpolam). O servo é a primeira entidade móvel de um herói: **pool fixo de 2 por Ocultista**, filhos de um `Node` simples da cena dele (sem spawn no meio da partida, compatível com o rollback; esse `Node` também quebra a herança de visibilidade do herói). Invocar só liga (`summon`); fim da duração ou HP 0 desliga (fora de alcance e sem colisão). Projéteis (F14): o netfox 1.35.3 não tem spawn dentro do rollback (só o `NetworkWeapon`, por RPC e fora da ressimulação; `RollbackSynchronizer` sem input e dono servidor nunca ressimula e, no cliente, nem simula). Por isso o projétil é um **pool fixo filho do herói** (`Arrow`, 4 por Arqueiro), que nasce com ele pelo `MultiplayerSpawner`; o estado de cada flecha entra no `RollbackSynchronizer` do próprio herói (`"Arrows/Arrow0:kind"`…) e o herói a avança no `_rollback_tick`. Disparar é ocupar um slot; ressimular o herói reproduz a flecha; o cliente prevê o próprio disparo e o acerto (dano pelo ledger) é só do servidor.
- `@rpc` cru **apenas** para eventos discretos fora da simulação: pick de herói, mudança de fase, kill, baú aberto, level up, fim de partida. Sempre `reliable`, sempre com `tick` no payload.
- **Efeito entre nodes (padrão `HitLedger`, nascido no F4):** o efeito de um golpe (`HitEffect`: dano, empurrão, atordoamento, lentidão, XP, saque, curas, marcas) **não** viaja por `NetworkRollback.mutate` — no netfox 1.35.3 a mudança de estado feita por ele se perde quando o alvo é ressimulado (`rollback-history-recorder.gd`, ADR-0001). O atacante/sistema registra `{tick, fonte, efeito}` num ledger **fora do estado**, só no servidor; o herói-alvo lê o ledger e aplica no **próprio** `_rollback_tick`. A chave da fonte é `atacante × 7 + Slot` (`BASIC`, `Q`, `E`, `R`, `REWARD`, `ZONE`, `PASSIVE`), então o mesmo atacante acerta com skills diferentes no mesmo tick; ressimular o alvo reaplica, ressimular o atacante não duplica (um efeito por fonte por tick). Vale para dano, empurrão, lentidão, zona, saque de baú e consumíveis, e para o roubo de vida do Berserker (`Slot.PASSIVE`, no ledger do próprio herói).
  - **Papel real do `mutate`:** `Hero._hit` grava o efeito no alvo (`receive_hit(tick + 1, …)`) e só então chama `NetworkRollback.mutate(alvo, tick + 1)`, só para marcar o alvo como alterado desde esse tick e o netfox **ressimulá-lo** se ele já simulou `tick + 1` sem o golpe. É um pedido de ressimulação, não um canal de efeito: o dano mora no ledger e é o `_rollback_tick` do alvo que o aplica.
  - **Alvo que não é herói** (`Monster`, `VoidServant`): não tem rollback, então `receive_hit` aplica na hora, uma vez por (tick, fonte) — `_seen`, um `HitLedger` próprio. Golpe já aplicado não é desfeito se a ressimulação do atacante errar (`cancel_hit` é vazio; risco aceito, raro).
  - **Golpe direto (F76):** `HitEffect.striker_id` ≠ `TargetRules.NONE` marca golpe de contato de um `Combatant` (`combat_id` de quem golpeou): básico corpo a corpo (Cavaleiro, Bárbaro, Berserker, Paladino), Investida, Execução, Emboscada, Golpe Consagrado, golpe de monstro de alvo único e golpe do servo. Não são diretos: projétil, zona, pulso, golpe em área (Golem, boss) e o Bacamarte do Engenheiro (`_basic_is_direct()` falso; decisão do PI em 2026-10-19). Só ele aciona a Retribuição do Paladino; o dano devolvido não leva `striker_id` (sem laço).
  - **Estado do próprio alvo, aplicado no `_rollback_tick` dele:** Maldição (`curse_stacks`, `curse_ticks`) e Praga (`dot_*`: pulsos e `dot_source`, que recebe o crédito) chegam por `HitEffect.curse`/`dot_*` e passam a ser estado do herói (e do monstro e do servo, fora do rollback); a Defesa efetiva usa `OccultistRules.effective_defense`. `invuln_ticks` (Rolamento e Bênção Inviolável) zera o dano, inclusive o `true_damage` da zona, mas não o controle. `cc_immune_ticks` (Ragnarök) descarta empurrão, atordoamento e lentidão no `_apply_effect`; Maldição e Praga não são controle e continuam valendo.
  - **Retribuição:** o Paladino mede, no `_apply_effect`, o dano que tomou depois da Defesa (0 sob a Bênção) e, se o golpe é direto e a origem está a ≤ `attack_range`, soma a devolução; no fim do `_apply_hits` grava cada uma no **ledger do atacante** (`Slot.E` do Paladino), que o aplica no próprio tick. O golpe que mata o Paladino não volta.
- Lag compensation de hits com `NetworkRollback` (hitbox no tick do atacante). Compensação só até N ticks (parâmetro em `match_pacing.tres`).
- O servidor valida faixa/NaN de todo input (`InputRules`): o `sanitize` do netfox só confere o dono da propriedade, não o valor.
- **Visão por peer (F32 mato alto, F37 neblina):** todo alvo que pode sumir (herói, monstro, servo, baú) tem um `Concealment` com a regra do próprio alvo (`seen_by(observer: Hero)`, sobre `VisionRules`/`VisibilityRules`). No servidor, o `VisionDirector` roda uma vez por tick em `NetworkTime.before_tick`, para cada herói observador (inclusive o bot e o jogador do host): quem não vê sai do `visibility_filter` do sincronizador do alvo (ao lado do `SpawnAck`) e recebe `_set_hidden(hidden, tick)` por RPC confiável; o cliente esconde o node e tira a colisão até chegar estado do tick da revelação. Baú não some: o `_show` vai só a quem vê, e quem passa a ver recebe o estado atual. Estado de herói (nível, baú aberto) vai só ao próprio peer; fase, morte, kill e o aviso/morte do boss seguem globais. O bot lê o mesmo recorte (`Hero.seen_by` + memória do último estado visto de monstros e baús). A neblina desenhada (`FogOfWar`, quad de tela) é só do cliente e usa apenas a posição do próprio herói.
- `enable_prediction=false` (padrão): node sem input no tick não é simulado nem transmitido. Bots e jogadores desconectados precisam de input (`BotInput` ou input vazio sintetizado pelo servidor) para continuar sendo simulados — ver §6.
- Logging de rede com rate limit; validação de tamanho e faixa de todo campo recebido (`.claude/rules/network-code.md`).

### 3.3 `match/` — ciclo da partida

`MatchController` (um por partida, existe **só no servidor**; clientes recebem o estado por `StateSynchronizer` + RPCs) é uma máquina de estados:

```
LOBBY_WAIT ─(2 jogadores conectados e token válido)─▶ HERO_PICK ─(ambos lock-in ou timeout 24 s)─▶
INTRO ─(≥ 5 s e `ready` dos 2, ou 8 s)─▶ PHASE1 (5:00) ─(relógio)─▶ TRANSITION (5 s) ─▶ PHASE2
  ─(4:00 da fase 2)─▶ SUDDEN_DEATH ─▶ ENDED          └─(meta de kills)───────────────────▶ ENDED
```

Estados em `MatchState` (`core/`), sem transição de volta; `TRANSITION` já conta como fase 2 (`is_phase2`). Em `ENDED` o servidor reporta o resultado e encerra o processo (§3.7); o cliente mostra a tela de fim e volta ao Launcher (§3.7).

- `INTRO` (F69, ADR-0015): os heróis nascem no spawn ao entrar (antes nasciam na `PHASE1`), com `Hero.input_locked` (o servidor não aplica input; o cliente manda input zerado, `PlayerInput.cinematic`). O relógio **não** corre: `MatchClock.start` roda ao sair da `INTRO`, então `t_match` começa em 0:00 nesse tick. O cliente toca a `IntroCamera` (`IntroRules`: voo 3 s → close 2 s → blend 0,5 s; `IntroOverlay` com classe e nome; HUD oculta) e manda `ready` por RPC (`MatchController.report_intro_ready`, any_peer, recusado fora da `INTRO` e sem vaga) quando termina; bot e jogador desconectado entram prontos. O `deadline_tick` da `INTRO` é o corte (8 s) e o mesmo `phase_changed` leva todos à `PHASE1` no mesmo tick. Rollback e `StateSynchronizer` não mudam.

- `MatchClock`: relógio autoritativo em ticks; `t_match`, `t_phase`. Boss aos 3:30, aviso aos 3:00, portões aos 5:00, zona fecha em 4:00 de fase 2, respawn desliga aos 9:00, colapso aos 10:00 (GDB §7.1).
- `ZoneController`: raio e dano por tempo (tabela GDB §7.1 em `match_pacing.tres`); registra o dano no ledger de cada herói fora do círculo, e cada herói aplica no próprio `_rollback_tick` (padrão `HitLedger`, §3.2).
- `KillTracker` + `VictoryRules`: ordem de avaliação GDB §7.2. Nunca empate.
- `SpawnDirector`: monstros, baús e boss por `arena.tscn` (marcadores) + `.tres`; **seed por partida** vinda do token/servidor para drops determinísticos e auditáveis.
- Eventos públicos (sinais do `MatchController`, consumidos pela UI e pelo `ResultReporter`): `phase_changed(from, to, tick)`, `hero_picked(peer, hero_id)`, `player_leveled(peer, level)`, `player_died(peer, killer, phase)`, `kill_scored(peer, total)`, `item_equipped(peer, slot, item_id)`, `chest_opened(peer, chest_id, drop)`, `zone_updated(radius, dps, t_next)`, `boss_spawned`, `match_ended(winner, reason, stats)`.

### 3.4 `ai/` — bot, monstros e servos

- **Bot:** `BotInput extends PlayerInput` **produz input** (inclusive `target_id`, só em alcance e com linha de tiro) e não toca em estado. A FSM (PRD §3.7) é `BotRules` (`core/`, pura); `BotInput` escolhe o alvo do estado e anda pelo navmesh (`ArenaNav`, assado dos colisores estáticos; um por time no soak bot × bot). Lê só o que um cliente teria: posições vistas pela neblina (`Hero.seen_by`), memória do último estado visto de monstros e baús, relógio replicado (invariante de honestidade, CONVENTION §4.6). Roda no servidor (treino offline, soak, vaga do roadmap) e, com `--autopilot=bot`, joga pelo herói local para medição.
- **`Monster`** (`Combatant`, neutro): idle → aggro (alcance) → atacar → reset (leash), IA no servidor, lê `MonsterData.tres`; só mira heróis. Golpe sobre herói vai pelo ledger do herói; o golpe recebido entra na hora (§3.2).
- **`VoidServant`** (`Combatant`, time do Ocultista; F78): IA no servidor a cada tick. Escolhe o alvo a cada `retarget_interval` e quando o atual morre ou some (`VoidServantRules.choose`): alvo travado do Ocultista → herói inimigo mais próximo → monstro mais próximo (boss incluído), sempre entre o que o **Ocultista** vê (`seen_by`); sem alvo, segue o Ocultista. O golpe leva `attacker_id` = peer do Ocultista (dano, XP de monstro, kill e aggro do campo contam para ele) e `striker_id` = uid do servo; não mexe na recarga do Ocultista, então não o revela no mato. Matar o servo não emite `died`, XP, drop nem kill. Visão como a do monstro (`seen_by`: o time do dono sempre vê).

### 3.5 `items/`

`Inventory` (4 slots, no servidor) aplica `ItemData` sobre os atributos base usando `shared/core/stats.gd` e `set_bonus.gd`; o equipado vai no estado de rollback do herói. Escolha no baú (ADR-0014, F61, substitui a SPEC-047): `F` (`interact_hold`) abre o baú; o servidor sorteia por `ChestRules` (seed da partida) e mostra 3 itens distintos só a quem abriu (baú reservado); o clique escolhe 1 e vai como input (`PlayerInput.chest_pick`, não RPC); o servidor valida e entrega pelo ledger (`HitEffect.item`, `Slot.REWARD`). `ItemRules` só compara ofertas (HUD e bot).

### 3.6 `ui/` — HUD e telas da partida

- Uma `CanvasLayer` por tela (`loading_screen` do boot até o `HERO_PICK`, `hero_select`, `intro_overlay`, `hud_phase1`, `hud_phase2`, `match_end`, `connection_lost_screen`); `HudController` troca a tela ao receber `phase_changed` e esconde a HUD na `INTRO`.
- A UI **só consome sinais e estado replicado**; nunca chama regra. Nunca calcula dano/XP localmente — exibe o que chegou.
- Theme, tokens e componentes vêm de `shared/ui/` (contrato em `docs/design-system/`). A HUD usa os mesmos componentes do Launcher (`StatBar`, `HotkeyBadge`, `SlotItem`, `PanelCard`).
- Telemetria de rede: `HudTelemetry` (FPS · PING · TICK na HUD) e, com `--probe`, o `NetProbe` (log de ticks, rede e VFX). **É aqui** que vive a telemetria de netfox — não no Launcher (o Launcher não tem netfox).

### 3.7 `server/` e `client/`

Há um único bootstrap, `Main` (`scripts/main.gd`, `scenes/main.tscn`), que lê `LaunchArgs` e liga os sinais; não existem `ServerMain`/`ClientMain` separados.

- **Servidor dedicado:** sobe `ENetMultiplayerPeer` → `ServerSession` (`AuthSession` valida o `--token` do handshake no backend, `Heartbeat`, `ResultReporter`; sem backend só com `--no-backend`, dev) → espera 2 peers → `MatchController.start()` → ao `match_ended`: `ResultReporter` posta o resultado, espera 2 s (para os RPCs confiáveis do fim chegarem) e encerra com o código de `ExitCodes` (§6). Timeout de espera por jogadores: parâmetro em `match_pacing.tres`; expirou → reporta `abandoned` e encerra.
- **Cliente:** conecta apresentando o token (`PeerAuth`) → `LoadingScreen` → seleção → `PlayerInput` no herói local → `INTRO` → partida → `match_ended`: `MatchEnd` com "Voltar ao lobby" e fechamento automático em 15 s (F70), ambos `quit(0)`; o Launcher então busca o resultado e mostra o card (`ARCHITECTURE-LAUNCHER.md`). Servidor perdido no meio: `ConnectionLostScreen` → código 4. "Jogar novamente" é do Launcher: o Game não tem fila.

### 3.8 `vfx/` — efeitos de combate (F41, ADR-0006 item 7)

- **Só cliente.** A `main` cria o `VfxSpawner` apenas quando o processo desenha (`VfxSpawner.wanted()`); o servidor headless não tem nó de VFX (GUT `test_vfx_headless`). O herói não ganha filho: os efeitos ficam sob o `VfxSpawner` e seguem o herói.
- **Disparo de habilidade = borda do estado**, lida no `_process` (`HeroVfx._started/_ended`, `VfxRules.started`), como o `HeroVisual`: nada nasce no `_rollback_tick`, então ressimular (que restaura o mesmo estado) não duplica, e o herói remoto — que o cliente não simula (`enable_prediction=false`) — entra pelo mesmo caminho. `is_fresh` sozinho não cobriria o remoto. Herói escondido (mato, neblina) ou morto não mostra nada; ao reaparecer as bordas recomeçam do estado atual.
- **Impacto = servidor.** `Hero._hit` emite `struck` quando registra o golpe no ledger do alvo; o `ImpactRelay` (existe nos dois lados desde o load) anuncia uma vez por (tick, atacante, slot, alvo) — `ImpactLog`, porque a ressimulação do atacante repete o `_hit` — por RPC `unreliable` só ao peer que vê o alvo (`Concealment.shown_to`). Perder um impacto tira uma faísca; nunca duplica.
- **Estado replicado também vira efeito:** marcas da Maldição e Praga no alvo (`CurseMarks` lê `curse_stacks` e `dot_ticks` de herói e monstro, sem evento); zonas postas (fumaça, Poção, Pântano, Círculo Profano, Torreta, Caixa) e suas instalações chegam por RPC do `ImpactRelay`, porque o lançador pode sumir de quem está fora da visão e a zona não.
- **Silhueta no mato alto (F72):** `HeroVisual` lê `Hero.zones_at` a cada quadro e, só no herói controlado neste processo, dentro de moita ou fumaça, põe overlay translúcido no herói e abre a moita em volta (shader `tall_grass`). Nada de rede, `VisibilityRules` intacta.
- **Pool** (`VfxPool`) só para o frequente: faísca, poeira, pulso, Terremoto, fantasma. Persistente (Muralha, rastros, saraivada) mora no `HeroVfx`.
- **Flecha visual desacoplada da rede** (`Arrow._process` + `VfxRules.arrow_progress`): anda na velocidade do disparo e só acompanha a posição da rede, sem recuar.
- Números de gameplay (alcance e arco do básico, raios do Terremoto e da Chuva, forma da Muralha) vêm do `HeroData`/cena; duração dos efeitos é dado visual das cenas de `scenes/vfx/`. Shaders de `scenes/vfx/` entram no warm-up (`ShaderWarmup.SHADERS`).
- Medição: com `--probe`, o `NetProbe` imprime `[probe] vfx` — bordas autoritativas no servidor × eventos mostrados no cliente, impactos anunciados × recebidos × repetidos.

## 4. Modo offline ("Praticar vs Bot")

Mesmo binário, `--offline --bot`: o `Main` roda em modo host — este processo é o servidor **e** o jogador local (peer 1), pelo mesmo caminho do online (ENet em `127.0.0.1`, porta efêmera), com `BotInput` no segundo slot. Um único caminho de código para regras; nenhum `if offline` dentro de `match/` ou `net/`. Sem backend: sem `ServerSession` (token não validado, resultado não reportado). Isso é o que faz o M1 ("arena single-player") já nascer com a arquitetura autoritativa — sem reescrita no M2.

## 5. Dados e balanceamento

- Todo número de balanceamento vem de `shared/data/**/*.tres` (GDB §8). Número literal em script = defeito.
- Classes `Resource` em `shared/resources/` com `@export` tipado. Carregadas pelo servidor na partida; o cliente carrega as mesmas para exibir (ícones, nomes, descrições) — nunca para calcular.
- IDs de itens/heróis/monstros são `StringName` estáveis (`&"sword_t2"`), enviados em RPC como `int` via tabela `shared/core/ids.gd` (PRD benchmark §4: "IDs inteiros correspondentes aos .tres").

## 6. Resiliência e falhas

| Situação | Comportamento |
|---|---|
| Cliente desconecta na partida | Servidor marca `disconnected` e passa a **sintetizar input vazio** para o herói (senão o netfox para de simulá-lo e ele fica imune a zona e dano — §3.2); herói fica parado e morre normalmente; sem reconexão (PRD §8.5). Partida termina pelas regras normais; resultado reportado. |
| Servidor cai | Clientes recebem `server_disconnected` → `ConnectionLostScreen` → encerram com código 4 (o Launcher mostra erro genérico); se a tela de fim já estava aberta, ela permanece. Backend marca partida `aborted` por timeout do heartbeat (ver `ARCHITECTURE-LAUNCHER.md` §6). |
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
| Soak | `tools/soak.ps1`: bot × bot headless, 50 partidas, falha se alguma > 10 min ou sem vencedor | `tools/soak.ps1` | gate do MVP, nightly (`soak.yml`) e fatia que mexe em regra de partida |
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
