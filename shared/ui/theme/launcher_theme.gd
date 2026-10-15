class_name LauncherTheme
extends RefCounted
## Tipos do Theme das telas do Launcher (F24, TOKENS §7): fontes e acabamento dos prototipos de
## docs/prd/telas/ (decisao do PI em 2026-10-15). Prefixo Ln; a HUD segue com os tipos v2 do
## ThemeBuilder, que chama add() no fim do build. Texto sem contorno (o Label base tem 1 px para a
## arena). Medidas do Tailwind do prototipo: rounded 2 px, rounded-lg 4, rounded-xl 8.

const DIR: String = "res://shared/ui/theme/launcher/"
## Sombras do prototipo: rgba(6,14,32,a) com deslocamento e desfoque em px.
const SHADOW_CARD: float = 0.6
const SHADOW_RAISED: float = 0.7
const SHADOW_BAR: float = 0.8
const SHADOW_BLUR_CARD: int = 20
const SHADOW_BLUR_RAISED: int = 24
const SHADOW_OFFSET: Vector2 = Vector2(0, 4)
const SHADOW_OFFSET_RAISED: Vector2 = Vector2(0, 8)
## Brilho dourado: aba ativa (12 px, 35 %), botao primario (16 px, 45 %), tecla R (8 px, 40 %).
const GLOW_TAB: float = 0.35
const GLOW_PRIMARY: float = 0.45
const GLOW_KEY: float = 0.4
const GLOW_TAB_SIZE: int = 12
const GLOW_PRIMARY_SIZE: int = 16
const GLOW_KEY_SIZE: int = 8
## Borda 3D do botao primario (shadow 0 4px 0) e o afundar de active:translate-y-0.5.
const PRIMARY_EDGE: int = 4
const PRESS_SHIFT: int = 2
## Inset (shadow-[inset_0_2px_4px_rgba(0,0,0,0.8)]) aproximado por borda superior escura.
const INSET: Color = Color(0, 0, 0, 0.8)
const INSET_W: int = 2
## hover:brightness-110 do botao primario.
const BRIGHTEN: float = 0.1
## Barra superior a 95 % (bg-surface-container-low/95) e fundo do modal.
const ALPHA_BAR: float = 0.95
## Espacamento de letras (tracking-wide/wider do prototipo) em px.
const TRACKING: int = 1
## Altura do trilho do slider (h-2).
const SLIDER_TRACK: int = 4
const SCROLL_W: int = 6

