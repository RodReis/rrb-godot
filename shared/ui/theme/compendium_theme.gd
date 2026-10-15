class_name CompendiumTheme
extends RefCounted
## Tipos do Theme do Compendio (F27: Bestiario e Forja, prototipos "Guia & Bestiario" e
## "Equipamentos & Forja" de docs/prd/telas/). Prefixo LnCp; chamado por LauncherTheme.add, que
## guarda os auxiliares de StyleBox. Medidas do Tailwind do prototipo: rounded-lg 4 px, rounded-xl
## 8 px; bg-surface-container = BG_PANEL; badges sobre a imagem a 90 %.

## Badges e abas sobre a imagem do card (bg-.../90).
const ALPHA_BADGE: float = 0.9
## Dica do card (bg-surface-container-high/60).
const ALPHA_TILE: float = 0.6
## Pilula de filtro inativa: hover do chefe (hover:bg-tertiary-container/30).
const ALPHA_PILL_HOVER: float = 0.3
## label-numeric-lg do prototipo (20 px).
const TYPE_NUM_LG: int = 20
const SEARCH_PAD_LEFT: int = 32
const SEARCH_PAD_Y: int = 6
const PILL_PAD_X: int = 8
const PILL_PAD_Y: int = 2
## Barra de atributo (h-1.5 = 6 px, rounded-full).
const BAR_HEIGHT: int = 6
const BAR_RADIUS: int = 3
## Moldura do item no simulador: 2 px; selecionado ganha brilho dourado.
const SLOT_BORDER: int = 2
const SLOT_GLOW: float = 0.4
const SLOT_GLOW_SIZE: int = 8
## Variacoes de Label: nome -> [fonte, peso, tamanho, cor].
const LABELS: Dictionary[StringName, Array] = {
	&"LnNumMdError":
	[UiTokens.FONT_LN_MONO_PATH, UiTokens.WEIGHT_BOLD, UiTokens.TYPE_LN_NUM_MD, &"ERROR"],
	&"LnNumLg": [UiTokens.FONT_LN_MONO_PATH, UiTokens.WEIGHT_BOLD, TYPE_NUM_LG, &"TEXT"],
	&"LnNumLgGold": [UiTokens.FONT_LN_MONO_PATH, UiTokens.WEIGHT_BOLD, TYPE_NUM_LG, &"GOLD_BRIGHT"],
	&"LnNumLgCyan": [UiTokens.FONT_LN_MONO_PATH, UiTokens.WEIGHT_BOLD, TYPE_NUM_LG, &"CYAN"],
	&"LnNumLgError": [UiTokens.FONT_LN_MONO_PATH, UiTokens.WEIGHT_BOLD, TYPE_NUM_LG, &"ERROR"],
	&"LnHeadlineMdCyan":
	[
		UiTokens.FONT_LN_DISPLAY_PATH,
		UiTokens.WEIGHT_SEMIBOLD,
		UiTokens.TYPE_LN_HEADLINE_MD,
		&"CYAN"
	],
	&"LnHeadlineMdError":
	[
		UiTokens.FONT_LN_DISPLAY_PATH,
		UiTokens.WEIGHT_SEMIBOLD,
		UiTokens.TYPE_LN_HEADLINE_MD,
		&"ERROR"
	],
	&"LnHeadlineSmCyan":
	[
		UiTokens.FONT_LN_DISPLAY_PATH,
		UiTokens.WEIGHT_SEMIBOLD,
		UiTokens.TYPE_LN_HEADLINE_SM,
		&"CYAN"
	],
	&"LnHeadlineLgGold":
	[
		UiTokens.FONT_LN_DISPLAY_PATH,
		UiTokens.WEIGHT_BOLD,
		UiTokens.TYPE_LN_HEADLINE_LG,
		&"GOLD_BRIGHT"
	],
	&"LnBodySmCyan":
	[UiTokens.FONT_LN_BODY_PATH, UiTokens.WEIGHT_MEDIUM, UiTokens.TYPE_LN_BODY_SM, &"CYAN"],
	&"LnBodySmGoldMedium":
	[UiTokens.FONT_LN_BODY_PATH, UiTokens.WEIGHT_MEDIUM, UiTokens.TYPE_LN_BODY_SM, &"GOLD_BRIGHT"],
	&"LnBodySmMedium":
	[UiTokens.FONT_LN_BODY_PATH, UiTokens.WEIGHT_MEDIUM, UiTokens.TYPE_LN_BODY_SM, &"TEXT"],
}


