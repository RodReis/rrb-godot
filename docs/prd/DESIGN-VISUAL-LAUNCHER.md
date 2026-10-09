# Documento de Design Visual & Especificação de Interface (UI/UX) — Launch 1v1

**Projeto:** MOBA de 2 Tempos (Nome Provisório)

**Repositório:** `rrb-godot`

**Caminho Local no Repositório:** `C:\Desenv\Projetos\rrb-godot\docs\prd\telas\design_visual_telas_launch.md`

**Versão:** 1.1 — 2026-10-09 (paleta e fontes de `docs/prd/telas/` — R-PEND-11 decidida pelo PI; TELA 10 Arena & Mapa)

**Engine:** Godot 4.7 (Forward+ Desktop / Netfox 30Hz Autoritative Server)

**Documentos de Referência:**

* PRD: `docs/prd/2026-10-08-prd-moba-2-tempos.md`

* GDB (Balanceamento): `docs/specs/game_design_balance_specification.md`

* Família de Assets: KayKit Medieval Hexagon, KayKit Adventurers, KayKit Skeletons e Quaternius

## 1. Visão Geral do Design System & Identidade Visual

### 1.1 Filosofia Estética & Princípios de Design

O design visual de interface do MOBA de 2 Tempos busca sintetizar **clareza competitiva instantânea** com a **estética acolhedora e vibrante do low-poly medieval** (influenciado por *Brawl Stars* no aspecto lúdico e *Eternal Return* na estrutura funcional de farm e inventário).

1. **Legibilidade em Alta Velocidade (Combat Readability):** Ação em terceira pessoa a 30 ticks/s exige que barras de vida, tempos de recarga e alertas de zona sejam interpretados em < 100 ms.

2. **Modularidade e Consistência (Godot 4.7 Theme System):** Todos os painéis derivam de uma base unificada de `StyleBoxFlat` e `NinePatchRect`, reduzindo draw calls e simplificando manutenção.

3. **Hierarquia de Informação por Cores Semânticas:** Ouro para títulos e recompensas, Azul para aliados e atributos táticos, Vermelho para perigo/dano, Verde para cura/vida e Roxo para o status épico do Boss.

4. **Sem Poluição Visual (Diegetic vs Non-Diegetic):** Elementos espaciais (retículas no chão, círculos da zona, barras de vida flutuantes) harmonizam-se com a HUD estática ancorada nas bordas da tela.

### 1.2 Paleta de Cores Oficial (Semântica de UI)

**Fonte (decisão do PI em 2026-10-09, R-PEND-11):** paleta e fontes de `docs/prd/telas/` (`DESIGN.md` "Runic Arcade MOBA HUD", igual em todas as pastas). Os nomes semânticos abaixo continuam; os valores mudaram. Tokens, `Color` e contraste: `docs/design-system/TOKENS.md` §1 (fonte para o código).

| Token Semântico | Hexadecimal | Origem em `telas/DESIGN.md` | Aplicação Principal |
| ----- | ----- | ----- | ----- |
| `BG_SURFACE_DARK` | `#0B1326` | `surface` / `background` | Fundos de tela inteira, overlays escuros |
| `BG_PANEL_SLATE` | `#171F33` | `surface-container` | Containers de cartões, fundos de menu |
| `BG_CARD_INNER` | `#222A3D` | `surface-container-high` | Slots de inventário, células de tabelas |
| `GOLD_NOBLE` | `#F59E0B` | `primary-container` (Runic Gold) | Títulos principais, molduras ativas, botões primários |
| `GOLD_BRIGHT` | `#FFC174` | `primary` | Textos de destaque, números de XP |
| `BLUE_MAGIC` | `#3198DC` | `secondary-container` | Botões de ação, buffs de inteligência, Set Guarda |
| `BLUE_CYAN` | `#93CCFF` | `secondary` | Manômetro de CDR, conexões de rede boas |
| `RED_CRIMSON` | `#EF4444` | Crimson Core | HP do oponente, avisos de zona mortal, derrota |
| `GREEN_EMERALD` | `#22C55E` | Health Vitality | Barra de HP do jogador, vitória, confirmações |
| `PURPLE_EPIC` | `#A855F7` | Epic Tier | Raridade Épica, Rei Esqueleto, ultimate (R) |
| `TEXT_PRIMARY` | `#DAE2FD` | `on-surface` | Títulos, nomes de heróis, contadores |
| `TEXT_MUTED` | `#D8C3AD` | `on-surface-variant` | Descrições secundárias, teclas de atalho |
| `BORDER_METALLIC` | `#534434` | `outline-variant` | Bordas neutras e divisores de container |

### 1.3 Tipografia & Escala de Textos (Godot Font System)

* **Fonte Principal (Headings/Display):** `Space Grotesk` Bold (OFL) — `docs/prd/telas/` (R-PEND-11, 2026-10-09).

* **Fonte Secundária (Corpo de Texto/Dados/HUD):** `Outfit` (OFL).

* **Fonte Numérica (contadores, timers, HP, atalhos numéricos):** `JetBrains Mono` Bold (OFL) — números tabulares, sem tremer ao mudar de valor.

| Nível Hierárquico | Tamanho (px @ 1080p) | Peso / Estilo | Uso no Jogo | 
| ----- | ----- | ----- | ----- | 
| **Display / Victory** | `56 px` | Bold / All Caps | "VITÓRIA", "DERROTA", "MORTE SÚBITA" | 
| **Heading 1 (H1)** | `32 px` | Bold | Títulos de Telas ("SELEÇÃO DE HERÓIS", "LOBBY") | 
| **Heading 2 (H2)** | `22 px` | Semi-Bold | Nomes de Habilidades, Nomes de Monstros | 
| **Body / Labels** | `15 px` | Medium | Descrições de itens, lore do bestiário | 
| **HUD Counter** | `28 px` | Monospaced Bold | Relógio da Fase (`04:59`), Placar de Kills (`3 / 5`) | 
| **Hotkey Badges** | `12 px` | Bold | Teclas sobrepostas nos ícones (`[Q]`, `[E]`, `[R]`, `[F]`) | 

### 1.4 Configuração de Viewport e Resolução

* **Resolução Base de Design:** `1920 × 1080` (16:9).

* **Godot Project Settings:**

  * `display/window/size/viewport_width = 1920`

  * `display/window/size/viewport_height = 1080`

  * `display/window/stretch/mode = "canvas_items"`

  * `display/window/stretch/aspect = "expand"`

* Permite ancoragem elástica sem distorcer caixas de texto ou proporções 1:1 de slots.

## 2. Especificação Detalhada das 10 Telas do Launch

### TELA 1: Lobby / Menu Principal (Menu Principal — Lobby 1v1)

#### 1. Objetivo & UX

O Lobby atua como o hub inicial do jogador ao abrir o cliente PC. Ele introduz o jogador ao universo medieval estilizado, exibe o status de conectividade com a infraestrutura dedicada Godot/NestJS, oferece acesso em 1 clique à busca de partida 1v1 (FIFO) ou treino solo contra Bot (M1), e fornece rotas intuitivas para enciclopédias e ajustes.

#### 2. Layout Wireframe (ASCII)

```
+--------------------------------------------------------------------------------------------------+
| [LOGO: 2-TEMPOS ARENA]                                             [Ping: 28ms] [v0.4.7-M2] [X]  |
+--------------------------------------------------------------------------------------------------+
|                                                                                                  |
|   +--------------------------+                                      +------------------------+   |
|   | PERFIL DO JOGADOR        |                                      | CENÁRIO 3D DIORAMA     |   |
|   | [AVATAR] SirRodrigo      |                                      | (Arena Hexagonal       |   |
|   | Nível 8  [====== 75% ==] |                                      |  Cavaleiro em Idle     |   |
|   | 1v1 Vitórias: 14 / 20    |                                      |  Tochas animadas)      |   |
|   +--------------------------+                                      |                        |   |
|                                                                     |                        |   |
|   +--------------------------+                                      |                        |   |
|   | MENU DE NAVEGAÇÃO        |                                      |                        |   |
|   |                          |                                      |                        |   |
|   | [ > JOGAR 1v1 ONLINE   ] |                                      |                        |   |
|   | [   PRATICAR VS BOT    ] |                                      |                        |   |
|   | [   SELEÇÃO DE HERÓIS  ] |                                      |                        |   |
|   | [   GUIA & BESTIÁRIO   ] |                                      |                        |   |
|   | [   FORJA & SETS       ] |                                      |                        |   |
|   | [   HISTÓRICO DE JOGOS ] |                                      |                        |   |
|   | [   CONFIGURAÇÕES      ] |                                      +------------------------+   |
|   | [   SAIR DO JOGO       ] |                                      | STATUS DA FILA 1v1:    |   |
|   +--------------------------+                                      | [ PROCURANDO PARTIDA ] |   |
|                                                                     | Tempo: 00:14  [Cancelar|   |
+--------------------------------------------------------------------------------------------------+
| Servidor: Brasil (VPS-SP) | Protocolo: Netfox UDP (30 Hz) | Pool de Servidores: 3 Ativos         |
+--------------------------------------------------------------------------------------------------+

```

#### 3. Hierarquia de Nós Godot 4.7 (`res://scenes/ui/lobby.tscn`)