## Sufixo -> espacamento dos tipos LnHGap*/LnVGap* (TOKENS §3).
const GAPS: Array[Array] = [
	["None", 0],
	["Xs", UiTokens.SPACE_XS],
	["Sm", UiTokens.SPACE_SM],
	["Md", UiTokens.SPACE_MD],
	["Lg", UiTokens.SPACE_LG],
	["Xl", UiTokens.SPACE_XL],
]
## Variacoes de Label: nome -> [fonte, peso, tamanho, cor].
const LABELS: Dictionary[StringName, Array] = {
	&"LnHeadlineLg":
	[UiTokens.FONT_LN_DISPLAY_PATH, UiTokens.WEIGHT_BOLD, UiTokens.TYPE_LN_HEADLINE_LG, &"TEXT"],
	&"LnHeadlineSm":
	[
		UiTokens.FONT_LN_DISPLAY_PATH,
		UiTokens.WEIGHT_SEMIBOLD,
		UiTokens.TYPE_LN_HEADLINE_SM,
		&"TEXT"
	],
	&"LnHeadlineSmGold":
	[
		UiTokens.FONT_LN_DISPLAY_PATH,
		UiTokens.WEIGHT_SEMIBOLD,
		UiTokens.TYPE_LN_HEADLINE_SM,
		&"GOLD_BRIGHT"
	],
	&"LnBrand":
	[
		UiTokens.FONT_LN_DISPLAY_PATH,
		UiTokens.WEIGHT_BOLD,
		UiTokens.TYPE_LN_HEADLINE_SM,
		&"GOLD_BRIGHT"
	],
	&"LnBody":
	[UiTokens.FONT_LN_BODY_PATH, UiTokens.WEIGHT_REGULAR, UiTokens.TYPE_LN_BODY, &"TEXT"],
	&"LnBodyMuted":
	[UiTokens.FONT_LN_BODY_PATH, UiTokens.WEIGHT_REGULAR, UiTokens.TYPE_LN_BODY, &"TEXT_MUTED"],
	&"LnBodyGold":
	[UiTokens.FONT_LN_BODY_PATH, UiTokens.WEIGHT_MEDIUM, UiTokens.TYPE_LN_BODY, &"GOLD_BRIGHT"],
	&"LnBodySm":
	[UiTokens.FONT_LN_BODY_PATH, UiTokens.WEIGHT_REGULAR, UiTokens.TYPE_LN_BODY_SM, &"TEXT"],
	&"LnBodySmMuted":
	[UiTokens.FONT_LN_BODY_PATH, UiTokens.WEIGHT_REGULAR, UiTokens.TYPE_LN_BODY_SM, &"TEXT_MUTED"],
	&"LnBodySmError":
	[UiTokens.FONT_LN_BODY_PATH, UiTokens.WEIGHT_MEDIUM, UiTokens.TYPE_LN_BODY_SM, &"ERROR"],
	&"LnNum":
	[UiTokens.FONT_LN_MONO_PATH, UiTokens.WEIGHT_BOLD, UiTokens.TYPE_LN_NUM, &"TEXT_MUTED"],
	&"LnNumText": [UiTokens.FONT_LN_MONO_PATH, UiTokens.WEIGHT_BOLD, UiTokens.TYPE_LN_NUM, &"TEXT"],
	&"LnNumGold":
	[UiTokens.FONT_LN_MONO_PATH, UiTokens.WEIGHT_BOLD, UiTokens.TYPE_LN_NUM, &"GOLD_BRIGHT"],
	&"LnNumCyan": [UiTokens.FONT_LN_MONO_PATH, UiTokens.WEIGHT_BOLD, UiTokens.TYPE_LN_NUM, &"CYAN"],
	&"LnIconGold":
	[UiTokens.FONT_ICONS_PATH, UiTokens.WEIGHT_REGULAR, UiTokens.ICON_SM, &"GOLD_BRIGHT"],
	&"LnIconCyan": [UiTokens.FONT_ICONS_PATH, UiTokens.WEIGHT_REGULAR, UiTokens.ICON_SM, &"CYAN"],
	&"LnIconMuted":
	[UiTokens.FONT_ICONS_PATH, UiTokens.WEIGHT_REGULAR, UiTokens.ICON_XL, &"TEXT_MUTED"],
	&"LnIconError": [UiTokens.FONT_ICONS_PATH, UiTokens.WEIGHT_REGULAR, UiTokens.ICON_XL, &"ERROR"],
	&"LnIconLogo":
	[UiTokens.FONT_ICONS_PATH, UiTokens.WEIGHT_REGULAR, UiTokens.ICON_LG, &"GOLD_BRIGHT"],
	&"LnIconTitle":
	[UiTokens.FONT_ICONS_PATH, UiTokens.WEIGHT_REGULAR, UiTokens.ICON_XL, &"GOLD_BRIGHT"],
}
## Variacoes que ganham tracking (uppercase tracking-wide do prototipo).
const TRACKED: Array[StringName] = [&"LnHeadlineSm", &"LnHeadlineSmGold", &"LnBrand", &"LnNum"]

static var _fonts: Dictionary[String, FontVariation] = {}


static func add(theme: Theme) -> void:
	_fonts.clear()
	_gaps(theme)
	_labels(theme)
	_panels(theme)
	_buttons(theme)
	_keys(theme)
	_controls(theme)