static func add(theme: Theme) -> void:
	_labels(theme)
	_panels(theme)
	_badges(theme)
	_controls(theme)
	_bars(theme)


static func _labels(theme: Theme) -> void:
	for type: StringName in LABELS:
		var spec: Array = LABELS[type]
		theme.set_type_variation(type, &"Label")
		theme.set_font(&"font", type, LauncherTheme.font(spec[0], spec[1]))
		theme.set_font_size(&"font_size", type, spec[2])
		theme.set_color(&"font_color", type, UiTokens.COLORS[spec[3]])
		theme.set_constant(&"outline_size", type, 0)


static func _panels(theme: Theme) -> void:
	# Grade de cards do bestiario (gap-space-lg) e ponto pulsante da secao (w-2 h-2 rounded-full).
	theme.set_type_variation(&"LnCpGrid", &"GridContainer")
	theme.set_constant(&"h_separation", &"LnCpGrid", UiTokens.SPACE_LG)
	theme.set_constant(&"v_separation", &"LnCpGrid", UiTokens.SPACE_LG)
	LauncherTheme._panel(
		theme, &"LnCpDot", LauncherTheme._box(UiTokens.GOLD_BRIGHT, LauncherTheme.DOT_RADIUS)
	)
	# Card de monstro e de arma: bg-surface-container rounded-xl shadow-lg, imagem rente a borda.
	var card := LauncherTheme._box(Color(UiTokens.BG_PANEL, 1.0), UiTokens.RADIUS_MD)
	LauncherTheme._shadow(
		card,
		LauncherTheme.SHADOW_RAISED,
		LauncherTheme.SHADOW_BLUR_CARD,
		LauncherTheme.SHADOW_OFFSET
	)
	LauncherTheme._panel(theme, &"LnCpCard", card)
	var padded := card.duplicate() as StyleBoxFlat
	padded.set_content_margin_all(UiTokens.SPACE_LG)
	LauncherTheme._panel(theme, &"LnCpPanel", padded)
	var tight := card.duplicate() as StyleBoxFlat
	tight.set_content_margin_all(UiTokens.SPACE_MD)
	LauncherTheme._panel(theme, &"LnCpPanelTight", tight)
	# Chefe: o mesmo card com borda dourada fina (o brilho vem de um gradiente no card).
	var boss := card.duplicate() as StyleBoxFlat
	boss.border_color = Color(UiTokens.GOLD, ALPHA_TILE)
	boss.set_border_width_all(1)
	LauncherTheme._panel(theme, &"LnCpCardBoss", boss)
	# Respiro interno do conteudo dos cards (p-space-lg).
	theme.set_type_variation(&"LnCpInset", &"MarginContainer")
	for side: StringName in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		theme.set_constant(side, &"LnCpInset", UiTokens.SPACE_LG)
	# Poco da imagem (arma): fundo escuro, sem respiro (a arte ocupa tudo). Margem do selo sobre ele.
	var image_well := LauncherTheme._box(UiTokens.BG_LOWEST, 0)
	LauncherTheme._panel(theme, &"LnCpWell", image_well)
	theme.set_type_variation(&"LnCpTagMargin", &"MarginContainer")
	for side: StringName in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		theme.set_constant(side, &"LnCpTagMargin", UiTokens.SPACE_SM)
	# Gola da rolagem do corpo: a barra nao encosta no conteudo.
	theme.set_type_variation(&"LnCpScrollGutter", &"MarginContainer")
	theme.set_constant(&"margin_right", &"LnCpScrollGutter", UiTokens.SPACE_MD)
	# Dica e linha de item (bg-surface-container-high/60).
	var tile := LauncherTheme._box(Color(UiTokens.BG_CARD, ALPHA_TILE), UiTokens.RADIUS_SM)
	tile.set_content_margin_all(UiTokens.SPACE_SM)
	LauncherTheme._panel(theme, &"LnCpTile", tile)
	# Abas do compendio: bg-surface-container-lowest p-1 rounded-xl, inset.
	var tabs := LauncherTheme._box(UiTokens.BG_LOWEST, UiTokens.RADIUS_MD)
	LauncherTheme._inset(tabs)
	tabs.set_content_margin_all(UiTokens.SPACE_XS)
	LauncherTheme._panel(theme, &"LnCpTabStrip", tabs)
	# Pilulas de filtro: bg-surface-container px-2 py-1 rounded-lg.
	var pills := LauncherTheme._box(Color(UiTokens.BG_PANEL, 1.0), UiTokens.RADIUS_SM)
	pills.content_margin_left = UiTokens.SPACE_SM
	pills.content_margin_right = UiTokens.SPACE_SM
	pills.content_margin_top = UiTokens.SPACE_XS
	pills.content_margin_bottom = UiTokens.SPACE_XS
	LauncherTheme._panel(theme, &"LnCpPills", pills)
	# Caixa do icone dos cards de regra (w-10 h-10 rounded-lg bg-surface-container-highest).
	var icon_box := LauncherTheme._box(UiTokens.BG_HIGHEST, UiTokens.RADIUS_SM)
	LauncherTheme._inset(icon_box)
	icon_box.set_content_margin_all(UiTokens.SPACE_SM)
	LauncherTheme._panel(theme, &"LnCpIconBox", icon_box)
	# Painel do resultado do simulador (borda esquerda de acento) e aviso de efeito do conjunto.
	var effect := LauncherTheme._box(UiTokens.BG_LOWEST, UiTokens.RADIUS_SM)
	LauncherTheme._inset(effect)
	effect.content_margin_left = UiTokens.SPACE_MD
	effect.content_margin_right = UiTokens.SPACE_MD
	effect.content_margin_top = UiTokens.SPACE_SM
	effect.content_margin_bottom = UiTokens.SPACE_SM
	LauncherTheme._panel(theme, &"LnCpEffect", effect)


