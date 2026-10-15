class_name MatchOverlay
extends Control
## "Partida em andamento" (ARCHITECTURE-LAUNCHER §3.4): cobre o Launcher inteiro enquanto o Game
## roda e bloqueia a navegacao; "Encerrar jogo" pede ao App para matar o processo.

signal end_requested

const CARD_WIDTH: float = 520.0

var _icon: Label = Label.new()
var _title: Label = Label.new()
var _body: Label = Label.new()
var _end: Button = Button.new()


func _init() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = ModalDialog.DIM
	dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(center)
	var card := GlassPanel.new(GlassPanel.BLUR_2XL)
	card.theme_type_variation = &"LnModal"
	card.custom_minimum_size.x = CARD_WIDTH
	center.add_child(card)
	var column := VBoxContainer.new()
	column.theme_type_variation = &"LnVGapMd"
	card.add_child(column)
	_icon.theme_type_variation = &"LnIconTitle"
	_icon.text = UiIcons.SPORTS_ESPORTS
	_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_icon)
	_title.theme_type_variation = &"LnHeadlineMd"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)
	_body.theme_type_variation = &"LnBodyMuted"
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.text = tr("O jogo está aberto em outra janela. O Launcher volta quando ele fechar.")
	column.add_child(_body)
	_end.theme_type_variation = &"LnButtonDanger"
	_end.text = "%s  %s" % [UiIcons.POWER_SETTINGS_NEW, tr("ENCERRAR JOGO")]
	_end.size_flags_horizontal = SIZE_SHRINK_CENTER
	_end.pressed.connect(end_requested.emit)
	column.add_child(_end)


func open(practice: bool) -> void:
	_title.text = tr("Treino em andamento") if practice else tr("Partida em andamento")
	visible = true
	_end.grab_focus.call_deferred()


func close() -> void:
	visible = false


func end_button() -> Button:
	return _end
