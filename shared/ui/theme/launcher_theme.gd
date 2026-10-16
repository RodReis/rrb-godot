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
## Login e Lobby (F25): cartoes sobre o diorama a 90 % (console da fila) e 80 % (cartoes leves),
## celula a 60 %; sombra pequena (shadow) de 4 px; borda 3D do JOGAR (shadow 0 3px 0).
const ALPHA_CONSOLE: float = 0.9
const ALPHA_SOFT: float = 0.8
const ALPHA_CELL: float = 0.6
const SHADOW_BLUR_SM: int = 4
const SHADOW_OFFSET_SM: Vector2 = Vector2(0, 1)
const PLAY_EDGE: int = 3
## Borda 3D do CTA da fila (shadow 0 6px 0 #935600).
const CTA_EDGE: int = 6
## Raio dos pontos de status (rounded-full ate 12 px).
const DOT_RADIUS: int = 6
## Campo de texto: px-10 (40 px, espaco do icone) e py-2.5 (10 px).
const INPUT_PAD_ICON: int = 40
const INPUT_PAD_Y: int = 10
const SELECTION_ALPHA: float = 0.4
## py-0.5 dos selos.
const BADGE_PAD_Y: int = 2

## Perfil (F35): avatar redondo do chip (w-8 h-8 rounded-full), moldura do avatar grande e borda
## do avatar escolhido na grade.
const AVATAR_CHIP_RADIUS: int = 16
const AVATAR_BORDER: int = 2
const AVATAR_PREVIEW_RADIUS: int = 12
## Historico (F26): faixa lateral do cartao (w-1.5), placar a 50 % (bg-lowest/50), py do selo de
## resultado (comum py-0.5, destaque py-1) e px dos contadores dos filtros (px-1.5).
const MATCH_STRIPE: int = 6
const ALPHA_BOARD: float = 0.5
const RESULT_PAD_Y: int = 2
const RESULT_PAD_Y_LG: int = 4
const COUNT_PAD_X: int = 6
const ICON_CARD: int = 16

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
	# Login e Lobby (F25).
	&"LnDisplay":
	[UiTokens.FONT_LN_DISPLAY_PATH, UiTokens.WEIGHT_BOLD, UiTokens.TYPE_LN_DISPLAY, &"TEXT"],
	&"LnDisplayGold":
	[UiTokens.FONT_LN_DISPLAY_PATH, UiTokens.WEIGHT_BOLD, UiTokens.TYPE_LN_DISPLAY, &"GOLD_BRIGHT"],
	&"LnHeadlineMd":
	[
		UiTokens.FONT_LN_DISPLAY_PATH,
		UiTokens.WEIGHT_SEMIBOLD,
		UiTokens.TYPE_LN_HEADLINE_MD,
		&"TEXT"
	],
	&"LnHeadlineMdGold":
	[
		UiTokens.FONT_LN_DISPLAY_PATH,
		UiTokens.WEIGHT_SEMIBOLD,
		UiTokens.TYPE_LN_HEADLINE_MD,
		&"GOLD_BRIGHT"
	],
	&"LnTitle":
	[UiTokens.FONT_LN_DISPLAY_PATH, UiTokens.WEIGHT_SEMIBOLD, UiTokens.TYPE_LN_BODY_LG, &"TEXT"],
	&"LnTitleGold":
	[UiTokens.FONT_LN_DISPLAY_PATH, UiTokens.WEIGHT_BOLD, UiTokens.TYPE_LN_BODY_LG, &"GOLD_BRIGHT"],
	&"LnBodyLg":
	[UiTokens.FONT_LN_BODY_PATH, UiTokens.WEIGHT_MEDIUM, UiTokens.TYPE_LN_BODY_LG, &"TEXT_MUTED"],
	&"LnBodySmGold":
	[UiTokens.FONT_LN_BODY_PATH, UiTokens.WEIGHT_REGULAR, UiTokens.TYPE_LN_BODY_SM, &"GOLD_BRIGHT"],
	&"LnBodySmOutline":
	[
		UiTokens.FONT_LN_BODY_PATH,
		UiTokens.WEIGHT_REGULAR,
		UiTokens.TYPE_LN_BODY_SM,
		&"TEXT_OUTLINE"
	],
	&"LnNumOutline":
	[UiTokens.FONT_LN_MONO_PATH, UiTokens.WEIGHT_BOLD, UiTokens.TYPE_LN_NUM, &"TEXT_OUTLINE"],
	&"LnNumMd":
	[UiTokens.FONT_LN_MONO_PATH, UiTokens.WEIGHT_BOLD, UiTokens.TYPE_LN_NUM_MD, &"TEXT"],
	&"LnNumMdGold":
	[UiTokens.FONT_LN_MONO_PATH, UiTokens.WEIGHT_BOLD, UiTokens.TYPE_LN_NUM_MD, &"GOLD_BRIGHT"],
	&"LnNumMdCyan":
	[UiTokens.FONT_LN_MONO_PATH, UiTokens.WEIGHT_BOLD, UiTokens.TYPE_LN_NUM_MD, &"CYAN"],
	&"LnIconSmMuted":
	[UiTokens.FONT_ICONS_PATH, UiTokens.WEIGHT_REGULAR, UiTokens.ICON_SM, &"TEXT_MUTED"],
	&"LnIconMdGold":
	[UiTokens.FONT_ICONS_PATH, UiTokens.WEIGHT_REGULAR, UiTokens.ICON_LG, &"GOLD_BRIGHT"],
	&"LnIconMdCyan": [UiTokens.FONT_ICONS_PATH, UiTokens.WEIGHT_REGULAR, UiTokens.ICON_LG, &"CYAN"],
	&"LnIconMdGoldDeep":
	[UiTokens.FONT_ICONS_PATH, UiTokens.WEIGHT_REGULAR, UiTokens.ICON_LG, &"GOLD"],
	&"LnIconOnGold":
	[UiTokens.FONT_ICONS_PATH, UiTokens.WEIGHT_REGULAR, UiTokens.ICON_XL, &"ON_PRIMARY"],
	# Historico (F26): rotulo do filtro (inativo, hover, ativo) e icones de 16 px dos cartoes.
	&"LnFilterLabel":
	[
		UiTokens.FONT_LN_DISPLAY_PATH,
		UiTokens.WEIGHT_SEMIBOLD,
		UiTokens.TYPE_LN_HEADLINE_SM,
		&"TEXT_MUTED"
	],
	&"LnFilterLabelHover":
	[
		UiTokens.FONT_LN_DISPLAY_PATH,
		UiTokens.WEIGHT_SEMIBOLD,
		UiTokens.TYPE_LN_HEADLINE_SM,
		&"TEXT"
	],
	&"LnFilterLabelOn":
	[
		UiTokens.FONT_LN_DISPLAY_PATH,
		UiTokens.WEIGHT_SEMIBOLD,
		UiTokens.TYPE_LN_HEADLINE_SM,
		&"ON_GOLD"
	],
	&"LnNumError":
	[UiTokens.FONT_LN_MONO_PATH, UiTokens.WEIGHT_BOLD, UiTokens.TYPE_LN_NUM, &"ERROR"],
	&"LnIconSmGold": [UiTokens.FONT_ICONS_PATH, UiTokens.WEIGHT_REGULAR, ICON_CARD, &"GOLD_BRIGHT"],
	&"LnIconSmError": [UiTokens.FONT_ICONS_PATH, UiTokens.WEIGHT_REGULAR, ICON_CARD, &"ERROR"],
	&"LnIconSmOn": [UiTokens.FONT_ICONS_PATH, UiTokens.WEIGHT_REGULAR, ICON_CARD, &"ON_GOLD"],
	&"LnIconSmCyan": [UiTokens.FONT_ICONS_PATH, UiTokens.WEIGHT_REGULAR, ICON_CARD, &"CYAN"],
	# Perfil (F35): nome no chip do cabecalho (font-headline-sm text-body-sm bold).
	&"LnChipName":
	[UiTokens.FONT_LN_DISPLAY_PATH, UiTokens.WEIGHT_BOLD, UiTokens.TYPE_LN_BODY_SM, &"TEXT"],
}
## Variacoes que ganham tracking (uppercase tracking-wide do prototipo).
const TRACKED: Array[StringName] = [
	&"LnHeadlineSm", &"LnHeadlineSmGold", &"LnBrand", &"LnNum", &"LnNumOutline"
]