```
CanvasLayer (LobbyUI)
├── Control (Root - Full Rect)
│   ├── SubViewportContainer (Diorama3D_Container - Full Rect)
│   │   └── SubViewport (WorldEnvironment, Camera3D, HexArena3D, KnightModel, Lighting)
│   ├── MarginContainer (Margin: 40px all)
│   │   ├── HBoxContainer (MainColumns - separation 30)
│   │   │   ├── VBoxContainer (LeftPanel - custom_minimum_size.x = 420)
│   │   │   │   ├── TextureRect (LogoGame)
│   │   │   │   ├── HSeparator (ThemeSeparator)
│   │   │   │   ├── PanelContainer (PlayerCard)
│   │   │   │   │   └── HBoxContainer
│   │   │   │   │       ├── TextureRect (AvatarFrame)
│   │   │   │   │       └── VBoxContainer
│   │   │   │   │           ├── Label (PlayerName: "SirRodrigo")
│   │   │   │   │           ├── ProgressBar (XPBar)
│   │   │   │   │           └── Label (StatsMini: "14V - 6D")
│   │   │   │   ├── VBoxContainer (NavButtons - separation 12)
│   │   │   │   │   ├── Button (BtnPlayOnline - Gold Accent)
│   │   │   │   │   ├── Button (BtnPlayBot)
│   │   │   │   │   ├── Button (BtnHeroes)
│   │   │   │   │   ├── Button (BtnBestiary)
│   │   │   │   │   ├── Button (BtnForge)
│   │   │   │   │   ├── Button (BtnHistory)
│   │   │   │   │   ├── Button (BtnSettings)
│   │   │   │   │   └── Button (BtnQuit)
│   │   │   ├── Control (CenterSpacer - size_flags_horizontal = EXPAND)
│   │   │   └── VBoxContainer (RightWidget - custom_minimum_size.x = 400)
│   │   │       ├── PanelContainer (SystemStatusCard)
│   │   │       │   └── Label (NetStatus: "Servidor Dedicado Online")
│   │   │       ├── Control (Spacer)
│   │   │       └── PanelContainer (QueueMatchmakingCard - Visible on Search)
│   │   │           └── VBoxContainer
│   │   │               ├── Label (QueueTitle: "Buscando Adversário...")
│   │   │               ├── Label (TimerLabel: "00:14")
│   │   │               └── Button (BtnCancelQueue: "Cancelar Busca")
│   └── PanelContainer (BottomStatusBar - Anchor Bottom, Height 40)
│       └── HBoxContainer
│           ├── Label (ServerRegion: "Região: Brasil (VPS)")
│           ├── VSeparator
│           ├── Label (NetfoxTick: "Netfox Tick: 30Hz")
│           └── Label (BuildVersion: "Build: v0.4.7-M2")

```

#### 4. Estados Interativos & Regras de Comportamento

* **Botão `Jogar 1v1 Online`:** Transiciona o cartão direito para o modo ativo de busca via RPC HTTP com o backend NestJS (`/matchmaking/find`). Inicia tween pulsante dourado na borda do cartão.

* **Botão `Praticar vs Bot`:** Pula a fila e instancia imediatamente o game server local com a máquina de estados M1 do Bot (`scripts/ai/bot_controller.gd`).

* **Animações de Hover:** Todos os botões do menu esquerdo deslizam $8	ext{ px}$ para a direita com tween `TRANS_CUBIC, EASE_OUT` (0.15 s) e tocam efeito sonoro suave de lâmina/madeira.

### TELA 2: Seleção de Heróis (Seleção de Heróis — Cavaleiro vs Arqueira)

#### 1. Objetivo & UX

Apresenta o confronto 1v1 com visual estilo arena de luta. Exibe os dois heróis disponíveis na fatia vertical, permitindo inspecionar modelos 3D em tempo real, examinar atributos base (HP, DEF, ATK, INT, AGI) e ler a descrição tática das habilidades Q, E e R com seus valores fundamentais do GDB §4.

#### 2. Layout Wireframe (ASCII)

```
+--------------------------------------------------------------------------------------------------+
| [VOLTAR]                    FASE DE ESCOLHA — DUELO 1v1               TEMPO RESTANTE: [ 24s ]    |
+--------------------------------------------------------------------------------------------------+
|                                                                                                  |
|   JOGADOR (VOCÊ)                                         OPONENTE (ONLINE / BOT)                 |
|   +-----------------------+     +-------------------+     +-----------------------+              |
|   | [ HEROI 3D VIEWPORT ] |     | CARDS DE SELEÇÃO: |     | [ HEROI 3D VIEWPORT ] |              |
|   |                       |     |                   |     |                       |              |
|   |   CAVALEIRO           |     | +---------------+ |     |   ARQUEIRA            |              |
|   |   "Tanque & Controle" |     | | [X] CAVALEIRO | |     |   "Ranger & Agilidade"|              |
|   |                       |     | +---------------+ |     |                       |              |
|   | ATRIBUTOS:            |     | | [ ] ARQUEIRA  | |     | STATUS:               |              |
|   | HP:  600 [==========] |     | +---------------+ |     | [ AGUARDANDO ESCOLHA] |              |
|   | DEF: 30  [====      ] |     +-------------------+     |                       |              |
|   | ATK: 40  [=====     ] |                               |                       |              |
|   | INT: 10  [==        ] |     HABILIDADES:              |                       |              |
|   | AGI: 10  [==        ] |     [Q] Investida (Knockback) |                       |              |
|   |                       |     [E] Muralha (Escudo Dano) |                       |              |
|   +-----------------------+     [R] Terremoto (Stun AoE)  +-----------------------+              |
|                                                                                                  |
|                             [ BLOQUEAR HERÓI (LOCK IN) ]                                         |
+--------------------------------------------------------------------------------------------------+
| Teclas de Atalho: [1] Cavaleiro   [2] Arqueira   [Espaço] Confirmar Escolha                      |
+--------------------------------------------------------------------------------------------------+

```

#### 3. Hierarquia de Nós Godot 4.7 (`res://scenes/ui/hero_select.tscn`)

```
CanvasLayer (HeroSelectUI)
└── Control (Root - Full Rect)
    ├── TextureRect (BackgroundVignette)
    ├── VBoxContainer (LayoutVertical - Margins: 30)
    │   ├── HBoxContainer (HeaderTop)
    │   │   ├── Button (BtnBack: "<- Voltar")
    │   │   ├── Label (Title: "SELEÇÃO DE HERÓIS — DUELO 1v1", Size: 32)
    │   │   └── Label (SelectionTimer: "TEMPO RESTANTE: 24s", Color: Gold)
    │   ├── HBoxContainer (CombatantsDuelArea - Flags: Expand)
    │   │   ├── PanelContainer (PlayerHeroCard - Left)
    │   │   │   └── VBoxContainer
    │   │   │       ├── SubViewportContainer (HeroPreviewLeft)
    │   │   │       │   └── SubViewport (Camera3D, Light, KnightMeshInstance)
    │   │   │       ├── Label (HeroName: "CAVALEIRO")
    │   │   │       ├── Label (HeroRole: "Tanque / Controle Melee")
    │   │   │       └── GridContainer (StatsGrid - 2 cols)
    │   │   │           ├── Label ("HP: 600") ├── ProgressBar (HPBar)
    │   │   │           ├── Label ("DEF: 30") ├── ProgressBar (DefBar)
    │   │   │           ├── Label ("ATK: 40") ├── ProgressBar (AtkBar)
    │   │   │           ├── Label ("INT: 10") ├── ProgressBar (IntBar)
    │   │   │           └── Label ("AGI: 10") └── ProgressBar (AgiBar)
    │   │   ├── VBoxContainer (CenterSelectorColumn - custom_minimum_size.x = 420)
    │   │   │   ├── Label (Instruction: "ESCOLHA SEU CAMPEÃO")
    │   │   │   ├── HBoxContainer (HeroThumbnailButtons)
    │   │   │   │   ├── TextureButton (BtnPickKnight - KayKit Knight Icon)
    │   │   │   │   └── TextureButton (BtnPickRanger - KayKit Ranger Icon)
    │   │   │   ├── PanelContainer (SkillBreakdownBox)
    │   │   │   │   └── VBoxContainer
    │   │   │   │       ├── Label (SkillsHeader: "HABILIDADES DO HERÓI")
    │   │   │   │       ├── RichTextLabel (SkillQDetail)
    │   │   │   │       ├── RichTextLabel (SkillEDetail)
    │   │   │   │       └── RichTextLabel (SkillRDetail)
    │   │   │   └── Button (BtnLockIn: "CONFIRMAR ESCOLHA (LOCK IN)")
    │   │   └── PanelContainer (EnemyHeroCard - Right)
    │   │       └── VBoxContainer
    │   │           ├── SubViewportContainer (HeroPreviewRight)
    │   │           ├── Label (EnemyName: "Adversário")
    │   │           └── Label (EnemyStatus: "Escolhendo...")
    │   └── HBoxContainer (FooterTips)

```

#### 4. Regras de Integração & Dados

* Ao alternar entre Cavaleiro e Arqueira, o script carrega os recursos serializados `data/heroes/knight.tres` ou `data/heroes/ranger.tres`.

* Os valores de `HP (600 vs 380)`, `DEF (30 vs 10)`, `ATK (40 vs 55)`, `INT (10 vs 15)` e `AGI (10 vs 25)` atualizam as barras em tempo real com tweens dinâmicos.

* O botão `Lock In` despacha o sinal de rede `submit_hero_selection(hero_id)` para o servidor autoritativo.

