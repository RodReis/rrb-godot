class_name HeroesTheme
extends RefCounted
## Tipos do Theme da Tela Herois (F71, prototipo "Tela Herois" de docs/prd/telas/). Prefixo LnHero;
## chamado por LauncherTheme.add, que guarda os auxiliares de StyleBox. Medidas do Tailwind do
## prototipo: rounded-xl 8 px, bg-surface-container-low = BG_LOW, card selecionado com borda e
## brilho dourados.

## Borda do card (border-2) e brilho do selecionado.
const CARD_BORDER: int = 2
const CARD_BORDER_HOVER_ALPHA: float = 0.5
const CARD_GLOW_ALPHA: float = 0.4
const CARD_GLOW_SIZE: int = 12
## Barra de atributo (h-1.5, rounded-full): o trecho do nivel 10 fica apagado atras do do nivel 1.
const BAR_RADIUS: int = 3
const BAR_HIGH_ALPHA: float = 0.35


static func add(theme: Theme) -> void:
	_panels(theme)
	_card(theme)
	_bars(theme)


static func _panels(theme: Theme) -> void:
	# Coluna de filtros e painel do heroi: bg-surface-container-low p-space-md rounded-xl shadow-xl.
	var side := LauncherTheme._box(UiTokens.BG_LOW, UiTokens.RADIUS_MD)
	LauncherTheme._shadow(
		side,
		LauncherTheme.SHADOW_RAISED,
		LauncherTheme.SHADOW_BLUR_RAISED,
		LauncherTheme.SHADOW_OFFSET_RAISED
	)
	side.set_content_margin_all(UiTokens.SPACE_MD)
	LauncherTheme._panel(theme, &"LnHeroSide", side)
	# Grade de cards (gap-space-sm do prototipo, um pouco maior: o card ergue 4 px com o mouse).
	theme.set_type_variation(&"LnHeroGrid", &"GridContainer")
	theme.set_constant(&"h_separation", &"LnHeroGrid", UiTokens.SPACE_MD)
	theme.set_constant(&"v_separation", &"LnHeroGrid", UiTokens.SPACE_MD)


## Card do heroi (Button de alternancia): selecionado = borda GOLD_BRIGHT com brilho.
static func _card(theme: Theme) -> void:
	var normal := LauncherTheme._box(Color(UiTokens.BG_PANEL, 1.0), UiTokens.RADIUS_MD)
	normal.set_border_width_all(CARD_BORDER)
	normal.border_color = Color.TRANSPARENT
	LauncherTheme._shadow(
		normal,
		LauncherTheme.SHADOW_CARD,
		LauncherTheme.SHADOW_BLUR_CARD,
		LauncherTheme.SHADOW_OFFSET
	)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.border_color = Color(UiTokens.GOLD, CARD_BORDER_HOVER_ALPHA)
	var selected := normal.duplicate() as StyleBoxFlat
	selected.border_color = UiTokens.GOLD_BRIGHT
	LauncherTheme._shadow(selected, CARD_GLOW_ALPHA, CARD_GLOW_SIZE, Vector2.ZERO, UiTokens.GOLD)
	theme.set_type_variation(&"LnHeroCard", &"Button")
	theme.set_stylebox(&"normal", &"LnHeroCard", normal)
	theme.set_stylebox(&"hover", &"LnHeroCard", hover)
	theme.set_stylebox(&"pressed", &"LnHeroCard", selected)
	theme.set_stylebox(&"hover_pressed", &"LnHeroCard", selected)
	theme.set_stylebox(&"focus", &"LnHeroCard", LauncherTheme._focus())


static func _bars(theme: Theme) -> void:
	var track := LauncherTheme._box(UiTokens.BG_HIGHEST, BAR_RADIUS)
	var clear := LauncherTheme._box(Color.TRANSPARENT, BAR_RADIUS)
	var bright := LauncherTheme._box(UiTokens.GOLD_BRIGHT, BAR_RADIUS)
	var dim := LauncherTheme._box(Color(UiTokens.GOLD, BAR_HIGH_ALPHA), BAR_RADIUS)
	var specs: Array[Array] = [
		[&"LnHeroBarHigh", track, dim],
		[&"LnHeroBarLow", clear, bright],
	]
	for spec: Array in specs:
		theme.set_type_variation(spec[0], &"ProgressBar")
		theme.set_stylebox(&"background", spec[0], spec[1])
		theme.set_stylebox(&"fill", spec[0], spec[2])
		theme.set_constant(&"outline_size", spec[0], 0)
