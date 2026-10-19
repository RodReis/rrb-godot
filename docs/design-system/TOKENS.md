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
| `BG_LOWEST` | `#060E20` | | Launcher (F24): poço, rodapé, faixa de ações, tecla | — |
| `BG_LOW` | `#131B2E` | | Launcher: card, barra superior | — |
| `BG_HIGHEST` | `#2D3449` | | Launcher: chip, caixa de ícone, segmento, divisor | — |
| `BG_BRIGHT` | `#31394D` | | Launcher: hover do segmento e da rolagem | — |
| `ON_GOLD` | `#613B00` | | Launcher: texto sobre `GOLD` (aba ativa, botão primário) | — |
| `GOLD_EDGE` | `#78350F` | | Launcher: borda 3D do botão primário | — |
| `ON_CYAN` | `#003351` | | Launcher: pino do switch ligado | — |
| `ERROR` | `#FFB4AB` | | Launcher: texto de erro, ícone de sair | — |
| `ERROR_BG` | `#93000A` | | Launcher: botão destrutivo, hover de sair | — |
| `ON_ERROR` | `#690005` | | Launcher: ícone de sair no hover | — |

Contraste WCAG calculado sobre `#171F33` (fórmula de luminância relativa; o teste `shared/test/test_theme_tokens.gd` recalcula). Consequência prática: nome do oponente, "DERROTA", nome do boss e "Épico" em `RED`/`PURPLE` só em `TYPE_VICTORY`/`TYPE_H1`/`TYPE_COUNTER`; em `TYPE_BODY` usar `TEXT` com borda/fundo colorido. Ver `DEBITO.md` DS-04. Texto sobre botão `GOLD` usa `BG_SURFACE` (8,6:1).

## 2. Tipografia

| Token | Família | Tamanho @1080p | Peso | Uso |
|---|---|---|---|---|
| `FONT_DISPLAY` | `font_display.ttf` = **Cinzel** (OFL, variável `wght`) | — | Bold | títulos, anúncios, atalhos |
| `FONT_DATA` | `font_data.ttf` = **Montserrat** (OFL, variável `wght`) | — | Medium/SemiBold | corpo, descrições, HUD |
| `FONT_MONO` | `font_mono.ttf` = **Barlow Condensed** Bold (OFL, estática) | — | Bold, algarismos tabulares (`tnum`) | contadores, timers, HP |
| `TYPE_VICTORY` | display | 56 | Bold, caps | VITÓRIA / DERROTA / MORTE SÚBITA |
| `TYPE_H1` | display | 32 | Bold | título de tela |
| `TYPE_H2` | display | 22 | SemiBold | nome de habilidade/monstro |
| `TYPE_BODY` | data | 15 | Medium | descrições |
| `TYPE_COUNTER` | mono | 28 | Bold | relógio, placar |
| `TYPE_BADGE` | display | 12 | Bold | `[Q]`, `[F]` |
| `TYPE_END_TITLE` | display | 80 | Bold, caps | VITÓRIA / DERROTA / SEM VENCEDOR na tela de fim (F52, protótipo 72 px × 1,1) |
| `TYPE_END_VALUE` | mono | 20 | Bold, `tnum` | valor de cada linha da tabela de fim e comparador `>` `<` (F52) |

Famílias de `docs/prd/telas/` (R-PEND-11); tamanhos mantidos do DV §1.3 (resolução 1080p).

**v2 (ADR-0006; R-PEND-14 decidida pelo PI em 2026-10-11, F43):** famílias acima — Cinzel, Montserrat e Barlow Condensed — no lugar das provisórias Space Grotesk/Outfit/JetBrains Mono. O token `FONT_MONO` mantém o nome; os números ficam fixos por `tnum`, não por fonte monoespaçada. Contorno: `OUTLINE` (`#000000`), `OUTLINE_W` 1 px no `Label` e `OUTLINE_W_LARGE` 2 px em `LabelVictory/H1/H2/Counter`. Molduras renderizadas por `art/ui/build_frames.py` em `shared/ui/theme/frames/` (painel 96 px e margem 9-slice 24; skill 72 px, margem 16; badge 24 px, margem 8); `PanelCardInner`, acentos e molduras de raridade continuam `StyleBoxFlat` (cor semântica). Regras do v2: todo texto sobre a arena (HUD) tem **outline 1–2 px `#000000`**; painéis usam `StyleBoxTexture` com moldura temática (metal escuro, cantos dourados) em vez de `StyleBoxFlat`; atalhos `Q/E/R` viram *badge* metálica no canto inferior direito do slot (`TYPE_BADGE`). Os nomes dos tokens não mudam; só os arquivos `font_*.ttf` e os `StyleBox` do `theme_moba.tres` — trocados no F43 (HUD v2) e consumidos pelo F24 (Theme do launcher). No Theme: `TYPE_*` viram `theme_type_variation` de `Label` (`LabelH1`, `LabelH2`, `LabelBody`, `LabelCounter`, `LabelBadge`, `LabelVictory`).

