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
## Variacoes com contorno de 2 px (as demais herdam o de 1 px do Label).
const OUTLINE_LARGE: Array[StringName] = [&"LabelVictory", &"LabelH1", &"LabelH2", &"LabelCounter"]
## Molduras StyleBoxTexture (TOKENS v2), renderizadas por art/ui/build_frames.py:
## caminho, margem 9-slice e respiro do conteudo (px).
const FRAMES_DIR: String = "res://shared/ui/theme/frames/"
const FRAME_PANEL: String = FRAMES_DIR + "frame_panel.png"
const FRAME_SURFACE: String = FRAMES_DIR + "frame_surface.png"
const FRAME_SKILL: String = FRAMES_DIR + "frame_skill.png"
const FRAME_SKILL_GOLD: String = FRAMES_DIR + "frame_skill_gold.png"
const BADGE_KEY: String = FRAMES_DIR + "badge_key.png"
const FRAME_MARGIN: int = 24
const FRAME_CONTENT: int = 16
const SKILL_MARGIN: int = 16
const BADGE_MARGIN: int = 8
## Fill da ghost bar do StatBar: clara, para o dano recente se destacar do GREEN/RED.
const GHOST_FILL: Color = Color(UiTokens.TEXT, 0.85)
## Selecao de herois (F51, prototipo): lado -> acento (voce CYAN, oponente RED). Gera os tipos
## Hero<Lado>Card/Cell/Skill/Tag/TagSoft/Badge/Icon.
const HERO_SIDES: Dictionary[StringName, Color] = {&"Ally": UiTokens.CYAN, &"Enemy": UiTokens.RED}
## Alfas do prototipo (Tailwind /80, /30, /15) e escurecimento da celula sobre o card.
const ALPHA_BORDER: float = 0.8
const ALPHA_GLOW: float = 0.4
const ALPHA_EDGE: float = 0.3
const ALPHA_SOFT: float = 0.15
const ALPHA_SHADE: float = 0.35
## Raio "cheio" da barra de atributo (rounded-full).
const RADIUS_PILL: int = 9

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
	_hero_select(theme)
	return theme


