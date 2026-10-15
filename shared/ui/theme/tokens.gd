class_name UiTokens
extends RefCounted
## Tokens de design (docs/design-system/TOKENS.md): fonte para codigo (tween, _draw, shader).
## O theme_moba.tres sai daqui (ThemeBuilder) e test_theme_tokens.gd confere que os dois batem.

# Cores (TOKENS §1). Fundos com alfa; texto e acentos opacos.
const BG_SURFACE: Color = Color(0.043, 0.075, 0.149, 0.95)
const BG_PANEL: Color = Color(0.090, 0.122, 0.200, 0.90)
const BG_CARD: Color = Color(0.133, 0.165, 0.239, 0.85)
const GOLD: Color = Color(0.961, 0.620, 0.043)
const GOLD_BRIGHT: Color = Color(1.000, 0.757, 0.455)
const BLUE: Color = Color(0.192, 0.596, 0.863)
const CYAN: Color = Color(0.576, 0.800, 1.000)
const RED: Color = Color(0.937, 0.267, 0.267)
const GREEN: Color = Color(0.133, 0.773, 0.369)
const PURPLE: Color = Color(0.659, 0.333, 0.969)
const TEXT: Color = Color(0.855, 0.886, 0.992)
const TEXT_MUTED: Color = Color(0.847, 0.765, 0.678)
const BORDER: Color = Color(0.325, 0.267, 0.204)
const RARITY_COMMON: Color = Color(0.580, 0.639, 0.722)
const RARITY_RARE: Color = Color(0.231, 0.510, 0.965)
const RARITY_EPIC: Color = PURPLE
# Launcher (F24): cores dos prototipos de docs/prd/telas/ que a HUD nao usa (nome Tailwind ao lado).
const BG_LOWEST: Color = Color(0.024, 0.055, 0.125)  # surface-container-lowest #060E20
const BG_LOW: Color = Color(0.075, 0.106, 0.180)  # surface-container-low #131B2E
const BG_HIGHEST: Color = Color(0.176, 0.204, 0.286)  # surface-container-highest #2D3449
const BG_BRIGHT: Color = Color(0.192, 0.224, 0.302)  # surface-bright #31394D
const ON_GOLD: Color = Color(0.380, 0.231, 0.0)  # on-primary-container #613B00
const GOLD_EDGE: Color = Color(0.471, 0.208, 0.059)  # borda 3D do botao primario #78350F
const ON_CYAN: Color = Color(0.0, 0.200, 0.318)  # on-secondary #003351
const ERROR: Color = Color(1.0, 0.706, 0.671)  # error #FFB4AB
const ERROR_BG: Color = Color(0.576, 0.0, 0.039)  # error-container #93000A
const ON_ERROR: Color = Color(0.412, 0.0, 0.020)  # on-error #690005
# Login e Lobby (F25).
const ON_PRIMARY: Color = Color(0.278, 0.165, 0.0)  # on-primary #472A00 (texto sobre GOLD_BRIGHT)
const GOLD_SHADE: Color = Color(0.576, 0.337, 0.0)  # borda 3D do CTA da fila #935600
const TEXT_OUTLINE: Color = Color(0.627, 0.557, 0.478)  # outline #A08E7A (rotulo apagado)
# Historico (F26).
# on-error-container #FFDAD6 (texto do selo DERROTA)
const ON_ERROR_CONTAINER: Color = Color(1.0, 0.855, 0.839)

## Nome do token -> cor; o Theme guarda cada uma no tipo Global com o mesmo nome.
const COLORS: Dictionary[StringName, Color] = {
	&"BG_SURFACE": BG_SURFACE,
	&"BG_PANEL": BG_PANEL,
	&"BG_CARD": BG_CARD,
	&"GOLD": GOLD,
	&"GOLD_BRIGHT": GOLD_BRIGHT,
	&"BLUE": BLUE,
	&"CYAN": CYAN,
	&"RED": RED,
	&"GREEN": GREEN,
	&"PURPLE": PURPLE,
	&"TEXT": TEXT,
	&"TEXT_MUTED": TEXT_MUTED,
	&"BORDER": BORDER,
	&"RARITY_COMMON": RARITY_COMMON,
	&"RARITY_RARE": RARITY_RARE,
	&"RARITY_EPIC": RARITY_EPIC,
	&"BG_LOWEST": BG_LOWEST,
	&"BG_LOW": BG_LOW,
	&"BG_HIGHEST": BG_HIGHEST,
	&"BG_BRIGHT": BG_BRIGHT,
	&"ON_GOLD": ON_GOLD,
	&"GOLD_EDGE": GOLD_EDGE,
	&"ON_CYAN": ON_CYAN,
	&"ERROR": ERROR,
	&"ERROR_BG": ERROR_BG,
	&"ON_ERROR": ON_ERROR,
	&"ON_PRIMARY": ON_PRIMARY,
	&"GOLD_SHADE": GOLD_SHADE,
	&"TEXT_OUTLINE": TEXT_OUTLINE,
	&"ON_ERROR_CONTAINER": ON_ERROR_CONTAINER,
}

