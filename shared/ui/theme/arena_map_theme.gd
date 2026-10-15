class_name ArenaMapTheme
extends RefCounted
## Tipos do Theme da tela Arena & Mapa (F33, prototipo "Arena & Mapa" de docs/prd/telas/). Prefixo
## LnAm; chamado por LauncherTheme.add, que guarda os auxiliares de StyleBox. Medidas do Tailwind
## do prototipo: rounded-lg 4 px, rounded-xl 8 px; bg-surface-container = BG_PANEL, -low = BG_LOW,
## -high = BG_CARD, -lowest = BG_LOWEST.

## Rotulo do pino sobre o mapa (bg-surface-container-lowest/90).
const ALPHA_PIN_LABEL: float = 0.9
const PIN_LABEL_PAD_X: int = 4
const PIN_LABEL_PAD_Y: int = 2
## Pontos de fase (w-3 h-3 rounded-full).
const DOT_RADIUS: int = 6
## Chip da fita do cabecalho (px-space-md py-space-sm).
const CHIP_PAD_Y: int = 8
## Fato do card de detalhe (px-space-md py-space-xs).
const FACT_PAD_Y: int = 4
## Tamanho do glifo: na caixa do card, no pino cheio e no pino claro.
const GLYPH_BOX: int = 28
const GLYPH_PIN_ON: int = 22
const GLYPH_PIN: int = 18
## Acento -> [fundo cheio, glifo sobre o cheio, acento sobre fundo escuro].
const ACCENTS: Dictionary[StringName, Array] = {
	&"Gold": [UiTokens.GOLD, UiTokens.ON_GOLD, UiTokens.GOLD_BRIGHT],
	&"Cyan": [UiTokens.CYAN, UiTokens.ON_CYAN, UiTokens.CYAN],
	&"Error": [UiTokens.ERROR_BG, UiTokens.ON_ERROR_CONTAINER, UiTokens.ERROR],
	&"Muted": [UiTokens.BG_HIGHEST, UiTokens.TEXT, UiTokens.TEXT],
}


static func add(theme: Theme) -> void:
	_panels(theme)
	_accents(theme)
	_rule(theme)


## Linha de regra do card de fase: texto do corpo (body-sm) com o destaque em negrito. O negrito
## vem de push_bold() no codigo, nunca de BBCode.
static func _rule(theme: Theme) -> void:
	var type := &"LnAmRule"
	theme.set_type_variation(type, &"RichTextLabel")
	theme.set_font(
		&"normal_font",
		type,
		LauncherTheme.font(UiTokens.FONT_LN_BODY_PATH, UiTokens.WEIGHT_REGULAR)
	)
	theme.set_font(
		&"bold_font", type, LauncherTheme.font(UiTokens.FONT_LN_BODY_PATH, UiTokens.WEIGHT_BOLD)
	)
	theme.set_font_size(&"normal_font_size", type, UiTokens.TYPE_LN_BODY_SM)
	theme.set_font_size(&"bold_font_size", type, UiTokens.TYPE_LN_BODY_SM)
	theme.set_color(&"default_color", type, UiTokens.TEXT_MUTED)


