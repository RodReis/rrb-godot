class_name ScreenFooter
extends PanelContainer
## Rodape do Launcher (COMPONENTS.md, FRONTEND-LAUNCHER §3): marca e status a esquerda, atalhos
## de teclado a direita. So texto real: nada de versao, servidor ou ano de exemplo (§8.3).

var _brand: Label = Label.new()
var _status: Label = Label.new()
var _hints: HBoxContainer = HBoxContainer.new()


func _init() -> void:
	theme_type_variation = &"LnFooter"
	custom_minimum_size.y = UiTokens.SIZE_FOOTER
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapMd"
	add_child(row)
	_brand.theme_type_variation = &"LnBrand"
	row.add_child(_brand)
	_status.theme_type_variation = &"LnBodySmMuted"
	_status.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(_status)
	_hints.theme_type_variation = &"LnHGapLg"
	row.add_child(_hints)


func bind(hints: Array[HotkeyHint], status: String, brand: String = "") -> void:
	_brand.text = brand
	_brand.visible = not brand.is_empty()
	_status.text = status
	for child: Node in _hints.get_children():
		child.queue_free()
	for hint: HotkeyHint in hints:
		var item := HBoxContainer.new()
		item.theme_type_variation = &"LnHGapXs"
		var key := Label.new()
		key.theme_type_variation = &"LnKeyLabel"
		key.text = hint.key
		item.add_child(key)
		var text := Label.new()
		text.theme_type_variation = &"LnBodySmMuted"
		text.text = hint.label
		item.add_child(text)
		_hints.add_child(item)
