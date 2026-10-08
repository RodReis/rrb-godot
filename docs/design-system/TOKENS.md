# TOKENS.md — Tokens de design

Fonte: DV §1.2–1.4. Nome do token = nome da constante em `UiTokens` (`shared/ui/theme/tokens.gd`) e nome da cor no `Theme` (`theme_moba.tres`, tipo `Global`).

## 1. Cores

| Token | Hex | `Color` | Uso | Contraste sobre `BG_PANEL` |
|---|---|---|---|---|
| `BG_SURFACE` | `#0D1117` | `Color(0.051, 0.071, 0.090, 0.95)` | fundo de tela, overlays | — |
| `BG_PANEL` | `#161F2E` | `Color(0.086, 0.122, 0.180, 0.90)` | cards, menus | — |
| `BG_CARD` | `#1E293B` | `Color(0.118, 0.161, 0.231, 0.85)` | slots, células | — |
| `GOLD` | `#F59E0B` | `Color(0.961, 0.620, 0.043)` | título, moldura ativa, botão primário | 7,7:1 ✔ |
| `GOLD_BRIGHT` | `#FDE047` | `Color(0.992, 0.878, 0.278)` | destaque, XP/ouro | 12,5:1 ✔ |
| `BLUE` | `#2563EB` | `Color(0.145, 0.388, 0.922)` | ação secundária, INT, set Guarda, raridade rara | 3,2:1 ✘ — **nunca como texto**; só fundo/borda/ícone |
| `CYAN` | `#38BDF8` | `Color(0.220, 0.741, 0.973)` | CDR, rede boa | 7,7:1 ✔ |
| `RED` | `#DC2626` | `Color(0.863, 0.149, 0.149)` | HP inimigo, zona, derrota | 3,4:1 ✘ — texto só ≥ 24 px bold (AA large); senão fundo/borda |
| `GREEN` | `#10B981` | `Color(0.063, 0.725, 0.506)` | HP próprio, vitória, ok | 6,5:1 ✔ |
| `PURPLE` | `#9333EA` | `Color(0.576, 0.200, 0.918)` | épico, boss, ultimate | 3,1:1 ✘ — texto só ≥ 24 px bold; senão fundo/borda |
| `TEXT` | `#F8FAFC` | `Color(0.973, 0.980, 0.988)` | texto principal | 15,8:1 ✔ |
| `TEXT_MUTED` | `#94A3B8` | `Color(0.580, 0.639, 0.722)` | secundário, atalhos | 6,5:1 ✔ |
| `BORDER` | `#475569` | `Color(0.278, 0.333, 0.408)` | bordas, divisores | — |
| `RARITY_COMMON` | `#F8FAFC` | = `TEXT` | borda de item comum | — |
| `RARITY_RARE` | = `BLUE` | | borda de item raro | — |
| `RARITY_EPIC` | = `PURPLE` | | borda de item épico | — |

Contraste WCAG calculado sobre `#161F2E` (fórmula de luminância relativa; o teste `shared/test/test_theme_tokens.gd` recalcula). Consequência prática: nome do oponente, "DERROTA", nome do boss e "Épico" em `RED`/`PURPLE` só em `TYPE_VICTORY`/`TYPE_H1`/`TYPE_COUNTER`; em `TYPE_BODY` usar `TEXT` com borda/fundo colorido. Ver `DEBITO.md` DS-04.

## 2. Tipografia

| Token | Família | Tamanho @1080p | Peso | Uso |
|---|---|---|---|---|
| `FONT_DISPLAY` | `font_display.ttf` (Cinzel Decorative **ou** Kenney Bold — PI escolhe; licença CC0/OFL obrigatória; registrar em `DEBITO.md` até escolher) | — | Bold | base dos tipos abaixo |
| `FONT_DATA` | `font_data.ttf` (Inter ou Montserrat, OFL) | — | Medium/SemiBold | corpo, HUD |
| `FONT_MONO` | `font_mono.ttf` (JetBrains Mono ou similar OFL) | — | Bold | contadores |
| `TYPE_VICTORY` | display | 56 | Bold, caps | VITÓRIA / DERROTA / MORTE SÚBITA |
| `TYPE_H1` | display | 32 | Bold | título de tela |
| `TYPE_H2` | data | 22 | SemiBold | nome de habilidade/monstro |
| `TYPE_BODY` | data | 15 | Medium | descrições |
| `TYPE_COUNTER` | mono | 28 | Bold | relógio, placar |
| `TYPE_BADGE` | data | 12 | Bold | `[Q]`, `[F]` |

