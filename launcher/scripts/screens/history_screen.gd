class_name HistoryScreen
extends LauncherScreen
## Historico (DV tela 9; FRONTEND-LAUNCHER §8: fiel a docs/prd/telas/Historico de Partidas —
## Duelos/). Cabecalho com o V–D da conta e os filtros Todas/Vitorias/Derrotas, o feed de duelos
## (o mais recente em destaque; rolagem so dentro do feed) e a faixa de rodape. Fora do prototipo
## (issue #83, §8.3): painel Auditoria M4, KPIs, ELO, KDA e taxa por heroi, itens finais,
## cronologia de eventos, miniatura da arena, filtros por heroi e busca, paginacao (vira rolagem).
## Dados do HistoryService; a tela nunca fala com o backend.

enum Filter { ALL, WINS, LOSSES }

const ICON_BOX: Vector2 = Vector2(40, 40)
const UNKNOWN_RECORD: String = "—"
const UNKNOWN_COUNT: int = -1
## Brilhos do cartao do cabecalho (prototipo): primary/5 de 256 px a -right-12 -top-12 e
## secondary/5 de 224 px a right-48 -bottom-16.
const GLOW_ALPHA: float = 0.05
const GLOW_GOLD_SIZE: float = 256.0
const GLOW_GOLD_INSET: float = -48.0
const GLOW_CYAN_SIZE: float = 224.0
const GLOW_CYAN_RIGHT: float = 192.0
const GLOW_CYAN_BOTTOM: float = -64.0
## Rolagem do feed por teclado: fracao da altura visivel por passo (setas) e por pagina.
const ARROW_SCROLL: float = 0.25
const PAGE_SCROLL: float = 0.9

var _service: HistoryService
var _filter: Filter = Filter.ALL
var _header: ScreenHeader = ScreenHeader.new()
var _chips: Dictionary[Filter, FilterChip] = {}
var _record: Label = Label.new()
var _state: StateBox = StateBox.new()
var _scroll: ScrollContainer = ScrollContainer.new()
var _feed: VBoxContainer = VBoxContainer.new()
var _count: Label = Label.new()
var _cards: Array[MatchCard] = []
var _strip_panel: PanelContainer
var _loading: bool = false
## O backend so manda as mais recentes: o V–D da conta e maior que o das partidas carregadas.
var _truncated: bool = false


func _ready() -> void:
	var margin := MarginContainer.new()
	margin.theme_type_variation = &"LnScreenMargin"
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(margin)
	var page := VBoxContainer.new()
	page.theme_type_variation = &"LnVGapMd"
	margin.add_child(page)
	page.add_child(_header)
	_build_header()
	_state.size_flags_vertical = SIZE_EXPAND_FILL
	_state.retry_requested.connect(_on_state_retry_requested)
	page.add_child(_state)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_state.add_child(_scroll)
	_feed.theme_type_variation = &"LnVGapMd"
	_feed.size_flags_horizontal = SIZE_EXPAND_FILL
	_scroll.add_child(_feed)
	_strip_panel = _strip()
	page.add_child(_strip_panel)
	_show_unknown()
	_state.set_state(StateBox.State.IDLE)
	_chips[Filter.ALL].grab_focus.call_deferred()
	if _service != null:
		refresh()


func _unhandled_key_input(event: InputEvent) -> void:
	var step := 0.0
	if event.is_action_pressed(&"ui_down", true):
		step = ARROW_SCROLL
	elif event.is_action_pressed(&"ui_up", true):
		step = -ARROW_SCROLL
	elif event.is_action_pressed(&"ui_page_down"):
		step = PAGE_SCROLL
	elif event.is_action_pressed(&"ui_page_up"):
		step = -PAGE_SCROLL
	if step != 0.0 and is_visible_in_tree() and _scroll.visible:
		_scroll.scroll_vertical += int(_scroll.size.y * step)
		get_viewport().set_input_as_handled()


## Liga a tela ao servico e carrega (cache da sessao, ou rede se ainda nao buscou).
func bind(service: HistoryService) -> void:
	_service = service
	if is_node_ready():
		refresh()


## Busca no servico (`force` ignora o cache) e redesenha o estado: loading, empty, ready ou erro.
func refresh(force: bool = false) -> void:
	if _service == null or _loading:
		return
	_loading = true
	if _service.history == null:
		_show_unknown()
	_state.set_state(StateBox.State.LOADING)
	# Sinal, nao await: a conexao morre com a tela (Esc durante o loading libera o no).
	_service.fetch_finished.connect(_on_service_fetch_finished, CONNECT_ONE_SHOT)
	_service.fetch.call(force)


func select_filter(filter: Filter) -> void:
	_filter = filter
	for key: Filter in _chips:
		_chips[key].set_pressed_no_signal(key == filter)
		_chips[key].refresh()
	_scroll.scroll_vertical = 0
	_apply_filter()


func state() -> StateBox.State:
	return _state.state


func cards() -> Array[MatchCard]:
	return _cards


func visible_cards() -> Array[MatchCard]:
	return _cards.filter(func(card: MatchCard) -> bool: return card.visible)


func filter_chip(filter: Filter) -> FilterChip:
	return _chips[filter]


func scroll_position() -> int:
	return _scroll.scroll_vertical


func record_text() -> String:
	return _record.text


func footer_text() -> String:
	return _count.text


func _can_go_back_changed() -> void:
	if is_node_ready():
		_bind_header()