static func _panels(theme: Theme) -> void:
	# Moldura do mapa: bg-surface-container-lowest p-space-sm rounded-xl shadow-2xl.
	var frame := LauncherTheme._box(UiTokens.BG_LOWEST, UiTokens.RADIUS_MD)
	frame.set_content_margin_all(UiTokens.SPACE_SM)
	LauncherTheme._shadow(
		frame,
		LauncherTheme.SHADOW_RAISED,
		LauncherTheme.SHADOW_BLUR_RAISED,
		LauncherTheme.SHADOW_OFFSET_RAISED
	)
	LauncherTheme._panel(theme, &"LnAmFrame", frame)
	# Barra do topo da moldura: bg-surface-container px-space-md py-space-xs rounded.
	var bar := LauncherTheme._box(Color(UiTokens.BG_PANEL, 1.0), UiTokens.RADIUS_XS)
	bar.content_margin_left = UiTokens.SPACE_MD
	bar.content_margin_right = UiTokens.SPACE_MD
	bar.content_margin_top = UiTokens.SPACE_XS
	bar.content_margin_bottom = UiTokens.SPACE_XS
	LauncherTheme._panel(theme, &"LnAmBar", bar)
	# Cartoes: -low com p-space-md (detalhe) e p-space-lg (cabecalho e rodape); fase = container.
	var low := LauncherTheme._box(UiTokens.BG_LOW, UiTokens.RADIUS_MD)
	low.set_content_margin_all(UiTokens.SPACE_MD)
	LauncherTheme._shadow(
		low, LauncherTheme.SHADOW_CARD, LauncherTheme.SHADOW_BLUR_CARD, LauncherTheme.SHADOW_OFFSET
	)
	LauncherTheme._panel(theme, &"LnAmCardLow", low)
	var wide := low.duplicate() as StyleBoxFlat
	wide.set_content_margin_all(UiTokens.SPACE_LG)
	LauncherTheme._panel(theme, &"LnAmCardWide", wide)
	var phase := LauncherTheme._box(Color(UiTokens.BG_PANEL, 1.0), UiTokens.RADIUS_MD)
	phase.set_content_margin_all(UiTokens.SPACE_MD)
	LauncherTheme._shadow(
		phase,
		LauncherTheme.SHADOW_RAISED,
		LauncherTheme.SHADOW_BLUR_RAISED,
		LauncherTheme.SHADOW_OFFSET_RAISED
	)
	LauncherTheme._panel(theme, &"LnAmPhase", phase)
	# Chip da fita (bg-surface-container-high rounded shadow-md) e fato do card (bg-container).
	var chip := LauncherTheme._box(Color(UiTokens.BG_CARD, 1.0), UiTokens.RADIUS_XS)
	chip.content_margin_left = UiTokens.SPACE_MD
	chip.content_margin_right = UiTokens.SPACE_MD
	chip.content_margin_top = CHIP_PAD_Y
	chip.content_margin_bottom = CHIP_PAD_Y
	LauncherTheme._shadow(
		chip,
		LauncherTheme.SHADOW_CARD,
		LauncherTheme.SHADOW_BLUR_SM,
		LauncherTheme.SHADOW_OFFSET_SM
	)
	LauncherTheme._panel(theme, &"LnAmChip", chip)
	var fact := LauncherTheme._box(Color(UiTokens.BG_PANEL, 1.0), UiTokens.RADIUS_XS)
	fact.content_margin_left = UiTokens.SPACE_MD
	fact.content_margin_right = UiTokens.SPACE_MD
	fact.content_margin_top = FACT_PAD_Y
	fact.content_margin_bottom = FACT_PAD_Y
	LauncherTheme._panel(theme, &"LnAmFact", fact)
	# Caixa do icone da faixa de rodape (w-9 h-9 rounded bg-surface-container).
	var stat := LauncherTheme._box(Color(UiTokens.BG_PANEL, 1.0), UiTokens.RADIUS_XS)
	LauncherTheme._panel(theme, &"LnAmStatBox", stat)
	# Rotulo do pino: bg-surface-container-lowest/90.
	var label := LauncherTheme._box(Color(UiTokens.BG_LOWEST, ALPHA_PIN_LABEL), UiTokens.RADIUS_XS)
	label.content_margin_left = PIN_LABEL_PAD_X
	label.content_margin_right = PIN_LABEL_PAD_X
	label.content_margin_top = PIN_LABEL_PAD_Y
	label.content_margin_bottom = PIN_LABEL_PAD_Y
	LauncherTheme._panel(theme, &"LnAmPinLabel", label)


## Por acento: caixa cheia, glifos (caixa, pino cheio, pino claro), selo de texto e ponto.
static func _accents(theme: Theme) -> void:
	var mono := LauncherTheme.font(UiTokens.FONT_LN_MONO_PATH, UiTokens.WEIGHT_BOLD)
	for accent: StringName in ACCENTS:
		var colors: Array = ACCENTS[accent]
		var box := LauncherTheme._box(colors[0], UiTokens.RADIUS_SM)
		LauncherTheme._shadow(
			box,
			LauncherTheme.SHADOW_CARD,
			LauncherTheme.SHADOW_BLUR_SM,
			LauncherTheme.SHADOW_OFFSET_SM
		)
		LauncherTheme._panel(theme, StringName("LnAmFill%s" % accent), box)
		_glyph(theme, StringName("LnAmGlyphOn%s" % accent), GLYPH_BOX, colors[1])
		_glyph(theme, StringName("LnAmPinOn%s" % accent), GLYPH_PIN_ON, colors[1])
		_glyph(theme, StringName("LnAmPin%s" % accent), GLYPH_PIN, colors[2])
		LauncherTheme._badge(theme, StringName("LnAmTag%s" % accent), colors[0], colors[1], mono)
		LauncherTheme._panel(
			theme, StringName("LnAmDot%s" % accent), LauncherTheme._box(colors[2], DOT_RADIUS)
		)


static func _glyph(theme: Theme, type: StringName, size: int, color: Color) -> void:
	theme.set_type_variation(type, &"Label")
	theme.set_font(
		&"font", type, LauncherTheme.font(UiTokens.FONT_ICONS_PATH, UiTokens.WEIGHT_REGULAR)
	)
	theme.set_font_size(&"font_size", type, size)
	theme.set_color(&"font_color", type, color)
	theme.set_constant(&"outline_size", type, 0)