No Theme: `TYPE_*` viram `theme_type_variation` de `Label` (`LabelH1`, `LabelH2`, `LabelBody`, `LabelCounter`, `LabelBadge`, `LabelVictory`).

## 3. Espaçamento e tamanhos (px @1080p)

| Token | Valor | Uso |
|---|---|---|
| `SPACE_XS` | 4 | entre ícone e texto |
| `SPACE_SM` | 8 | dentro de card |
| `SPACE_MD` | 12 | entre botões de menu |
| `SPACE_LG` | 20 | entre cards |
| `SPACE_XL` | 30 | entre colunas, margem interna de tela |
| `SPACE_SCREEN` | 40 | margem externa de tela |
| `RADIUS_SM` | 4 | slots, badges |
| `RADIUS_MD` | 8 | cards, botões |
| `BORDER_W` | 2 | borda padrão; 3 para moldura ativa/raridade |
| `SIZE_LIST_COL` | 360 | coluna de lista (bestiário) |
| `SIZE_NAV_COL` | 420 | coluna de navegação (lobby) |
| `SIZE_SIDE_COL` | 400 | widget direito (lobby) |
| `SIZE_SLOT` | 64 | slot de item |
| `SIZE_SKILL` | 72 | botão de skill na HUD |
| `SIZE_TARGET_MIN` | 40 | alvo clicável mínimo |
| `SIZE_FOOTER` | 40 | barra de status |

## 4. Movimento

| Token | Valor | Uso |
|---|---|---|
| `DUR_FAST` | 0,15 s | hover (`TRANS_CUBIC`, `EASE_OUT`), deslocamento 8 px |
| `DUR_BASE` | 0,30 s | troca de tela (fade), barras de atributo |
| `DUR_SLOW` | 0,60 s | título de vitória (`TRANS_BOUNCE`), banner de fase |
| `PULSE_QUEUE` | 1,2 s loop | borda dourada do card de fila |
| `PULSE_ZONE` | 0,8 s loop | vinheta vermelha fora da zona (intensidade ∝ dano/s) |

Sem movimento acima de `DUR_SLOW` em UI; a opção "reduzir animação" não existe na fatia (`DEBITO.md`).

## 5. Viewport

`display/window/size/viewport_width=1920`, `viewport_height=1080`, `stretch/mode=canvas_items`, `stretch/aspect=expand` — nos **dois** `project.godot`. Mínimo suportado 1280×720.

## 6. Mapeamento para o Theme (`theme_moba.tres`)

| Tipo Godot | StyleBox / cor | Token |
|---|---|---|
| `Button` normal / hover / pressed / focus / disabled | `StyleBoxFlat` `BG_CARD` / `BG_CARD`+borda `GOLD` / `BG_SURFACE` / borda `GOLD_BRIGHT` 3 px / `BG_CARD` 50% | — |
| `ButtonPrimary` (variation) | fundo `GOLD`, texto `BG_SURFACE` | — |
| `ButtonDanger` (variation) | fundo `RED`, texto `TEXT` | — |
| `PanelContainer` | `StyleBoxFlat` `BG_PANEL`, borda `BORDER` 2 px, raio `RADIUS_MD` | — |
| `PanelCardSurface` / `PanelCardInner` (variations) | `BG_SURFACE` / `BG_CARD` | — |
| `ProgressBar` fill / bg | `GREEN` / `BG_SURFACE` ; variations `ProgressXp` (`GOLD_BRIGHT`), `ProgressEnemy` (`RED`), `ProgressStat` (`BLUE`) | — |
| `LineEdit` | `BG_CARD`, borda `BORDER` → `GOLD` em foco | — |
| `Tree`, `ItemList` | fundo `BG_PANEL`, seleção `BG_CARD`+borda `GOLD` | — |
| `TabContainer` | aba ativa `GOLD` texto, inativa `TEXT_MUTED` | — |
| `HSeparator`/`VSeparator` | `BORDER` 1 px | — |
| `Label` default | `TEXT`, `TYPE_BODY` | — |

O teste `shared/test/test_theme_tokens.gd` lê o `.tres` e confere que cada cor acima bate com `UiTokens`.