### TELA 3: In-Game HUD — Fase 1: Preparação & Farm (In-Game HUD — Fase 1)

#### 1. Objetivo & UX

Projetada para suportar a dinâmica dos primeiros 5 minutos de jogo definidos no PRD §3.2 e GDB §5: matar monstros nas bases seguras, coletar baús de equipamentos, subir de nível (1 a 10), alocar pontos de skill e monitorar o surgimento do Rei Esqueleto no centro em 3:30. A interface prioriza o inventário de 4 slots, bônus de sets ativos e o indicador de *Catch-up* de XP.

#### 2. Layout Wireframe (ASCII)

```
+--------------------------------------------------------------------------------------------------+
| [PORTÃO SEGURO: ATIVO]        FASE 1: PREPARAÇÃO [ 03:42 ]             [REI ESQUELETO: 00:12]    |
| (Base Segura Aliada)          Boss surge no centro aos 3:30            Centro Contestado PvP     |
+--------------------------------------------------------------------------------------------------+
|                                                                                                  |
| [BUFF: CATCH-UP +25% XP]                                                   +------------------+  |
| (Ativo: 2 nv atrás)                                                        | MINI-MAPA        |  |
|                                                                            | [Base A]  (Porta)|  |
|                                                                            |     \   /        |  |
|                                                                            |    [CENTRO]      |  |
|                                                                            |    (Boss 3:30)   |  |
|                                                                            |     /   \        |  |
|                                                                            | (Porta)  [Base B]|  |
|                                                                            | Baús: 4/6 Monst:2|  |
|                                                                            +------------------+  |
|                                                                                                  |
| [NOTIFICAÇÃO: "Baú Raro Aberto: Elmo da Guarda (Raro) coletado!"]                                |
|                                                                                                  |
|                               +------------------------------+                                   |
|                               | CAVALEIRO - NÍVEL 4          |                                   |
|                               | HP: 735 / 735 [============] |                                   |
|                               | XP: 180 / 300 [======      ] |                                   |
|                               +------------------------------+                                   |
|   +-----------------------+     +--------------------------+     +---------------------------+   |
|   | EQUIPAMENTOS & SETS   |     | HABILIDADES              |     | CONTROLES RÁPIDOS         |   |
|   | [Arma: Rara (+25 ATK)]|     | [Q] Investida   (Nv 2)   |     | [WASD] Movimentação       |   |
|   | [Elmo: Guarda Raro]   |     | [E] Muralha     (Nv 2)   |     | [LMB]  Ataque Básico      |   |
|   | [Peito: Guarda Comum] |     | [R] Terremoto   [BLOQ 6] |     | [F]    Interagir Baú      |   |
|   | [Bota: Vazio         ]|     |                          |     | [TAB]  Ver Placar Geral   |   |
|   | Set: Guarda (2/3)     |     | [* Ponto Disp: +Q / +E]  |     | [B]    Guia / Bestiário   |   |
|   +-----------------------+     +--------------------------+     +---------------------------+   |
+--------------------------------------------------------------------------------------------------+
| Ping: 32 ms | Perda: 0% | Netfox Tick: 30 | Servidor: Dedicated Docker SP                        |
+--------------------------------------------------------------------------------------------------+

```

#### 3. Hierarquia de Nós Godot 4.7 (`res://scenes/ui/hud_phase1.tscn`)

```
CanvasLayer (HUDPhase1)
└── Control (Root - Full Rect)
    ├── MarginContainer (TopBarMargin - Top Anchor)
    │   └── HBoxContainer (TopBar)
    │       ├── PanelContainer (BaseGateStatus)
    │       │   └── Label (GateText: "PORTÃO BASE: SEGURO")
    │       ├── PanelContainer (TimerCenterBox)
    │       │   └── VBoxContainer
    │       │       ├── Label (PhaseTitle: "FASE 1: PREPARAÇÃO")
    │       │       └── Label (PhaseCountdown: "03:42", Font: 28)
    │       └── PanelContainer (BossSpawnAlert)
    │           └── HBoxContainer
    │               ├── TextureRect (BossIconSkull)
    │               └── Label (BossTimer: "REI ESQUELETO: 00:12")
    ├── MarginContainer (TopRightMargin - Top Right Anchor)
    │   └── VBoxContainer (MapAndObjectives)
    │       ├── PanelContainer (MinimapContainer)
    │       │   └── SubViewportContainer (MinimapView)
    │       └── PanelContainer (LootCounterCard)
    │           └── Label (LootText: "Baús Base: 4/6 | Monstros: 3/5")
    ├── MarginContainer (LeftAlertMargin - Left Center Anchor)
    │   └── PanelContainer (CatchUpBanner - Visible if level <= enemy_level - 2)
    │       └── Label ("BUFF ATIVO: CATCH-UP (+25% XP)")
    ├── MarginContainer (BottomHUDMargin - Bottom Anchor)
    │   └── VBoxContainer (BottomBarGroup)
    │       ├── PanelContainer (HealthAndXPPlate)
    │       │   └── VBoxContainer
    │       │       ├── HBoxContainer (HeroNameAndLevel)
    │       │       │   ├── Label (HeroTitle: "CAVALEIRO")
    │       │       │   └── Label (HeroLevel: "NÍVEL 4")
    │       │       ├── TextureProgressBar (HealthBar - Fill Green)
    │       │       └── ProgressBar (XPProgressBar - Fill Gold)
    │       ├── HBoxContainer (ActionAndEquipmentBar - separation 20)
    │       │   ├── PanelContainer (InventoryEquipmentBox)
    │       │   │   └── VBoxContainer
    │       │   │       ├── HBoxContainer (SlotsRow)
    │       │   │       │   ├── TextureButton (SlotWeapon)
    │       │   │       │   ├── TextureButton (SlotHelmet)
    │       │   │       │   ├── TextureButton (SlotChest)
    │       │   │       │   └── TextureButton (SlotBoots)
    │       │   │       └── Label (SetBonusLabel: "Set Guarda: (2/3)")
    │       │   ├── PanelContainer (SkillsBox)
    │       │   │   └── HBoxContainer (SkillsButtons)
    │       │   │       ├── TextureProgressBar (SkillQ_CD)
    │       │   │       ├── TextureProgressBar (SkillE_CD)
    │       │   │       └── TextureProgressBar (SkillR_CD_Ultimate)
    │       │   └── PanelContainer (SkillUpgradeButtons)
    │       │       └── HBoxContainer
    │       │           ├── Button (BtnLevelUpQ: "+Q")
    │       │           └── Button (BtnLevelUpE: "+E")
    └── PanelContainer (RespawnOverlay - Visible on Phase 1 Death)
        └── Label ("VOCÊ FOI ABATIDO NO CENTRO! RENASCENDO NA BASE EM: 07s")

```

#### 4. Elementos Chave & Regras de Comportamento

* **Barra de XP:** Vinculada à tabela de XP do GDB §3.2 (Nível 4 requer 440 acumulado). A cada level up, aciona partícula de brilho dourado e libera botões `+Q` e `+E` (ou `+R` no nível 6).

* **Slots de Equipamento:** Borda com cor dinâmica da raridade (Comum = Branco, Raro = Azul `#2563EB`, Épico = Roxo `#9333EA`). Tooltip rico ao passar o mouse ou segurar tecla.

* **Temporizador do Boss:** Quando o relógio global atinge 03:30, a caixa do Boss pisca em vermelho/dourado e toca anúncio sonoro global: *"O Rei Esqueleto despertou no centro!"*.

### TELA 4: In-Game HUD — Fase 2: Confronto & Zona (In-Game HUD — Fase 2)

#### 1. Objetivo & UX

Aos 5:00, os portões caem e a interface se transforma: o foco migra de farm para **confronto direto, controle da zona mortal e meta de 5 kills** (GDB §7). A HUD destaca a contagem regressiva da zona, a taxa de dano fora do círculo (1% a 5% HP/s), o placar de kills do duelo e o aviso crítico aos 9:00 ("Morte Súbita — Respawn Desligado").

#### 2. Layout Wireframe (ASCII)

```
+--------------------------------------------------------------------------------------------------+
| [PORTÕES CAÍDOS!]        FASE 2: CONFRONTO FINAL [ 02:15 ]         [META DE KILLS: 5]            |
| PLACAR 1v1:  [VOCÊ: CAVALEIRO] ( 3 )   x   ( 2 ) [OPONENTE: ARQUEIRA]                            |
+--------------------------------------------------------------------------------------------------+
|                                                                                                  |
| [!!! ALERTA DE ZONA !!!]                                                   +------------------+  |
| RAIO: 50% (17.5u)                                                          | MINI-MAPA        |  |
| Dano Fora: 3.0% HP/s                                                       |   /----------\   |  |
| Próximo Encolhimento: 00:45                                                |  /   (ZONA)   \  |  |
|                                                                            | |   [P1]  [P2] | |  |
|                                                                            |  \   Raio 50% /  |  |
|                                                                            |   \----------/   |  |
|                                                                            +------------------+  |
|                                                                                                  |
| [EFEITO VISUAL: BORDAS DA TELA VERMELHAS PULSANTES SE ESTIVER FORA DA ZONA]                      |
|                                                                                                  |
|                               +------------------------------+                                   |
|                               | CAVALEIRO - NÍVEL 9          |                                   |
|                               | HP: 840 / 1150 [===========] |                                   |
|                               | SET GUARDA 3/3 ATIVO (+15%HP)|                                   |
|                               +------------------------------+                                   |
|   +-----------------------+     +--------------------------+     +---------------------------+   |
|   | EQUIPAMENTOS FINAIS   |     | HABILIDADES              |     | STATUS DO RESPAWN         |   |
|   | [Arma: Épica (Fúria)] |     | [Q] Investida   (Nv 5)   |     | [ ATIVO: 6.0s ]           |   |
|   | [Elmo: Guarda Épico]  |     | [E] Muralha     (Nv 3)   |     |                           |   |
|   | [Peito: Guarda Raro]  |     | [R] Terremoto   (Nv 1)   |     | (Desativa aos 04:00 da F2 |   |
|   | [Bota: Guarda Raro]   |     | CDR Efetivo: 18.5%       |     |  -> Morte Súbita)         |   |
|   | Set: Guarda (3/3) ON  |     +--------------------------+     +---------------------------+   |
+--------------------------------------------------------------------------------------------------+
| VENCERÁ QUEM ATINGIR 5 KILLS OU SOBREVIVER AO COLAPSO TOTAL DA ZONA                              |
+--------------------------------------------------------------------------------------------------+

```