## Espacamento entre filhos por token (componente nao usa override, COMPONENTS regra 4):
## LnHGap<Xs..Xl> para HBoxContainer, LnVGap<Xs..Xl> para VBoxContainer.
static func _gaps(theme: Theme) -> void:
	for gap: Array in GAPS:
		for axis: Array in [[&"LnHGap", &"HBoxContainer"], [&"LnVGap", &"VBoxContainer"]]:
			var type := StringName(String(axis[0]) + String(gap[0]))
			theme.set_type_variation(type, axis[1])
			theme.set_constant(&"separation", type, gap[1])


static func _labels(theme: Theme) -> void:
	for type: StringName in LABELS:
		var spec: Array = LABELS[type]
		theme.set_type_variation(type, &"Label")
		theme.set_font(&"font", type, font(spec[0], spec[1], type in TRACKED))
		theme.set_font_size(&"font_size", type, spec[2])
		theme.set_color(&"font_color", type, UiTokens.COLORS[spec[3]])
		theme.set_constant(&"outline_size", type, 0)


static func _panels(theme: Theme) -> void:
	var bar := _box(Color(UiTokens.BG_LOW, ALPHA_BAR), 0)
	_shadow(bar, SHADOW_BAR, SHADOW_BLUR_CARD, SHADOW_OFFSET)
	bar.content_margin_left = UiTokens.SPACE_MARGIN
	bar.content_margin_right = UiTokens.SPACE_MARGIN
	_panel(theme, &"LnAppBar", bar)
	var card := _box(UiTokens.BG_LOW, UiTokens.RADIUS_MD)
	_shadow(card, SHADOW_CARD, SHADOW_BLUR_CARD, SHADOW_OFFSET)
	card.set_content_margin_all(UiTokens.SPACE_LG)
	_panel(theme, &"LnCard", card)
	var raised := card.duplicate() as StyleBoxFlat
	_shadow(raised, SHADOW_RAISED, SHADOW_BLUR_RAISED, SHADOW_OFFSET_RAISED)
	_panel(theme, &"LnCardRaised", raised)
	var ribbon := _box(UiTokens.BG_LOWEST, UiTokens.RADIUS_MD)
	_shadow(ribbon, SHADOW_BAR, SHADOW_BLUR_CARD, SHADOW_OFFSET)
	ribbon.set_content_margin_all(UiTokens.SPACE_MD)
	_panel(theme, &"LnRibbon", ribbon)
	var footer := _box(UiTokens.BG_LOWEST, 0)
	footer.content_margin_left = UiTokens.SPACE_MARGIN
	footer.content_margin_right = UiTokens.SPACE_MARGIN
	_panel(theme, &"LnFooter", footer)
	var row := _box(Color(UiTokens.BG_PANEL, 1.0), UiTokens.RADIUS_XS)
	row.content_margin_left = UiTokens.SPACE_SM
	row.content_margin_right = UiTokens.SPACE_SM
	row.content_margin_top = UiTokens.SPACE_XS
	row.content_margin_bottom = UiTokens.SPACE_XS
	_panel(theme, &"LnRow", row)
	var row_hover := row.duplicate() as StyleBoxFlat
	row_hover.bg_color = Color(UiTokens.BG_CARD, 1.0)
	_panel(theme, &"LnRowHover", row_hover)
	var well := _box(UiTokens.BG_LOWEST, UiTokens.RADIUS_SM)
	_inset(well)
	well.set_content_margin_all(UiTokens.SPACE_SM)
	_panel(theme, &"LnWell", well)
	var chip := _box(UiTokens.BG_HIGHEST, UiTokens.RADIUS_XS)
	chip.content_margin_left = UiTokens.SPACE_XS
	chip.content_margin_right = UiTokens.SPACE_XS
	chip.content_margin_top = 2
	chip.content_margin_bottom = 2
	_panel(theme, &"LnChip", chip)
	var icon_box := _box(UiTokens.BG_HIGHEST, UiTokens.RADIUS_XS)
	icon_box.set_content_margin_all(UiTokens.SPACE_XS)
	_panel(theme, &"LnIconBox", icon_box)
	var logo := _box(UiTokens.BG_HIGHEST, UiTokens.RADIUS_SM)
	_inset(logo)
	logo.set_content_margin_all(UiTokens.SPACE_XS)
	_panel(theme, &"LnLogoBox", logo)
	var modal := card.duplicate() as StyleBoxFlat
	modal.border_color = UiTokens.BORDER
	modal.set_border_width_all(1)
	_panel(theme, &"LnModal", modal)
	var toast := modal.duplicate() as StyleBoxFlat
	toast.set_content_margin_all(UiTokens.SPACE_MD)
	_panel(theme, &"LnToast", toast)
	# Margem do conteudo da tela (px-margin py-space-lg do prototipo).
	theme.set_type_variation(&"LnScreenMargin", &"MarginContainer")
	for side: StringName in [&"margin_left", &"margin_right"]:
		theme.set_constant(side, &"LnScreenMargin", UiTokens.SPACE_MARGIN)
	for side: StringName in [&"margin_top", &"margin_bottom"]:
		theme.set_constant(side, &"LnScreenMargin", UiTokens.SPACE_LG)
	theme.set_type_variation(&"LnDivider", &"HSeparator")
	var line := StyleBoxLine.new()
	line.color = UiTokens.BG_HIGHEST
	line.thickness = 2
	theme.set_stylebox(&"separator", &"LnDivider", line)
	theme.set_constant(&"separation", &"LnDivider", 2)
	theme.set_type_variation(&"LnDividerV", &"VSeparator")
	var vline := StyleBoxLine.new()
	vline.color = UiTokens.BG_HIGHEST
	vline.vertical = true
	vline.thickness = 1
	theme.set_stylebox(&"separator", &"LnDividerV", vline)