static var _fonts: Dictionary[String, FontVariation] = {}


static func add(theme: Theme) -> void:
	_fonts.clear()
	_gaps(theme)
	_labels(theme)
	_panels(theme)
	_buttons(theme)
	_keys(theme)
	_controls(theme)
	_auth_and_lobby(theme)
	_history(theme)
	_profile(theme)
	CompendiumTheme.add(theme)
	ArenaMapTheme.add(theme)


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


## Login e Lobby (F25): campo de texto, abas Entrar/Criar conta, botoes de envio, cartoes do
## lobby sobre o diorama (bg-surface-container-lowest/80-90), celulas, selos e chip de status.
static func _auth_and_lobby(theme: Theme) -> void:
	var display := font(UiTokens.FONT_LN_DISPLAY_PATH, UiTokens.WEIGHT_SEMIBOLD, true)
	var body := font(UiTokens.FONT_LN_BODY_PATH, UiTokens.WEIGHT_REGULAR)
	var mono := font(UiTokens.FONT_LN_MONO_PATH, UiTokens.WEIGHT_BOLD)
	# Cartoes: login (low/95, shadow-2xl), console da fila (lowest/90), cartao leve (lowest/80).
	var glass := _box(Color(UiTokens.BG_LOW, ALPHA_BAR), UiTokens.RADIUS_MD)
	_shadow(glass, SHADOW_RAISED, SHADOW_BLUR_RAISED, SHADOW_OFFSET_RAISED)
	glass.set_content_margin_all(UiTokens.SPACE_LG)
	_panel(theme, &"LnCardGlass", glass)
	var glass_md := glass.duplicate() as StyleBoxFlat
	glass_md.set_content_margin_all(UiTokens.SPACE_MD)
	_panel(theme, &"LnCardGlassMd", glass_md)
	var console := _fill(glass, Color(UiTokens.BG_LOWEST, ALPHA_CONSOLE))
	_panel(theme, &"LnConsole", console)
	var soft := _fill(glass, Color(UiTokens.BG_LOWEST, ALPHA_SOFT))
	soft.set_content_margin_all(UiTokens.SPACE_MD)
	_shadow(soft, SHADOW_CARD, SHADOW_BLUR_CARD, SHADOW_OFFSET)
	_panel(theme, &"LnConsoleSoft", soft)
	_panel(theme, &"LnConsoleSoftHover", _fill(soft, Color(UiTokens.BG_LOW, ALPHA_SOFT)))
	# Chip de vidro sobre a arte do Login (bg-highest/90 backdrop-blur-md, px-2 py-0.5).
	var chip_glass := _box(Color(UiTokens.BG_HIGHEST, ALPHA_CONSOLE), UiTokens.RADIUS_XS)
	chip_glass.content_margin_left = UiTokens.SPACE_SM
	chip_glass.content_margin_right = UiTokens.SPACE_SM
	chip_glass.content_margin_top = BADGE_PAD_Y
	chip_glass.content_margin_bottom = BADGE_PAD_Y
	_panel(theme, &"LnChipGlass", chip_glass)
	# Moldura da arte do Login (h-72 rounded-xl bg-low shadow-xl, sem respiro).
	var art := _box(UiTokens.BG_LOW, UiTokens.RADIUS_MD)
	_shadow(art, SHADOW_RAISED, SHADOW_BLUR_RAISED, SHADOW_OFFSET_RAISED)
	_panel(theme, &"LnArtFrame", art)
	# Margens: tela do Login (lg:p-space-xl) e respiro interno (space-md).
	for margin: Array in [
		[&"LnScreenMarginXl", UiTokens.SPACE_XL], [&"LnInsetMd", UiTokens.SPACE_MD]
	]:
		theme.set_type_variation(margin[0], &"MarginContainer")
		for side: StringName in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
			theme.set_constant(side, margin[0], margin[1])
	# Trilho do sub-menu do lobby (bg-lowest/80 backdrop-blur-xl p-1 rounded-xl shadow-xl).
	var subnav := _fill(soft, Color(UiTokens.BG_LOWEST, ALPHA_SOFT))
	subnav.set_content_margin_all(UiTokens.SPACE_XS)
	_panel(theme, &"LnSubNavTrack", subnav)
	# Trilho das abas (p-1 bg-lowest rounded-lg) e trilho das celulas (p-2 bg-low rounded-lg).
	var track := _box(UiTokens.BG_LOWEST, UiTokens.RADIUS_SM)
	track.set_content_margin_all(UiTokens.SPACE_XS)
	_panel(theme, &"LnTabTrack", track)
	var cells := _box(UiTokens.BG_LOW, UiTokens.RADIUS_SM)
	cells.set_content_margin_all(UiTokens.SPACE_SM)
	_panel(theme, &"LnCellTrack", cells)
	var cell := _box(Color(UiTokens.BG_LOWEST, ALPHA_CELL), UiTokens.RADIUS_XS)
	cell.set_content_margin_all(UiTokens.SPACE_XS)
	_panel(theme, &"LnCell", cell)
	# Linha de modo ativo (bg-surface-container rounded-lg shadow) e faixas de status.
	var mode := _box(Color(UiTokens.BG_PANEL, 1.0), UiTokens.RADIUS_SM)
	mode.set_content_margin_all(UiTokens.SPACE_SM)
	_shadow(mode, SHADOW_CARD, SHADOW_BLUR_SM, SHADOW_OFFSET_SM)
	_panel(theme, &"LnModeRow", mode)
	var banner := _box(Color(UiTokens.BG_CARD, 1.0), UiTokens.RADIUS_SM)
	banner.set_content_margin_all(UiTokens.SPACE_SM)
	_panel(theme, &"LnBanner", banner)
	_panel(theme, &"LnBannerError", _fill(banner, UiTokens.ERROR_BG))
	# Chip de status da barra superior (rounded-xl px-3 py-1): BG_LOWEST para destacar da barra
	# (no prototipo a barra e mais escura que o chip; aqui a barra do F24 ja e BG_LOW).
	var chip := _box(UiTokens.BG_LOWEST, UiTokens.RADIUS_MD)
	chip.content_margin_left = UiTokens.SPACE_MD
	chip.content_margin_right = UiTokens.SPACE_MD
	chip.content_margin_top = UiTokens.SPACE_XS
	chip.content_margin_bottom = UiTokens.SPACE_XS
	_panel(theme, &"LnStatusChip", chip)
	# Caixas de icone: dourada (heroi), card (bento) e alta (relogio da fila).
	var icon_gold := _box(UiTokens.GOLD, UiTokens.RADIUS_SM)
	_inset(icon_gold)
	_panel(theme, &"LnIconBoxGold", icon_gold)
	_panel(theme, &"LnIconBoxCard", _box(Color(UiTokens.BG_PANEL, 1.0), UiTokens.RADIUS_SM))
	var icon_high := _box(Color(UiTokens.BG_CARD, 1.0), UiTokens.RADIUS_SM)
	_inset(icon_high)
	_panel(theme, &"LnIconBoxHigh", icon_high)
	# Selos (Label com fundo): ATIVO (GOLD) e papel do heroi (BG_HIGHEST, texto GOLD_BRIGHT).
	_badge(theme, &"LnBadgeGold", UiTokens.GOLD, UiTokens.ON_PRIMARY, mono)
	_badge(theme, &"LnBadgeChip", UiTokens.BG_HIGHEST, UiTokens.GOLD_BRIGHT, mono)
	# Pontos de status (rounded-full): online, offline, verificando e o da fila (dourado).
	for dot: Array in [
		[&"LnDotOnline", UiTokens.CYAN],
		[&"LnDotOffline", UiTokens.ERROR],
		[&"LnDotChecking", UiTokens.TEXT_MUTED],
		[&"LnDotGold", UiTokens.GOLD_BRIGHT],
	]:
		theme.set_type_variation(dot[0], &"Panel")
		theme.set_stylebox(&"panel", dot[0], _box(dot[1], DOT_RADIUS))
	_buttons_f25(theme, display)
	_input(theme, body)


