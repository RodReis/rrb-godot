class_name TutorialOverlay
extends CanvasLayer
## Instrucao do tutorial (F85, SPEC-085 §2): cartao no alto da tela com o passo atual, o texto e o
## botao "Pular tutorial" com confirmacao. So exibe: quem decide o passo e o TutorialDirector; quem
## encerra o processo ao pular e o Main (sinal [signal skip_confirmed]). O jogo nao pausa; com a
## confirmacao aberta o heroi fica parado (PlayerInput.suspended, como o ExitMenu).

signal skip_confirmed

const THEME: Theme = preload("res://shared/ui/theme/theme_moba.tres")
## Abaixo do ExitMenu (90) e do bestiario: o menu e a ficha abrem por cima.
const LAYER: int = 80
const CARD_WIDTH: float = 560.0
const CONFIRM_WIDTH: float = 520.0
const TOP_MARGIN: float = 24.0
const DIM_ALPHA: float = 0.6

var skip_button: Button
var confirm_button: Button
var back_button: Button

var _title: Label
var _body: Label
var _card: Control
var _confirm: Control


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var root := Control.new()
	root.theme = THEME
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_card = _build_card()
	root.add_child(_card)
	_confirm = _build_confirm()
	root.add_child(_confirm)


func _unhandled_input(event: InputEvent) -> void:
	if is_confirming() and event.is_action_pressed(InputActions.CANCEL) and not event.is_echo():
		_close_confirm()
		get_viewport().set_input_as_handled()


func is_confirming() -> bool:
	return _confirm != null and _confirm.visible


## Mostra o passo [param step] (titulo com a posicao, instrucao com as teclas de verdade).
func show_step(step: TutorialRules.Step) -> void:
	if step == TutorialRules.Step.DONE:
		_title.text = tr("TUTORIAL CONCLUÍDO")
	else:
		_title.text = (
			"%s %d/%d · %s"
			% [tr("TUTORIAL"), step + 1, TutorialRules.STEP_COUNT, TutorialRules.title(step)]
		)
	_body.text = TutorialRules.instruction(step)
	skip_button.visible = step != TutorialRules.Step.DONE


func _build_card() -> Control:
	var anchor := CenterContainer.new()
	anchor.set_anchors_preset(Control.PRESET_TOP_WIDE)
	anchor.offset_top = TOP_MARGIN
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card := PanelCard.new()
	card.custom_minimum_size.x = CARD_WIDTH
	anchor.add_child(card)
	var column := _padded_column(card)
	_title = Label.new()
	_title.theme_type_variation = &"LabelH2"
	column.add_child(_title)
	_body = Label.new()
	_body.theme_type_variation = &"LabelMuted"
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_body)
	skip_button = Button.new()
	skip_button.text = tr("Pular tutorial")
	skip_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	skip_button.pressed.connect(_ask_confirmation)
	column.add_child(skip_button)
	return anchor


func _build_confirm() -> Control:
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	var dim := ColorRect.new()
	dim.color = Color(Color.BLACK, DIM_ALPHA)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var card := PanelCard.new()
	card.custom_minimum_size.x = CONFIRM_WIDTH
	center.add_child(card)
	var column := _padded_column(card)
	var title := Label.new()
	title.theme_type_variation = &"LabelH1"
	title.text = tr("PULAR O TUTORIAL?")
	column.add_child(title)
	var message := Label.new()
	message.theme_type_variation = &"LabelMuted"
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.text = tr("Você volta ao Launcher e pode refazê-lo quando quiser, pelo botão Tutorial.")
	column.add_child(message)
	confirm_button = Button.new()
	confirm_button.theme_type_variation = &"ButtonDanger"
	confirm_button.text = tr("Pular")
	confirm_button.pressed.connect(_on_confirm_pressed)
	column.add_child(confirm_button)
	back_button = Button.new()
	back_button.theme_type_variation = &"ButtonPrimary"
	back_button.text = tr("Continuar o tutorial")
	back_button.pressed.connect(_close_confirm)
	column.add_child(back_button)
	return overlay


func _padded_column(card: PanelCard) -> VBoxContainer:
	var margin := MarginContainer.new()
	for side: StringName in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		margin.add_theme_constant_override(side, UiTokens.SPACE_LG)
	card.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", UiTokens.SPACE_MD)
	margin.add_child(column)
	return column


func _ask_confirmation() -> void:
	_confirm.visible = true
	PlayerInput.suspended = true
	back_button.grab_focus()


func _close_confirm() -> void:
	_confirm.visible = false
	PlayerInput.suspended = false


func _on_confirm_pressed() -> void:
	_confirm.visible = false
	skip_confirmed.emit()