static func _buttons(theme: Theme) -> void:
	var display := font(UiTokens.FONT_LN_DISPLAY_PATH, UiTokens.WEIGHT_SEMIBOLD, true)
	# Aba e item do menu (toggle): transparente; hover BG_CARD; ativo GOLD com brilho.
	var tab := _box(Color.TRANSPARENT, UiTokens.RADIUS_SM)
	tab.content_margin_left = UiTokens.SPACE_MD
	tab.content_margin_right = UiTokens.SPACE_MD
	tab.content_margin_top = UiTokens.SPACE_XS
	tab.content_margin_bottom = UiTokens.SPACE_XS
	var tab_hover := _fill(tab, UiTokens.BG_CARD)
	var tab_active := _fill(tab, UiTokens.GOLD)
	_shadow(tab_active, GLOW_TAB, GLOW_TAB_SIZE, Vector2.ZERO, UiTokens.GOLD)
	_button(theme, &"LnTab", [tab, tab_hover, tab_active, tab_active], display)
	_button_colors(theme, &"LnTab", UiTokens.TEXT_MUTED, UiTokens.TEXT, UiTokens.ON_GOLD)
	# Botao secundario: BG_CARD; hover BG_HIGHEST; afunda 2 px ao apertar.
	var ghost := _box(UiTokens.BG_CARD, UiTokens.RADIUS_SM)
	ghost.content_margin_left = UiTokens.SPACE_MD
	ghost.content_margin_right = UiTokens.SPACE_MD
	ghost.content_margin_top = UiTokens.SPACE_SM
	ghost.content_margin_bottom = UiTokens.SPACE_SM
	var ghost_hover := _fill(ghost, UiTokens.BG_HIGHEST)
	_button(theme, &"LnButton", [ghost, ghost_hover, _pressed(ghost_hover), ghost_hover], display)
	_button_colors(theme, &"LnButton", UiTokens.TEXT_MUTED, UiTokens.TEXT, UiTokens.TEXT)
	# Destrutivo (modal): error-container do prototipo.
	var danger := _fill(ghost, UiTokens.ERROR_BG)
	var danger_hover := _fill(ghost, UiTokens.ERROR_BG.lightened(BRIGHTEN))
	_button(
		theme, &"LnButtonDanger", [danger, danger_hover, _pressed(danger), danger_hover], display
	)
	_button_colors(theme, &"LnButtonDanger", UiTokens.ERROR, UiTokens.ERROR, UiTokens.ERROR)
	# Primario: GOLD, borda 3D de 4 px, brilho dourado; hover mais claro.
	var primary := _fill(ghost, UiTokens.GOLD)
	primary.content_margin_left = UiTokens.SPACE_LG
	primary.content_margin_right = UiTokens.SPACE_LG
	primary.border_color = UiTokens.GOLD_EDGE
	primary.border_width_bottom = PRIMARY_EDGE
	_shadow(primary, GLOW_PRIMARY, GLOW_PRIMARY_SIZE, Vector2.ZERO, UiTokens.GOLD)
	var primary_hover := _fill(primary, UiTokens.GOLD.lightened(BRIGHTEN))
	var primary_pressed := _pressed(primary_hover)
	primary_pressed.border_width_bottom = PRIMARY_EDGE - PRESS_SHIFT
	var bold := font(UiTokens.FONT_LN_DISPLAY_PATH, UiTokens.WEIGHT_BOLD, true)
	_button(
		theme, &"LnButtonPrimary", [primary, primary_hover, primary_pressed, primary_hover], bold
	)
	_button_colors(theme, &"LnButtonPrimary", UiTokens.ON_GOLD, UiTokens.ON_GOLD, UiTokens.ON_GOLD)
	# Botao de icone da barra superior (36 x 36): engrenagem e sair.
	var icon_font := font(UiTokens.FONT_ICONS_PATH, UiTokens.WEIGHT_REGULAR)
	var square := _box(UiTokens.BG_CARD, UiTokens.RADIUS_SM)
	square.set_content_margin_all(UiTokens.SPACE_SM)
	var square_hover := _fill(square, UiTokens.BG_HIGHEST)
	_button(theme, &"LnIconButton", [square, square_hover, square_hover, square_hover], icon_font)
	theme.set_font_size(&"font_size", &"LnIconButton", UiTokens.ICON_MD)
	_button_colors(theme, &"LnIconButton", UiTokens.TEXT_MUTED, UiTokens.TEXT, UiTokens.TEXT)
	var power_hover := _fill(square, UiTokens.ERROR_BG)
	_button(
		theme, &"LnIconButtonDanger", [square, power_hover, power_hover, power_hover], icon_font
	)
	theme.set_font_size(&"font_size", &"LnIconButtonDanger", UiTokens.ICON_MD)
	_button_colors(
		theme, &"LnIconButtonDanger", UiTokens.ERROR, UiTokens.ON_ERROR, UiTokens.ON_ERROR
	)
	# Segmento (limite de quadros): BG_HIGHEST; escolhido GOLD.
	var mono := font(UiTokens.FONT_LN_MONO_PATH, UiTokens.WEIGHT_BOLD)
	var seg := _box(UiTokens.BG_HIGHEST, UiTokens.RADIUS_XS)
	seg.content_margin_left = UiTokens.SPACE_SM
	seg.content_margin_right = UiTokens.SPACE_SM
	seg.content_margin_top = 2
	seg.content_margin_bottom = 2
	var seg_on := _fill(seg, UiTokens.GOLD)
	_button(theme, &"LnSegment", [seg, _fill(seg, UiTokens.BG_BRIGHT), seg_on, seg_on], mono)
	theme.set_font_size(&"font_size", &"LnSegment", UiTokens.TYPE_LN_NUM)
	_button_colors(theme, &"LnSegment", UiTokens.TEXT_MUTED, UiTokens.TEXT, UiTokens.ON_GOLD)


