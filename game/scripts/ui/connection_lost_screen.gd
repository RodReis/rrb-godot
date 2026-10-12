class_name ConnectionLostScreen
extends CanvasLayer
## Tela de erro quando o servidor encerra ou cai no meio da partida (#102, ARCHITECTURE-GAME §6).
## So avisa e pede o fim do processo por sinal ([signal exit_requested]); quem encerra e o Main.
## Roda com a arvore pausada: o Main pausa tudo para o cliente parar de simular sem peer.

signal exit_requested

const THEME: Theme = preload("res://shared/ui/theme/theme_moba.tres")
const LAYER: int = 100
const CARD_WIDTH: float = 520.0
const DIM_ALPHA: float = 0.7

var exit_button: Button


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var root := Control.new()
	root.theme = THEME
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(Color.BLACK, DIM_ALPHA)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var card := PanelCard.new()
	card.accent = PanelCard.Accent.RED
	card.custom_minimum_size.x = CARD_WIDTH
	center.add_child(card)
	var margin := MarginContainer.new()
	for side: StringName in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		margin.add_theme_constant_override(side, UiTokens.SPACE_LG)
	card.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", UiTokens.SPACE_MD)
	margin.add_child(column)
	var title := Label.new()
	title.theme_type_variation = &"LabelH1"
	title.text = tr("CONEXÃO PERDIDA")
	column.add_child(title)
	var message := Label.new()
	message.theme_type_variation = &"LabelMuted"
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.text = tr("O servidor encerrou ou caiu. A partida não pode continuar.")
	column.add_child(message)
	exit_button = Button.new()
	exit_button.theme_type_variation = &"ButtonPrimary"
	exit_button.text = tr("Sair")
	exit_button.pressed.connect(exit_requested.emit)
	column.add_child(exit_button)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		exit_requested.emit()


## Mostra a tela e leva o foco ao botao (teclado e gamepad).
func present() -> void:
	visible = true
	exit_button.grab_focus()
