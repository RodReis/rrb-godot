@tool
class_name HotkeyBadge
extends Label
## Atalho de teclado visivel (COMPONENTS.md, PATTERNS P11). SM: "[Q]" em texto secundario;
## MD: tecla com fundo, para ficar legivel sobre o icone de uma skill.

enum Size { SM, MD }

const SIZE_TYPES: Array[StringName] = [&"LabelBadge", &"LabelBadgeMd"]

@export var key: String = "":
	set(value):
		key = value
		_refresh()
@export var size_variant: Size = Size.SM:
	set(value):
		size_variant = value
		_refresh()


func _init() -> void:
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_refresh()


func _refresh() -> void:
	theme_type_variation = SIZE_TYPES[size_variant]
	text = "[%s]" % key if size_variant == Size.SM else key