## Tecla do mapeamento: BG_LOWEST com inset; hover borda GOLD; escutando (pressed) GOLD.
static func _keys(theme: Theme) -> void:
	var hotkey := font(UiTokens.FONT_LN_DISPLAY_PATH, UiTokens.WEIGHT_BOLD, true)
	var key := _box(UiTokens.BG_LOWEST, UiTokens.RADIUS_XS)
	_inset(key)
	key.content_margin_left = UiTokens.SPACE_SM
	key.content_margin_right = UiTokens.SPACE_SM
	key.content_margin_top = UiTokens.SPACE_XS
	key.content_margin_bottom = UiTokens.SPACE_XS
	var key_hover := key.duplicate() as StyleBoxFlat
	key_hover.border_color = UiTokens.GOLD
	key_hover.set_border_width_all(1)
	var listening := _fill(key, UiTokens.GOLD)
	listening.border_width_top = 0
	_button(theme, &"LnKey", [key, key_hover, listening, listening], hotkey)
	theme.set_font_size(&"font_size", &"LnKey", UiTokens.TYPE_LN_NUM)
	_button_colors(theme, &"LnKey", UiTokens.GOLD_BRIGHT, UiTokens.GOLD_BRIGHT, UiTokens.ON_GOLD)
	theme.set_type_variation(&"LnKeyCyan", &"LnKey")
	for color: StringName in [&"font_color", &"font_hover_color", &"font_focus_color"]:
		theme.set_color(color, &"LnKeyCyan", UiTokens.CYAN)
	theme.set_type_variation(&"LnKeyUltimate", &"LnKey")
	var ultimate := listening.duplicate() as StyleBoxFlat
	_shadow(ultimate, GLOW_KEY, GLOW_KEY_SIZE, Vector2.ZERO, UiTokens.GOLD)
	theme.set_stylebox(&"normal", &"LnKeyUltimate", ultimate)
	theme.set_stylebox(&"hover", &"LnKeyUltimate", ultimate)
	for color: StringName in [&"font_color", &"font_hover_color", &"font_focus_color"]:
		theme.set_color(color, &"LnKeyUltimate", UiTokens.ON_GOLD)
	# Tecla so de leitura (mouse): Label com o mesmo visual.
	theme.set_type_variation(&"LnKeyLabel", &"Label")
	theme.set_stylebox(&"normal", &"LnKeyLabel", key)
	theme.set_font(&"font", &"LnKeyLabel", hotkey)
	theme.set_font_size(&"font_size", &"LnKeyLabel", UiTokens.TYPE_LN_NUM)
	theme.set_color(&"font_color", &"LnKeyLabel", UiTokens.CYAN)
	theme.set_constant(&"outline_size", &"LnKeyLabel", 0)


