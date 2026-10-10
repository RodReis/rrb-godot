# TOKENS.md — Tokens de design

Fonte: DV §1.2–1.4 (valores de `docs/prd/telas/`, R-PEND-11 decidida em 2026-10-09). Nome do token = nome da constante em `UiTokens` (`shared/ui/theme/tokens.gd`) e nome da cor no `Theme` (`theme_moba.tres`, tipo `Global`).

## 1. Cores

Valores de `docs/prd/telas/*/DESIGN.md` (decisão do PI em 2026-10-09, R-PEND-11). Nomes dos tokens mantidos.

| Token | Hex | `Color` | Uso | Contraste sobre `BG_PANEL` |
|---|---|---|---|---|
| `BG_SURFACE` | `#0B1326` | `Color(0.043, 0.075, 0.149, 0.95)` | fundo de tela, overlays | — |
| `BG_PANEL` | `#171F33` | `Color(0.090, 0.122, 0.200, 0.90)` | cards, menus | — |
| `BG_CARD` | `#222A3D` | `Color(0.133, 0.165, 0.239, 0.85)` | slots, células | — |
| `GOLD` | `#F59E0B` | `Color(0.961, 0.620, 0.043)` | título, moldura ativa, botão primário | 7,6:1 ✔ |
| `GOLD_BRIGHT` | `#FFC174` | `Color(1.000, 0.757, 0.455)` | destaque, XP | 10,3:1 ✔ |
| `BLUE` | `#3198DC` | `Color(0.192, 0.596, 0.863)` | ação secundária, INT, set Guarda | 5,2:1 ✔ |
| `CYAN` | `#93CCFF` | `Color(0.576, 0.800, 1.000)` | CDR, rede boa | 9,6:1 ✔ |
| `RED` | `#EF4444` | `Color(0.937, 0.267, 0.267)` | HP inimigo, zona, derrota | 4,4:1 ✘ — texto só ≥ 24 px bold (AA large); senão fundo/borda |
| `GREEN` | `#22C55E` | `Color(0.133, 0.773, 0.369)` | HP próprio, vitória, ok | 7,2:1 ✔ |
| `PURPLE` | `#A855F7` | `Color(0.659, 0.333, 0.969)` | épico, boss, ultimate | 4,1:1 ✘ — texto só ≥ 24 px bold; senão fundo/borda |
| `TEXT` | `#DAE2FD` | `Color(0.855, 0.886, 0.992)` | texto principal | 12,7:1 ✔ |
| `TEXT_MUTED` | `#D8C3AD` | `Color(0.847, 0.765, 0.678)` | secundário, atalhos | 9,6:1 ✔ |
| `BORDER` | `#534434` | `Color(0.325, 0.267, 0.204)` | bordas, divisores | — |
| `RARITY_COMMON` | `#94A3B8` | `Color(0.580, 0.639, 0.722)` | borda de item comum | 6,4:1 ✔ |
| `RARITY_RARE` | `#3B82F6` | `Color(0.231, 0.510, 0.965)` | borda de item raro | 4,5:1 ✔ (limite) |
| `RARITY_EPIC` | = `PURPLE` | | borda de item épico | — |

Contraste WCAG calculado sobre `#171F33` (fórmula de luminância relativa; o teste `shared/test/test_theme_tokens.gd` recalcula). Consequência prática: nome do oponente, "DERROTA", nome do boss e "Épico" em `RED`/`PURPLE` só em `TYPE_VICTORY`/`TYPE_H1`/`TYPE_COUNTER`; em `TYPE_BODY` usar `TEXT` com borda/fundo colorido. Ver `DEBITO.md` DS-04. Texto sobre botão `GOLD` usa `BG_SURFACE` (8,6:1).

## 2. Tipografia

| Token | Família | Tamanho @1080p | Peso | Uso |
|---|---|---|---|---|
| `FONT_DISPLAY` | `font_display.ttf` = **Space Grotesk** (OFL) | — | Bold | títulos, anúncios, atalhos |
| `FONT_DATA` | `font_data.ttf` = **Outfit** (OFL) | — | Regular/Medium | corpo, descrições, HUD |
| `FONT_MONO` | `font_mono.ttf` = **JetBrains Mono** (OFL) | — | Bold | contadores, timers, HP |
| `TYPE_VICTORY` | display | 56 | Bold, caps | VITÓRIA / DERROTA / MORTE SÚBITA |
| `TYPE_H1` | display | 32 | Bold | título de tela |
| `TYPE_H2` | display | 22 | SemiBold | nome de habilidade/monstro |
| `TYPE_BODY` | data | 15 | Medium | descrições |
| `TYPE_COUNTER` | mono | 28 | Bold | relógio, placar |
| `TYPE_BADGE` | display | 12 | Bold | `[Q]`, `[F]` |

Famílias de `docs/prd/telas/` (R-PEND-11); tamanhos mantidos do DV §1.3 (resolução 1080p).

**v2 (ADR-0006, 2026-10-10):** as famílias acima são **provisórias** até o PI decidir R-PEND-14 (candidatas do guia: Cinzel, Barlow Condensed, Montserrat SemiBold). Regras novas que já valem: todo texto sobre a arena (HUD) tem **outline 1–2 px `#000000`**; painéis usam `StyleBoxTexture` com moldura temática (metal escuro, cantos dourados) em vez de `StyleBoxFlat`; atalhos `Q/E/R` viram *badge* metálica no canto inferior direito do slot (`TYPE_BADGE`). Os nomes dos tokens não mudam; só os arquivos `font_*.ttf` e os `StyleBox` do `theme_moba.tres` — trocados no F43 (HUD v2) e consumidos pelo F24 (Theme do launcher). No Theme: `TYPE_*` viram `theme_type_variation` de `Label` (`LabelH1`, `LabelH2`, `LabelBody`, `LabelCounter`, `LabelBadge`, `LabelVictory`).

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