func _build_header() -> void:
	_bind_header()
	_header.back_requested.connect(back_requested.emit)
	_header.add_glow(
		Color(UiTokens.GOLD_BRIGHT, GLOW_ALPHA), GLOW_GOLD_SIZE, GLOW_GOLD_INSET, GLOW_GOLD_INSET
	)
	_header.add_glow(
		Color(UiTokens.CYAN, GLOW_ALPHA), GLOW_CYAN_SIZE, GLOW_CYAN_RIGHT, GLOW_CYAN_BOTTOM, true
	)
	_header.right_slot.add_child(_season_badge())
	var group := ButtonGroup.new()
	var specs: Array[Array] = [
		[Filter.ALL, "Todas as partidas", "", FilterChip.ICON_INACTIVE_DEFAULT],
		[Filter.WINS, "Vitórias", UiIcons.VERIFIED, &"LnIconSmGold"],
		[Filter.LOSSES, "Derrotas", UiIcons.CLOSE, &"LnIconSmError"],
	]
	for spec: Array in specs:
		var chip := FilterChip.new(tr(spec[1]), spec[2], spec[3])
		chip.button_group = group
		chip.set_count(0)
		chip.pressed.connect(select_filter.bind(spec[0]))
		_header.bottom_slot.add_child(chip)
		_chips[spec[0]] = chip
	_chips[Filter.ALL].set_pressed_no_signal(true)
	_chips[Filter.ALL].refresh()
	_header.show_bottom_slot()


func _bind_header() -> void:
	(
		_header
		. bind(
			tr("HISTÓRICO DE DUELOS"),
			can_go_back,
			tr("Histórico"),
			UiIcons.HISTORY,
			tr(
				"Suas partidas 1x1: resultado, heróis dos dois lados, placar de kills, nível final e duração."
			)
		)
	)


## V–D da conta (no lugar da "Ladder Oficial" do prototipo: sem ELO nem ranking).
func _season_badge() -> PanelContainer:
	var badge := PanelContainer.new()
	badge.theme_type_variation = &"LnSeasonBadge"
	badge.size_flags_vertical = SIZE_SHRINK_CENTER
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapMd"
	badge.add_child(row)
	var icon_box := PanelContainer.new()
	icon_box.theme_type_variation = &"LnIconBoxCard"
	icon_box.custom_minimum_size = ICON_BOX
	var icon := Label.new()
	icon.theme_type_variation = &"LnIconMdGold"
	icon.text = UiIcons.EMOJI_EVENTS
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_box.add_child(icon)
	row.add_child(icon_box)
	var text := VBoxContainer.new()
	text.theme_type_variation = &"LnVGapNone"
	row.add_child(text)
	var caption := Label.new()
	caption.theme_type_variation = &"LnNum"
	caption.text = tr("V–D DA CONTA")
	text.add_child(caption)
	_record.theme_type_variation = &"LnHeadlineSmGold"
	_record.text = UNKNOWN_RECORD
	text.add_child(_record)
	return badge


## Faixa de rodape do feed ("Mostrando N partidas"; a paginacao do prototipo virou rolagem).
func _strip() -> PanelContainer:
	var strip := PanelContainer.new()
	strip.theme_type_variation = &"LnStrip"
	_count.theme_type_variation = &"LnNum"
	strip.add_child(_count)
	return strip


## Sem dado (carregando ou erro): nada de "0V — 0D" nem de contagem zerada.
func _show_unknown() -> void:
	_record.text = UNKNOWN_RECORD
	for chip: FilterChip in _chips.values():
		chip.set_count(UNKNOWN_COUNT)
	_strip_panel.visible = false


func _show_history(history: MatchHistory) -> void:
	_strip_panel.visible = true
	for card: MatchCard in _cards:
		card.queue_free()
	_cards.clear()
	var wins := 0
	var losses := 0
	for i: int in history.matches.size():
		var summary: MatchSummary = history.matches[i]
		var card := MatchCard.new()
		card.bind(summary, i == 0)
		_feed.add_child(card)
		_cards.append(card)
		wins += int(summary.result == MatchCard.WIN)
		losses += int(summary.result == MatchCard.LOSS)
	_truncated = history.totals.wins + history.totals.losses > wins + losses
	_record.text = _record_text(history.totals.wins, history.totals.losses)
	_chips[Filter.ALL].set_count(history.matches.size())
	_chips[Filter.WINS].set_count(wins)
	_chips[Filter.LOSSES].set_count(losses)
	_apply_filter()


## Esconde os cartoes fora do filtro (o destaque segue sendo a partida mais recente).
func _apply_filter() -> void:
	var shown := 0
	for card: MatchCard in _cards:
		var matches := (
			_filter == Filter.ALL
			or (_filter == Filter.WINS and card.result == MatchCard.WIN)
			or (_filter == Filter.LOSSES and card.result == MatchCard.LOSS)
		)
		card.visible = matches
		shown += int(matches)
	_count.text = tr("Mostrando %d partidas") % shown if shown != 1 else tr("Mostrando 1 partida")
	if _truncated:
		_count.text += " · " + tr("só as mais recentes")
	if _service == null or _service.history == null:
		return
	if _cards.is_empty():
		_state.set_state(StateBox.State.EMPTY, tr("Nenhuma partida jogada ainda."))
	elif shown == 0:
		_state.set_state(StateBox.State.EMPTY, tr("Nenhuma partida neste filtro."))
	else:
		_state.set_state(StateBox.State.READY)


func _record_text(wins: int, losses: int) -> String:
	return tr("%dV — %dD") % [wins, losses]


func _error_text(code: String) -> String:
	if code == ApiClient.OFFLINE:
		return tr("Servidor fora do ar. Tente de novo em instantes.")
	return tr("Não foi possível carregar o histórico.")


func _on_service_fetch_finished() -> void:
	_loading = false
	if _service.is_ready():
		_show_history(_service.history)
	else:
		_show_unknown()
		_state.set_state(StateBox.State.ERROR, _error_text(_service.error_code))


func _on_state_retry_requested() -> void:
	refresh(true)