static func _controls(theme: Theme) -> void:
	var body := font(UiTokens.FONT_LN_BODY_PATH, UiTokens.WEIGHT_REGULAR)
	# Switch (CheckButton): pilula CYAN ligada, BG_HIGHEST desligada.
	theme.set_type_variation(&"LnSwitch", &"CheckButton")
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled"]:
		theme.set_stylebox(state, &"LnSwitch", StyleBoxEmpty.new())
	theme.set_stylebox(&"focus", &"LnSwitch", _focus())
	theme.set_icon(&"checked", &"LnSwitch", _texture("switch_on.svg"))
	theme.set_icon(&"unchecked", &"LnSwitch", _texture("switch_off.svg"))
	theme.set_icon(&"checked_disabled", &"LnSwitch", _texture("switch_on_disabled.svg"))
	theme.set_icon(&"unchecked_disabled", &"LnSwitch", _texture("switch_off_disabled.svg"))
	theme.set_font(&"font", &"LnSwitch", body)
	theme.set_font_size(&"font_size", &"LnSwitch", UiTokens.TYPE_LN_BODY)
	# Slider: trilho BG_LOWEST de 8 px, preenchido GOLD_BRIGHT, pino dourado.
	theme.set_type_variation(&"LnSlider", &"HSlider")
	var track := _box(UiTokens.BG_LOWEST, UiTokens.RADIUS_XS)
	track.content_margin_top = SLIDER_TRACK
	track.content_margin_bottom = SLIDER_TRACK
	var filled := _fill(track, UiTokens.GOLD_BRIGHT)
	theme.set_stylebox(&"slider", &"LnSlider", track)
	theme.set_stylebox(&"grabber_area", &"LnSlider", filled)
	theme.set_stylebox(&"grabber_area_highlight", &"LnSlider", filled)
	theme.set_icon(&"grabber", &"LnSlider", _texture("slider_grabber.svg"))
	theme.set_icon(&"grabber_highlight", &"LnSlider", _texture("slider_grabber_hover.svg"))
	theme.set_stylebox(&"focus", &"LnSlider", _focus())
	# Lista de opcoes (resolucao): texto mono; hover BG_HIGHEST; menu no BG_LOW.
	var option := _box(Color.TRANSPARENT, UiTokens.RADIUS_XS)
	option.content_margin_left = UiTokens.SPACE_SM
	option.content_margin_right = UiTokens.SPACE_SM
	var option_hover := _fill(option, UiTokens.BG_HIGHEST)
	var mono := font(UiTokens.FONT_LN_MONO_PATH, UiTokens.WEIGHT_BOLD)
	theme.set_type_variation(&"LnOption", &"OptionButton")
	for state: Array in [
		[&"normal", option],
		[&"hover", option_hover],
		[&"pressed", option_hover],
		[&"hover_pressed", option_hover],
		[&"disabled", option]
	]:
		theme.set_stylebox(state[0], &"LnOption", state[1])
	theme.set_stylebox(&"focus", &"LnOption", _focus())
	theme.set_font(&"font", &"LnOption", mono)
	theme.set_font_size(&"font_size", &"LnOption", UiTokens.TYPE_LN_NUM)
	_button_colors(theme, &"LnOption", UiTokens.TEXT, UiTokens.GOLD_BRIGHT, UiTokens.GOLD_BRIGHT)
	theme.set_type_variation(&"LnPopup", &"PopupMenu")
	var menu := _box(UiTokens.BG_LOW, UiTokens.RADIUS_SM)
	menu.border_color = UiTokens.BORDER
	menu.set_border_width_all(1)
	menu.set_content_margin_all(UiTokens.SPACE_XS)
	theme.set_stylebox(&"panel", &"LnPopup", menu)
	theme.set_stylebox(&"hover", &"LnPopup", _box(UiTokens.BG_HIGHEST, UiTokens.RADIUS_XS))
	theme.set_font(&"font", &"LnPopup", mono)
	theme.set_font_size(&"font_size", &"LnPopup", UiTokens.TYPE_LN_NUM)
	theme.set_color(&"font_color", &"LnPopup", UiTokens.TEXT)
	theme.set_color(&"font_hover_color", &"LnPopup", UiTokens.GOLD_BRIGHT)
	# Rolagem das listas (creditos): trilho fino BG_LOWEST, barra BG_HIGHEST.
	theme.set_type_variation(&"LnScrollBar", &"VScrollBar")
	var scroll := _box(UiTokens.BG_LOWEST, UiTokens.RADIUS_XS)
	scroll.content_margin_left = SCROLL_W / 2.0
	scroll.content_margin_right = SCROLL_W / 2.0
	var grabber := _box(UiTokens.BG_HIGHEST, UiTokens.RADIUS_XS)
	theme.set_stylebox(&"scroll", &"LnScrollBar", scroll)
	theme.set_stylebox(&"grabber", &"LnScrollBar", grabber)
	theme.set_stylebox(&"grabber_highlight", &"LnScrollBar", _fill(grabber, UiTokens.BG_BRIGHT))
	theme.set_stylebox(&"grabber_pressed", &"LnScrollBar", _fill(grabber, UiTokens.GOLD))