## Selo sobre a imagem: tier do monstro, XP e o chefe.
static func _badges(theme: Theme) -> void:
	var mono := LauncherTheme.font(UiTokens.FONT_LN_MONO_PATH, UiTokens.WEIGHT_BOLD)
	var low := Color(UiTokens.BG_LOWEST, ALPHA_BADGE)
	LauncherTheme._badge(theme, &"LnCpBadgeT1", low, UiTokens.TEXT, mono)
	LauncherTheme._badge(
		theme, &"LnCpBadgeT2", Color(UiTokens.BLUE, ALPHA_BADGE), UiTokens.ON_CYAN, mono
	)
	LauncherTheme._badge(
		theme, &"LnCpBadgeT3", Color(UiTokens.GOLD_BRIGHT, ALPHA_BADGE), UiTokens.ON_PRIMARY, mono
	)
	LauncherTheme._badge(theme, &"LnCpBadgeXp", low, UiTokens.GOLD_BRIGHT, mono)
	LauncherTheme._badge(
		theme, &"LnCpBadgeSet", Color(UiTokens.GOLD, 0.2), UiTokens.GOLD_BRIGHT, mono
	)
	LauncherTheme._badge(theme, &"LnCpBadgeSetBlue", Color(UiTokens.BLUE, 0.2), UiTokens.CYAN, mono)
	# Chefe: error-container, texto headline-sm uppercase (CHEFE DA ARENA).
	var display := LauncherTheme.font(UiTokens.FONT_LN_DISPLAY_PATH, UiTokens.WEIGHT_BOLD, true)
	LauncherTheme._label_box(
		theme,
		&"LnCpBadgeBoss",
		UiTokens.ERROR_BG,
		UiTokens.ON_ERROR_CONTAINER,
		display,
		UiTokens.SPACE_XS,
		UiTokens.SPACE_SM
	)