#### 3. Hierarquia de Nós Godot 4.7 (`res://scenes/ui/hud_phase2.tscn`)

```
CanvasLayer (HUDPhase2)
└── Control (Root - Full Rect)
    ├── ColorRect (ZoneDamageVignette - ShaderMaterial de Pulso Vermelho nas Bordas)
    ├── MarginContainer (TopHeaderGroup - Top Anchor)
    │   └── VBoxContainer
    │       ├── PanelContainer (KillScoreboardBanner)
    │       │   └── HBoxContainer (ScoreRow - Centered)
    │       │       ├── Label (P1_Name: "CAVALEIRO (VOCÊ)", Color: Green)
    │       │       ├── Label (P1_Score: "3", Font: 36, Color: Gold)
    │       │       ├── Label (VS_Label: "VS", Font: 20)
    │       │       ├── Label (P2_Score: "2", Font: 36, Color: Crimson)
    │       │       ├── Label (P2_Name: "ARQUEIRA (INIMIGO)", Color: Crimson)
    │       │       └── VSeparator
    │       │       └── Label (KillTarget: "META: 5 KILLS")
    │       └── HBoxContainer (ZoneStatusSubBar)
    │           ├── Label (ZoneTimer: "TEMPO DA FASE 2: 02:15")
    │           ├── Label (ZoneRadiusText: "ZONA: 50% (Raio 17.5u)")
    │           └── Label (ZoneDPS: "DANO EXTERNO: 3.0%/s")
    ├── MarginContainer (RightZoneMap - Top Right)
    │   └── VBoxContainer
    │       ├── PanelContainer (MinimapZoneRadar)
    │       │   └── TextureRect (MapCircleDisplay - Círculo Branco Seguro vs Vermelho Mortal)
    │       └── PanelContainer (RespawnStateBox)
    │           └── Label (RespawnInfo: "Respawn Ativo: 6.0s\nMorte Súbita em: 01:45")
    ├── MarginContainer (SuddenDeathAlert - Center - Default Invisible)
    │   └── Label (SuddenDeathBanner: "ATENÇÃO: MORTE SÚBITA ATIVA!\nRESPAWN DESLIGADO", Font: 42)
    └── MarginContainer (BottomCombatGroup - Bottom Anchor)
        └── VBoxContainer
            ├── PanelContainer (PlayerCombatPlate)
            │   └── HBoxContainer
            │       ├── TextureProgressBar (HealthBarBig)
            │       └── Label (SetBonusIndicator: "SET GUARDA 3/3 (+15% HP / +10 DEF)")
            └── HBoxContainer (SkillsAndItemsActive)
                ├── PanelContainer (FinalItemsRow)
                └── PanelContainer (CombatSkillsReady)

```

#### 4. Feedbacks Visuais & Dinâmica da Zona

* **Shader de Vinheta de Dano:** Quando a posição do jogador (`Vector3`) estiver fora do raio atual da zona gerenciada pelo servidor, a tela ganha uma vinheta avermelhada pulsante proporcional ao dano por segundo.

* **Transição de 5s aos 5:00:** Banner cinemático central `OS PORTÕES DA ARENA CAÍRAM! PREPARE-SE PARA A BATALHA!` desce com fade e shake de tela.

* **Desligamento de Respawn (9:00 de partida / 4:00 da Fase 2):** Efeito estroboscópico de alerta vermelho com texto `MORTE SÚBITA: QUEM MORRER ESTÁ FORA!`.

### TELA 5: Guia & Bestiário (Guia & Bestiário — Monstros e Equipamentos)

#### 1. Objetivo & UX

Enciclopédia in-game consultável no Lobby ou durante o jogo (tecla `B` na Fase 1). Apresenta a ficha técnica completa dos 5 monstros da fatia vertical definidos no PRD §5 e GDB §5.1, ensinando o jogador casual a planejar suas rotas de farm nas bases e calcular o risco de invadir o centro contestado.

#### 2. Layout Wireframe (ASCII)

```
+--------------------------------------------------------------------------------------------------+
| [VOLTAR AO MENU]              GUIA DE COMBATE — BESTIÁRIO DA ARENA               [FILTRO: TODOS] |
+--------------------------------------------------------------------------------------------------+
| LISTA DE MONSTROS:         DETALHES DO MONSTRO SELECIONADO:                                      |
| +------------------------+ +-------------------------------------------------------------------+ |
| | [X] Esqueleto (T1)     | | REI ESQUELETO (CHEFE DO CENTRO)                       [TIER: BOSS]| |
| | [ ] Esqueleto Guerreiro| | "O soberano caído que guarda os tesouros épicos da arena."        | |
| | [ ] Esqueleto Mago (T2)| +---------------------------------+---------------------------------+ |
| | [ ] Golem de Pedra (T3)| | VISUALIZAÇÃO 3D (SubViewport):  | ATRIBUTOS DE COMBATE (GDB §5.1):| |
| | [ ] Rei Esqueleto(BOSS)| |                                 | HP Total:       2400            | |
| +------------------------+ |     [MODELO 3D KAYKIT]          | Dano / Golpe:   75 (AoE)        | |
|                            |     (Com coroa dourada,         | Intervalo Atq:  1.4 segundos    | |
| ESTATÍSTICAS DA ARENA:     |      animação Idle)             | XP Concedido:   550 XP          | |
| - Monstros por Base: 5     |                                 | Momento Spawn:  3:30 (Fase 1)   | |
| - Monstros Centro: 5       |                                 | Ocorrência:     1 por partida   | |
| - Total XP no Centro: 1260 | +---------------------------------+---------------------------------+ |
| - Drop Épico: 100% no Boss | | DROPS GARANTIDOS:               | DICAS TÁTICAS DE DUELO:         | |
|                            | | - 1x Item Épico Aleatório       | - Evite enfrentá-lo com < 70% HP| |
|                            | | - 550 XP (Garante 1 a 2 níveis) | - Atordoa com Terremoto (R)     | |
|                            | | - Controle da Rota Central      | - Cuidado com emboscadas!       | |
|                            +-----------------------------------+---------------------------------+ |
+--------------------------------------------------------------------------------------------------+
| Atalhos: [Seta Cima/Baixo] Navegar   [ESC] Fechar Guia                                            |
+--------------------------------------------------------------------------------------------------+

```

#### 3. Hierarquia de Nós Godot 4.7 (`res://scenes/ui/bestiary_screen.tscn`)

```
CanvasLayer (BestiaryUI)
└── Control (Root - Full Rect)
    ├── Panel (DarkBackdrop - Color: BG_SURFACE_DARK)
    ├── VBoxContainer (ContentLayout - Margins: 30)
    │   ├── HBoxContainer (HeaderBar)
    │   │   ├── Button (BtnBack: "<- Voltar")
    │   │   ├── Label (Title: "GUIA & BESTIÁRIO DA ARENA", Font: 32)
    │   │   └── OptionButton (FilterDropdown: "Todos", "Bases", "Centro")
    │   ├── HBoxContainer (SplitBody - Flags: Expand)
    │   │   ├── PanelContainer (MonsterListContainer - custom_minimum_size.x = 360)
    │   │   │   └── VBoxContainer (MonsterCardsVBox)
    │   │   │       ├── Button (BtnSelectSkeletonT1)
    │   │   │       ├── Button (BtnSelectSkeletonWarriorT2)
    │   │   │       ├── Button (BtnSelectSkeletonMageT2)
    │   │   │       ├── Button (BtnSelectStoneGolemT3)
    │   │   │       └── Button (BtnSelectSkeletonKingBoss - Purple Border)
    │   │   └── PanelContainer (MonsterDetailCard - Flags: Expand)
    │   │       └── VBoxContainer
    │   │           ├── HBoxContainer (MonsterTitleRow)
    │   │           │   ├── Label (SelectedMonsterName: "REI ESQUELETO")
    │   │           │   └── Label (MonsterTierBadge: "TIER: BOSS", Color: Purple)
    │   │           ├── Label (MonsterFlavorText: "O soberano caído que guarda...")
    │   │           ├── HBoxContainer (DisplayAndStatsRow)
    │   │           │   ├── SubViewportContainer (Monster3DPreview)
    │   │           │   │   └── SubViewport (Camera3D, DirectionalLight3D, MonsterMesh)
    │   │           │   └── GridContainer (StatsGrid - 2 cols)
    │   │           │       ├── Label ("Vida Máxima:") ├── Label ("2400 HP")
    │   │           │       ├── Label ("Dano Médio:") ├── Label ("75 (AoE + Knockback)")
    │   │           │       ├── Label ("Cadência:") ├── Label ("1.4 s")
    │   │           │       ├── Label ("XP:") ├── Label ("550 XP")
    │   │           │       └── Label ("Surge em:") ├── Label ("3:30 de Jogo")
    │   │           ├── HSeparator
    │   │           └── HBoxContainer (LootAndStrategy)
    │   │               ├── VBoxContainer (DropsColumn)
    │   │               │   ├── Label ("Tabela de Loot:")
    │   │               │   └── RichTextLabel (DropItemsDetails)
    │   │               └── VBoxContainer (StrategyColumn)
    │   │                   ├── Label ("Estratégia Recomendada:")
    │   │                   └── RichTextLabel (StrategyNotes)
    └── HBoxContainer (FooterNavigation)

```

