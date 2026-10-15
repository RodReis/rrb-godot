class_name ScreenHeader
extends PanelContainer
## Cabecalho de tela do Launcher (COMPONENTS.md, FRONTEND-LAUNCHER §3): bloco de titulo dos
## prototipos — voltar (so com pilha), sobretitulo com icone, titulo H1 e descricao a esquerda;
## slot a direita para abas ou filtro. Emite back_requested; quem decide e o App.

signal back_requested

## Abas, filtro ou acao da tela; alinhado ao fundo do bloco (md:items-end do prototipo).
var right_slot: HBoxContainer = HBoxContainer.new()

var _back: Button = Button.new()
var _icon: Label = Label.new()
var _kicker: Label = Label.new()
var _title: Label = Label.new()
var _description: Label = Label.new()


func _init() -> void:
	theme_type_variation = &"LnCardRaised"
	var columns := HBoxContainer.new()
	columns.theme_type_variation = &"LnHGapMd"
	add_child(columns)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = SIZE_EXPAND_FILL
	left.theme_type_variation = &"LnVGapXs"
	columns.add_child(left)
	var kicker_row := HBoxContainer.new()
	kicker_row.theme_type_variation = &"LnHGapSm"
	left.add_child(kicker_row)
	_back.theme_type_variation = &"LnIconButton"
	_back.text = UiIcons.ARROW_BACK
	_back.tooltip_text = tr("Voltar")
	_back.visible = false
	_back.pressed.connect(back_requested.emit)
	kicker_row.add_child(_back)
	_icon.theme_type_variation = &"LnIconTitle"
	kicker_row.add_child(_icon)
	_kicker.theme_type_variation = &"LnHeadlineSmGold"
	_kicker.uppercase = true
	kicker_row.add_child(_kicker)
	_title.theme_type_variation = &"LnHeadlineLg"
	_title.uppercase = true
	left.add_child(_title)
	_description.theme_type_variation = &"LnBodyMuted"
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(_description)
	right_slot.size_flags_vertical = SIZE_SHRINK_END
	columns.add_child(right_slot)


func bind(
	title: String, show_back: bool, kicker: String = "", icon: String = "", description: String = ""
) -> void:
	_title.text = title
	_back.visible = show_back
	_kicker.text = kicker
	_icon.text = icon
	_icon.visible = not icon.is_empty()
	_description.text = description
	_description.visible = not description.is_empty()
