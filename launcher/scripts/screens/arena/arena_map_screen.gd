class_name ArenaMapScreen
extends LauncherScreen
## Arena & Mapa (DV tela 10; FRONTEND-LAUNCHER §8: fiel ao prototipo "Arena & Mapa — O Vale Runico
## Apocaliptico"). Somente leitura: o render estatico da arena real com um pino por ponto de
## interesse (clique abre o card de detalhe), as duas fases com os numeros do GDB, a faixa de
## totais e "Treino vs Bot" (a mesma acao do lobby). Numeros, nomes e contagens vem de shared/data
## (MatchRules, MonsterData) e dos dados gerados da arena (ArenaMapData), nunca do prototipo.
## Fora do prototipo (§8.3, issue #85): zoom isometrico 3D e linha de visao, grade A1-F6, alternador
## de camera, "Rotas de Farm", "Simular Tempestade", travessia, torres runicas, relevo e as artes
## geradas. A tela emite; quem navega e o App.

## Treino contra o bot: o App abre o Game como no lobby.
signal practice_requested

## Brilhos do cabecalho (iguais aos do compendio): primary/10 e secondary/10.
const GLOW_ALPHA: float = 0.07
const GLOW_GOLD_SIZE: float = 384.0
const GLOW_GOLD_INSET: float = -96.0
const GLOW_CYAN_SIZE: float = 320.0
const GLOW_CYAN_RIGHT: float = 640.0
const GLOW_CYAN_BOTTOM: float = -80.0
## Colunas: mapa e fases (21 : 20 na tela de 1920: o mapa 16:9 enche a coluna e, com o card de
## detalhe, cabe sem rolagem).
const MAP_RATIO: float = 21.0
const PHASES_RATIO: float = 20.0
const MAP_ASPECT: float = ArenaMapView.ASPECT
const STAT_BOX: Vector2 = Vector2(36, 36)
const PAGE_SCROLL: float = 0.9
const NO_MAP: String = "Não foi possível carregar o mapa da arena."
## Ponto escolhido ao abrir (o prototipo abre na cratera).
const DEFAULT_POI: String = ArenaMapPois.CRATER
const CHIP_ICONS: Array[String] = [UiIcons.TIMER, UiIcons.CRISIS_ALERT, UiIcons.EMOJI_EVENTS]
const CHIP_ACCENTS: Array[StringName] = [&"Gold", &"Cyan", &"Error"]

var catalog: CatalogService

var _header: ScreenHeader = ScreenHeader.new()
var _state: StateBox = StateBox.new()
var _scroll: ScrollContainer = ScrollContainer.new()
var _columns: HBoxContainer = HBoxContainer.new()
var _canvas: ArenaMapCanvas = ArenaMapCanvas.new()
var _detail: PoiDetailCard = PoiDetailCard.new()
var _phase_one: PhaseCard = PhaseCard.new()
var _phase_two: PhaseCard = PhaseCard.new()
var _footer: PanelContainer = PanelContainer.new()
var _stats: HBoxContainer = HBoxContainer.new()
var _practice: Button = Button.new()
var _ribbon: HBoxContainer = HBoxContainer.new()
var _built: bool = false


func _ready() -> void:
	var margin := MarginContainer.new()
	margin.theme_type_variation = &"LnScreenMargin"
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(margin)
	var page := VBoxContainer.new()
	page.theme_type_variation = &"LnVGapMd"
	margin.add_child(page)
	_build_header()
	page.add_child(_header)
	_state.size_flags_vertical = SIZE_EXPAND_FILL
	_state.retry_requested.connect(refresh)
	page.add_child(_state)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	_scroll.get_v_scroll_bar().theme_type_variation = &"LnScrollBar"
	_state.add_child(_scroll)
	var gutter := MarginContainer.new()
	gutter.theme_type_variation = &"LnCpScrollGutter"
	gutter.size_flags_horizontal = SIZE_EXPAND_FILL
	_scroll.add_child(gutter)
	_columns.theme_type_variation = &"LnHGapLg"
	_columns.size_flags_horizontal = SIZE_EXPAND_FILL
	_columns.size_flags_vertical = SIZE_EXPAND_FILL
	gutter.add_child(_columns)
	# Dentro do ScrollContainer nada expande na vertical: o corpo ganha, no minimo, a altura visivel
	# (o mapa 16:9 ocupa o que sobra do card; se o conteudo for maior, rola).
	_scroll.resized.connect(_fit_body)
	_build_footer()
	_footer.visible = false
	page.add_child(_footer)
	_state.set_state(StateBox.State.IDLE)
	if catalog != null:
		refresh()


func _unhandled_key_input(event: InputEvent) -> void:
	var step := 0.0
	if event.is_action_pressed(&"ui_page_down"):
		step = PAGE_SCROLL
	elif event.is_action_pressed(&"ui_page_up"):
		step = -PAGE_SCROLL
	if step != 0.0 and is_visible_in_tree() and _scroll.visible:
		_scroll.scroll_vertical += int(_scroll.size.y * step)
		get_viewport().set_input_as_handled()


