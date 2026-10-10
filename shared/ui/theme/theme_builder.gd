class_name ThemeBuilder
extends SceneTree
## Gera shared/ui/theme/theme_moba.tres a partir de UiTokens (TOKENS.md §6). Rode depois de
## mudar um token:
##   godot --headless --path game --script res://shared/ui/theme/theme_builder.gd
## O .tres e versionado; test_theme_tokens.gd confere que ele bate com os tokens.

const OUTPUT: String = "res://shared/ui/theme/theme_moba.tres"
## Tipo do Theme que guarda as cores com o nome do token (TOKENS.md, cabecalho).
const GLOBAL_TYPE: StringName = &"Global"
## Variacoes de Label: nome -> [fonte, peso, tamanho] (TOKENS §2).
const LABELS: Dictionary[StringName, Array] = {
	&"LabelVictory": [UiTokens.FONT_DISPLAY_PATH, UiTokens.WEIGHT_BOLD, UiTokens.TYPE_VICTORY],
	&"LabelH1": [UiTokens.FONT_DISPLAY_PATH, UiTokens.WEIGHT_BOLD, UiTokens.TYPE_H1],
	&"LabelH2": [UiTokens.FONT_DISPLAY_PATH, UiTokens.WEIGHT_SEMIBOLD, UiTokens.TYPE_H2],
	&"LabelBody": [UiTokens.FONT_DATA_PATH, UiTokens.WEIGHT_MEDIUM, UiTokens.TYPE_BODY],
	&"LabelCounter": [UiTokens.FONT_MONO_PATH, UiTokens.WEIGHT_BOLD, UiTokens.TYPE_COUNTER],
	&"LabelBadge": [UiTokens.FONT_DISPLAY_PATH, UiTokens.WEIGHT_BOLD, UiTokens.TYPE_BADGE],
}

var _fonts: Dictionary[String, FontVariation] = {}


func _initialize() -> void:
	var err := ResourceSaver.save(build(), OUTPUT)
	if err != OK:
		push_error("[theme] falha ao salvar %s: %s" % [OUTPUT, error_string(err)])
	else:
		print("[theme] salvo em %s" % OUTPUT)
	quit(err)


func build() -> Theme:
	var theme := Theme.new()
	theme.default_font = _font(UiTokens.FONT_DATA_PATH, UiTokens.WEIGHT_MEDIUM)
	theme.default_font_size = UiTokens.TYPE_BODY
	for token: StringName in UiTokens.COLORS:
		theme.set_color(token, GLOBAL_TYPE, UiTokens.COLORS[token])
	_labels(theme)
	_buttons(theme)
	_panels(theme)
	_progress(theme)
	_inputs(theme)
	_slots(theme)
	return theme


func _labels(theme: Theme) -> void:
	theme.set_color(&"font_color", &"Label", UiTokens.TEXT)
	for type: StringName in LABELS:
		var spec: Array = LABELS[type]
		theme.set_type_variation(type, &"Label")
		theme.set_font(&"font", type, _font(spec[0], spec[1]))
		theme.set_font_size(&"font_size", type, spec[2])
	theme.set_color(&"font_color", &"LabelBadge", UiTokens.TEXT_MUTED)
	theme.set_type_variation(&"LabelMuted", &"Label")
	theme.set_color(&"font_color", &"LabelMuted", UiTokens.TEXT_MUTED)
	# TimerLabel: aviso e perigo (PATTERNS P7). RED so em texto >= 24 px bold (TOKENS §1).
	theme.set_type_variation(&"LabelCounterWarning", &"LabelCounter")
	theme.set_color(&"font_color", &"LabelCounterWarning", UiTokens.GOLD)
	theme.set_type_variation(&"LabelCounterDanger", &"LabelCounter")
	theme.set_color(&"font_color", &"LabelCounterDanger", UiTokens.RED)
	# HotkeyBadge MD: sobre o icone da skill, precisa de fundo para ler.
	theme.set_type_variation(&"LabelBadgeMd", &"LabelBadge")
	theme.set_color(&"font_color", &"LabelBadgeMd", UiTokens.TEXT)
	var badge := _box(UiTokens.BG_SURFACE, UiTokens.RADIUS_SM)
	badge.set_content_margin_all(UiTokens.SPACE_XS / 2.0)
	theme.set_stylebox(&"normal", &"LabelBadgeMd", badge)
	theme.set_color(&"font_color", &"TooltipLabel", UiTokens.TEXT)
	# O Godot embrulha todo tooltip num TooltipPanel: vazio, para o ItemTooltip (PanelCard) nao
	# ganhar borda dupla; o tooltip de texto desenha o proprio card no TooltipLabel.
	theme.set_stylebox(&"panel", &"TooltipPanel", StyleBoxEmpty.new())
	theme.set_stylebox(&"normal", &"TooltipLabel", _panel(UiTokens.BG_PANEL))


