class_name SettingRow
extends PanelContainer
## Linha das listas de Configuracoes (prototipo: bg-surface-container, hover -high): rotulo e
## subtitulo opcional a esquerda, controles a direita (controls).

var controls: HBoxContainer = HBoxContainer.new()

var _label: Label = Label.new()
var _sub: Label = Label.new()


func _init(label: String = "", sub: String = "", label_type: StringName = &"LnBody") -> void:
	theme_type_variation = &"LnRow"
	mouse_filter = MOUSE_FILTER_PASS
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapSm"
	add_child(row)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = SIZE_EXPAND_FILL
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.add_theme_constant_override(&"separation", 0)
	row.add_child(texts)
	_label.theme_type_variation = label_type
	_label.text = label
	texts.add_child(_label)
	_sub.theme_type_variation = &"LnNum"
	_sub.text = sub
	_sub.visible = not sub.is_empty()
	texts.add_child(_sub)
	controls.theme_type_variation = &"LnHGapXs"
	controls.alignment = BoxContainer.ALIGNMENT_END
	row.add_child(controls)


func _on_mouse_entered() -> void:
	theme_type_variation = &"LnRowHover"


func _on_mouse_exited() -> void:
	theme_type_variation = &"LnRow"
