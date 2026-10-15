class_name IconField
extends Control
## Campo de texto do Login (prototipo: input px-10 com icone absoluto a esquerda e, na senha, o
## olho a direita). O LineEdit (LnInput) ocupa tudo; o icone fica por cima, sem receber mouse.

## Icone a left-3 / right-3 do prototipo.
const ICON_INSET: float = 12.0

var line_edit: LineEdit = LineEdit.new()

var _icon: Label = Label.new()
var _reveal: Button


func _init() -> void:
	line_edit.theme_type_variation = &"LnInput"
	line_edit.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(line_edit)
	_icon.theme_type_variation = &"LnIconSmMuted"
	_icon.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_icon)
	line_edit.minimum_size_changed.connect(update_minimum_size)
	resized.connect(_place_icons)


func _get_minimum_size() -> Vector2:
	return line_edit.get_combined_minimum_size()


func bind(icon: String, placeholder: String) -> void:
	_icon.text = icon
	line_edit.placeholder_text = placeholder


## Campo de senha: esconde o texto e poe o olho (mostrar/ocultar) a direita.
func make_secret() -> void:
	line_edit.secret = true
	_reveal = Button.new()
	_reveal.theme_type_variation = &"LnIconToggle"
	_reveal.text = UiIcons.VISIBILITY
	_reveal.tooltip_text = tr("Mostrar senha")
	_reveal.pressed.connect(_on_reveal_pressed)
	add_child(_reveal)
	_place_icons()


## Icone a esquerda e olho a direita, centrados na altura do campo (sem ancora: o tamanho
## minimo do glifo decide a caixa e o centro e calculado).
func _place_icons() -> void:
	_icon.size = _icon.get_combined_minimum_size()
	_icon.position = Vector2(ICON_INSET, (size.y - _icon.size.y) * 0.5)
	if _reveal != null:
		_reveal.size = _reveal.get_combined_minimum_size()
		_reveal.position = Vector2(
			size.x - ICON_INSET - _reveal.size.x, (size.y - _reveal.size.y) * 0.5
		)


func reveal_button() -> Button:
	return _reveal


func _on_reveal_pressed() -> void:
	line_edit.secret = not line_edit.secret
	_reveal.text = UiIcons.VISIBILITY if line_edit.secret else UiIcons.VISIBILITY_OFF
	_reveal.tooltip_text = tr("Mostrar senha") if line_edit.secret else tr("Ocultar senha")