func _labels(theme: Theme) -> void:
	theme.set_color(&"font_color", &"Label", UiTokens.TEXT)
	theme.set_color(&"font_outline_color", &"Label", UiTokens.OUTLINE)
	theme.set_constant(&"outline_size", &"Label", UiTokens.OUTLINE_W)
	for type: StringName in LABELS:
		var spec: Array = LABELS[type]
		theme.set_type_variation(type, &"Label")
		theme.set_font(&"font", type, _font(spec[0], spec[1]))
		theme.set_font_size(&"font_size", type, spec[2])
	for type: StringName in OUTLINE_LARGE:
		theme.set_constant(&"outline_size", type, UiTokens.OUTLINE_W_LARGE)
	theme.set_color(&"font_color", &"LabelBadge", UiTokens.TEXT_MUTED)
	theme.set_type_variation(&"LabelMuted", &"Label")
	theme.set_color(&"font_color", &"LabelMuted", UiTokens.TEXT_MUTED)
	# TimerLabel: aviso e perigo (PATTERNS P7). RED so em texto >= 24 px bold (TOKENS §1).
	theme.set_type_variation(&"LabelCounterWarning", &"LabelCounter")
	theme.set_color(&"font_color", &"LabelCounterWarning", UiTokens.GOLD)
	theme.set_type_variation(&"LabelCounterDanger", &"LabelCounter")
	theme.set_color(&"font_color", &"LabelCounterDanger", UiTokens.RED)
	# ScoreBanner: kills de quem joga (as do adversario usam o Danger).
	theme.set_type_variation(&"LabelCounterAlly", &"LabelCounter")
	theme.set_color(&"font_color", &"LabelCounterAlly", UiTokens.GREEN)
	# HotkeyBadge MD: badge metalica sobre o icone da skill (TOKENS v2).
	theme.set_type_variation(&"LabelBadgeMd", &"LabelBadge")
	theme.set_color(&"font_color", &"LabelBadgeMd", UiTokens.TEXT)
	var badge := _frame(BADGE_KEY, BADGE_MARGIN, UiTokens.SPACE_XS)
	badge.content_margin_left = UiTokens.SPACE_SM
	badge.content_margin_right = UiTokens.SPACE_SM
	theme.set_stylebox(&"normal", &"LabelBadgeMd", badge)
	theme.set_color(&"font_color", &"TooltipLabel", UiTokens.TEXT)
	# O Godot embrulha todo tooltip num TooltipPanel: vazio, para o ItemTooltip (PanelCard) nao
	# ganhar borda dupla; o tooltip de texto desenha o proprio card no TooltipLabel.
	theme.set_stylebox(&"panel", &"TooltipPanel", StyleBoxEmpty.new())
	theme.set_stylebox(&"normal", &"TooltipLabel", _frame(FRAME_PANEL, FRAME_MARGIN, FRAME_CONTENT))


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
	# Paineis com moldura de metal (TOKENS v2); o card interno (celula) fica liso.
	theme.set_stylebox(
		&"panel", &"PanelContainer", _frame(FRAME_PANEL, FRAME_MARGIN, FRAME_CONTENT)
	)
	theme.set_type_variation(&"PanelCardSurface", &"PanelContainer")
	var surface := _frame(FRAME_SURFACE, FRAME_MARGIN, FRAME_CONTENT)
	theme.set_stylebox(&"panel", &"PanelCardSurface", surface)
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
	theme.set_type_variation(StatBar.GHOST_TYPE, &"ProgressBar")
	theme.set_stylebox(&"fill", StatBar.GHOST_TYPE, _box(GHOST_FILL, UiTokens.RADIUS_SM))


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
	}
	for type: StringName in frames:
		theme.set_type_variation(type, &"Panel")
		var spec: Array = frames[type]
		var frame := _outline(spec[0], spec[1], UiTokens.RADIUS_SM)
		frame.draw_center = spec[2]
		frame.bg_color = UiTokens.BG_CARD
		theme.set_stylebox(&"panel", type, frame)
	# SkillButton: so a moldura, por cima do icone e da recarga.
	theme.set_type_variation(SkillButton.FRAME_READY, &"Panel")
	theme.set_stylebox(&"panel", SkillButton.FRAME_READY, _frame(FRAME_SKILL, SKILL_MARGIN, 0))
	theme.set_type_variation(SkillButton.FRAME_UPGRADABLE, &"Panel")
	var gold := _frame(FRAME_SKILL_GOLD, SKILL_MARGIN, 0)
	theme.set_stylebox(&"panel", SkillButton.FRAME_UPGRADABLE, gold)