## Perfil (F35): chip do cabecalho (bg-surface-container rounded-xl, hover mais claro), avatar
## redondo de 32 px, moldura do avatar grande e a grade de avatares (borda dourada no escolhido).
static func _profile(theme: Theme) -> void:
	var chip := _box(Color(UiTokens.BG_PANEL, 1.0), UiTokens.RADIUS_MD)
	chip.content_margin_left = UiTokens.SPACE_XS
	chip.content_margin_right = UiTokens.SPACE_SM
	chip.content_margin_top = UiTokens.SPACE_XS
	chip.content_margin_bottom = UiTokens.SPACE_XS
	_panel(theme, &"LnProfileChip", chip)
	_panel(theme, &"LnProfileChipHover", _fill(chip, Color(UiTokens.BG_CARD, 1.0)))
	var focus := _fill(chip, Color(UiTokens.BG_CARD, 1.0))
	focus.border_color = UiTokens.GOLD_BRIGHT
	focus.set_border_width_all(UiTokens.BORDER_W)
	_panel(theme, &"LnProfileChipFocus", focus)
	_panel(theme, &"LnAvatar", _box(UiTokens.GOLD_BRIGHT, AVATAR_CHIP_RADIUS))
	var preview := _box(UiTokens.BG_LOWEST, AVATAR_PREVIEW_RADIUS)
	preview.border_color = UiTokens.GOLD
	preview.set_border_width_all(AVATAR_BORDER)
	_panel(theme, &"LnAvatarPreview", preview)
	var tile := _box(UiTokens.BG_LOWEST, UiTokens.RADIUS_SM)
	tile.border_color = UiTokens.BG_HIGHEST
	tile.set_border_width_all(AVATAR_BORDER)
	var tile_hover := tile.duplicate() as StyleBoxFlat
	tile_hover.border_color = Color(UiTokens.GOLD, ALPHA_SOFT)
	var tile_on := tile.duplicate() as StyleBoxFlat
	tile_on.border_color = UiTokens.GOLD_BRIGHT
	tile_on.shadow_color = Color(UiTokens.GOLD, GLOW_TAB)
	tile_on.shadow_size = GLOW_TAB_SIZE
	_button(
		theme,
		&"LnAvatarTile",
		[tile, tile_hover, tile_on, tile_on],
		font(UiTokens.FONT_LN_DISPLAY_PATH, UiTokens.WEIGHT_SEMIBOLD)
	)


