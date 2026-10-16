class_name LoadingScreen
extends CanvasLayer
## Tela de loading do Game (F68, SPEC-068): do boot ate a selecao de herois, na fila e no treino.
## Uma das 3 artes (render real da arena de dia, de noite ou dos herois), uma dica de regra
## documentada e a barra do LoadingProgress com o texto da etapa. Tema do Game (HUD v2). So
## apresenta: quem reporta as etapas e o Main. Esc pede o fim do processo por sinal. Servidor
## headless nunca a cria ([method wanted]).

signal exit_requested

const THEME: Theme = preload("res://shared/ui/theme/theme_moba.tres")
## Acima da HUD e da selecao, abaixo da tela de conexao perdida (100).
const LAYER: int = 90
const BAR_HEIGHT: float = 10.0
const SCRIM_HEIGHT_RATIO: float = 0.42
const SCRIM_ALPHA: float = 0.94

## Indice da arte mostrada (LoadingRules.ART_PATHS); -1 antes de show_random.
var art_index: int = -1
var tip_text: String = ""
var progress: LoadingProgress = LoadingProgress.new()

var _art: TextureRect
var _tip: Label
var _status: Label
var _bar: ProgressBar


## So quem desenha tem tela para cobrir (nunca o servidor headless).
static func wanted() -> bool:
	return DisplayServer.get_name() != "headless"


func _ready() -> void:
	layer = LAYER
	visible = false
	_build()


## Mostra a tela com a arte e a dica sorteadas pela [param rng_seed] e zera o progresso.
func show_random(rng_seed: int, tips: TipList) -> void:
	art_index = LoadingRules.art_index(rng_seed)
	_art.texture = load(LoadingRules.ART_PATHS[art_index]) as Texture2D
	var tip_at := LoadingRules.tip_index(rng_seed, tips.tips.size() if tips != null else 0)
	tip_text = tips.tips[tip_at] if tip_at >= 0 else ""
	_tip.text = tr(tip_text)
	_tip.get_parent().visible = tip_at >= 0
	progress = LoadingProgress.new()
	_refresh()
	visible = true


func report(stage: LoadingProgress.Stage, fraction: float) -> void:
	progress.report(stage, fraction)
	_refresh()


func complete(stage: LoadingProgress.Stage) -> void:
	progress.complete(stage)
	_refresh()


func dismiss() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		exit_requested.emit()
		get_viewport().set_input_as_handled()


func _refresh() -> void:
	_bar.value = progress.value()
	var status := progress.status()
	_status.text = tr(status) if not status.is_empty() else ""


func _build() -> void:
	var root := Control.new()
	root.theme = THEME
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var floor_color := ColorRect.new()
	floor_color.color = Color(UiTokens.BG_SURFACE, 1.0)
	floor_color.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(floor_color)
	_art = TextureRect.new()
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(_art)
	root.add_child(_scrim())
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: StringName in [&"margin_left", &"margin_right", &"margin_bottom"]:
		margin.add_theme_constant_override(side, UiTokens.SPACE_SCREEN)
	margin.add_theme_constant_override(&"margin_top", UiTokens.SPACE_SCREEN)
	root.add_child(margin)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_END
	column.add_theme_constant_override(&"separation", UiTokens.SPACE_MD)
	margin.add_child(column)
	column.add_child(_tip_block())
	_status = Label.new()
	_status.theme_type_variation = &"LabelMuted"
	column.add_child(_status)
	_bar = ProgressBar.new()
	_bar.theme_type_variation = &"ProgressXp"
	_bar.min_value = 0.0
	_bar.max_value = 1.0
	_bar.step = 0.0
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0.0, BAR_HEIGHT)
	column.add_child(_bar)
	var hint := Label.new()
	hint.theme_type_variation = &"LabelMuted"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.text = tr("ESC  sair")
	column.add_child(hint)


## Degrade escuro na base: o texto le sobre qualquer uma das 3 artes.
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


func _tip_block() -> VBoxContainer:
	var block := VBoxContainer.new()
	block.add_theme_constant_override(&"separation", UiTokens.SPACE_XS)
	var kicker := Label.new()
	kicker.theme_type_variation = &"LabelBadge"
	kicker.add_theme_color_override(&"font_color", UiTokens.GOLD)
	kicker.text = tr("DICA")
	block.add_child(kicker)
	_tip = Label.new()
	_tip.theme_type_variation = &"LabelH2"
	_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	block.add_child(_tip)
	return block
