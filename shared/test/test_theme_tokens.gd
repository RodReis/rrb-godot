extends GutTest
## theme_moba.tres bate com UiTokens (TOKENS.md §6) e o contraste da tabela do §1 se mantem.
## Theme desatualizado: rode o ThemeBuilder (comando no cabecalho de theme_builder.gd).

const THEME_PATH: String = "res://shared/ui/theme/theme_moba.tres"
const AA_TEXT: float = 4.5
## Texto pequeno passa sobre BG_PANEL (TOKENS §1, ✔).
const READABLE: Array[StringName] = [
	&"GOLD", &"GOLD_BRIGHT", &"BLUE", &"CYAN", &"GREEN", &"TEXT", &"TEXT_MUTED", &"RARITY_COMMON"
]
## So fundo/borda ou texto >= 24 px bold (TOKENS §1, ✘; DEBITO DS-04). RARITY_RARE da 4,46:1
## (a tabela do TOKENS §1 arredonda para 4,5 "limite"): so borda, nunca texto pequeno.
const NOT_READABLE: Array[StringName] = [&"RED", &"PURPLE", &"RARITY_RARE"]

var _theme: Theme


func before_all() -> void:
	_theme = load(THEME_PATH) as Theme


func test_every_token_color_is_in_the_theme() -> void:
	for token: StringName in UiTokens.COLORS:
		assert_true(_theme.has_color(token, ThemeBuilder.GLOBAL_TYPE), "falta %s" % token)
		var color := _theme.get_color(token, ThemeBuilder.GLOBAL_TYPE)
		assert_true(color.is_equal_approx(UiTokens.COLORS[token]), "%s difere" % token)


func test_button_states() -> void:
	assert_color(_flat(&"normal", &"Button").bg_color, UiTokens.BG_CARD)
	assert_color(_flat(&"hover", &"Button").border_color, UiTokens.GOLD)
	assert_color(_flat(&"pressed", &"Button").bg_color, UiTokens.BG_SURFACE)
	var focus := _flat(&"focus", &"Button")
	assert_color(focus.border_color, UiTokens.GOLD_BRIGHT)
	assert_eq(focus.border_width_top, UiTokens.BORDER_W_ACTIVE)
	var disabled := UiTokens.BG_CARD
	disabled.a *= UiTokens.DISABLED_ALPHA
	assert_color(_flat(&"disabled", &"Button").bg_color, disabled)


func test_primary_and_danger_buttons() -> void:
	assert_eq(_theme.get_type_variation_base(&"ButtonPrimary"), &"Button")
	assert_color(_flat(&"normal", &"ButtonPrimary").bg_color, UiTokens.GOLD)
	assert_color(_theme.get_color(&"font_color", &"ButtonPrimary"), UiTokens.BG_SURFACE)
	assert_color(_flat(&"normal", &"ButtonDanger").bg_color, UiTokens.RED)
	assert_color(_theme.get_color(&"font_color", &"ButtonDanger"), UiTokens.TEXT)


func test_panels() -> void:
	var panel := _flat(&"panel", &"PanelContainer")
	assert_color(panel.bg_color, UiTokens.BG_PANEL)
	assert_color(panel.border_color, UiTokens.BORDER)
	assert_eq(panel.border_width_left, UiTokens.BORDER_W)
	assert_eq(panel.corner_radius_top_left, UiTokens.RADIUS_MD)
	assert_color(_flat(&"panel", &"PanelCardSurface").bg_color, UiTokens.BG_SURFACE)
	assert_color(_flat(&"panel", &"PanelCardInner").bg_color, UiTokens.BG_CARD)
	for accent: StringName in PanelCard.ACCENT_TOKENS:
		var outline := _flat(&"panel", accent)
		assert_false(outline.draw_center, accent)
		assert_color(outline.border_color, UiTokens.COLORS[PanelCard.ACCENT_TOKENS[accent]])
		assert_eq(outline.border_width_left, UiTokens.BORDER_W_ACTIVE)


func test_progress_bars() -> void:
	assert_color(_flat(&"background", &"ProgressBar").bg_color, UiTokens.BG_SURFACE)
	assert_color(_flat(&"fill", &"ProgressBar").bg_color, UiTokens.GREEN)
	assert_color(_flat(&"fill", &"ProgressXp").bg_color, UiTokens.GOLD_BRIGHT)
	assert_color(_flat(&"fill", &"ProgressEnemy").bg_color, UiTokens.RED)
	assert_color(_flat(&"fill", &"ProgressStat").bg_color, UiTokens.BLUE)


