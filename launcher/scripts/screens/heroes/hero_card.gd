class_name HeroCard
extends Button
## Card de heroi da Tela Herois (F71; prototipo "Tela Herois", article.hero-card): retrato 4:5 com o
## icone da classe no canto e o degrade que o funde com o card, nome e classe embaixo. Botao de
## alternancia: pressionado = selecionado (borda e brilho dourados do Theme), foco por teclado pelo
## anel do Button. O conteudo e um VBox por cima (mouse_filter IGNORE); o tamanho minimo vem dele
## (um Button ignora _get_minimum_size). Tudo sai de HeroData: o prototipo tem maestria, estrelas e
## "M5", que nao existem em shared/data (§8.3 regras 1 e 2).

const ART_HEIGHT: float = 320.0
## Altura do degrade que funde o retrato com o card (h-12 do prototipo).
const FADE_HEIGHT: int = 64
## Caixa do icone da classe (w-6 h-6 do prototipo, ampliada: o card e 1,5x maior).
const CLASS_BOX: Vector2 = Vector2(32, 32)
const BADGE_ALPHA: float = 0.9
## Zoom do retrato com o mouse (group-hover:scale-105, 300 ms).
const ZOOM: float = 1.05
const ZOOM_SECONDS: float = 0.3

var hero: HeroData
## Nome, classe e arma em minusculas, para a busca.
var search_text: String = ""

var _column: VBoxContainer = VBoxContainer.new()
var _art: TextureRect = TextureRect.new()
var _selected_tag: Label = Label.new()
var _zoom_tween: Tween


func _init() -> void:
	theme_type_variation = &"LnHeroCard"
	toggle_mode = true
	clip_contents = true
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	# A borda de 2 px do Theme fica a vista: o conteudo nao a cobre.
	_column.offset_left = UiTokens.BORDER_W
	_column.offset_top = UiTokens.BORDER_W
	_column.offset_right = -UiTokens.BORDER_W
	_column.offset_bottom = -UiTokens.BORDER_W
	_column.theme_type_variation = &"LnVGapNone"
	add_child(_column)
	_column.minimum_size_changed.connect(_on_column_minimum_size_changed)
	mouse_entered.connect(_set_zoom.bind(true))
	mouse_exited.connect(_set_zoom.bind(false))


func bind(data: HeroData) -> void:
	hero = data
	search_text = ("%s %s %s" % [data.display_name, data.role, data.weapon_name]).to_lower()
	_column.add_child(_art_frame(data))
	_column.add_child(_info(data))


## Marca ou desmarca o card sem emitir sinal (quem escolhe e a tela).
func set_selected(selected: bool) -> void:
	set_pressed_no_signal(selected)
	_selected_tag.visible = selected


func is_zoomed() -> bool:
	return _art.scale.x > 1.0


func is_selected_tag_visible() -> bool:
	return _selected_tag.visible


func _art_frame(data: HeroData) -> Control:
	var frame := Control.new()
	frame.custom_minimum_size = Vector2(0.0, ART_HEIGHT)
	frame.clip_contents = true
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_art.texture = HeroesFormat.portrait(data.id)
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.resized.connect(_on_art_resized)
	frame.add_child(_art)
	frame.add_child(_fade())
	var box := PanelContainer.new()
	box.theme_type_variation = &"LnCpIconBox"
	box.custom_minimum_size = CLASS_BOX
	box.set_anchors_and_offsets_preset(PRESET_TOP_RIGHT)
	box.grow_horizontal = GROW_DIRECTION_BEGIN
	box.offset_top = UiTokens.SPACE_SM
	box.offset_right = -UiTokens.SPACE_SM
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glyph := Label.new()
	glyph.theme_type_variation = &"LnIconSmCyan"
	glyph.text = HeroesFormat.class_icon(data.role)
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(glyph)
	frame.add_child(box)
	_selected_tag.theme_type_variation = &"LnCpBadgeT3"
	_selected_tag.text = tr("SELECIONADO")
	_selected_tag.position = Vector2(UiTokens.SPACE_SM, UiTokens.SPACE_SM)
	_selected_tag.visible = button_pressed
	_selected_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(_selected_tag)
	return frame


## Degrade que funde o retrato com o fundo do card (from-surface-container-lowest).
func _fade() -> TextureRect:
	var gradient := Gradient.new()
	var solid := Color(UiTokens.BG_PANEL, 1.0)
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	gradient.colors = PackedColorArray([Color(solid, 0.0), solid])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 1
	texture.height = FADE_HEIGHT
	texture.fill_from = Vector2.ZERO
	texture.fill_to = Vector2(0.0, 1.0)
	var fade := TextureRect.new()
	fade.texture = texture
	fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade.stretch_mode = TextureRect.STRETCH_SCALE
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
	fade.offset_top = -FADE_HEIGHT
	return fade


func _info(data: HeroData) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.theme_type_variation = &"LnCpTagMargin"
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lines := VBoxContainer.new()
	lines.theme_type_variation = &"LnVGapXs"
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(lines)
	var title := Label.new()
	title.theme_type_variation = &"LnHeadlineSm"
	title.text = data.display_name
	title.clip_text = true
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.add_child(title)
	var role := Label.new()
	role.theme_type_variation = &"LnBodySmCyan"
	role.text = "%s  %s" % [HeroesFormat.class_icon(data.role), data.role]
	role.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.add_child(role)
	return margin


func _set_zoom(zoomed: bool) -> void:
	if _zoom_tween != null:
		_zoom_tween.kill()
	_zoom_tween = create_tween()
	(
		_zoom_tween
		. tween_property(_art, ^"scale", Vector2.ONE * (ZOOM if zoomed else 1.0), ZOOM_SECONDS)
		. set_ease(Tween.EASE_OUT)
	)


func _on_art_resized() -> void:
	_art.pivot_offset = _art.size / 2.0


func _on_column_minimum_size_changed() -> void:
	custom_minimum_size = (
		_column.get_combined_minimum_size() + Vector2.ONE * 2.0 * UiTokens.BORDER_W
	)
