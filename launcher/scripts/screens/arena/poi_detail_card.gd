class_name PoiDetailCard
extends PanelContainer
## Card de detalhe do ponto de interesse escolhido (prototipo "Arena & Mapa", poi-detail-card):
## caixa de icone no acento do ponto, selo e titulo, os fatos (chips) e o texto. O conteudo vem
## pronto de ArenaMapTexts.PoiInfo (numeros de shared/data); o card so desenha e troca com fade.

const ICON_BOX: Vector2 = Vector2(48, 48)
const FADE_FROM: float = 0.3

var _info: ArenaMapTexts.PoiInfo
var _box: PanelContainer = PanelContainer.new()
var _glyph: Label = Label.new()
var _tag: Label = Label.new()
var _title: Label = Label.new()
var _facts: HBoxContainer = HBoxContainer.new()
var _text: Label = Label.new()
var _fade: Tween


func _init() -> void:
	theme_type_variation = &"LnAmCardLow"
	var column := VBoxContainer.new()
	column.theme_type_variation = &"LnVGapSm"
	add_child(column)
	var head := HBoxContainer.new()
	head.theme_type_variation = &"LnHGapMd"
	column.add_child(head)
	_box.custom_minimum_size = ICON_BOX
	_box.size_flags_vertical = SIZE_SHRINK_BEGIN
	_glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_box.add_child(_glyph)
	head.add_child(_box)
	var names := VBoxContainer.new()
	names.theme_type_variation = &"LnVGapXs"
	names.size_flags_horizontal = SIZE_EXPAND_FILL
	names.size_flags_vertical = SIZE_SHRINK_CENTER
	_tag.size_flags_horizontal = SIZE_SHRINK_BEGIN
	_tag.uppercase = true
	names.add_child(_tag)
	_title.theme_type_variation = &"LnHeadlineMd"
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	names.add_child(_title)
	head.add_child(names)
	_facts.theme_type_variation = &"LnHGapSm"
	_facts.size_flags_vertical = SIZE_SHRINK_CENTER
	head.add_child(_facts)
	_text.theme_type_variation = &"LnBodyMuted"
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_text)


## Mostra o ponto; o primeiro bind aparece direto, os seguintes entram com fade.
func bind(info: ArenaMapTexts.PoiInfo) -> void:
	var first := _info == null
	_info = info
	var accent := String(info.accent).capitalize()
	_box.theme_type_variation = StringName("LnAmFill%s" % accent)
	_glyph.theme_type_variation = StringName("LnAmGlyphOn%s" % accent)
	_glyph.text = info.icon
	_tag.theme_type_variation = StringName("LnAmTag%s" % accent)
	_tag.text = info.tag
	_title.text = info.title
	_text.text = info.text
	for child: Node in _facts.get_children():
		_facts.remove_child(child)
		child.queue_free()
	for fact: PackedStringArray in info.facts:
		_facts.add_child(_fact(fact[0], fact[1]))
	if not first and is_inside_tree():
		if _fade != null:
			_fade.kill()
		modulate.a = FADE_FROM
		_fade = create_tween()
		_fade.tween_property(self, ^"modulate:a", 1.0, UiTokens.DUR_BASE)


## Id do ponto mostrado ("" antes do primeiro bind).
func poi_id() -> String:
	return "" if _info == null else _info.id


func title_text() -> String:
	return _title.text


func tag_text() -> String:
	return _tag.text


func body_text() -> String:
	return _text.text


## Pares "ROTULO valor" dos chips, na ordem.
func fact_texts() -> PackedStringArray:
	var found := PackedStringArray()
	for chip: Node in _facts.get_children():
		var labels := chip.find_children("*", "Label", true, false)
		found.append("%s %s" % [(labels[0] as Label).text, (labels[1] as Label).text])
	return found


func _fact(caption: String, value: String) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.theme_type_variation = &"LnAmFact"
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapXs"
	var label := Label.new()
	label.theme_type_variation = &"LnNum"
	label.text = caption
	row.add_child(label)
	var amount := Label.new()
	amount.theme_type_variation = &"LnNumGold"
	amount.text = value
	row.add_child(amount)
	chip.add_child(row)
	return chip