## Historico (F26, prototipo "Historico de Partidas - Duelos"): cartao de duelo com faixa lateral
## (vitoria GOLD_BRIGHT, derrota ERROR, interrompida TEXT_OUTLINE), selo de resultado, placar,
## moldura de retrato, etiquetas de nivel e papel, filtros e a faixa de rodape.
static func _history(theme: Theme) -> void:
	var display := font(UiTokens.FONT_LN_DISPLAY_PATH, UiTokens.WEIGHT_SEMIBOLD)
	var mono := font(UiTokens.FONT_LN_MONO_PATH, UiTokens.WEIGHT_BOLD)
	# [sufixo, faixa, fundo do selo, texto do selo]
	var outcomes: Array[Array] = [
		["Win", UiTokens.GOLD_BRIGHT, UiTokens.GOLD, UiTokens.ON_GOLD],
		["Loss", UiTokens.ERROR, UiTokens.ERROR_BG, UiTokens.ON_ERROR_CONTAINER],
		["None", UiTokens.TEXT_OUTLINE, UiTokens.BG_HIGHEST, UiTokens.TEXT_MUTED],
	]
	# [sufixo, respiro do cartao, py do selo]: comum (p-md) e destaque (p-lg).
	var sizes: Array[Array] = [
		["", UiTokens.SPACE_MD, RESULT_PAD_Y], ["Lg", UiTokens.SPACE_LG, RESULT_PAD_Y_LG]
	]
	for outcome: Array in outcomes:
		for size: Array in sizes:
			var card := _box(UiTokens.BG_LOW, UiTokens.RADIUS_MD)
			card.border_color = outcome[1]
			card.border_width_left = MATCH_STRIPE
			_shadow(card, SHADOW_CARD, SHADOW_BLUR_CARD, SHADOW_OFFSET)
			card.set_content_margin_all(size[1])
			_panel(theme, StringName("LnMatchCard%s%s" % [outcome[0], size[0]]), card)
			var tag := StringName("LnResult%s%s" % [outcome[0], size[0]])
			_label_box(theme, tag, outcome[2], outcome[3], display, size[2], UiTokens.SPACE_SM)
	var board := _box(Color(UiTokens.BG_LOWEST, ALPHA_BOARD), UiTokens.RADIUS_MD)
	board.set_content_margin_all(UiTokens.SPACE_MD)
	_panel(theme, &"LnMatchBoard", board)
	var chip := _box(UiTokens.BG_LOWEST, UiTokens.RADIUS_SM)
	chip.content_margin_left = UiTokens.SPACE_SM
	chip.content_margin_right = UiTokens.SPACE_SM
	chip.content_margin_top = UiTokens.SPACE_XS
	chip.content_margin_bottom = UiTokens.SPACE_XS
	_panel(theme, &"LnChipLowest", chip)
	var orb := _box(UiTokens.BG_HIGHEST, UiTokens.RADIUS_MD)
	orb.content_margin_left = UiTokens.SPACE_MD
	orb.content_margin_right = UiTokens.SPACE_MD
	orb.content_margin_top = UiTokens.SPACE_SM
	orb.content_margin_bottom = UiTokens.SPACE_SM
	_shadow(orb, SHADOW_CARD, SHADOW_BLUR_SM, SHADOW_OFFSET_SM)
	_panel(theme, &"LnScoreChip", orb)
	_panel(theme, &"LnPortrait", _box(Color(UiTokens.BG_PANEL, 1.0), UiTokens.RADIUS_MD))
	var badge := _box(Color(UiTokens.BG_LOWEST, ALPHA_SOFT), UiTokens.RADIUS_SM)
	badge.content_margin_left = UiTokens.SPACE_MD
	badge.content_margin_right = UiTokens.SPACE_MD
	badge.content_margin_top = UiTokens.SPACE_SM
	badge.content_margin_bottom = UiTokens.SPACE_SM
	_shadow(badge, SHADOW_CARD, SHADOW_BLUR_SM, SHADOW_OFFSET_SM)
	_panel(theme, &"LnSeasonBadge", badge)
	var strip := _box(UiTokens.BG_LOW, UiTokens.RADIUS_MD)
	strip.content_margin_left = UiTokens.SPACE_MD
	strip.content_margin_right = UiTokens.SPACE_MD
	strip.content_margin_top = UiTokens.SPACE_SM
	strip.content_margin_bottom = UiTokens.SPACE_SM
	_panel(theme, &"LnStrip", strip)
	# Etiqueta de nivel no canto do retrato (rounded-tl, px-1, mono 11).
	for tag: Array in [
		[&"LnTagLevelMe", UiTokens.GOLD_BRIGHT, UiTokens.ON_PRIMARY],
		[&"LnTagLevelRival", UiTokens.BG_HIGHEST, UiTokens.TEXT],
	]:
		_label_box(theme, tag[0], tag[1], tag[2], mono, 0, UiTokens.SPACE_XS)
		theme.set_font_size(&"font_size", tag[0], UiTokens.TYPE_LN_NUM)
		var corner := theme.get_stylebox(&"normal", tag[0]) as StyleBoxFlat
		corner.set_corner_radius_all(0)
		corner.corner_radius_top_left = UiTokens.RADIUS_SM
	_badge(theme, &"LnBadgeRoleMe", Color(UiTokens.GOLD_BRIGHT, 0.2), UiTokens.GOLD_BRIGHT, mono)
	_badge(theme, &"LnBadgeRoleRival", UiTokens.BG_HIGHEST, UiTokens.TEXT_MUTED, mono)
	_badge(theme, &"LnCountOn", Color(UiTokens.ON_GOLD, 0.2), UiTokens.ON_GOLD, mono)
	_badge(theme, &"LnCount", UiTokens.BG_LOWEST, UiTokens.TEXT_MUTED, mono)
	for count: StringName in [&"LnCountOn", &"LnCount"]:
		var count_box := theme.get_stylebox(&"normal", count) as StyleBoxFlat
		count_box.content_margin_left = COUNT_PAD_X
		count_box.content_margin_right = COUNT_PAD_X
	# Filtro (toggle): inativo BG_PANEL, hover BG_CARD, ativo GOLD sem brilho (shadow-md).
	var filter := _box(Color(UiTokens.BG_PANEL, 1.0), UiTokens.RADIUS_SM)
	filter.content_margin_left = UiTokens.SPACE_MD
	filter.content_margin_right = UiTokens.SPACE_MD
	filter.content_margin_top = UiTokens.SPACE_XS
	filter.content_margin_bottom = UiTokens.SPACE_XS
	var filter_on := _fill(filter, UiTokens.GOLD)
	_shadow(filter_on, SHADOW_CARD, SHADOW_BLUR_SM, SHADOW_OFFSET_SM)
	var filter_boxes: Array = [filter, _fill(filter, UiTokens.BG_CARD), filter_on, filter_on]
	_button(theme, &"LnFilter", filter_boxes, display)
	_button_colors(theme, &"LnFilter", UiTokens.TEXT_MUTED, UiTokens.TEXT, UiTokens.ON_GOLD)


