class_name ProfileChip
extends PanelContainer
## Chip de perfil do cabecalho (F35; prototipo Menu Principal: avatar redondo, nome e uma linha
## de numeros). Mostra o #nickname, o avatar local e o V-D do historico no lugar do ELO do
## prototipo (sem ELO nem nivel de conta, R-PEND-02). Clicar (ou Enter com foco) abre o perfil.

signal pressed

## w-8 h-8 do prototipo.
const AVATAR_SIZE: Vector2 = Vector2(32, 32)
const HOVER_TYPE: StringName = &"LnProfileChipHover"
const FOCUS_TYPE: StringName = &"LnProfileChipFocus"
const NORMAL_TYPE: StringName = &"LnProfileChip"
const RECORD_FORMAT: String = "%dV–%dD"

var _avatar_frame: PanelContainer = PanelContainer.new()
var _avatar: TextureRect = TextureRect.new()
var _glyph: Label = Label.new()
var _name: Label = Label.new()
var _record: Label = Label.new()
var _hovered: bool = false


func _init() -> void:
	theme_type_variation = NORMAL_TYPE
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	size_flags_vertical = SIZE_SHRINK_CENTER
	tooltip_text = tr("Seu perfil")
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapSm"
	row.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(row)
	_avatar_frame.theme_type_variation = &"LnAvatar"
	_avatar_frame.custom_minimum_size = AVATAR_SIZE
	_avatar_frame.size_flags_vertical = SIZE_SHRINK_CENTER
	_avatar_frame.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	_avatar_frame.mouse_filter = MOUSE_FILTER_IGNORE
	row.add_child(_avatar_frame)
	_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_avatar.mouse_filter = MOUSE_FILTER_IGNORE
	_avatar_frame.add_child(_avatar)
	_glyph.theme_type_variation = &"LnIconSmOn"
	_glyph.text = UiIcons.PERSON
	_glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_glyph.mouse_filter = MOUSE_FILTER_IGNORE
	_avatar_frame.add_child(_glyph)
	var text := VBoxContainer.new()
	text.theme_type_variation = &"LnVGapNone"
	text.size_flags_vertical = SIZE_SHRINK_CENTER
	text.mouse_filter = MOUSE_FILTER_IGNORE
	row.add_child(text)
	_name.theme_type_variation = &"LnChipName"
	_name.mouse_filter = MOUSE_FILTER_IGNORE
	text.add_child(_name)
	_record.theme_type_variation = &"LnNumGold"
	_record.mouse_filter = MOUSE_FILTER_IGNORE
	_record.visible = false
	text.add_child(_record)
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	focus_entered.connect(_refresh_style)
	focus_exited.connect(_refresh_style)


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		pressed.emit()
	elif event.is_action_pressed(&"ui_accept"):
		accept_event()
		pressed.emit()


## "14V–6D" (V = vitorias, D = derrotas do historico).
static func record_text(wins: int, losses: int) -> String:
	return RECORD_FORMAT % [wins, losses]


## Nickname (so o nome: o # entra aqui) e avatar; sem avatar escolhido, o icone padrao.
func bind(nickname: String, avatar: Texture2D) -> void:
	_name.text = NicknameRules.display(nickname)
	_avatar.texture = avatar
	_avatar.visible = avatar != null
	_glyph.visible = avatar == null


## V-D do historico; sem historico carregado a linha some (nada de 0V-0D inventado).
func set_record(wins: int, losses: int) -> void:
	_record.text = record_text(wins, losses)
	_record.visible = true


func clear_record() -> void:
	_record.text = ""
	_record.visible = false


func name_text() -> String:
	return _name.text


func record_label_text() -> String:
	return _record.text if _record.visible else ""


func has_avatar() -> bool:
	return _avatar.visible


func _set_hovered(hovered: bool) -> void:
	_hovered = hovered
	_refresh_style()


func _refresh_style() -> void:
	if has_focus():
		theme_type_variation = FOCUS_TYPE
	else:
		theme_type_variation = HOVER_TYPE if _hovered else NORMAL_TYPE