## Selecao de herois (F51): cards com brilho neon por lado, celulas, tags, badges, card de heroi
## da grade, botao de lock-in (o gradiente e um RunicBackdrop atras), cabecalho, rodape e barra.
func _hero_select(theme: Theme) -> void:
	for side: StringName in HERO_SIDES:
		var color: Color = HERO_SIDES[side]
		var prefix := "Hero" + side
		var card := _hero_box(UiTokens.BG_SURFACE, Color(color, ALPHA_BORDER), UiTokens.BORDER_W)
		card.set_corner_radius_all(UiTokens.RADIUS_LG)
		card.set_content_margin_all(UiTokens.SPACE_LG)
		_glow(card, Color(color, ALPHA_GLOW))
		_panel_variation(theme, prefix + "Card", card)
		var cell := _hero_box(Color(Color.BLACK, ALPHA_SHADE), Color(color, ALPHA_EDGE), 1)
		cell.set_content_margin_all(UiTokens.SPACE_MD)
		_panel_variation(theme, prefix + "Cell", cell)
		var skill := _hero_box(Color(color, ALPHA_SOFT), Color(color, ALPHA_EDGE), 1)
		skill.set_content_margin_all(UiTokens.SPACE_SM)
		_panel_variation(theme, prefix + "Skill", skill)
		_panel_variation(theme, prefix + "Tag", _hero_tag(Color(color, ALPHA_SOFT), color))
		var soft := _hero_tag(Color(Color.BLACK, ALPHA_SHADE), Color(color, ALPHA_EDGE))
		_panel_variation(theme, prefix + "TagSoft", soft)
		_panel_variation(theme, prefix + "Badge", _hero_tag(color, color))
		var icon := _hero_box(Color(color, ALPHA_SOFT), color, 1)
		icon.set_content_margin_all(UiTokens.SPACE_XS)
		_panel_variation(theme, prefix + "Icon", icon)
	var ultimate := _hero_box(Color(UiTokens.GOLD, ALPHA_SOFT), Color(UiTokens.GOLD, ALPHA_GLOW), 1)
	ultimate.set_content_margin_all(UiTokens.SPACE_SM)
	_panel_variation(theme, "HeroGoldSkill", ultimate)
	_panel_variation(theme, "HeroGoldBadge", _hero_tag(UiTokens.GOLD, UiTokens.GOLD))
	var roster := _hero_box(Color(UiTokens.BG_SURFACE, 0.6), UiTokens.BORDER, 1)
	roster.set_corner_radius_all(UiTokens.RADIUS_LG)
	roster.set_content_margin_all(UiTokens.SPACE_LG)
	_glow(roster, Color(Color.BLACK, 0.5))
	_panel_variation(theme, "HeroRoster", roster)
	var timer := _hero_box(UiTokens.BG_SURFACE, Color(UiTokens.GOLD, ALPHA_EDGE), 1)
	timer.set_corner_radius_all(UiTokens.RADIUS_LG)
	timer.content_margin_left = UiTokens.SPACE_LG
	timer.content_margin_right = UiTokens.SPACE_LG
	timer.content_margin_top = UiTokens.SPACE_XS
	timer.content_margin_bottom = UiTokens.SPACE_XS
	_glow(timer, Color(UiTokens.GOLD, 0.2))
	_panel_variation(theme, "HeroTimer", timer)
	_hero_bars(theme)
	_hero_choice(theme)
	_hero_lock_in(theme)
	_hero_labels(theme)


## Cabecalho e rodape (faixas com uma borda so) e barra de atributo do card.
func _hero_bars(theme: Theme) -> void:
	var header := _box(Color(Color.BLACK, ALPHA_SHADE), 0)
	header.border_color = Color(UiTokens.CYAN, 0.2)
	header.border_width_bottom = 1
	header.content_margin_left = UiTokens.SPACE_SCREEN
	header.content_margin_right = UiTokens.SPACE_SCREEN
	header.content_margin_top = UiTokens.SPACE_MD
	header.content_margin_bottom = UiTokens.SPACE_MD
	_panel_variation(theme, "HeroHeader", header)
	var footer := header.duplicate() as StyleBoxFlat
	footer.border_color = UiTokens.BORDER
	footer.border_width_bottom = 0
	footer.border_width_top = 1
	footer.content_margin_top = UiTokens.SPACE_SM
	footer.content_margin_bottom = UiTokens.SPACE_SM
	_panel_variation(theme, "HeroFooter", footer)
	theme.set_type_variation(&"ProgressHero", &"ProgressBar")
	var track := _box(Color(Color.BLACK, ALPHA_SHADE), RADIUS_PILL)
	track.border_color = UiTokens.BG_CARD
	track.set_border_width_all(1)
	theme.set_stylebox(&"background", &"ProgressHero", track)
	var fill := _box(UiTokens.CYAN, RADIUS_PILL)
	fill.shadow_color = Color(UiTokens.CYAN, ALPHA_GLOW)
	fill.shadow_size = UiTokens.SPACE_SM
	theme.set_stylebox(&"fill", &"ProgressHero", fill)


