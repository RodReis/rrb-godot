class_name CatalogList
extends VBoxContainer
## Lista do padrao lista + detalhe (COMPONENTS.md, PATTERNS P3): um botao por entrada, so um
## selecionado; o primeiro ja vem selecionado. Setas movem o foco e o foco seleciona, entao
## da para navegar so pelo teclado. Emite o id; nao sabe o que a tela faz com ele.

signal selected(id: StringName)

var _group: ButtonGroup = ButtonGroup.new()
var _buttons: Dictionary[StringName, Button] = {}
var _selected: StringName = &""


func bind(entries: Array[CatalogEntry]) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_buttons.clear()
	_selected = &""
	for entry: CatalogEntry in entries:
		var button := Button.new()
		button.toggle_mode = true
		button.button_group = _group
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = UiTokens.SIZE_TARGET_MIN
		button.text = (
			"%s   %s" % [entry.title, entry.tag] if not entry.tag.is_empty() else entry.title
		)
		button.toggled.connect(_on_button_toggled.bind(entry.id))
		button.focus_entered.connect(select.bind(entry.id))
		add_child(button)
		_buttons[entry.id] = button
	if not entries.is_empty():
		select(entries[0].id)


func select(id: StringName) -> void:
	if _buttons.has(id):
		_buttons[id].button_pressed = true


func selected_id() -> StringName:
	return _selected


## Foco do teclado no selecionado (ao abrir a tela).
func focus_selected() -> void:
	if _buttons.has(_selected):
		_buttons[_selected].grab_focus()


func _on_button_toggled(on: bool, id: StringName) -> void:
	if on and id != _selected:
		_selected = id
		selected.emit(id)
