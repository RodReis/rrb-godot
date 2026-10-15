class_name RuleCard
extends PanelContainer
## Card de regra do topo da Forja (prototipo "Equipamentos & Forja"): caixa de icone, sobretitulo
## colorido, titulo, texto e uma faixa de rodape com icone. So texto montado de shared/data (§8.3).

const ICON_BOX: Vector2 = Vector2(40, 40)


## [param kicker_type] tipo do Label do sobretitulo (cor do acento); [param strip] faixa de rodape.
func bind(
	icon: String,
	kicker: String,
	kicker_type: StringName,
	title: String,
	text: String,
	strip: String
) -> void:
	theme_type_variation = &"LnCpPanel"
	size_flags_horizontal = SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.theme_type_variation = &"LnVGapMd"
	add_child(column)
	var head := HBoxContainer.new()
	head.theme_type_variation = &"LnHGapMd"
	var box := PanelContainer.new()
	box.theme_type_variation = &"LnCpIconBox"
	box.custom_minimum_size = ICON_BOX
	box.size_flags_vertical = SIZE_SHRINK_BEGIN
	var glyph := _label(icon, &"LnIconMdCyan")
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(glyph)
	head.add_child(box)
	var names := VBoxContainer.new()
	names.theme_type_variation = &"LnVGapNone"
	var caption := _label(kicker, kicker_type)
	caption.uppercase = true
	names.add_child(caption)
	var heading := _label(title, &"LnHeadlineSm")
	heading.uppercase = true
	names.add_child(heading)
	head.add_child(names)
	column.add_child(head)
	var body := _label(text, &"LnBodyMuted")
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_vertical = SIZE_EXPAND_FILL
	column.add_child(body)
	var well := PanelContainer.new()
	well.theme_type_variation = &"LnWell"
	var line := HBoxContainer.new()
	line.theme_type_variation = &"LnHGapXs"
	line.add_child(_label(UiIcons.INFO, &"LnIconSmCyan"))
	var note := _label(strip, &"LnNum")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.size_flags_horizontal = SIZE_EXPAND_FILL
	line.add_child(note)
	well.add_child(line)
	column.add_child(well)


func _label(text: String, type: StringName) -> Label:
	var label := Label.new()
	label.theme_type_variation = type
	label.text = text
	return label