**Vidro da HUD (F57, decisão do PI em 2026-10-12):** a HUD da partida (fases 1 e 2) troca a moldura de metal pelo vidro do protótipo `docs/prd/telas/HUD Moderno/`, como **variantes novas** — o `PanelContainer` padrão, o Launcher e as molduras de skill/slot do F43 não mudam. `PanelCardGlass`: `BG_SURFACE` a 82 %, borda 1 px `GOLD` a 35 %, raio `RADIUS_LG`, sombra preta 55 % / 16 px, respiro `SPACE_MD`. `PanelCardGlassInner` (módulo do dock): `BG_SURFACE` a 45 %, borda 1 px `TEXT` a 15 %, raio `RADIUS_BUTTON`, respiro `SPACE_SM`. Acentos do vidro `PanelCardGlassAccent*`: 1 px, cor do token a 60 %, raio `RADIUS_LG`. Cantoneiras douradas (`PanelCard.corners`, 8 px × 2 px `GOLD`). Sem token de cor novo; alfas em `ThemeBuilder.ALPHA_GLASS*`.

**Launcher (F24, decisão do PI em 2026-10-15):** as telas do Launcher usam as famílias dos protótipos de `docs/prd/telas/` — **Space Grotesk** (`FONT_LN_DISPLAY_PATH`: títulos, botões, teclas), **Outfit** (`FONT_LN_BODY_PATH`: texto) e **JetBrains Mono** (`FONT_LN_MONO_PATH`: rótulos numéricos) — e os painéis lisos do protótipo, sem as molduras de metal nem o contorno preto da HUD (que segue com o v2 acima). Ícones: **Material Symbols Outlined** recortado em `font_icons.ttf` (`tools/ui/build_icon_font.py`, glifos em `UiIcons`), fallback de todas as fontes do Launcher. Tamanhos do Tailwind dos protótipos: `TYPE_LN_HEADLINE_LG` 32 (título), `TYPE_LN_HEADLINE_SM` 18 (card, botão, aba), `TYPE_LN_BODY` 14, `TYPE_LN_BODY_SM` 12, `TYPE_LN_NUM` 11 (rótulo numérico e tecla); ícones `ICON_SM` 18, `ICON_MD` 20, `ICON_LG` 22, `ICON_XL` 28. Tipos no §7.

## 3. Espaçamento e tamanhos (px @1080p)

| Token | Valor | Uso |
|---|---|---|
| `SPACE_XS` | 4 | entre ícone e texto |
| `SPACE_SM` | 8 | dentro de card |
| `SPACE_MD` | 12 | entre botões de menu |
| `SPACE_LG` | 20 | entre cards |
| `SPACE_XL` | 30 | entre colunas, margem interna de tela |
| `SPACE_SCREEN` | 40 | margem externa de tela |
| `SPACE_MARGIN` | 16 | margem de tela do Launcher (`px-margin` do protótipo) |
| `RADIUS_XS` | 2 | Launcher: linha, chip, tecla (`rounded` do protótipo) |
| `RADIUS_SM` | 4 | slots, badges |
| `RADIUS_MD` | 8 | cards, botões |
| `RADIUS_LG` | 16 | cards grandes da seleção de heróis (F51) e da tela de fim (F52) |
| `RADIUS_BUTTON` | 12 | botões e moldura do ícone de herói da tela de fim (rounded-xl do protótipo, F52) |
| `SIZE_GLOW` | 24 | brilho neon de card (sombra `StyleBoxFlat`, F51) |
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
| Seleção de heróis (F51) | `Hero{Ally,Enemy}{Card,Cell,Skill,Tag,TagSoft,Badge,Icon}` (acento `CYAN` / `RED`, card com sombra `SIZE_GLOW` e raio `RADIUS_LG`), `HeroGoldSkill`/`HeroGoldBadge`, `HeroRoster`, `HeroTimer`, `HeroHeader`/`HeroFooter`, `HeroChoice`/`HeroChoiceActive` (borda `GOLD`), `HeroPortrait`/`HeroPortraitActive`, `HeroLockInGlow` + `ButtonLockIn` (texto `BG_SURFACE`, gradiente por shader `runic_backdrop`), `ProgressHero` (`CYAN`), `HeroDot*`, `LabelHero{Accent,Highlight,Ready,Strong,Title,Mode,Dark}` | — |
| Tela de fim (F52) | por tom `{Win,Lose,Draw}` (`GOLD`/`RED`/`TEXT_MUTED`): `EndCard<tom>` (fundo `BG_SURFACE` 80 %, borda do tom, brilho, raio `RADIUS_LG`), `EndIcon<tom>`, `EndReason<tom>` + `LabelEndReason<tom>`, `LabelEndTitle<tom>` (`TYPE_END_TITLE`), `LabelEndTag<tom>`, `LabelEndLevel<tom>`; linhas `EndRow`/`EndRowHover`/`EndRowBoss` (`GOLD`)/`EndRowSet` (`CYAN`)/`EndRowMuted`; valores `LabelEndValue{GoldBright,Green,Cyan,Text,TextMuted}` (`TYPE_END_VALUE`, mono), `LabelEndPill{Gold,Muted}`; comparador `EndGlyph` + `LabelEndGlyph`, `EndVs` + `LabelEndVs`; rodapé `EndFooter`, `EndKey`/`EndKeyDark`; botões `ButtonEnd`, `ButtonEndPrimary` (`GOLD`), `ButtonEndDanger` (red-600 do protótipo) + `LabelEndButton`/`LabelEndButtonDark` | — |