static func _controls(theme: Theme) -> void:
	var mono := LauncherTheme.font(UiTokens.FONT_LN_MONO_PATH, UiTokens.WEIGHT_BOLD)
	# Pilula de filtro (toggle): inativa so texto; ativa GOLD_BRIGHT sobre ON_PRIMARY.
	var pill := LauncherTheme._box(Color.TRANSPARENT, UiTokens.RADIUS_XS)
	pill.content_margin_left = PILL_PAD_X
	pill.content_margin_right = PILL_PAD_X
	pill.content_margin_top = PILL_PAD_Y
	pill.content_margin_bottom = PILL_PAD_Y
	var pill_on := LauncherTheme._fill(pill, UiTokens.GOLD_BRIGHT)
	var pill_boxes: Array = [pill, pill, pill_on, pill_on]
	LauncherTheme._button(theme, &"LnCpPill", pill_boxes, mono)
	theme.set_font_size(&"font_size", &"LnCpPill", UiTokens.TYPE_LN_NUM)
	LauncherTheme._button_colors(
		theme, &"LnCpPill", UiTokens.TEXT_MUTED, UiTokens.TEXT, UiTokens.ON_PRIMARY
	)
	# Pilula do chefe: texto ERROR; ativa/hover com error-container a 30 %.
	var boss := LauncherTheme._fill(pill, Color(UiTokens.ERROR_BG, ALPHA_PILL_HOVER))
	LauncherTheme._button(theme, &"LnCpPillBoss", [pill, boss, boss, boss], mono)
	theme.set_font_size(&"font_size", &"LnCpPillBoss", UiTokens.TYPE_LN_NUM)
	LauncherTheme._button_colors(
		theme, &"LnCpPillBoss", UiTokens.ERROR, UiTokens.ERROR, UiTokens.ERROR
	)
	# Busca: bg-surface-container-highest/60, icone a esquerda, anel dourado no foco.
	theme.set_type_variation(&"LnCpSearch", &"LineEdit")
	var field := LauncherTheme._box(Color(UiTokens.BG_HIGHEST, ALPHA_TILE), UiTokens.RADIUS_SM)
	field.content_margin_left = SEARCH_PAD_LEFT
	field.content_margin_right = UiTokens.SPACE_MD
	field.content_margin_top = SEARCH_PAD_Y
	field.content_margin_bottom = SEARCH_PAD_Y
	theme.set_stylebox(&"normal", &"LnCpSearch", field)
	theme.set_stylebox(&"read_only", &"LnCpSearch", field)
	var focus := field.duplicate() as StyleBoxFlat
	focus.border_color = UiTokens.GOLD_BRIGHT
	focus.set_border_width_all(1)
	theme.set_stylebox(&"focus", &"LnCpSearch", focus)
	theme.set_font(
		&"font",
		&"LnCpSearch",
		LauncherTheme.font(UiTokens.FONT_LN_BODY_PATH, UiTokens.WEIGHT_REGULAR)
	)
	theme.set_font_size(&"font_size", &"LnCpSearch", UiTokens.TYPE_LN_BODY_SM)
	theme.set_color(&"font_color", &"LnCpSearch", UiTokens.TEXT)
	theme.set_color(&"font_placeholder_color", &"LnCpSearch", UiTokens.TEXT_MUTED)
	theme.set_color(&"caret_color", &"LnCpSearch", UiTokens.GOLD_BRIGHT)
	theme.set_color(
		&"selection_color", &"LnCpSearch", Color(UiTokens.GOLD, LauncherTheme.SELECTION_ALPHA)
	)
	theme.set_constant(&"outline_size", &"LnCpSearch", 0)
	_slots(theme)


## Item do simulador (toggle): moldura pela raridade; escolhido ganha o brilho dourado.
static func _slots(theme: Theme) -> void:
	var rarities: Array[Array] = [
		[&"Common", UiTokens.RARITY_COMMON],
		[&"Rare", UiTokens.RARITY_RARE],
		[&"Epic", UiTokens.RARITY_EPIC],
	]
	for rarity: Array in rarities:
		var box := LauncherTheme._box(UiTokens.BG_LOWEST, UiTokens.RADIUS_SM)
		box.border_color = rarity[1]
		box.set_border_width_all(SLOT_BORDER)
		box.set_content_margin_all(UiTokens.SPACE_XS)
		var hover := LauncherTheme._fill(box, Color(UiTokens.BG_CARD, 1.0))
		var chosen := LauncherTheme._fill(box, Color(UiTokens.BG_CARD, 1.0))
		chosen.border_color = UiTokens.GOLD_BRIGHT
		LauncherTheme._shadow(chosen, SLOT_GLOW, SLOT_GLOW_SIZE, Vector2.ZERO, UiTokens.GOLD)
		var type := StringName("LnCpSlot%s" % rarity[0])
		var display := LauncherTheme.font(UiTokens.FONT_LN_DISPLAY_PATH, UiTokens.WEIGHT_SEMIBOLD)
		LauncherTheme._button(theme, type, [box, hover, chosen, chosen], display)
		LauncherTheme._button_colors(theme, type, UiTokens.TEXT_MUTED, UiTokens.TEXT, UiTokens.TEXT)


## Barra de atributo do chefe e absorcao de dano: trilho BG_HIGHEST, preenchimento no acento.
static func _bars(theme: Theme) -> void:
	var track := LauncherTheme._box(UiTokens.BG_HIGHEST, BAR_RADIUS)
	var fills: Array[Array] = [
		[&"LnCpBarGold", UiTokens.GOLD_BRIGHT],
		[&"LnCpBarCyan", UiTokens.CYAN],
		[&"LnCpBarError", UiTokens.ERROR],
	]
	for fill: Array in fills:
		theme.set_type_variation(fill[0], &"ProgressBar")
		theme.set_stylebox(&"background", fill[0], track)
		theme.set_stylebox(&"fill", fill[0], LauncherTheme._box(fill[1], BAR_RADIUS))
		theme.set_constant(&"outline_size", fill[0], 0)