## Fonte variavel no peso pedido, com os icones de fallback (glifo de UiIcons no meio do texto).
static func font(path: String, weight: int, tracked: bool = false) -> FontVariation:
	var key := "%s@%d@%s" % [path, weight, tracked]
	if not _fonts.has(key):
		var variation := FontVariation.new()
		variation.base_font = load(path) as FontFile
		if path != UiTokens.FONT_ICONS_PATH:
			var wght := TextServerManager.get_primary_interface().name_to_tag("wght")
			variation.variation_opentype = {wght: weight}
			variation.fallbacks = [load(UiTokens.FONT_ICONS_PATH) as FontFile]
		if tracked:
			variation.spacing_glyph = TRACKING
		_fonts[key] = variation
	return _fonts[key]


## Estilos [normal, hover, pressed, hover_pressed]; desabilitado = normal a 50 %; foco = contorno.
static func _button(theme: Theme, type: StringName, boxes: Array, text_font: Font) -> void:
	var base := &"Button"
	theme.set_type_variation(type, base)
	theme.set_stylebox(&"normal", type, boxes[0])
	theme.set_stylebox(&"hover", type, boxes[1])
	theme.set_stylebox(&"pressed", type, boxes[2])
	theme.set_stylebox(&"hover_pressed", type, boxes[3])
	var disabled := (boxes[0] as StyleBoxFlat).duplicate() as StyleBoxFlat
	disabled.bg_color.a *= UiTokens.DISABLED_ALPHA
	theme.set_stylebox(&"disabled", type, disabled)
	theme.set_stylebox(&"focus", type, _focus())
	theme.set_font(&"font", type, text_font)
	theme.set_font_size(&"font_size", type, UiTokens.TYPE_LN_HEADLINE_SM)