O teste `shared/test/test_theme_tokens.gd` lê o `.tres` e confere que cada cor acima bate com `UiTokens`.

## 7. Tipos do Launcher (`LauncherTheme`, F24)

Gerados por `shared/ui/theme/launcher_theme.gd` (chamado no fim do `ThemeBuilder.build()`), prefixo `Ln`. Medidas do Tailwind dos protótipos (1 px CSS = 1 px no canvas 1920×1080); texto sem contorno.

| Grupo | Tipos |
|---|---|
| Texto (`Label`) | `LnHeadlineLg`, `LnHeadlineSm`, `LnHeadlineSmGold`, `LnBrand`, `LnBody`, `LnBodyMuted`, `LnBodyGold`, `LnBodySm`, `LnBodySmMuted`, `LnBodySmError`, `LnNum`, `LnNumText`, `LnNumGold`, `LnNumCyan`; ícones `LnIconGold`, `LnIconCyan`, `LnIconMuted`, `LnIconError`, `LnIconTitle` |
| Painéis (`PanelContainer`) | `LnAppBar` (`BG_LOW` 95 %, sombra), `LnCard` / `LnCardRaised` (`BG_LOW`, raio 8, sombra 20/24 px), `LnRibbon`, `LnFooter`, `LnRow` / `LnRowHover` (`BG_PANEL`/`BG_CARD` opacos, raio 2), `LnWell` (`BG_LOWEST` com inset), `LnChip`, `LnIconBox`, `LnModal`, `LnToast` |
| Botões | `LnTab` (aba e menu; ativo `GOLD` com brilho), `LnButton`, `LnButtonPrimary` (`GOLD`, borda 3D `GOLD_EDGE` 4 px, brilho), `LnButtonDanger` (`ERROR_BG`), `LnIconButton`, `LnIconButtonDanger`, `LnSegment`, `LnKey` / `LnKeyCyan` / `LnKeyUltimate` (tecla; escutando = `GOLD`), `LnKeyLabel` (tecla só leitura) |
| Controles | `LnSwitch` (`CheckButton`, SVG em `shared/ui/theme/launcher/`), `LnSlider`, `LnOption` + `LnPopup`, `LnScrollBar` |
| Layout | `LnHGap{Xs,Sm,Md,Lg,Xl}` / `LnVGap{…}` (espaçamento por token, sem override em componente), `LnScreenMargin`, `LnDivider` / `LnDividerV` |

Inset do CSS (`shadow-[inset_…]`) vira borda superior escura de 2 px (o `StyleBoxFlat` não tem sombra interna). O teste `shared/test/test_theme_tokens.gd` confere fontes, fallback de ícones, espaçamentos e estados.

### Acréscimos registrados em 2026-10-16 (pendências do F25–F35)

- Tokens de cor: `ON_PRIMARY`, `GOLD_SHADE`, `TEXT_OUTLINE` (F25), `ON_ERROR_CONTAINER` (F26). Fonte da verdade: `shared/ui/theme/tokens.gd` (`class_name UiTokens`) e `launcher_theme.gd`.
- Tipos de tema: `LnMatchCard*`, `LnResult*`, `LnTag*`, `LnFilter*` (F26); `LnCp*` via `CompendiumTheme` (F27); `LnAm*` via `ArenaMapTheme` (F33); `LnProfileChip*`, `LnAvatar*` (F35); `LnHeroSide`, `LnHeroCard`, `LnHeroGrid`, `LnHeroBarHigh`/`LnHeroBarLow` via `HeroesTheme` (F71, Tela Heróis). Todos chamados por `LauncherTheme.add`; `theme_moba.tres` regerado a cada acréscimo.
- Ícones: a fonte recortada (`tools/ui/build_icon_font.py`) ganhou 15 (F25) + 4 (F26) + 12 (F27) + 11 (F33) ícones; lista em `UiIcons`.
- Fontes: Launcher = protótipo (Space Grotesk / Outfit / JetBrains Mono); HUD do Game = v2 (Cinzel / Montserrat / Barlow Condensed) — R-PEND-14 fechada; a linha "F24 herda Cinzel/metal" deste documento está superada.