#### 4. Dados Integrados do GDB

* **Esqueleto (T1):** Base Segura, 160 HP, 14 dano, 35 XP, 8 unidades no mapa.

* **Esqueleto Guerreiro (T2):** Base/Centro, 360 HP, 28 dano, 85 XP, 4 unidades.

* **Esqueleto Mago (T2):** Centro, 260 HP, 38 dano ranged (7u), 80 XP, 2 unidades.

* **Golem de Pedra (T3):** Centro, 680 HP, 50 dano AoE, 190 XP, 2 unidades.

* **Rei Esqueleto (Boss):** Centro, 2400 HP, 75 dano AoE + Knockback, 550 XP, drop épico 100%.

### TELA 6: Guia & Forja / Equipamentos & Sets (Guia & Forja — 12 Equipamentos e Sets)

#### 1. Objetivo & UX

Apresenta o ecossistema de equipamentos da fatia vertical (GDB §6). Permite ao jogador inspecionar os 12 itens distribuídos nos 4 slots corporais (**Arma, Elmo, Peitoral, Botas**), entender a progressão pelas 3 raridades (Comum, Rara e Épica) e simular interativamente o impacto dos **Bônus de Conjunto (Guarda vs Caçador)** nos atributos finais do Cavaleiro ou da Arqueira.

#### 2. Layout Wireframe (ASCII)

```
+--------------------------------------------------------------------------------------------------+
| [VOLTAR]                    FORJA & CATÁLOGO DE EQUIPAMENTOS (12 ITENS)          [HERÓI: CAVALEIRO]|
+--------------------------------------------------------------------------------------------------+
| CATÁLOGO DE ITENS:                              SIMULADOR DE CONJUNTOS & ATRIBUTOS:              |
| +---------------------------------------------+ +----------------------------------------------+ |
| | ARMAS (Escala ATK):                         | | SLOTS EQUIPADOS ATUALMENTE:                  | |
| | [ Arma Comum (+12) ] [ Arma Rara (+25) ]    | | [ Arma: Épica (Fúria)                      ] | |
| | [ Arma Épica: Fúria (+45 ATK, +6% HP Dano) ]| | [ Elmo: Guarda Raro (+15 DEF, +5 INT)      ] | |
| |                                             | | [ Peitoral: Guarda Raro (+110 HP, +12 DEF) ] | |
| | CONJUNTO GUARDA (Defesa & Sobrevivência):   | | [ Botas: Guarda Raro (+10% AGI, +5 DEF)    ] | |
| | Elmo:    [Comum] [Raro] [Épico]             | +----------------------------------------------+ |
| | Peitoral:[Comum] [Raro] [Épico]             | | BÔNUS DE SET ATIVO:                          | |
| | Botas:   [Comum] [Raro] [Épico]             | | [X] GUARDA (3/3): +15% HP MÁXIMO & +10 DEF   | |
| |                                             | | [ ] CAÇADOR (0/3): Sem bônus                 | |
| | CONJUNTO CAÇADOR (Ataque & Velocidade):     | +----------------------------------------------+ |
| | Elmo:    [Comum] [Raro] [Épico]             | | IMPACTO TOTAL NOS ATRIBUTOS (Nv 10 Base):    | |
| | Peitoral:[Comum] [Raro] [Épico]             | | HP:   1005 -> 1397 (+392 HP com bônus set)   | |
| | Botas:   [Comum] [Raro] [Épico]             | | DEF:  57   -> 99   (Mitigação: 49.7%)        | |
| +---------------------------------------------+ | ATK:  71.5 -> 116.5 (Dano Base + Arma)       | |
|                                                 | INT:  19   -> 24   (CDR Efetivo: 12.0%)      | |
| REGRAS DE SAQUE (PRD §6):                       | AGI:  19   -> 20.9 (Velocidade: +10%)        | |
| - Substituição automática se raridade > atual | +----------------------------------------------+ |
| - Tecla [F] segurada por 0.4s confirma troca  | [ TESTAR COMBINAÇÃO ]    [ LIMPAR SIMULAÇÃO ]  | |
+--------------------------------------------------------------------------------------------------+

```

#### 3. Hierarquia de Nós Godot 4.7 (`res://scenes/ui/forge_catalog_screen.tscn`)

```
CanvasLayer (ForgeCatalogUI)
└── Control (Root - Full Rect)
    ├── Panel (Backdrop - BG_SURFACE_DARK)
    ├── VBoxContainer (MainVertical - Margins: 30)
    │   ├── HBoxContainer (HeaderBar)
    │   │   ├── Button (BtnBack: "<- Menu")
    │   │   ├── Label (Title: "GUIA & FORJA — 12 EQUIPAMENTOS E SETS", Font: 32)
    │   │   └── OptionButton (HeroSelector: "Cavaleiro", "Arqueira")
    │   ├── HBoxContainer (SplitColumns - separation 30)
    │   │   ├── ScrollContainer (CatalogScroll - Width 700)
    │   │   │   └── VBoxContainer (CatalogSections)
    │   │   │       ├── Label (SecWeapons: "ARMAS (BÔNUS DE ATAQUE)")
    │   │   │       ├── HBoxContainer (WeaponsRow)
    │   │   │       │   ├── Button (BtnWeaponCommon: "+12 ATK")
    │   │   │       │   ├── Button (BtnWeaponRare: "+25 ATK")
    │   │   │       │   └── Button (BtnWeaponEpic: "+45 ATK + Fúria", Color: Purple)
    │   │   │       ├── Label (SecGuard: "CONJUNTO GUARDA (DEFESA / HP)")
    │   │   │       ├── GridContainer (GuardGrid - 3 cols)
    │   │   │       ├── Label (SecHunter: "CONJUNTO CAÇADOR (ATAQUE / AGI)")
    │   │   │       └── GridContainer (HunterGrid - 3 cols)
    │   │   └── VBoxContainer (SimulatorPanel - Flags: Expand)
    │   │       ├── PanelContainer (EquippedSlotsCard)
    │   │       │   └── GridContainer (SlotsEquipped - 2x2)
    │   │       ├── PanelContainer (SetBonusCard)
    │   │       │   └── VBoxContainer
    │   │       │       ├── Label (SetBonusTitle: "STATUS DOS CONJUNTOS")
    │   │       │       ├── Label (GuardStatus: "Guarda: 3/3 (ATIVO: +15% HP, +10 DEF)")
    │   │       │       └── Label (HunterStatus: "Caçador: 0/3 (INATIVO)")
    │   │       ├── PanelContainer (StatPreviewCard)
    │   │       │   └── VBoxContainer (AttributeCalculatedBars)
    │   │       └── HBoxContainer (SimButtons)
    │   │           ├── Button (BtnResetSim: "Limpar")
    │   │           └── Button (BtnApplyBuild: "Definir como Recomendado")
    └── HBoxContainer (FooterBar)

```

#### 4. Fórmulas Aplicadas em Tempo Real

* **Cálculo de HP com Set Guarda:** $ext{HP Total} = (	ext{HP Base} + \sum 	ext{HP Itens}) 	imes 1.15$

* **Cálculo de DEF com Set Guarda:** $ext{DEF Total} = 	ext{DEF Base} + \sum 	ext{DEF Itens} + 10$

* **Passiva da Arma Épica (*Fúria*):** Tooltip exibe: *"Ataques básicos causam +6% do HP restante do alvo como dano físico bônus."*

### TELA 7: Fim de Partida / Vitória & Derrota (Fim de Partida — Resumo do Duelo 1v1)

#### 1. Objetivo & UX

Tela de desfecho com grande impacto emocional. Apresenta o banner cinematográfico de **VITÓRIA** ou **DERROTA**, a razão exata do desfecho (Meta de 5 Kills atingida ou Eliminação na Morte Súbita da Zona), a duração total e uma tabela comparativa lado a lado com todas as métricas do duelo 1v1 para análise do jogador.

#### 2. Layout Wireframe (ASCII)