## Label com fundo e fonte propria (selo de resultado, etiqueta de nivel).
static func _label_box(
	theme: Theme,
	type: StringName,
	fill: Color,
	text: Color,
	text_font: Font,
	pad_y: int,
	pad_x: int
) -> void:
	var box := _box(fill, UiTokens.RADIUS_XS)
	box.content_margin_left = pad_x
	box.content_margin_right = pad_x
	box.content_margin_top = pad_y
	box.content_margin_bottom = pad_y
	theme.set_type_variation(type, &"Label")
	theme.set_stylebox(&"normal", type, box)
	theme.set_font(&"font", type, text_font)
	theme.set_font_size(&"font_size", type, UiTokens.TYPE_LN_HEADLINE_SM)
	theme.set_color(&"font_color", type, text)
	theme.set_constant(&"outline_size", type, 0)


static func _buttons_f25(theme: Theme, display: Font) -> void:
	# Abas Entrar / Criar conta (toggle): ativa bg-surface-container-high + GOLD_BRIGHT.
	var tab := _box(Color.TRANSPARENT, UiTokens.RADIUS_XS)
	tab.content_margin_top = UiTokens.SPACE_XS
	tab.content_margin_bottom = UiTokens.SPACE_XS
	var tab_on := _fill(tab, Color(UiTokens.BG_CARD, 1.0))
	_shadow(tab_on, SHADOW_CARD, SHADOW_BLUR_SM, SHADOW_OFFSET_SM)
	_button(theme, &"LnAuthTab", [tab, tab, tab_on, tab_on], display)
	_button_colors(theme, &"LnAuthTab", UiTokens.TEXT_MUTED, UiTokens.TEXT, UiTokens.GOLD_BRIGHT)
	# Envio do formulario: bg-primary, texto on-primary, rounded-lg, shadow-lg, py-3.
	var submit := _box(UiTokens.GOLD_BRIGHT, UiTokens.RADIUS_SM)
	submit.set_content_margin_all(UiTokens.SPACE_MD)
	_shadow(submit, SHADOW_CARD, SHADOW_BLUR_CARD, SHADOW_OFFSET)
	var submit_hover := _fill(submit, UiTokens.GOLD_BRIGHT.lightened(BRIGHTEN))
	_button(
		theme, &"LnButtonSubmit", [submit, submit_hover, _pressed(submit), submit_hover], display
	)
	theme.set_font_size(&"font_size", &"LnButtonSubmit", UiTokens.TYPE_LN_HEADLINE_MD)
	_button_colors(
		theme, &"LnButtonSubmit", UiTokens.ON_PRIMARY, UiTokens.ON_PRIMARY, UiTokens.ON_PRIMARY
	)
	# Secundario ciano (treino vs bot): bg-surface-container; hover surface-container-high.
	var cyan := _box(Color(UiTokens.BG_PANEL, 1.0), UiTokens.RADIUS_SM)
	cyan.set_content_margin_all(UiTokens.SPACE_SM)
	var cyan_hover := _fill(cyan, Color(UiTokens.BG_CARD, 1.0))
	_button(theme, &"LnButtonCyan", [cyan, cyan_hover, _pressed(cyan_hover), cyan_hover], display)
	_button_colors(theme, &"LnButtonCyan", UiTokens.CYAN, UiTokens.CYAN, UiTokens.CYAN)
	# Sub-menu do lobby: JOGAR (GOLD com borda 3D) e itens planos.
	var nav := _box(Color.TRANSPARENT, UiTokens.RADIUS_SM)
	nav.content_margin_left = UiTokens.SPACE_MD
	nav.content_margin_right = UiTokens.SPACE_MD
	nav.content_margin_top = UiTokens.SPACE_XS
	nav.content_margin_bottom = UiTokens.SPACE_XS
	var nav_hover := _fill(nav, Color(UiTokens.BG_CARD, 1.0))
	_button(theme, &"LnSubNav", [nav, nav_hover, _pressed(nav_hover), nav_hover], display)
	_button_colors(theme, &"LnSubNav", UiTokens.TEXT_MUTED, UiTokens.TEXT, UiTokens.TEXT)
	var play := _fill(nav, UiTokens.GOLD)
	play.content_margin_left = UiTokens.SPACE_LG
	play.content_margin_right = UiTokens.SPACE_LG
	play.border_color = UiTokens.GOLD_SHADE
	play.border_width_bottom = PLAY_EDGE
	var play_pressed := _pressed(play)
	play_pressed.border_width_bottom = PLAY_EDGE - 1
	var play_hover := _fill(play, UiTokens.GOLD.lightened(BRIGHTEN))
	_button(theme, &"LnSubNavPlay", [play, play_hover, play_pressed, play_hover], display)
	_button_colors(
		theme, &"LnSubNavPlay", UiTokens.ON_PRIMARY, UiTokens.ON_PRIMARY, UiTokens.ON_PRIMARY
	)
	# Botoes pequenos dos cartoes do rodape: neutro (BG_HIGHEST) e azul (Iniciar).
	var small := _box(UiTokens.BG_HIGHEST, UiTokens.RADIUS_SM)
	small.content_margin_left = UiTokens.SPACE_SM
	small.content_margin_right = UiTokens.SPACE_SM
	small.content_margin_top = UiTokens.SPACE_XS
	small.content_margin_bottom = UiTokens.SPACE_XS
	var small_hover := _fill(small, Color(UiTokens.BG_PANEL, 1.0))
	_button(
		theme, &"LnButtonSmall", [small, small_hover, _pressed(small_hover), small_hover], display
	)
	theme.set_font_size(&"font_size", &"LnButtonSmall", UiTokens.TYPE_LN_BODY_SM)
	_button_colors(theme, &"LnButtonSmall", UiTokens.TEXT, UiTokens.TEXT, UiTokens.TEXT)
	var blue := _fill(small, UiTokens.BLUE)
	var blue_hover := _fill(small, UiTokens.CYAN)
	_button(
		theme, &"LnButtonSmallBlue", [blue, blue_hover, _pressed(blue_hover), blue_hover], display
	)
	theme.set_font_size(&"font_size", &"LnButtonSmallBlue", UiTokens.TYPE_LN_BODY_SM)
	_button_colors(theme, &"LnButtonSmallBlue", Color.WHITE, UiTokens.ON_CYAN, UiTokens.ON_CYAN)
	# CTA da fila (CtaButton): o fundo e o shader ui_cta; aqui so o texto (headline-lg bold).
	theme.set_type_variation(&"LnButtonCta", &"Button")
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled"]:
		var pad := StyleBoxEmpty.new()
		pad.content_margin_left = UiTokens.SPACE_XL
		pad.content_margin_right = UiTokens.SPACE_XL
		pad.content_margin_top = UiTokens.SPACE_LG
		pad.content_margin_bottom = UiTokens.SPACE_LG + CTA_EDGE
		theme.set_stylebox(state, &"LnButtonCta", pad)
	theme.set_stylebox(&"focus", &"LnButtonCta", _focus())
	var bold := font(UiTokens.FONT_LN_DISPLAY_PATH, UiTokens.WEIGHT_BOLD, true)
	theme.set_font(&"font", &"LnButtonCta", bold)
	theme.set_font_size(&"font_size", &"LnButtonCta", UiTokens.TYPE_LN_HEADLINE_LG)
	_button_colors(
		theme, &"LnButtonCta", UiTokens.ON_PRIMARY, UiTokens.ON_PRIMARY, UiTokens.ON_PRIMARY
	)
	theme.set_constant(&"h_separation", &"LnButtonCta", UiTokens.SPACE_MD)
	# Olho da senha: so o icone, muted; hover TEXT.
	theme.set_type_variation(&"LnIconToggle", &"Button")
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled"]:
		theme.set_stylebox(state, &"LnIconToggle", StyleBoxEmpty.new())
	theme.set_stylebox(&"focus", &"LnIconToggle", _focus())
	theme.set_font(
		&"font", &"LnIconToggle", font(UiTokens.FONT_ICONS_PATH, UiTokens.WEIGHT_REGULAR)
	)
	theme.set_font_size(&"font_size", &"LnIconToggle", UiTokens.ICON_SM)
	_button_colors(theme, &"LnIconToggle", UiTokens.TEXT_MUTED, UiTokens.TEXT, UiTokens.TEXT)


