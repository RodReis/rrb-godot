class_name StateBox
extends MarginContainer
## Os 5 estados de dado remoto (COMPONENTS.md, PATTERNS P5, FRONTEND-LAUNCHER §3): o conteudo
## (filhos comuns) so aparece em READY; LOADING (spinner, so depois de 150 ms para nao piscar),
## EMPTY (frase curta) e ERROR (mensagem + "Tentar de novo") ocupam o lugar dele.

signal retry_requested

enum State { IDLE, LOADING, READY, EMPTY, ERROR }

## P5: o spinner so aparece se o carregamento passar disso.
const LOADING_DELAY: float = 0.15
## Uma volta do spinner.
const SPIN_PERIOD: float = 1.0
## Indice = State; vazio = sem icone.
const ICONS: Array[String] = ["", UiIcons.PROGRESS_ACTIVITY, "", UiIcons.INBOX, UiIcons.ERROR]
const ICON_TYPES: Array[StringName] = [&"", &"LnIconMuted", &"", &"LnIconMuted", &"LnIconError"]

var state: State = State.IDLE

## Coluna na largura toda (texto com quebra precisa de largura; CenterContainer daria o minimo).
var _overlay: VBoxContainer = VBoxContainer.new()
var _icon: Label = Label.new()
var _message: Label = Label.new()
var _retry: Button = Button.new()
var _spin: Tween
## Cada set_state invalida o atraso do LOADING anterior.
var _request: int = 0


func _init() -> void:
	add_child(_overlay, false, INTERNAL_MODE_BACK)
	var column := _overlay
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.theme_type_variation = &"LnVGapSm"
	_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_icon.resized.connect(_on_icon_resized)  # o spinner gira no centro, ja com o layout feito
	column.add_child(_icon)
	_message.theme_type_variation = &"LnBodyMuted"
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_message)
	_retry.theme_type_variation = &"LnButton"
	_retry.text = "%s  %s" % [UiIcons.RESTART_ALT, tr("TENTAR DE NOVO")]
	_retry.size_flags_horizontal = SIZE_SHRINK_CENTER
	_retry.pressed.connect(retry_requested.emit)
	column.add_child(_retry)


func _ready() -> void:
	set_state(state)


func set_state(new_state: State, message: String = "") -> void:
	state = new_state
	_request += 1
	_message.text = message
	_message.visible = not message.is_empty()
	_icon.text = ICONS[new_state]
	_icon.theme_type_variation = ICON_TYPES[new_state]
	_retry.visible = new_state == State.ERROR
	for child: Node in get_children():
		if child is CanvasItem:
			(child as CanvasItem).visible = new_state == State.READY
	_stop_spin()
	_overlay.visible = new_state in [State.EMPTY, State.ERROR]
	if new_state == State.LOADING and is_inside_tree():
		# Tween morre com o no: tela fechada antes dos 150 ms nao retoma nada.
		var delay := create_tween()
		delay.tween_interval(LOADING_DELAY)
		delay.tween_callback(_show_spinner.bind(_request))


## O spinner esta na tela (LOADING depois do atraso)?
func is_spinning() -> bool:
	return _overlay.visible and state == State.LOADING


func _show_spinner(request: int) -> void:
	if request == _request:
		_overlay.visible = true
		_start_spin()


func _start_spin() -> void:
	_spin = create_tween().set_loops()
	_spin.tween_property(_icon, ^"rotation", TAU, SPIN_PERIOD).from(0.0)


func _stop_spin() -> void:
	if _spin != null:
		_spin.kill()
		_spin = null
	_icon.rotation = 0.0


func _on_icon_resized() -> void:
	_icon.pivot_offset = _icon.size / 2.0
