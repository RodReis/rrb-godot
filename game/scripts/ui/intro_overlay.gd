class_name IntroOverlay
extends CanvasLayer
## Sobreposicao da cinematica de abertura (F69, SPEC-069 §2): nome do heroi e da classe no canto
## de baixo, no tema do Game (HUD v2). So apresenta; quem decide quando aparecer e a IntroCamera.

const THEME: Theme = preload("res://shared/ui/theme/theme_moba.tres")
## Acima da HUD, abaixo da tela de loading (90).
const LAYER: int = 80
const SCRIM_HEIGHT_RATIO: float = 0.34
const SCRIM_ALPHA: float = 0.85

var _root: Control
var _role: Label
var _name: Label


func _ready() -> void:
	layer = LAYER
	visible = false
	_build()


## Heroi do jogador local; a transparencia vem de [method set_alpha].
func show_hero(data: HeroData) -> void:
	_name.text = tr(data.display_name).to_upper()
	_role.text = tr(data.role).to_upper()
	visible = true


func set_alpha(alpha: float) -> void:
	_root.modulate.a = alpha


func dismiss() -> void:
	visible = false


func _build() -> void:
	_root = Control.new()
	_root.theme = THEME
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.modulate.a = 0.0
	add_child(_root)
	_root.add_child(_scrim())
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: StringName in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		margin.add_theme_constant_override(side, UiTokens.SPACE_SCREEN)
	_root.add_child(margin)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_END
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", UiTokens.SPACE_XS)
	margin.add_child(column)
	_role = Label.new()
	_role.theme_type_variation = &"LabelH2"
	_role.add_theme_color_override(&"font_color", UiTokens.GOLD)
	column.add_child(_role)
	_name = Label.new()
	_name.theme_type_variation = &"LabelH1"
	_name.add_theme_font_size_override(&"font_size", UiTokens.TYPE_VICTORY)
	column.add_child(_name)


## Degrade escuro na base: o texto le sobre o dia e sobre a noite.
func _scrim() -> TextureRect:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(UiTokens.BG_SURFACE, 0.0))
	gradient.set_color(1, Color(UiTokens.BG_SURFACE, SCRIM_ALPHA))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(0.0, 1.0)
	var scrim := TextureRect.new()
	scrim.texture = texture
	scrim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scrim.stretch_mode = TextureRect.STRETCH_SCALE
	scrim.anchor_top = 1.0 - SCRIM_HEIGHT_RATIO
	scrim.anchor_right = 1.0
	scrim.anchor_bottom = 1.0
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return scrim