func _buttons(theme: Theme) -> void:
	_button_states(theme, &"Button", UiTokens.BG_CARD, UiTokens.TEXT)
	theme.set_type_variation(&"ButtonPrimary", &"Button")
	_button_states(theme, &"ButtonPrimary", UiTokens.GOLD, UiTokens.BG_SURFACE)
	theme.set_type_variation(&"ButtonDanger", &"Button")
	_button_states(theme, &"ButtonDanger", UiTokens.RED, UiTokens.TEXT)


## Normal / hover (borda GOLD) / pressed (BG_SURFACE) / foco (borda GOLD_BRIGHT 3 px) /
## desabilitado (fundo a 50 %) — TOKENS §6.
func _button_states(theme: Theme, type: StringName, fill: Color, text: Color) -> void:
	theme.set_stylebox(&"normal", type, _button_box(fill, UiTokens.BORDER))
	theme.set_stylebox(&"hover", type, _button_box(fill, UiTokens.GOLD))
	theme.set_stylebox(&"pressed", type, _button_box(UiTokens.BG_SURFACE, UiTokens.GOLD))
	theme.set_stylebox(&"hover_pressed", type, _button_box(UiTokens.BG_SURFACE, UiTokens.GOLD))
	var disabled := fill
	disabled.a *= UiTokens.DISABLED_ALPHA
	theme.set_stylebox(&"disabled", type, _button_box(disabled, UiTokens.BORDER))
	var focus := _outline(UiTokens.GOLD_BRIGHT, UiTokens.BORDER_W_ACTIVE, UiTokens.RADIUS_MD)
	theme.set_stylebox(&"focus", type, focus)
	for color: StringName in [&"font_color", &"font_hover_color", &"font_focus_color"]:
		theme.set_color(color, type, text)
	theme.set_color(&"font_pressed_color", type, UiTokens.TEXT)
	theme.set_color(&"font_hover_pressed_color", type, UiTokens.TEXT)
	theme.set_color(&"font_disabled_color", type, UiTokens.TEXT_MUTED)


func _panels(theme: Theme) -> void:
	theme.set_stylebox(&"panel", &"PanelContainer", _panel(UiTokens.BG_PANEL))
	theme.set_type_variation(&"PanelCardSurface", &"PanelContainer")
	theme.set_stylebox(&"panel", &"PanelCardSurface", _panel(UiTokens.BG_SURFACE))
	theme.set_type_variation(&"PanelCardInner", &"PanelContainer")
	theme.set_stylebox(&"panel", &"PanelCardInner", _panel(UiTokens.BG_CARD))
	# Acento do PanelCard (borda 3 px): tipos lidos pelo componente, desenhados sobre o fundo.
	for accent: StringName in PanelCard.ACCENT_TOKENS:
		var color: Color = UiTokens.COLORS[PanelCard.ACCENT_TOKENS[accent]]
		var outline := _outline(color, UiTokens.BORDER_W_ACTIVE, UiTokens.RADIUS_MD)
		theme.set_stylebox(&"panel", accent, outline)
	for box: StringName in [&"HBoxContainer", &"VBoxContainer"]:
		theme.set_constant(&"separation", box, UiTokens.SPACE_SM)
	var line := StyleBoxLine.new()
	line.color = UiTokens.BORDER
	line.thickness = 1
	theme.set_stylebox(&"separator", &"HSeparator", line)
	var vline := line.duplicate() as StyleBoxLine
	vline.vertical = true
	theme.set_stylebox(&"separator", &"VSeparator", vline)


func _progress(theme: Theme) -> void:
	theme.set_stylebox(&"background", &"ProgressBar", _box(UiTokens.BG_SURFACE, UiTokens.RADIUS_SM))
	theme.set_stylebox(&"fill", &"ProgressBar", _box(UiTokens.GREEN, UiTokens.RADIUS_SM))
	var fills: Dictionary[StringName, Color] = {
		&"ProgressXp": UiTokens.GOLD_BRIGHT,
		&"ProgressEnemy": UiTokens.RED,
		&"ProgressStat": UiTokens.BLUE,
	}
	for type: StringName in fills:
		theme.set_type_variation(type, &"ProgressBar")
		theme.set_stylebox(&"fill", type, _box(fills[type], UiTokens.RADIUS_SM))


