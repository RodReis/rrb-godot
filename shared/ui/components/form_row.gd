class_name FormRow
extends VBoxContainer
## Linha de formulario (COMPONENTS.md, FRONTEND-LAUNCHER §3.2): rotulo, o controle (filho comum
## adicionado pela tela) e a mensagem de erro, que so aparece com set_error.

var _label: Label = Label.new()
var _error: Label = Label.new()


func _init() -> void:
	theme_type_variation = &"LnVGapXs"
	_label.theme_type_variation = &"LnNum"
	_label.uppercase = true
	add_child(_label, false, INTERNAL_MODE_FRONT)
	_error.theme_type_variation = &"LnBodySmError"
	_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error.visible = false
	add_child(_error, false, INTERNAL_MODE_BACK)


func bind(label: String) -> void:
	_label.text = label


func set_error(message: String) -> void:
	_error.text = "%s %s" % [UiIcons.ERROR, message]
	_error.visible = true


func clear_error() -> void:
	_error.text = ""
	_error.visible = false


func has_error() -> bool:
	return _error.visible


## Texto da mensagem de erro; "" sem erro.
func error_text() -> String:
	return _error.text if _error.visible else ""