## Card de heroi da grade: normal / hover (borda GOLD) / ativo (fundo e borda GOLD, brilho) e
## a moldura do retrato.
func _hero_choice(theme: Theme) -> void:
	var normal := _hero_box(Color(UiTokens.BG_SURFACE, 0.8), UiTokens.BORDER, 1)
	normal.set_content_margin_all(UiTokens.SPACE_MD)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = UiTokens.BG_CARD
	hover.border_color = Color(UiTokens.GOLD, 0.6)
	var active := _hero_box(Color(UiTokens.GOLD, 0.12), UiTokens.GOLD, UiTokens.BORDER_W)
	active.set_content_margin_all(UiTokens.SPACE_MD)
	_glow(active, Color(UiTokens.GOLD, ALPHA_EDGE))
	var focus := _outline(UiTokens.GOLD_BRIGHT, UiTokens.BORDER_W_ACTIVE)
	for type: StringName in [&"HeroChoice", &"HeroChoiceActive"]:
		theme.set_type_variation(type, &"Button")
		var base := normal if type == &"HeroChoice" else active
		theme.set_stylebox(&"normal", type, base)
		theme.set_stylebox(&"hover", type, hover if type == &"HeroChoice" else active)
		theme.set_stylebox(&"pressed", type, active)
		theme.set_stylebox(&"hover_pressed", type, active)
		theme.set_stylebox(&"disabled", type, base)
		theme.set_stylebox(&"focus", type, focus)
	var portrait := _hero_box(UiTokens.BG_SURFACE, UiTokens.BORDER, 1)
	_panel_variation(theme, "HeroPortrait", portrait)
	var lit := _hero_box(UiTokens.BG_SURFACE, Color(UiTokens.GOLD, 0.6), 1)
	_panel_variation(theme, "HeroPortraitActive", lit)


## Lock-in: o botao so tem texto e foco; o brilho e a moldura dourada sao o painel atras.
func _hero_lock_in(theme: Theme) -> void:
	var glow := _hero_box(UiTokens.GOLD, UiTokens.GOLD_BRIGHT, UiTokens.BORDER_W)
	glow.set_corner_radius_all(UiTokens.RADIUS_LG)
	_glow(glow, Color(UiTokens.GOLD, 0.5))
	_panel_variation(theme, "HeroLockInGlow", glow)
	theme.set_type_variation(&"ButtonLockIn", &"Button")
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled"]:
		theme.set_stylebox(state, &"ButtonLockIn", StyleBoxEmpty.new())
	var focus := _outline(UiTokens.TEXT, UiTokens.BORDER_W_ACTIVE, UiTokens.RADIUS_LG)
	theme.set_stylebox(&"focus", &"ButtonLockIn", focus)
	theme.set_font(
		&"font", &"ButtonLockIn", _font(UiTokens.FONT_DISPLAY_PATH, UiTokens.WEIGHT_BOLD)
	)
	theme.set_font_size(&"font_size", &"ButtonLockIn", UiTokens.TYPE_H2)
	for color: StringName in [
		&"font_color",
		&"font_hover_color",
		&"font_focus_color",
		&"font_pressed_color",
		&"font_hover_pressed_color",
		&"font_disabled_color",
		&"icon_normal_color",
		&"icon_hover_color",
		&"icon_focus_color",
		&"icon_pressed_color",
		&"icon_hover_pressed_color",
		&"icon_disabled_color",
	]:
		theme.set_color(color, &"ButtonLockIn", UiTokens.BG_SURFACE)