## Campo de texto do Login: bg-lowest, px-10 (icone a esquerda e a direita), py-2.5; foco
## bg-surface-container com filete GOLD embaixo (o foco do teclado precisa aparecer, §5).
static func _input(theme: Theme, body: Font) -> void:
	theme.set_type_variation(&"LnInput", &"LineEdit")
	var field := _box(UiTokens.BG_LOWEST, UiTokens.RADIUS_XS)
	field.content_margin_left = INPUT_PAD_ICON
	field.content_margin_right = INPUT_PAD_ICON
	field.content_margin_top = INPUT_PAD_Y
	field.content_margin_bottom = INPUT_PAD_Y
	theme.set_stylebox(&"normal", &"LnInput", field)
	theme.set_stylebox(&"read_only", &"LnInput", field)
	var focus := _fill(field, Color(UiTokens.BG_PANEL, 1.0))
	focus.border_color = UiTokens.GOLD_BRIGHT
	focus.border_width_bottom = UiTokens.BORDER_W
	theme.set_stylebox(&"focus", &"LnInput", focus)
	theme.set_font(&"font", &"LnInput", body)
	theme.set_font_size(&"font_size", &"LnInput", UiTokens.TYPE_LN_BODY)
	theme.set_color(&"font_color", &"LnInput", UiTokens.TEXT)
	theme.set_color(&"font_placeholder_color", &"LnInput", UiTokens.BORDER)
	theme.set_color(&"caret_color", &"LnInput", UiTokens.GOLD_BRIGHT)
	theme.set_color(&"selection_color", &"LnInput", Color(UiTokens.GOLD, SELECTION_ALPHA))
	theme.set_constant(&"outline_size", &"LnInput", 0)


## Label com fundo (selo): px-1 py-0.5 rounded, mono 11.
static func _badge(theme: Theme, type: StringName, fill: Color, text: Color, mono: Font) -> void:
	var box := _box(fill, UiTokens.RADIUS_XS)
	box.content_margin_left = UiTokens.SPACE_XS
	box.content_margin_right = UiTokens.SPACE_XS
	box.content_margin_top = BADGE_PAD_Y
	box.content_margin_bottom = BADGE_PAD_Y
	theme.set_type_variation(type, &"Label")
	theme.set_stylebox(&"normal", type, box)
	theme.set_font(&"font", type, mono)
	theme.set_font_size(&"font_size", type, UiTokens.TYPE_LN_NUM)
	theme.set_color(&"font_color", type, text)
	theme.set_constant(&"outline_size", type, 0)


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
