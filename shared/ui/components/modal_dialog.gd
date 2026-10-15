class_name ModalDialog
extends Control
## Confirmacao modal (COMPONENTS.md, PATTERNS P12): escurece a tela, mostra titulo, texto e os
## botoes; open() devolve o indice do botao escolhido (await). Esc fecha com CANCELLED. O foco
## comeca no primeiro botao — ponha o seguro (cancelar) primeiro.

signal closed(index: int)

const CANCELLED: int = -1
## Fundo escurecido atras do card.
const DIM: Color = Color(UiTokens.BG_LOWEST, 0.7)
const CARD_WIDTH: float = 480.0

var _title: Label = Label.new()
var _body: Label = Label.new()
var _actions: HBoxContainer = HBoxContainer.new()


func _init() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = DIM
	dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(center)
	var card := PanelContainer.new()
	card.theme_type_variation = &"LnModal"
	card.custom_minimum_size.x = CARD_WIDTH
	center.add_child(card)
	var column := VBoxContainer.new()
	column.theme_type_variation = &"LnVGapMd"
	card.add_child(column)
	_title.theme_type_variation = &"LnHeadlineSm"
	_title.uppercase = true
	column.add_child(_title)
	_body.theme_type_variation = &"LnBodyMuted"
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_body)
	_actions.alignment = BoxContainer.ALIGNMENT_END
	_actions.theme_type_variation = &"LnHGapSm"
	column.add_child(_actions)


## Ja aberto: devolve CANCELLED na hora (um segundo open nao rouba a resposta do primeiro).
func open(title: String, body: String, actions: Array[DialogAction]) -> int:
	if visible:
		return CANCELLED
	_title.text = title
	_body.text = body
	for child: Node in _actions.get_children():
		_actions.remove_child(child)
		child.queue_free()
	for i: int in actions.size():
		var button := Button.new()
		button.theme_type_variation = DialogAction.TYPES[actions[i].kind]
		button.text = actions[i].label
		button.pressed.connect(closed.emit.bind(i))
		_actions.add_child(button)
	_trap_focus()
	visible = true
	modulate.a = 0.0
	create_tween().tween_property(self, ^"modulate:a", 1.0, UiTokens.DUR_FAST)
	if _actions.get_child_count() > 0:
		(_actions.get_child(0) as Button).grab_focus.call_deferred()
	var index: int = await closed
	visible = false
	# Quem espera retoma fora do emit do botao: pode liberar o dialogo sem "locked object".
	await get_tree().process_frame
	return index


## Botoes do dialogo aberto, na ordem de open().
func buttons() -> Array[Button]:
	var list: Array[Button] = []
	for child: Node in _actions.get_children():
		list.append(child as Button)
	return list


## Tab e setas giram so entre os botoes: o foco nao sai para a tela de baixo.
func _trap_focus() -> void:
	var list := buttons()
	for i: int in list.size():
		var next := list[(i + 1) % list.size()].get_path()
		var previous := list[(i - 1 + list.size()) % list.size()].get_path()
		list[i].focus_next = next
		list[i].focus_previous = previous
		list[i].focus_neighbor_right = next
		list[i].focus_neighbor_left = previous
		list[i].focus_neighbor_top = list[i].get_path()
		list[i].focus_neighbor_bottom = list[i].get_path()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit(CANCELLED)