## Liga a tela ao catalogo e monta (ou mostra o erro se o mapa nao carregou).
func bind(service: CatalogService) -> void:
	catalog = service
	if is_node_ready():
		refresh()


## Carrega o catalogo (de novo, se falhou) e monta o corpo uma unica vez.
func refresh() -> void:
	if catalog == null:
		return
	catalog.load_all()
	if not _map_ready():
		_footer.visible = false
		_state.set_state(StateBox.State.ERROR, tr(NO_MAP))
		return
	if not _built:
		_built = _build_body()
		if not _built:
			_footer.visible = false
			_state.set_state(StateBox.State.ERROR, tr(NO_MAP))
			return
	_footer.visible = true
	_state.set_state(StateBox.State.READY)
	var first := _canvas.pins_of(selected_poi())
	if not first.is_empty() and is_inside_tree():
		first[0].grab_focus.call_deferred()


func state() -> StateBox.State:
	return _state.state


## Escolhe o ponto de interesse: marca os pinos e troca o card de detalhe.
func select_poi(id: String) -> void:
	if _canvas.pins().is_empty():
		return
	var info := ArenaMapTexts.poi_info(id, catalog.arena_map, catalog)
	if info.id.is_empty():
		return
	_canvas.select(id)
	_detail.bind(info)


func selected_poi() -> String:
	return _detail.poi_id() if not _detail.poi_id().is_empty() else DEFAULT_POI


func canvas() -> ArenaMapCanvas:
	return _canvas


func detail_card() -> PoiDetailCard:
	return _detail


func phase_card(kind: PhaseCard.Kind) -> PhaseCard:
	return _phase_one if kind == PhaseCard.Kind.PREPARATION else _phase_two


func practice_button() -> Button:
	return _practice


func scroll_to(pixels: int) -> void:
	_scroll.scroll_vertical = pixels


func _fit_body() -> void:
	_columns.custom_minimum_size.y = _scroll.size.y


func _can_go_back_changed() -> void:
	if is_node_ready() and _built:
		_bind_header()


## Mapa carregou e a imagem esta no enquadramento do codigo (senao os pinos errariam o lugar).
func _map_ready() -> bool:
	return catalog.is_loaded() and catalog.arena_map != null and catalog.arena_map.matches_view()


func _build_header() -> void:
	_header.back_requested.connect(back_requested.emit)
	_header.use_compact_kicker()
	_header.add_glow(
		Color(UiTokens.GOLD, GLOW_ALPHA), GLOW_GOLD_SIZE, GLOW_GOLD_INSET, GLOW_GOLD_INSET
	)
	_header.add_glow(
		Color(UiTokens.CYAN, GLOW_ALPHA), GLOW_CYAN_SIZE, GLOW_CYAN_RIGHT, GLOW_CYAN_BOTTOM, true
	)
	_ribbon.theme_type_variation = &"LnHGapSm"
	_ribbon.visible = false
	_header.right_slot.add_child(_ribbon)
	_bind_header()


func _bind_header() -> void:
	var description := ""
	if catalog != null and catalog.is_loaded():
		description = ArenaMapTexts.header_description(catalog.match_rules)
	_header.bind(
		ArenaMapTexts.header_title(), can_go_back, tr("MAPA TÁTICO"), UiIcons.RADAR, description
	)


func _build_body() -> bool:
	var data := catalog.arena_map
	var rules := catalog.match_rules
	if not _canvas.bind(data, rules):
		return false
	_canvas.poi_selected.connect(select_poi)
	var left := VBoxContainer.new()
	left.theme_type_variation = &"LnVGapMd"
	left.size_flags_horizontal = SIZE_EXPAND_FILL
	left.size_flags_vertical = SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = MAP_RATIO
	left.add_child(_map_frame())
	left.add_child(_detail)
	_columns.add_child(left)
	var right := VBoxContainer.new()
	right.theme_type_variation = &"LnVGapMd"
	right.size_flags_horizontal = SIZE_EXPAND_FILL
	right.size_flags_vertical = SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = PHASES_RATIO
	_phase_one.bind(
		PhaseCard.Kind.PREPARATION,
		tr("Fase 1"),
		ArenaMapTexts.phase_one_window(rules),
		tr("Preparação, Creeps & Farm"),
		ArenaMapTexts.phase_one_rules(rules, data)
	)
	_phase_one.set_note(ArenaMapTexts.phase_one_note(rules))
	_phase_two.bind(
		PhaseCard.Kind.CONFRONTATION,
		tr("Fase 2"),
		ArenaMapTexts.phase_two_window(rules),
		tr("Confronto & Tempestade Tóxica"),
		ArenaMapTexts.phase_two_rules(rules)
	)
	_phase_two.set_zone(tr("Raio da zona por minuto"), ArenaMapTexts.zone_steps(rules))
	right.add_child(_phase_one)
	right.add_child(_phase_two)
	_columns.add_child(right)
	_build_ribbon(rules)
	_build_stats(data)
	select_poi(DEFAULT_POI)
	return true


