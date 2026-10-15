class_name FilterChip
extends Button
## Chip de filtro do Historico (prototipo: .filter-btn): [icone] ROTULO [contagem]. Toggle: o ativo
## vira GOLD com o rotulo ON_GOLD e a contagem em caixa translucida; inativo e BG_PANEL, hover
## BG_CARD. Um Button so tem um texto, entao o conteudo e um HBox por cima (mouse_filter IGNORE) e
## o tamanho minimo vem dele (custom_minimum_size: o Button calcula o proprio minimo por nativo e
## ignora _get_minimum_size).

## set_count com isto esconde a caixa da contagem.
const NO_COUNT: int = -1
const ICON_INACTIVE_DEFAULT: StringName = &"LnIconSmGold"
const ICON_ACTIVE: StringName = &"LnIconSmOn"
const LABEL_INACTIVE: StringName = &"LnFilterLabel"
const LABEL_HOVER: StringName = &"LnFilterLabelHover"
const LABEL_ACTIVE: StringName = &"LnFilterLabelOn"
const COUNT_INACTIVE: StringName = &"LnCount"
const COUNT_ACTIVE: StringName = &"LnCountOn"

var _icon_type: StringName
var _row: HBoxContainer = HBoxContainer.new()
var _icon: Label = Label.new()
var _label: Label = Label.new()
var _count: Label = Label.new()


## [param icon] glifo de UiIcons ("" = sem icone); [param icon_type] cor do icone quando inativo.
func _init(
	label_text: String = "", icon: String = "", icon_type: StringName = ICON_INACTIVE_DEFAULT
) -> void:
	theme_type_variation = &"LnFilter"
	toggle_mode = true
	_icon_type = icon_type
	_row.theme_type_variation = &"LnHGapXs"
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_row.offset_left = UiTokens.SPACE_MD
	_row.offset_right = -UiTokens.SPACE_MD
	_row.offset_top = UiTokens.SPACE_XS
	_row.offset_bottom = -UiTokens.SPACE_XS
	add_child(_row)
	_icon.text = icon
	_icon.visible = not icon.is_empty()
	_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_row.add_child(_icon)
	_label.text = label_text
	_label.uppercase = true
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_row.add_child(_label)
	_count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_count.size_flags_vertical = SIZE_SHRINK_CENTER
	_row.add_child(_count)
	_row.minimum_size_changed.connect(_on_row_minimum_size_changed)
	toggled.connect(_on_toggled)
	mouse_entered.connect(refresh)
	mouse_exited.connect(refresh)
	refresh()


## Contagem na caixa do chip; negativa = ainda desconhecida (carregando ou erro): some.
func set_count(count: int) -> void:
	_count.text = str(count) if count >= 0 else ""
	_count.visible = count >= 0


func count_text() -> String:
	return _count.text


func label_text() -> String:
	return _label.text


func set_label_text(text: String) -> void:
	_label.text = text


func refresh() -> void:
	var active := button_pressed
	_icon.theme_type_variation = ICON_ACTIVE if active else _icon_type
	if active:
		_label.theme_type_variation = LABEL_ACTIVE
	else:
		_label.theme_type_variation = LABEL_HOVER if is_hovered() else LABEL_INACTIVE
	_count.theme_type_variation = COUNT_ACTIVE if active else COUNT_INACTIVE


func _on_toggled(_pressed: bool) -> void:
	refresh()


func _on_row_minimum_size_changed() -> void:
	var pad := Vector2(2.0 * UiTokens.SPACE_MD, 2.0 * UiTokens.SPACE_XS)
	custom_minimum_size = _row.get_combined_minimum_size() + pad