static func _button_colors(
	theme: Theme, type: StringName, normal: Color, hover: Color, pressed: Color
) -> void:
	theme.set_color(&"font_color", type, normal)
	theme.set_color(&"font_focus_color", type, hover)
	theme.set_color(&"font_hover_color", type, hover)
	theme.set_color(&"font_pressed_color", type, pressed)
	theme.set_color(&"font_hover_pressed_color", type, pressed)
	theme.set_color(&"font_disabled_color", type, Color(normal, UiTokens.DISABLED_ALPHA))
	theme.set_constant(&"outline_size", type, 0)
	theme.set_constant(&"h_separation", type, UiTokens.SPACE_XS)


static func _panel(theme: Theme, type: StringName, box: StyleBox) -> void:
	theme.set_type_variation(type, &"PanelContainer")
	theme.set_stylebox(&"panel", type, box)


static func _box(fill: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(radius)
	box.anti_aliasing = true
	return box


## Copia com outro fundo.
static func _fill(box: StyleBoxFlat, fill: Color) -> StyleBoxFlat:
	var copy := box.duplicate() as StyleBoxFlat
	copy.bg_color = fill
	return copy


## Copia afundada 2 px (active:translate-y-0.5).
static func _pressed(box: StyleBoxFlat) -> StyleBoxFlat:
	var copy := box.duplicate() as StyleBoxFlat
	copy.content_margin_top += PRESS_SHIFT
	copy.content_margin_bottom -= PRESS_SHIFT
	return copy


static func _shadow(
	box: StyleBoxFlat, alpha: float, size: int, offset: Vector2, color: Color = UiTokens.BG_LOWEST
) -> void:
	box.shadow_color = Color(color, alpha)
	box.shadow_size = size
	box.shadow_offset = offset


static func _inset(box: StyleBoxFlat) -> void:
	box.border_color = INSET
	box.border_width_top = INSET_W


## Anel de foco do teclado (P11): contorno GOLD_BRIGHT 2 px.
static func _focus() -> StyleBoxFlat:
	var box := _box(Color.TRANSPARENT, UiTokens.RADIUS_SM)
	box.draw_center = false
	box.border_color = UiTokens.GOLD_BRIGHT
	box.set_border_width_all(UiTokens.BORDER_W)
	box.set_expand_margin_all(UiTokens.BORDER_W)
	return box


static func _texture(file: String) -> Texture2D:
	return load(DIR + file) as Texture2D