## Moldura: barra do topo (radar, projecao, dica) e o quadro 16:9 com o mapa.
func _map_frame() -> PanelContainer:
	var frame := PanelContainer.new()
	frame.theme_type_variation = &"LnAmFrame"
	frame.size_flags_vertical = SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.theme_type_variation = &"LnVGapXs"
	frame.add_child(column)
	var bar := PanelContainer.new()
	bar.theme_type_variation = &"LnAmBar"
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapMd"
	var radar := Label.new()
	radar.theme_type_variation = &"LnIconSmGold"
	radar.text = UiIcons.RADAR
	row.add_child(radar)
	var tactical := Label.new()
	tactical.theme_type_variation = &"LnNumGold"
	tactical.text = tr("MAPA TÁTICO")
	row.add_child(tactical)
	var projection := Label.new()
	projection.theme_type_variation = &"LnNum"
	projection.text = tr("PROJEÇÃO ORTOGRÁFICA %d°") % roundi(ArenaMapView.PITCH_DEGREES)
	row.add_child(projection)
	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(spacer)
	var hint := PanelContainer.new()
	hint.theme_type_variation = &"LnChip"
	var hint_text := Label.new()
	hint_text.theme_type_variation = &"LnNumText"
	hint_text.text = tr("CLIQUE NUM PONTO PARA ANALISAR")
	hint.add_child(hint_text)
	row.add_child(hint)
	bar.add_child(row)
	column.add_child(bar)
	var aspect := AspectRatioContainer.new()
	aspect.ratio = MAP_ASPECT
	aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	aspect.size_flags_vertical = SIZE_EXPAND_FILL
	_canvas.size_flags_horizontal = SIZE_EXPAND_FILL
	_canvas.size_flags_vertical = SIZE_EXPAND_FILL
	aspect.add_child(_canvas)
	column.add_child(aspect)
	return frame


## Fita do cabecalho: tres chips (duracao, zona inicial, meta de kills).
func _build_ribbon(rules: MatchRules) -> void:
	var cells := ArenaMapTexts.header_chips(rules)
	for i: int in cells.size():
		var cell: Array = cells[i]
		var chip := PanelContainer.new()
		chip.theme_type_variation = &"LnAmChip"
		var row := HBoxContainer.new()
		row.theme_type_variation = &"LnHGapXs"
		var icon := Label.new()
		icon.theme_type_variation = StringName("LnAmPin%s" % CHIP_ACCENTS[i])
		icon.text = CHIP_ICONS[i]
		icon.size_flags_vertical = SIZE_SHRINK_CENTER
		row.add_child(icon)
		var box := VBoxContainer.new()
		box.theme_type_variation = &"LnVGapNone"
		var caption := Label.new()
		caption.theme_type_variation = &"LnNum"
		caption.text = cell[0]
		caption.uppercase = true
		box.add_child(caption)
		var value_row := HBoxContainer.new()
		value_row.theme_type_variation = &"LnHGapXs"
		var value := Label.new()
		value.theme_type_variation = cell[3]
		value.text = cell[1]
		value_row.add_child(value)
		var unit := Label.new()
		unit.theme_type_variation = &"LnBodySmMuted"
		unit.text = cell[2]
		unit.size_flags_vertical = SIZE_SHRINK_END
		value_row.add_child(unit)
		box.add_child(value_row)
		row.add_child(box)
		chip.add_child(row)
		_ribbon.add_child(chip)
	_ribbon.visible = true


func _build_footer() -> void:
	_footer.theme_type_variation = &"LnAmCardWide"
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapXl"
	_footer.add_child(row)
	_stats.theme_type_variation = &"LnHGapXl"
	_stats.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(_stats)
	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(spacer)
	_practice.theme_type_variation = &"LnButtonPrimary"
	_practice.text = "%s  %s" % [UiIcons.PLAY_ARROW, tr("INICIAR TREINO VS BOT")]
	_practice.size_flags_vertical = SIZE_SHRINK_CENTER
	_practice.pressed.connect(practice_requested.emit)
	row.add_child(_practice)


## Faixa de totais: icone numa caixa, rotulo e valor (monstros, baus, mato alto, boss).
func _build_stats(data: ArenaMapData) -> void:
	for stat: Array in ArenaMapTexts.strip_stats(data, catalog):
		var tile := HBoxContainer.new()
		tile.theme_type_variation = &"LnHGapSm"
		var box := PanelContainer.new()
		box.theme_type_variation = &"LnAmStatBox"
		box.custom_minimum_size = STAT_BOX
		box.size_flags_vertical = SIZE_SHRINK_CENTER
		var icon := Label.new()
		icon.theme_type_variation = StringName("LnAmPin%s" % String(stat[3]).capitalize())
		icon.text = stat[2]
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		box.add_child(icon)
		tile.add_child(box)
		var text := VBoxContainer.new()
		text.theme_type_variation = &"LnVGapNone"
		var caption := Label.new()
		caption.theme_type_variation = &"LnNum"
		caption.text = stat[0]
		caption.uppercase = true
		text.add_child(caption)
		var value := Label.new()
		value.theme_type_variation = &"LnNumText"
		value.text = stat[1]
		text.add_child(value)
		tile.add_child(text)
		_stats.add_child(tile)