```
+--------------------------------------------------------------------------------------------------+
|                                                                                                  |
|                             * * * * * * * * * * * * * * * * * *                                  |
|                             *          V I T Ó R I A          *                                  |
|                             * * * * * * * * * * * * * * * * * *                                  |
|                                                                                                  |
|                      CONDIÇÃO: META DE 5 KILLS ATINGIDA NA FASE 2                                |
|                              DURAÇÃO DA PARTIDA: 07m 48s                                         |
|                                                                                                  |
|   VOCÊ: SirRodrigo (CAVALEIRO)                           OPONENTE: ShadowHunter (ARQUEIRA)       |
|   +------------------------------------+                 +------------------------------------+  |
|   | ESTATÍSTICA                        |     COMPARAÇÃO  | ESTATÍSTICA                        |  |
|   +------------------------------------+-----------------+------------------------------------+  |
|   | Kills:              5              |      [ > ]      | Kills:              3              |  |
|   | Mortes:             3              |      [ < ]      | Mortes:             5              |  |
|   | Nível Final:        9              |      [ > ]      | Nível Final:        8              |  |
|   | Dano em Heróis:     4,250          |      [ > ]      | Dano em Heróis:     3,820          |  |
|   | Dano Sofrido:       4,800          |      [ = ]      | Dano Sofrido:       4,900          |  |
|   | Monstros Abatidos:  7              |      [ > ]      | Monstros Abatidos:  4              |  |
|   | Baús Abertos:       5              |      [ = ]      | Baús Abertos:       5              |  |
|   | Rei Esqueleto:      Abatido (Drop) |      [ ★ ]      | Rei Esqueleto:      Não participou |  |
|   | Conjunto Ativo:     Guarda 3/3     |                 | Conjunto Ativo:     Caçador 2/3    |  |
|   +------------------------------------+                 +------------------------------------+  |
|                                                                                                  |
|          [ JOGAR NOVAMENTE (NOVA FILA) ]                     [ VOLTAR AO LOBBY PRINCIPAL ]       |
+--------------------------------------------------------------------------------------------------+
| Partida salva no Histórico Local | Hash de Auditoria M4: #a8f9-42b1-998e                         |
+--------------------------------------------------------------------------------------------------+

```

#### 3. Hierarquia de Nós Godot 4.7 (`res://scenes/ui/match_end_screen.tscn`)

```
CanvasLayer (MatchEndUI)
└── Control (Root - Full Rect)
    ├── ColorRect (DramaticBackdrop - Dark with radial gradient)
    ├── CPUParticles2D (VictoryConfetti - or DefeatEmbers)
    ├── VBoxContainer (CenterLayout - Anchors: Center, Width 1100)
    │   ├── Label (MatchOutcomeTitle: "VITÓRIA", Font: 56, Color: Gold)
    │   ├── Label (VictoryReason: "META DE 5 KILLS ATINGIDA NA FASE 2", Font: 20)
    │   ├── Label (MatchDuration: "Duração Total: 07:48 | Fase 1: 05:00 | Fase 2: 02:48")
    │   ├── HSeparator
    │   ├── HBoxContainer (DuelComparisonRow)
    │   │   ├── PanelContainer (WinnerStatsCard - Left, Border: Gold)
    │   │   │   └── VBoxContainer
    │   │   │       ├── Label (WinnerHeader: "VOCÊ (CAVALEIRO)")
    │   │   │       └── GridContainer (StatsLeftGrid - 2 cols)
    │   │   ├── PanelContainer (MidCompareColumn - Width 80)
    │   │   │   └── VBoxContainer (VisualCompareIndicators: ">", "<", "=")
    │   │   └── PanelContainer (LoserStatsCard - Right, Border: Crimson)
    │   │       └── VBoxContainer
    │   │           ├── Label (LoserHeader: "OPONENTE (ARQUEIRA)")
    │   │           └── GridContainer (StatsRightGrid - 2 cols)
    │   ├── HSeparator
    │   └── HBoxContainer (ActionButtonsRow - Centered, separation 40)
    │       ├── Button (BtnPlayAgain: "JOGAR NOVAMENTE")
    │       └── Button (BtnBackLobby: "VOLTAR AO LOBBY")
    └── Label (AuditFooterNote: "Audit Token: 1v1-M4-VALIDATED")

```

#### 4. Animação de Entrada & Áudio

* **Entrada da Vitória:** O título `VITÓRIA` surge com escala `1.5 -> 1.0` via `Tween` (`TRANS_BOUNCE, EASE_OUT`) em 0.6s, acompanhado por trompetes e explosão de partículas douradas.

* **Entrada da Derrota:** O título `DERROTA` cai lentamente com vinheta escura, som de sino fúnebre e desaturação do fundo 3D da arena.

### TELA 8: Configurações & Diagnóstico de Rede (Ajustes & Diagnóstico de Rede — PC / Netfox Godot 4.7)

#### 1. Objetivo & UX

Projetada para cumprir os requisitos técnicos rigorosos do PRD §8.3, §8.5 e Marco M0/M4. Reúne em abas limpas as configurações de **Vídeo** (resoluções PC, taxa de quadros, modo fullscreen), **Áudio** (canais independentes), **Controles** (teclado/mouse e gamepad com sensibilidade) e uma aba especializada de **Rede & Netfox** capaz de diagnosticar e auditar em tempo real latência, jitter, perda de pacotes, ticks do servidor e buffer de predição/rollback.

#### 2. Layout Wireframe (ASCII)

```
+--------------------------------------------------------------------------------------------------+
| [VOLTAR]                      CONFIGURAÇÕES & TELEMETRIA DE REDE               [RESTAURAR PADRÃO]|
+--------------------------------------------------------------------------------------------------+
| [ VÍDEO & GRÁFICOS ]  [ ÁUDIO & SONS ]  [ CONTROLES (PC/PAD) ]  [ * REDE & NETFOX (DIAGNÓSTICO) *|
+--------------------------------------------------------------------------------------------------+
| PAINEL ATIVO: REDE & NETFOX (GODOT 4.7 HEADLESS DEDICADO)                                        |
|                                                                                                  |
| TELEMETRIA EM TEMPO REAL:                       CONFIGURAÇÕES DO NETCODE (NETFOX):               |
| +---------------------------------------------+ +----------------------------------------------+ |
| | Servidor Conectado:   VPS-SP (177.136.x.x)  | | Tick Rate do Servidor:  30 Hz (Fixo)         | |
| | Porta UDP / ENet:     7005                  | | Predição de Movimento:  [X] Ativada (Client) | |
| | Ping / RTT Atual:     32 ms  [ÓTIMO]        | | Compensação de Lag:     [X] Ativada (Hits)   | |
| | Jitter da Conexão:    1.8 ms                | | Buffer de Interpolação: [ 2 Ticks ]          | |
| | Perda de Pacotes:     0.0 %                 | | Limite de Rollback:     [ 8 Frames ]         | |
| | Dessincronizações:    0 detectadas          | | Renderizador Godot:     Forward+ (Desktop)   | |
| +---------------------------------------------+ +----------------------------------------------+ |
|                                                                                                  |
| GRÁFICO HISTÓRICO DE LATÊNCIA (ÚLTIMOS 60 SEGUNDOS):                                             |
| 100ms |                                                                                          |
|  80ms |--------------------------- TETO CRITÉRIO M4 (80ms) ------------------------------------- |
|  40ms |                                                                                          |
|  20ms | ~~~~/\~~~~~/\~~~~~~~~~~~~~~~~~~~~~~~~~~~ Média: 31.4 ms                                  |
|   0ms +----------------------------------------------------------------------------------------+ |
|       0s                                         30s                                        60s  |
|                                                                                                  |
| [ TESTAR CONEXÃO AGORA ]   [ EXPORTAR LOG DE REDE (.TXT) ]       [ APLICAR AJUSTES ]             |
+--------------------------------------------------------------------------------------------------+

```

#### 3. Hierarquia de Nós Godot 4.7 (`res://scenes/ui/settings_network_screen.tscn`)

```
CanvasLayer (SettingsNetworkUI)
└── Control (Root - Full Rect)
    ├── Panel (Backdrop - BG_SURFACE_DARK)
    ├── VBoxContainer (MainContainer - Margins: 30)
    │   ├── HBoxContainer (HeaderTop)
    │   │   ├── Button (BtnBack: "<- Voltar")
    │   │   ├── Label (Title: "CONFIGURAÇÕES DO SISTEMA", Font: 32)
    │   │   └── Button (BtnResetDefaults: "Restaurar Padrões")
    │   ├── TabContainer (SettingsTabs - StyleBoxFlat TabBar)
    │   │   ├── MarginContainer (TabVideo - Resolução, Modo Janela, V-Sync, FPS Cap)
    │   │   ├── MarginContainer (TabAudio - Sliders: Master, Música, SFX, Locutor)
    │   │   ├── MarginContainer (TabControls - Mapeamento de Teclas WASD, Q, E, R, F, Gamepad)
    │   │   └── MarginContainer (TabNetfox - Diagnóstico de Rede)
    │   │       └── VBoxContainer
    │   │           ├── HBoxContainer (TelemetryRow)
    │   │           │   ├── PanelContainer (LiveTelemetryBox - Left)
    │   │           │   │   └── GridContainer (StatsGrid - 2 cols)
    │   │           │   │       ├── Label ("Servidor Ativo:") ├── Label ("VPS Docker Headless")
    │   │           │   │       ├── Label ("Ping Médio:") ├── Label ("32 ms", Color: Green)
    │   │           │   │       ├── Label ("Jitter:") ├── Label ("1.8 ms")
    │   │           │   │       └── Label ("Perda de Pacotes:") ├── Label ("0.0%")
    │   │           │   └── PanelContainer (NetfoxConfigBox - Right)
    │   │           │       └── VBoxContainer
    │   │           │           ├── CheckBox (CheckPrediction: "Client-side Prediction")
    │   │           │           ├── CheckBox (CheckLagComp: "Lag Compensation")
    │   │           │           └── HSlider (SliderInterpolationBuffer)
    │   │           ├── PanelContainer (LatencyGraphBox - Height 180)
    │   │           │   └── CustomControl (LatencyPlotter2D - desenha curva via _draw())
    │   │           └── HBoxContainer (NetActionButtons)
    │   │               ├── Button (BtnPingTest: "Testar Conexão")
    │   │               ├── Button (BtnExportNetLog: "Exportar Log de Rede")
    │   │               └── Button (BtnApplySettings: "Salvar Ajustes")
    └── HBoxContainer (FooterStatus)

```