func test_inputs_lists_tabs_and_separators() -> void:
	assert_color(_flat(&"normal", &"LineEdit").bg_color, UiTokens.BG_CARD)
	assert_color(_flat(&"focus", &"LineEdit").border_color, UiTokens.GOLD)
	for type: StringName in [&"ItemList", &"Tree"]:
		assert_color(_flat(&"panel", type).bg_color, UiTokens.BG_PANEL)
		assert_color(_flat(&"selected", type).bg_color, UiTokens.BG_CARD)
		assert_color(_flat(&"selected", type).border_color, UiTokens.GOLD)
	assert_color(_theme.get_color(&"font_selected_color", &"TabContainer"), UiTokens.GOLD)
	assert_color(_theme.get_color(&"font_unselected_color", &"TabContainer"), UiTokens.TEXT_MUTED)
	for type: StringName in [&"HSeparator", &"VSeparator"]:
		var line := _theme.get_stylebox(&"separator", type) as StyleBoxLine
		assert_color(line.color, UiTokens.BORDER)
		assert_eq(line.thickness, 1)


func test_labels_and_typography() -> void:
	assert_color(_theme.get_color(&"font_color", &"Label"), UiTokens.TEXT)
	assert_eq(_theme.default_font_size, UiTokens.TYPE_BODY)
	var sizes: Dictionary[StringName, int] = {
		&"LabelVictory": UiTokens.TYPE_VICTORY,
		&"LabelH1": UiTokens.TYPE_H1,
		&"LabelH2": UiTokens.TYPE_H2,
		&"LabelBody": UiTokens.TYPE_BODY,
		&"LabelCounter": UiTokens.TYPE_COUNTER,
		&"LabelBadge": UiTokens.TYPE_BADGE,
	}
	for type: StringName in sizes:
		assert_eq(_theme.get_type_variation_base(type), &"Label", type)
		assert_eq(_theme.get_font_size(&"font_size", type), sizes[type], type)
	var counter := _theme.get_font(&"font", &"LabelCounter") as FontVariation
	assert_eq(counter.base_font.resource_path, UiTokens.FONT_MONO_PATH)


func test_every_variation_used_by_components_exists() -> void:
	var used: Array[StringName] = []
	used.append_array(HotkeyBadge.SIZE_TYPES)
	used.append_array(TimerLabel.STATE_TYPES)
	used.append_array(ScoreBanner.SCORE_TYPES)
	used.append_array(StatBar.VARIANT_TYPES)
	used.append_array(PanelCard.VARIANT_TYPES)
	used.append_array(PanelCard.ACCENT_TYPES)
	used.append_array(SlotItem.RARITY_FRAMES)
	used.append_array([SlotItem.EMPTY_FRAME, SkillButton.FRAME_READY, SkillButton.FRAME_UPGRADABLE])
	var types := _theme.get_type_list()
	for type: StringName in used:
		if type != &"":
			assert_has(types, type, "variacao %s fora do Theme" % type)


func test_contrast_over_panel_matches_tokens_table() -> void:
	var panel := Color(UiTokens.BG_PANEL, 1.0)
	for token: StringName in READABLE:
		var ratio := _contrast(UiTokens.COLORS[token], panel)
		assert_gte(ratio, AA_TEXT, "%s: %.2f:1" % [token, ratio])
	for token: StringName in NOT_READABLE:
		assert_lt(_contrast(UiTokens.COLORS[token], panel), AA_TEXT, token)
	# Texto do botao primario (TOKENS §1: 8,6:1).
	assert_gte(_contrast(Color(UiTokens.BG_SURFACE, 1.0), UiTokens.GOLD), AA_TEXT)


func assert_color(got: Color, expected: Color) -> void:
	assert_true(got.is_equal_approx(expected), "esperado %s, veio %s" % [expected, got])


func _flat(name: StringName, type: StringName) -> StyleBoxFlat:
	return _theme.get_stylebox(name, type) as StyleBoxFlat


## Razao de contraste WCAG 2.x entre duas cores opacas.
func _contrast(a: Color, b: Color) -> float:
	var la := _luminance(a)
	var lb := _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _luminance(color: Color) -> float:
	var channels: Array[float] = []
	for c: float in [color.r, color.g, color.b]:
		channels.append(c / 12.92 if c <= 0.03928 else pow((c + 0.055) / 1.055, 2.4))
	return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]
