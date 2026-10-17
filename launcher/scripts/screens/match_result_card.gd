class_name MatchResultCard
extends Control
## Card "Resultado da partida" por cima do lobby (F70, ADR-0015 item 8; COMPONENTS.md). Modal como o
## ModalDialog (escurece, prende o clique, Esc fecha), mas com o conteudo do MatchCard em destaque:
## resultado, heroi dos dois lados e #nickname do rival, kills/mortes, nivel, duracao e motivo de
## fim, mais o V-D da conta. Cinco estados: carregando (espera a partida aparecer no historico),
## vitoria, derrota, interrompida e erro (a partida nao apareceu). Nao fala com o backend: o App
## entrega o MatchSummary e os totais do HistoryService.

signal play_again_requested
signal history_requested
signal closed
## "Tentar de novo" do estado de erro: o App busca a partida outra vez.
signal retry_requested

const CARD_WIDTH: float = 960.0
## A caixa de estado nao encolhe no carregando e no erro (sem o cartao de resultado dentro).
const BODY_MIN_HEIGHT: float = 220.0

var _title: Label = Label.new()
var _record_caption: Label = Label.new()
var _record: Label = Label.new()
var _state: StateBox = StateBox.new()
var _holder: VBoxContainer = VBoxContainer.new()
var _history: Button = Button.new()
var _play_again: Button = Button.new()
var _match_card: MatchCard = null


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
	var card := PanelContainer.new()
	card.theme_type_variation = &"LnModal"
	card.custom_minimum_size.x = CARD_WIDTH
	center.add_child(card)
	var column := VBoxContainer.new()
	column.theme_type_variation = &"LnVGapMd"
	card.add_child(column)
	column.add_child(_header())
	_state.custom_minimum_size.y = BODY_MIN_HEIGHT
	_state.retry_requested.connect(retry_requested.emit)
	_state.add_child(_holder)
	column.add_child(_state)
	column.add_child(_actions())


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
		closed.emit()


## Espera a partida aparecer no historico: sem resultado ainda, so "Ver historico".
func show_loading() -> void:
	_open(StateBox.State.LOADING, tr("Buscando o resultado da partida…"))
	_play_again.visible = false


## [param summary] a partida; [param totals] o V-D da conta ja com ela.
func show_result(summary: MatchSummary, totals: MatchTotals) -> void:
	_clear_match_card()
	_match_card = MatchCard.new()
	_match_card.bind(summary, true)
	_holder.add_child(_match_card)
	_record.text = tr("%dV — %dD") % [totals.wins, totals.losses]
	_open(StateBox.State.READY)
	_play_again.visible = true
	_play_again.grab_focus.call_deferred()


## A partida nao apareceu a tempo: o aviso do codigo 3 (App) e outro; aqui, o caminho ao Historico.
func show_error() -> void:
	_clear_match_card()
	_open(StateBox.State.ERROR, tr("Não foi possível carregar o resultado desta partida."))
	_play_again.visible = false
	_history.grab_focus.call_deferred()


func close() -> void:
	visible = false


func state() -> StateBox.State:
	return _state.state


## WIN, LOSS ou INTERRUPTED (do MatchCard); "" fora do estado de resultado.
func result() -> String:
	return (
		_match_card.result if _match_card != null and _state.state == StateBox.State.READY else ""
	)


func play_again_button() -> Button:
	return _play_again


func history_button() -> Button:
	return _history


func _header() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapMd"
	_title.theme_type_variation = &"LnHeadlineSm"
	_title.text = tr("Resultado da partida")
	_title.uppercase = true
	row.add_child(_title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(spacer)
	_record_caption.theme_type_variation = &"LnNum"
	_record_caption.text = tr("V–D DA CONTA")
	_record_caption.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(_record_caption)
	_record.theme_type_variation = &"LnHeadlineSmGold"
	row.add_child(_record)
	return row


func _actions() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapSm"
	row.alignment = BoxContainer.ALIGNMENT_END
	_history.theme_type_variation = &"LnButton"
	_history.text = "%s  %s" % [UiIcons.HISTORY, tr("VER HISTÓRICO")]
	_history.pressed.connect(history_requested.emit)
	row.add_child(_history)
	_play_again.theme_type_variation = &"LnButtonPrimary"
	_play_again.text = "%s  %s" % [UiIcons.SWORDS, tr("JOGAR DE NOVO")]
	_play_again.pressed.connect(play_again_requested.emit)
	row.add_child(_play_again)
	return row


func _open(state: StateBox.State, message: String = "") -> void:
	_record.visible = state == StateBox.State.READY
	_record_caption.visible = _record.visible
	_state.set_state(state, message)
	if not visible:
		visible = true
		modulate.a = 0.0
		create_tween().tween_property(self, ^"modulate:a", 1.0, UiTokens.DUR_FAST)


func _clear_match_card() -> void:
	if _match_card == null:
		return
	_holder.remove_child(_match_card)
	_match_card.queue_free()
	_match_card = null