#### 4. Integração com Netfox e Critérios de M4

* Monitora os valores retornados pelo addon `netfox` no Godot 4.7:

  * `NetworkTime.rtt` (Round-Trip Time convertido para milissegundos).

  * `NetworkTime.jitter` (Desvio padrão dos ticks de chegada).

  * Alerta visual caso o ping ultrapasse $80	ext{ ms}$ (limite fixado no PRD §9.2 como critério de aceitação de playtest no Brasil).

### TELA 9: Histórico de Duelos & Auditoria M4 (Histórico de Partidas — Duelos 1v1 & Auditoria M4)

#### 1. Objetivo & UX

O painel de Histórico e Auditoria M4 atende diretamente ao objetivo do dev solo de validar o protótipo contra as 4 metas formais de sucesso do Marco M4 (PRD §9.2):

1. 100% das partidas terminando em $\le 10	ext{ min}$.

2. Ping médio $\le 80	ext{ ms}$ no Brasil sem teleportes.

3. Taxa de vitória de quem fechou a Fase 1 na liderança de nível em $< 75\%$ (controle de snowball).

4. Coleta de telemetria para relatórios de playtest com 10+ jogadores.

#### 2. Layout Wireframe (ASCII)

```
+--------------------------------------------------------------------------------------------------+
| [VOLTAR]                   HISTÓRICO DE DUELOS & AUDITORIA M4                    [EXPORTAR CSV]  |
+--------------------------------------------------------------------------------------------------+
| PAINEL DE AUDITORIA DO MARCO M4 (PLAYTEST TELEMETRY):                                            |
| +----------------------------------------------------------------------------------------------+ |
| | TOTAL PARTIDAS: 24   | DURAÇÃO MÉDIA: 07:35  | PING MÉDIO: 34.2 ms | SNOWBALL RATE: 62.5%    | |
| | META <= 10 min: 100% | STATUS: [ APROVADO ]  | META <= 80ms: [ OK ]| META < 75%:    [ OK ]   | |
| +----------------------------------------------------------------------------------------------+ |
|                                                                                                  |
| HISTÓRICO DE PARTIDAS RECENTES (ÚLTIMOS DUELOS 1v1):                                             |
| +----------------------------------------------------------------------------------------------+ |
| | DATA/HORA        | HERÓI   | VS INIMIGO | RESULTADO | DURAÇÃO | KILLS | PING MÉD | AUDITORIA M4| |
| +------------------+---------+------------+-----------+---------+-------+----------+-------------+ |
| | 08/10/26 19:42   | Cavaleiro| Arqueira  | VITÓRIA   | 07m 48s | 5 - 3 | 32 ms    | CONFORME    | |
| | 08/10/26 19:25   | Arqueira | Cavaleiro | DERROTA   | 08m 10s | 2 - 5 | 29 ms    | CONFORME    | |
| | 08/10/26 18:50   | Cavaleiro| Cavaleiro | VITÓRIA   | 09m 04s | 5 - 4 | 36 ms    | MORTE SÚBITA| |
| | 08/10/26 18:15   | Arqueira | Arqueira  | VITÓRIA   | 06m 52s | 5 - 1 | 31 ms    | CONFORME    | |
| +----------------------------------------------------------------------------------------------+ |
|                                                                                                  |
| DETALHE DA PARTIDA SELECIONADA (#a8f9-42b1):                                                     |
| - Líder de Nível na Fase 1: Cavaleiro (Nv 6) vs Arqueira (Nv 4) -> Vencedor Final: Cavaleiro    |
| - Boss Rei Esqueleto: Disputado aos 3:30 (Abatido pelo Cavaleiro)                               |
| - Desfecho da Zona: Fechamento em 50% (Raio 17.5u)                                               |
| - Total de Teleportes / Dessincronizações: ZERO (netfox rollback suave)                         |
+--------------------------------------------------------------------------------------------------+
| Armazenamento: Local SQLite/JSON + Sincronização HTTP NestJS (/telemetry/matches)                |
+--------------------------------------------------------------------------------------------------+

```

#### 3. Hierarquia de Nós Godot 4.7 (`res://scenes/ui/match_history_m4_screen.tscn`)

```
CanvasLayer (MatchHistoryUI)
└── Control (Root - Full Rect)
    ├── Panel (Backdrop - BG_SURFACE_DARK)
    ├── VBoxContainer (MainLayout - Margins: 30)
    │   ├── HBoxContainer (HeaderBar)
    │   │   ├── Button (BtnBack: "<- Voltar")
    │   │   ├── Label (Title: "HISTÓRICO DE PARTIDAS & AUDITORIA M4", Font: 32)
    │   │   └── Button (BtnExportData: "Exportar Dados Playtest (.CSV)")
    │   ├── PanelContainer (M4KPIAuditCard - Border: Green)
    │   │   └── HBoxContainer (KPIGrid - 4 Colunas Equitativas)
    │   │       ├── VBoxContainer (KPI1: "Duração <= 10 min: 100% [APROVADO]")
    │   │       ├── VBoxContainer (KPI2: "Ping Médio <= 80 ms: 34.2 ms [APROVADO]")
    │   │       ├── VBoxContainer (KPI3: "Snowball Rate < 75%: 62.5% [EQUILIBRADO]")
    │   │       └── VBoxContainer (KPI4: "Teleportes Reportados: 0 [EXCELENTE]")
    │   ├── Label (SubHeaderHistory: "Duelos Recentes 1v1:")
    │   ├── ScrollContainer (HistoryScroll - Flags: Expand)
    │   │   └── Tree (HistoryTableTree - Colunas configuradas via GDScript)
    │   ├── PanelContainer (MatchDeepDiveBox - Height 160)
    │   │   └── RichTextLabel (MatchInspectionDetails)
    └── HBoxContainer (FooterStatus)

```

#### 4. Lógica de Auditoria Automatizada

* **Fórmula do Snowball Rate:**
  \$$	ext{Taxa de Snowball (%)} = \\left(rac{	ext{Partidas onde o Líder de Nível na F1 Venceu}}{	ext{Total de Partidas}} ight) 	imes 100$$

* Se a taxa ultrapassar $75\%$, a caixa de KPI muda automaticamente a cor para Laranja de Alerta, sinalizando a necessidade de rebalancear monstros ou aumentar o bônus de catch-up ($+25\%$).

### TELA 10: Arena & Mapa (Guia da Arena — Vale Rúnico)

> Incluída por decisão do PI em 2026-10-09 (tela informativa do Launcher, MVP3 — F33 / SPEC-033). Conceito visual: `docs/prd/telas/Arena & Mapa — O Vale Rúnico Apocalíptico/`. **Conteúdo e números vêm da SPEC-007 e do GDB**, não do conceito.

#### 1. Objetivo & UX

Tela **somente leitura** que apresenta ao jogador a arena "Vale Rúnico" e as regras dos dois tempos antes da primeira partida: onde fica cada base, o rio e as pontes, a cratera do Rei Esqueleto, os campos de monstros, o mato alto e os baús, e o que muda aos 5:00. Não altera nada no jogo nem no backend.

* **Imagem do mapa:** render da **arena real** (vista de cima/isométrica da arena da SPEC-007), arquivo estático em `shared/assets/ui/arena_map.png`, regerado sempre que a arena mudar. O Launcher **não** carrega cena de arena (regra I9; `ARCHITECTURE-LAUNCHER.md` §1). A arte conceito da pasta acima é a **meta visual** para a evolução de gráficos e texturas da arena (ADR-0005); quando a arena evoluir, o render acompanha.
* **Marcadores (POIs)** sobre a imagem, clicáveis, abrem o card de detalhe: Base A "Ordem", Base B "Ruína", Rio e 2 pontes, Cratera (Rei Esqueleto), Campos Noroeste/Sudeste (monstros T2–T3), Mato alto, Baús.

#### 2. Layout Wireframe (ASCII)

