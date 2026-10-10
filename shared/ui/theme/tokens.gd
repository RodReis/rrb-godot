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

# Espacamento e tamanhos em px @1080p (TOKENS §3).
const SPACE_XS: int = 4
const SPACE_SM: int = 8
const SPACE_MD: int = 12
const SPACE_LG: int = 20
const SPACE_XL: int = 30
const SPACE_SCREEN: int = 40
const RADIUS_SM: int = 4
const RADIUS_MD: int = 8
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