# Tipografia (TOKENS §2): tamanho em px @1080p e peso OpenType (wght) da fonte variavel.
const FONT_DISPLAY_PATH: String = "res://shared/ui/theme/fonts/font_display.ttf"
const FONT_DATA_PATH: String = "res://shared/ui/theme/fonts/font_data.ttf"
const FONT_MONO_PATH: String = "res://shared/ui/theme/fonts/font_mono.ttf"
const WEIGHT_MEDIUM: int = 500
const WEIGHT_SEMIBOLD: int = 600
const WEIGHT_BOLD: int = 700
const TYPE_VICTORY: int = 56
const TYPE_H1: int = 32
const TYPE_H2: int = 22
const TYPE_BODY: int = 15
const TYPE_COUNTER: int = 28
const TYPE_BADGE: int = 12
## Tela de fim (F52, protótipo): título VITÓRIA/DERROTA e valor de cada linha da tabela.
const TYPE_END_TITLE: int = 80
const TYPE_END_VALUE: int = 20
## Contorno preto do texto sobre a arena (TOKENS v2): 1 px no corpo, 2 px em titulo/contador.
const OUTLINE: Color = Color(0.0, 0.0, 0.0)
const OUTLINE_W: int = 1
const OUTLINE_W_LARGE: int = 2
## Launcher (F24, decisao do PI em 2026-10-15): familias dos prototipos de docs/prd/telas/, com os
## icones do Material Symbols como fallback (UiIcons). Tamanhos e pesos do Tailwind do prototipo.
const FONT_LN_DISPLAY_PATH: String = "res://shared/ui/theme/fonts/font_launcher_display.ttf"
const FONT_LN_BODY_PATH: String = "res://shared/ui/theme/fonts/font_launcher_body.ttf"
const FONT_LN_MONO_PATH: String = "res://shared/ui/theme/fonts/font_launcher_mono.ttf"
const FONT_ICONS_PATH: String = "res://shared/ui/theme/fonts/font_icons.ttf"
const WEIGHT_REGULAR: int = 400
const TYPE_LN_DISPLAY: int = 56  # display-hero: marca no Login (F25)
const TYPE_LN_HEADLINE_LG: int = 32  # headline-lg: titulo da tela
const TYPE_LN_HEADLINE_MD: int = 22  # headline-md: botao de envio, nome do heroi (F25)
const TYPE_LN_HEADLINE_SM: int = 18  # headline-sm: titulo de card, botao, aba
const TYPE_LN_BODY_LG: int = 16  # body-lg (F25)
const TYPE_LN_BODY: int = 14  # body-md
const TYPE_LN_BODY_SM: int = 12  # body-sm
const TYPE_LN_NUM: int = 11  # label-numeric-sm e hotkey-cap
const TYPE_LN_NUM_MD: int = 14  # label-numeric-md (F25)
## Icones do prototipo (text-[Npx]).
const ICON_SM: int = 18
const ICON_MD: int = 20
const ICON_LG: int = 22
const ICON_XL: int = 28

# Espacamento e tamanhos em px @1080p (TOKENS §3).
const SPACE_XS: int = 4
const SPACE_SM: int = 8
const SPACE_MD: int = 12
const SPACE_LG: int = 20
const SPACE_XL: int = 30
const SPACE_SCREEN: int = 40
## Margem de tela do Launcher (px-margin do prototipo, 1 rem).
const SPACE_MARGIN: int = 16
## rounded do prototipo do Launcher (0,125 rem): linhas, chips e teclas.
const RADIUS_XS: int = 2
const RADIUS_SM: int = 4
const RADIUS_MD: int = 8
const RADIUS_LG: int = 16
## rounded-xl do protótipo da tela de fim: botões e moldura do ícone de herói (12 px).
const RADIUS_BUTTON: int = 12
## Brilho neon de card (box-shadow do prototipo da selecao de herois).
const SIZE_GLOW: int = 24
const BORDER_W: int = 2
const BORDER_W_ACTIVE: int = 3
const SIZE_LIST_COL: int = 360
const SIZE_NAV_COL: int = 420
const SIZE_SIDE_COL: int = 400
const SIZE_SLOT: int = 64
const SIZE_SKILL: int = 72
const SIZE_TARGET_MIN: int = 40
const SIZE_FOOTER: int = 40

# Movimento em segundos (TOKENS §4).
const DUR_FAST: float = 0.15
const DUR_BASE: float = 0.30
const DUR_SLOW: float = 0.60
const PULSE_QUEUE: float = 1.2
const PULSE_ZONE: float = 0.8
## Alfa do botao desabilitado (TOKENS §6: BG_CARD 50 %).
const DISABLED_ALPHA: float = 0.5