```
+--------------------------------------------------------------------------------------------------+
| [VOLTAR]                         ARENA & MAPA — VALE RÚNICO (1v1)                                |
+--------------------------------------------------------------------------------------------------+
|  Raio 35 u • Base→centro ~6 s • Ponta a ponta ~13 s • 16 baús • 17 monstros                      |
+-----------------------------------------------------------+--------------------------------------+
|  +-----------------------------------------------------+  | FASE 1 • 00:00 – 05:00               |
|  | [RENDER DA ARENA REAL]                              |  | Preparação & Farm                    |
|  |   (A) Base Ordem          (B) Base Ruína            |  | - Portões fechados: base segura      |
|  |        [Rio + Ponte A]   [Cratera: Boss 3:30]       |  | - 6 baús comuns por base, 4 raros    |
|  |   (NO) Campo T2–T3        (SE) Campo T2–T3          |  |   no centro                          |
|  |        [Mato]            [Ponte B]                  |  | - PvP no centro: respawn 8 s,        |
|  +-----------------------------------------------------+  |   não conta kill                     |
|  +-----------------------------------------------------+  | - Aviso do boss 3:00, surge 3:30     |
|  | DETALHE DO MARCADOR SELECIONADO                     |  +--------------------------------------+
|  | Cratera Central — Rei Esqueleto                     |  | FASE 2 • 05:00 – 10:00               |
|  | Surge aos 3:30 • HP 2400 • 1 item épico garantido   |  | Confronto & Zona                     |
|  | 8 pilares, 4 entradas de 4 u; flecha não passa      |  | - Portões caem                       |
|  | entre pilares.                                      |  | - Zona: raio 35 u → 3,5 u em 4:00    |
|  +-----------------------------------------------------+  | - Dano fora: 1% → 5% HP máx/s        |
|                                                           | - Respawn 6 s até 9:00, depois não   |
|                                                           | - Vitória: 5 kills → sobrevivência   |
|                                                           |   → maior % de vida aos 10:00        |
+-----------------------------------------------------------+--------------------------------------+
|                                                                    [ PRATICAR VS BOT ]           |
+--------------------------------------------------------------------------------------------------+
```

#### 3. Hierarquia de Nós Godot 4.7 (`launcher/scenes/screens/arena_map.tscn`)

```
Control (ArenaMapScreen - Full Rect)  # script arena_map_screen.gd
├── PanelContainer (Backdrop - PanelCardSurface)
└── VBoxContainer (MainLayout - Margins: SPACE_XL)
    ├── HBoxContainer (HeaderBar)
    │   ├── Button (BtnBack: "Voltar")
    │   └── Label (Title - LabelH1: "ARENA & MAPA")
    ├── HBoxContainer (FactsBar)                 # números da SPEC-007 / GDB via CatalogService
    ├── HBoxContainer (Body)
    │   ├── VBoxContainer (MapColumn - Expand)
    │   │   ├── AspectRatioContainer (MapFrame)
    │   │   │   ├── TextureRect (MapRender: shared/assets/ui/arena_map.png)
    │   │   │   └── Control (PoiLayer)           # um Button por POI, posição normalizada (0–1)
    │   │   └── PanelContainer (PoiDetail - PanelCardInner)
    │   └── VBoxContainer (RulesColumn - SIZE_SIDE_COL)
    │       ├── PanelContainer (Phase1Card)
    │       └── PanelContainer (Phase2Card)
    └── HBoxContainer (FooterActions)
        └── Button (BtnPractice - ButtonPrimary: "Praticar vs Bot")  # mesma ação do lobby (F25)
```

#### 4. Regras de Conteúdo & Comportamento

* **Fonte dos números:** SPEC-007 (layout, escala, POIs) e GDB §5.1 (monstros), §6.2 (baús), §7.1–7.2 (zona e vitória). Textos e valores lidos de `shared/data` pelo `CatalogService` sempre que existirem lá; nada de número digitado na tela que divirja do GDB (ADR-0004).
* **Navegação:** entrada "ARENA & MAPA" no menu do lobby; `push` a partir do lobby, `Esc`/Voltar = `pop`. "Praticar vs Bot" dispara exatamente a mesma ação do lobby.
* **Estados:** carregando (catálogo) → pronto; imagem ausente → placeholder neutro com o texto "Mapa indisponível" e o resto da tela funcional.
* **Fora desta tela (estava no conceito e não está no PRD/GDB — `FORA-DE-ESCOPO.md`):** torres rúnicas, "Aura do Flagelo", ouro e progressão de ouro, lama −15 %, relevo/depressão da cratera, fog of war/linha de visão, item lendário, alternador de câmera isométrica/FOV, botões "Rotas de Farm" e "Simular Tempestade", grade "24 × 18 / 432 células", travessia "20 s / 8 s" e zona "1,5 % → 6 %" (valem os números do GDB).

## 3. Arquitetura Técnica de UI no Godot 4.7

### 3.1 Estrutura de Diretórios Recomendada

```
res://
├── assets/
│   ├── ui/
│   │   ├── theme_moba.tres         # Tema global com botões, fontes e margins
│   │   ├── fonts/
│   │   │   ├── font_title_bold.ttf
│   │   │   └── font_data_mono.ttf
│   │   ├── styles/
│   │   │   ├── box_slate_normal.tres
│   │   │   ├── box_slate_hover.tres
│   │   │   ├── box_gold_accent.tres
│   │   │   └── box_crimson_danger.tres
│   │   └── icons/
│   │       ├── skills/ (investida.png, muralha.png, terremoto.png, etc.)
│   │       ├── items/  (sword_t1..t3.png, guard_set.png, hunter_set.png)
│   │       └── hud/    (skull_boss.png, minimap_hex.png, ping_icon.png)
├── scenes/
│   └── ui/
│       ├── lobby.tscn
│       ├── hero_select.tscn
│       ├── hud_phase1.tscn
│       ├── hud_phase2.tscn
│       ├── bestiary_screen.tscn
│       ├── forge_catalog_screen.tscn
│       ├── match_end_screen.tscn
│       ├── settings_network_screen.tscn
│       └── match_history_m4_screen.tscn
└── scripts/
    └── ui/
        ├── ui_manager.gd           # Gerenciador global de pilhas de tela e popups
        ├── hud_controller.gd       # Controlador da HUD in-game e troca de fases
        ├── netfox_debugger.gd      # Leitura de telemetria RTT/Jitter da rede
        └── m4_audit_tracker.gd     # Cálculo em tempo real dos KPIs do Marco M4

```

### 3.2 Padrão de Sinais & Eventos (Event-Driven UI)

Para evitar acoplamento direto entre as regras do jogo (`scripts/core/`) e os nós visuais, a interface consome exclusivamente sinais emitidos pelo `MatchController`:

```
# Exemplo de conexões no hud_controller.gd:
func _ready() -> void:
    MatchController.phase_transition_started.connect(_on_phase_transition)
    MatchController.player_level_up.connect(_on_player_level_up)
    MatchController.player_health_changed.connect(_on_health_changed)
    MatchController.item_equipped.connect(_on_item_equipped)
    MatchController.zone_radius_updated.connect(_on_zone_updated)
    MatchController.kill_scored.connect(_on_kill_scored)
    MatchController.match_ended.connect(_on_match_ended)

```

### 3.3 Tabela de Mapeamento dos Controles (PC Keyboard & Gamepad)

| Ação de Entrada (`InputMap`) | Teclado & Mouse | Gamepad (Xbox/PlayStation) | Efeito na Interface | 
| ----- | ----- | ----- | ----- | 
| `move_forward/back/left/right` | `W`, `S`, `A`, `D` | Analógico Esquerdo | Movimenta o Campeão | 
| `primary_attack` | Botão Esquerdo do Mouse | Gatilho Direito (`RT` / `R2`) | Executa Ataque Básico | 
| `skill_q` | Tecla `Q` | Botão Superior Esquerdo (`LB` / `L1`) | Habilidade 1 | 
| `skill_e` | Tecla `E` | Botão Superior Direito (`RB` / `R1`) | Habilidade 2 | 
| `skill_r` | Tecla `R` | Gatilho Esquerdo (`LT` / `L2`) | Ultimate (Nível 6+) | 
| `interact_chest` | Tecla `F` (Segurar 0.4s) | Botão `X` / `Quadrado` | Abre Baú / Troca Item | 
| `open_bestiary` | Tecla `B` | D-Pad Cima | Abre Modal do Guia | 
| `open_scoreboard` | Tecla `Tab` | Botão `View` / `Share` | Mostra Placar Completo | 
| `cancel_menu` | Tecla `Esc` | Botão `B` / `Círculo` | Fecha Janelas / Pausa | 

## 4. Checklist de Verificação e Prontidão de Telas

* \[x\] **Lobby 1v1:** Conexão com backend NestJS, botão de fila casual e treino bot M1.

* \[x\] **Seleção de Heróis:** Exibição 3D do Cavaleiro e da Arqueira com atributos GDB §4.

* \[x\] **HUD Fase 1:** Relógio de 5:00, contador do Rei Esqueleto (3:30), inventário de 4 slots e catch-up.

* \[x\] **HUD Fase 2:** Transição de portões, meta de 5 kills, radar da zona e alerta de Morte Súbita.

* \[x\] **Guia & Bestiário:** 5 monstros da fatia vertical com HP, dano, XP e táticas.

* \[x\] **Guia & Forja:** Catálogo dos 12 itens, raridades e simulação de bônus de sets (Guarda vs Caçador).

* \[x\] **Fim de Partida:** Comparativo estatístico lado a lado, razão de vitória e retorno ao loop.

* \[x\] **Configurações & Rede:** Abas completas com telemetria Netfox em tempo real e gráfico RTT.

* \[ \] **Arena & Mapa:** Render da arena real com marcadores, regras das duas fases pelos números do GDB (F33).

* \[x\] **Histórico & Auditoria M4:** Monitoramento das 4 metas críticas de sucesso (Snowball < 75%, Ping <= 80ms, Tempo <= 10m).

*Fim da Especificação de Design Visual do Launch — Pronto para implementação das cenas em Godot 4.7.*