func _inputs(theme: Theme) -> void:
	var edit := _button_box(UiTokens.BG_CARD, UiTokens.BORDER)
	theme.set_stylebox(&"normal", &"LineEdit", edit)
	theme.set_stylebox(&"focus", &"LineEdit", _outline(UiTokens.GOLD, UiTokens.BORDER_W))
	theme.set_color(&"font_color", &"LineEdit", UiTokens.TEXT)
	var selected := _button_box(UiTokens.BG_CARD, UiTokens.GOLD)
	for type: StringName in [&"ItemList", &"Tree"]:
		theme.set_stylebox(&"panel", type, _panel(UiTokens.BG_PANEL))
		theme.set_stylebox(&"selected", type, selected)
		theme.set_stylebox(&"selected_focus", type, selected)
		theme.set_color(&"font_color", type, UiTokens.TEXT)
	theme.set_color(&"font_selected_color", &"TabContainer", UiTokens.GOLD)
	theme.set_color(&"font_unselected_color", &"TabContainer", UiTokens.TEXT_MUTED)
	theme.set_color(&"font_hovered_color", &"TabContainer", UiTokens.GOLD_BRIGHT)
	theme.set_stylebox(&"panel", &"TabContainer", _panel(UiTokens.BG_PANEL))
	theme.set_stylebox(
		&"tab_selected", &"TabContainer", _box(UiTokens.BG_PANEL, UiTokens.RADIUS_SM)
	)
	theme.set_stylebox(
		&"tab_unselected", &"TabContainer", _box(UiTokens.BG_CARD, UiTokens.RADIUS_SM)
	)


## Moldura do SlotItem (fundo BG_CARD, borda pela raridade) e do SkillButton (so borda, por
## cima do icone e da recarga).
func _slots(theme: Theme) -> void:
	var frames: Dictionary[StringName, Array] = {
		&"FrameEmpty": [UiTokens.BORDER, UiTokens.BORDER_W, true],
		&"FrameCommon": [UiTokens.RARITY_COMMON, UiTokens.BORDER_W_ACTIVE, true],
		&"FrameRare": [UiTokens.RARITY_RARE, UiTokens.BORDER_W_ACTIVE, true],
		&"FrameEpic": [UiTokens.RARITY_EPIC, UiTokens.BORDER_W_ACTIVE, true],
		&"SkillFrame": [UiTokens.BORDER, UiTokens.BORDER_W, false],
		&"SkillFrameUpgradable": [UiTokens.GOLD, UiTokens.BORDER_W_ACTIVE, false],
	}
	for type: StringName in frames:
		theme.set_type_variation(type, &"Panel")
		var spec: Array = frames[type]
		var frame := _outline(spec[0], spec[1], UiTokens.RADIUS_SM)
		frame.draw_center = spec[2]
		frame.bg_color = UiTokens.BG_CARD
		theme.set_stylebox(&"panel", type, frame)


func _font(path: String, weight: int) -> FontVariation:
	var key := "%s@%d" % [path, weight]
	if not _fonts.has(key):
		var font := FontVariation.new()
		font.base_font = load(path) as FontFile
		var wght := TextServerManager.get_primary_interface().name_to_tag("wght")
		font.variation_opentype = {wght: weight}
		_fonts[key] = font
	return _fonts[key]


func _box(fill: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(radius)
	return box


## Card: fundo, borda BORDER 2 px, raio MD, respiro SPACE_SM (TOKENS §3, §6).
func _panel(fill: Color) -> StyleBoxFlat:
	var box := _box(fill, UiTokens.RADIUS_MD)
	box.border_color = UiTokens.BORDER
	box.set_border_width_all(UiTokens.BORDER_W)
	box.set_content_margin_all(UiTokens.SPACE_SM)
	return box


func _button_box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := _box(fill, UiTokens.RADIUS_MD)
	box.border_color = border
	box.set_border_width_all(UiTokens.BORDER_W)
	box.content_margin_left = UiTokens.SPACE_MD
	box.content_margin_right = UiTokens.SPACE_MD
	box.content_margin_top = UiTokens.SPACE_SM
	box.content_margin_bottom = UiTokens.SPACE_SM
	return box


## So borda, sem fundo (foco, acento, moldura).
func _outline(color: Color, width: int, radius: int = UiTokens.RADIUS_MD) -> StyleBoxFlat:
	var box := _box(Color.TRANSPARENT, radius)
	box.draw_center = false
	box.border_color = color
	box.set_border_width_all(width)
	return box