## Textos coloridos da selecao: acento CYAN, titulo GOLD, destaque GOLD_BRIGHT, pronto GREEN e
## texto escuro sem contorno sobre badge (RED nunca em texto pequeno, TOKENS §1).
func _hero_labels(theme: Theme) -> void:
	var bold := _font(UiTokens.FONT_DATA_PATH, UiTokens.WEIGHT_BOLD)
	var colors: Dictionary[StringName, Color] = {
		&"LabelHeroAccent": UiTokens.CYAN,
		&"LabelHeroHighlight": UiTokens.GOLD_BRIGHT,
		&"LabelHeroReady": UiTokens.GREEN,
	}
	for type: StringName in colors:
		theme.set_type_variation(type, &"Label")
		theme.set_color(&"font_color", type, colors[type])
		theme.set_font(&"font", type, bold)
	theme.set_type_variation(&"LabelHeroStrong", &"Label")
	theme.set_font(&"font", &"LabelHeroStrong", bold)
	theme.set_type_variation(&"LabelHeroTitle", &"LabelH2")
	theme.set_color(&"font_color", &"LabelHeroTitle", UiTokens.GOLD)
	theme.set_type_variation(&"LabelHeroMode", &"LabelH1")
	theme.set_color(&"font_color", &"LabelHeroMode", UiTokens.GOLD_BRIGHT)
	# Ponto de status (circulo cheio): voce, oponente, pronto, escolhendo.
	var dots: Dictionary[StringName, Color] = {
		&"HeroDotAlly": UiTokens.CYAN,
		&"HeroDotEnemy": UiTokens.RED,
		&"HeroDotReady": UiTokens.GREEN,
		&"HeroDotWaiting": UiTokens.GOLD_BRIGHT,
	}
	for type: StringName in dots:
		theme.set_type_variation(type, &"Panel")
		theme.set_stylebox(&"panel", type, _box(dots[type], UiTokens.SPACE_SM))
	theme.set_type_variation(&"LabelHeroDark", &"LabelBadge")
	theme.set_color(&"font_color", &"LabelHeroDark", UiTokens.BG_SURFACE)
	theme.set_font(&"font", &"LabelHeroDark", bold)
	theme.set_constant(&"outline_size", &"LabelHeroDark", 0)


func _panel_variation(theme: Theme, type: StringName, box: StyleBox) -> void:
	theme.set_type_variation(type, &"PanelContainer")
	theme.set_stylebox(&"panel", type, box)


## Caixa da selecao: fundo, borda de [param width] px e raio MD.
func _hero_box(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var box := _box(fill, UiTokens.RADIUS_MD)
	box.border_color = border
	box.set_border_width_all(width)
	return box


## Tag/badge: raio SM, respiro horizontal maior que o vertical.
func _hero_tag(fill: Color, border: Color) -> StyleBoxFlat:
	var box := _hero_box(fill, border, 1)
	box.set_corner_radius_all(UiTokens.RADIUS_SM)
	box.content_margin_left = UiTokens.SPACE_SM
	box.content_margin_right = UiTokens.SPACE_SM
	box.content_margin_top = 2
	box.content_margin_bottom = 2
	return box


## Brilho neon (box-shadow do prototipo) como sombra do StyleBoxFlat.
func _glow(box: StyleBoxFlat, color: Color) -> void:
	box.shadow_color = color
	box.shadow_size = UiTokens.SIZE_GLOW


func _font(path: String, weight: int) -> FontVariation:
	var key := "%s@%d" % [path, weight]
	if not _fonts.has(key):
		var font := FontVariation.new()
		font.base_font = load(path) as FontFile
		var wght := TextServerManager.get_primary_interface().name_to_tag("wght")
		font.variation_opentype = {wght: weight}
		if path == UiTokens.FONT_MONO_PATH:
			# Algarismos tabulares: relogio e placar nao "dancam" quando o numero muda.
			var tnum := TextServerManager.get_primary_interface().name_to_tag("tnum")
			font.opentype_features = {tnum: 1}
		_fonts[key] = font
	return _fonts[key]


## Moldura 9-slice: [param margin] na textura, [param content] de respiro.
func _frame(path: String, margin: int, content: int) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = load(path) as Texture2D
	box.set_texture_margin_all(margin)
	box.set_content_margin_all(content)
	return box


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
