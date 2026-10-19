class_name ExitMenu
extends CanvasLayer
## Menu de saida (F80, ADR-0020): Esc abre com "Continuar" e "Sair do jogo"; sair pede confirmacao.
## Online o texto avisa que sair conta como derrota por abandono; no treino, nao. So avisa por
## sinal ([signal leave_confirmed]); quem manda o RPC e encerra o processo e o Main. O jogo nao
## pausa (tempo real): enquanto aberto o heroi local fica parado (PlayerInput.suspended, como o
## Bestiario). Esc com alvo selecionado so solta o alvo: [member can_open] decide.

signal resumed
signal leave_confirmed

enum Step { MENU, CONFIRM, LEAVING }

const THEME: Theme = preload("res://shared/ui/theme/theme_moba.tres")
const LAYER: int = 90
const CARD_WIDTH: float = 520.0
const DIM_ALPHA: float = 0.6

## func() -> bool: o Main diz se o Esc pode abrir agora (nada aberto, sem alvo, partida viva).
var can_open: Callable = func() -> bool: return true

var continue_button: Button
var leave_button: Button
var confirm_button: Button
var back_button: Button

var _online: bool = false
var _step: Step = Step.MENU
var _title: Label
var _message: Label
var _menu_box: VBoxContainer
var _confirm_box: VBoxContainer


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
	card.custom_minimum_size.x = CARD_WIDTH
	center.add_child(card)
	var margin := MarginContainer.new()
	for side: StringName in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		margin.add_theme_constant_override(side, UiTokens.SPACE_LG)
	card.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", UiTokens.SPACE_MD)
	margin.add_child(column)
	_title = Label.new()
	_title.theme_type_variation = &"LabelH1"
	column.add_child(_title)
	_message = Label.new()
	_message.theme_type_variation = &"LabelMuted"
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_message)
	_menu_box = _buttons(column)
	continue_button = _button(_menu_box, tr("Continuar"), &"ButtonPrimary", close)
	leave_button = _button(_menu_box, tr("Sair do jogo"), &"", _ask_confirmation)
	_confirm_box = _buttons(column)
	confirm_button = _button(_confirm_box, tr("Sair"), &"ButtonDanger", _confirm)
	back_button = _button(_confirm_box, tr("Voltar"), &"ButtonPrimary", _back_to_menu)
	_show_step(Step.MENU)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(InputActions.CANCEL) or event.is_echo():
		return
	if not visible:
		if can_open.call():
			open(_online)
			get_viewport().set_input_as_handled()
		return
	match _step:
		Step.MENU:
			close()
		Step.CONFIRM:
			_back_to_menu()
	get_viewport().set_input_as_handled()


func is_open() -> bool:
	return visible


func step() -> Step:
	return _step


## Partida online (sair conta como derrota por abandono) ou treino. O Main define antes do 1o Esc.
func set_online(online: bool) -> void:
	_online = online


func open(online: bool) -> void:
	_online = online
	visible = true
	PlayerInput.suspended = true
	_show_step(Step.MENU)


func close() -> void:
	if not visible:
		return
	visible = false
	PlayerInput.suspended = false
	resumed.emit()


## O Main avisa que o RPC saiu: os botoes travam ate o processo acabar.
func show_leaving() -> void:
	_show_step(Step.LEAVING)


func _ask_confirmation() -> void:
	_show_step(Step.CONFIRM)


func _back_to_menu() -> void:
	_show_step(Step.MENU)


func _confirm() -> void:
	leave_confirmed.emit()


func _show_step(to: Step) -> void:
	_step = to
	_menu_box.visible = to == Step.MENU
	_confirm_box.visible = to == Step.CONFIRM
	match to:
		Step.MENU:
			_title.text = tr("MENU")
			_message.text = tr("O jogo continua enquanto o menu está aberto.")
			continue_button.grab_focus()
		Step.CONFIRM:
			_title.text = tr("SAIR DA PARTIDA?") if _online else tr("SAIR DO TREINO?")
			_message.text = (
				tr("Sair agora conta como derrota por abandono.")
				if _online
				else tr("O treino termina e você volta ao Launcher.")
			)
			back_button.grab_focus()
		Step.LEAVING:
			_title.text = tr("SAINDO…")
			_message.text = tr("Voltando ao Launcher.")


func _buttons(parent: VBoxContainer) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", UiTokens.SPACE_SM)
	parent.add_child(box)
	return box


func _button(
	parent: VBoxContainer, text: String, variation: StringName, action: Callable
) -> Button:
	var button := Button.new()
	if variation != &"":
		button.theme_type_variation = variation
	button.text = text
	button.pressed.connect(action)
	parent.add_child(button)
	return button
