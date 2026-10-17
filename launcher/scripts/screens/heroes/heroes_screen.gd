class_name HeroesScreen
extends LauncherScreen
## Tela Herois (F71; FRONTEND-LAUNCHER §8: fiel ao prototipo "Tela Herois" de docs/prd/telas/).
## Cabecalho do catalogo, e abaixo, num corpo que rola na propria tela: coluna de busca e classes,
## grade de cards dos herois e o painel do heroi escolhido. Nomes, classes, atributos, habilidades e
## arma vem de shared/data pelo CatalogService (GDB vence o prototipo, §8.3 regra 2). Fora do
## prototipo (issue #199, §8.3): epiteto/lore, ELO e ping, "adquiridos", maestria, estrelas, tier,
## ordenacao, grade compacta, abas Runas/Talentos/..., builds, skins e "testar no treino".

const COLUMNS: int = 4
const SIDE_WIDTH: float = 300.0
const DETAIL_WIDTH: float = 440.0
## Papel "todos": chave do chip que limpa o filtro de classe.
const ALL_ROLES: String = ""
## Rolagem por teclado: fracao da altura visivel por pagina (as setas movem o foco entre os cards).
const PAGE_SCROLL: float = 0.9
const NO_CATALOG: String = "Não foi possível carregar o catálogo do jogo."

var catalog: CatalogService

var _header: ScreenHeader = ScreenHeader.new()
var _ribbon: PanelContainer = PanelContainer.new()
var _state: StateBox = StateBox.new()
var _scroll: ScrollContainer = ScrollContainer.new()
var _body: HBoxContainer = HBoxContainer.new()
var _search: LineEdit
var _chips: Dictionary[String, FilterChip] = {}
var _frames: Array[LiftFrame] = []
var _detail: HeroDetail = HeroDetail.new()
var _no_match: Label
var _role_filter: String = ALL_ROLES
var _selected: HeroData
var _maxima: Dictionary[StringName, float] = {}
var _built: bool = false


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
	_state.retry_requested.connect(refresh)
	page.add_child(_state)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	_scroll.get_v_scroll_bar().theme_type_variation = &"LnScrollBar"
	_state.add_child(_scroll)
	# Respiro a direita: a barra de rolagem nao encosta no conteudo.
	var gutter := MarginContainer.new()
	gutter.theme_type_variation = &"LnCpScrollGutter"
	gutter.size_flags_horizontal = SIZE_EXPAND_FILL
	_scroll.add_child(gutter)
	_body.theme_type_variation = &"LnHGapLg"
	_body.size_flags_horizontal = SIZE_EXPAND_FILL
	gutter.add_child(_body)
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


## Liga a tela ao catalogo e monta (ou mostra o erro se o catalogo nao carregou).
func bind(service: CatalogService) -> void:
	catalog = service
	if is_node_ready():
		refresh()


## Carrega o catalogo (de novo, se falhou) e monta o corpo uma unica vez.
func refresh() -> void:
	if catalog == null:
		return
	# O carregamento e local e sincrono: o StateBox so mostra o spinner depois de 150 ms (P5).
	_state.set_state(StateBox.State.LOADING)
	catalog.load_all()
	if not catalog.is_loaded():
		_state.set_state(StateBox.State.ERROR, tr(NO_CATALOG))
		return
	if not _built:
		_built = true
		_bind_header()
		_build_ribbon()
		_build_body()
		_let_wheel_through(_body)
		select_hero(catalog.heroes[0].id)
	_state.set_state(StateBox.State.READY)
	_focus_selected.call_deferred()


func state() -> StateBox.State:
	return _state.state


func cards() -> Array[HeroCard]:
	var found: Array[HeroCard] = []
	for frame: LiftFrame in _frames:
		found.append(frame.card() as HeroCard)
	return found


func visible_cards() -> Array[HeroCard]:
	var found: Array[HeroCard] = []
	for frame: LiftFrame in _frames:
		if frame.visible:
			found.append(frame.card() as HeroCard)
	return found


func selected_hero() -> HeroData:
	return _selected


func detail() -> HeroDetail:
	return _detail


func search_field() -> LineEdit:
	return _search


func role_chip(role: String) -> FilterChip:
	return _chips[role]


func no_match_visible() -> bool:
	return _no_match.visible


func scroll_position() -> int:
	return _scroll.scroll_vertical


## Rola o corpo (captura e teste); alem do fim vai ate o fim.
func scroll_to(pixels: int) -> void:
	_scroll.scroll_vertical = pixels


## Textos da fita de contadores: [rotulo, valor, unidade] (para teste e captura).
func ribbon_texts() -> PackedStringArray:
	if catalog == null or not catalog.is_loaded():
		return PackedStringArray()
	return PackedStringArray([tr("Heróis"), "%02d" % catalog.heroes.size(), tr("disponíveis")])


## Escolhe o heroi: marca o card, mostra o painel e guarda a escolha.
func select_hero(id: StringName) -> void:
	for card: HeroCard in cards():
		card.set_selected(card.hero.id == id)
		if card.hero.id == id:
			_selected = card.hero
	if _selected != null:
		_detail.bind(_selected, _maxima)
		# O painel e refeito a cada heroi: os nos novos tambem deixam a roda chegar a rolagem.
		_let_wheel_through(_detail)


## Filtra pela classe (ALL_ROLES = todas); a busca continua valendo.
func select_role(role: String) -> void:
	_role_filter = role
	for key: String in _chips:
		_chips[key].set_pressed_no_signal(key == role)
		_chips[key].refresh()
	_apply_filter()


func _can_go_back_changed() -> void:
	if is_node_ready() and _built:
		_bind_header()


func _build_header() -> void:
	_header.back_requested.connect(back_requested.emit)
	_header.use_compact_kicker()
	_header.add_glow(
		Color(UiTokens.GOLD, CompendiumScreen.GLOW_ALPHA),
		CompendiumScreen.GLOW_GOLD_SIZE,
		CompendiumScreen.GLOW_GOLD_INSET,
		CompendiumScreen.GLOW_GOLD_INSET
	)
	_header.add_glow(
		Color(UiTokens.CYAN, CompendiumScreen.GLOW_ALPHA),
		CompendiumScreen.GLOW_CYAN_SIZE,
		CompendiumScreen.GLOW_CYAN_RIGHT,
		CompendiumScreen.GLOW_CYAN_BOTTOM,
		true
	)
	_header.right_slot.add_child(_ribbon)
	_ribbon.visible = false
	_bind_header()


func _bind_header() -> void:
	_header.bind(
		tr("Heróis & Campeões"),
		can_go_back,
		tr("Catálogo do jogo"),
		UiIcons.MILITARY_TECH,
		tr("Classe, atributos e habilidades de cada herói.")
	)


## Fita com a contagem real de herois (o prototipo diz "10 heroes disponiveis").
func _build_ribbon() -> void:
	var texts := ribbon_texts()
	_ribbon.theme_type_variation = &"LnRibbon"
	_ribbon.size_flags_vertical = SIZE_SHRINK_END
	var box := VBoxContainer.new()
	box.theme_type_variation = &"LnVGapNone"
	var caption := _label(texts[0], &"LnNum")
	caption.uppercase = true
	box.add_child(caption)
	var value_row := HBoxContainer.new()
	value_row.theme_type_variation = &"LnHGapXs"
	value_row.add_child(_label(texts[1], &"LnNumLgGold"))
	var unit := _label(texts[2], &"LnBodySmMuted")
	unit.size_flags_vertical = SIZE_SHRINK_END
	value_row.add_child(unit)
	box.add_child(value_row)
	_ribbon.add_child(box)
	_ribbon.visible = true


func _build_body() -> void:
	_maxima = HeroesFormat.maxima(catalog.heroes)
	_body.add_child(_side_panel())
	_body.add_child(_roster())
	_detail.custom_minimum_size.x = DETAIL_WIDTH
	_detail.size_flags_vertical = SIZE_SHRINK_BEGIN
	_body.add_child(_detail)


## Coluna da esquerda: busca por nome, classe ou arma e a lista de classes com a contagem.
func _side_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"LnHeroSide"
	panel.custom_minimum_size.x = SIDE_WIDTH
	panel.size_flags_vertical = SIZE_SHRINK_BEGIN
	var column := VBoxContainer.new()
	column.theme_type_variation = &"LnVGapMd"
	panel.add_child(column)
	column.add_child(_section_title(UiIcons.SEARCH, tr("BUSCAR")))
	column.add_child(_search_box())
	column.add_child(_section_title(UiIcons.TUNE, tr("CLASSES & FUNÇÕES")))
	column.add_child(_role_chips())
	return panel


func _section_title(icon_glyph: String, text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapXs"
	row.add_child(_label(icon_glyph, &"LnIconSmGold"))
	row.add_child(_label(text, &"LnHeadlineSmGold"))
	return row


func _search_box() -> LineEdit:
	_search = LineEdit.new()
	_search.theme_type_variation = &"LnCpSearch"
	_search.placeholder_text = tr("Buscar por nome ou arma...")
	_search.clear_button_enabled = false
	_search.text_changed.connect(_on_search_text_changed)
	var glyph := _label(UiIcons.SEARCH, &"LnIconSmMuted")
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.set_anchors_and_offsets_preset(PRESET_CENTER_LEFT)
	glyph.offset_left = UiTokens.SPACE_SM
	glyph.grow_vertical = GROW_DIRECTION_BOTH
	_search.add_child(glyph)
	return _search


## "Todos os papeis" e uma entrada por classe presente no catalogo, com quantos herois tem.
func _role_chips() -> VBoxContainer:
	var column := VBoxContainer.new()
	column.theme_type_variation = &"LnVGapXs"
	var group := ButtonGroup.new()
	var roles: Array[String] = []
	for hero: HeroData in catalog.heroes:
		if not roles.has(hero.role):
			roles.append(hero.role)
	var entries: Array[String] = [ALL_ROLES]
	entries.append_array(roles)
	for role: String in entries:
		var everyone := role == ALL_ROLES
		var chip := FilterChip.new(
			tr("Todos os papéis") if everyone else role,
			UiIcons.STARS if everyone else HeroesFormat.class_icon(role),
			FilterChip.ICON_INACTIVE_DEFAULT
		)
		chip.button_group = group
		chip.size_flags_horizontal = SIZE_EXPAND_FILL
		chip.set_count(catalog.heroes.size() if everyone else _count_role(role))
		chip.set_pressed_no_signal(everyone)
		chip.refresh()
		chip.pressed.connect(select_role.bind(role))
		column.add_child(chip)
		_chips[role] = chip
	return column


func _count_role(role: String) -> int:
	var count := 0
	for hero: HeroData in catalog.heroes:
		count += int(hero.role == role)
	return count


## Centro: titulo da lista e grade de cards.
func _roster() -> VBoxContainer:
	var column := VBoxContainer.new()
	column.theme_type_variation = &"LnVGapMd"
	column.size_flags_horizontal = SIZE_EXPAND_FILL
	column.size_flags_vertical = SIZE_SHRINK_BEGIN
	column.add_child(_roster_title())
	var grid := GridContainer.new()
	grid.theme_type_variation = &"LnHeroGrid"
	grid.columns = COLUMNS
	grid.size_flags_horizontal = SIZE_EXPAND_FILL
	column.add_child(grid)
	for hero: HeroData in catalog.heroes:
		var card := HeroCard.new()
		card.bind(hero)
		card.pressed.connect(select_hero.bind(hero.id))
		LiftFrame.ignore_mouse(card)
		var frame := LiftFrame.new(card)
		frame.size_flags_horizontal = SIZE_EXPAND_FILL
		_frames.append(frame)
		grid.add_child(frame)
	_no_match = _label(tr("Nenhum herói encontrado."), &"LnBodyMuted")
	_no_match.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_no_match.visible = false
	column.add_child(_no_match)
	return column


func _roster_title() -> PanelContainer:
	var bar := PanelContainer.new()
	bar.theme_type_variation = &"LnHeroSide"
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapMd"
	bar.add_child(row)
	var title := _label(tr("ESCOLHA SEU HERÓI"), &"LnHeadlineSm")
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(title)
	row.add_child(_label("%d %s" % [catalog.heroes.size(), tr("HERÓIS")], &"LnCpBadgeSet"))
	return bar


func _apply_filter() -> void:
	var needle := _search.text.strip_edges().to_lower()
	var shown := 0
	var first_shown: HeroCard
	for frame: LiftFrame in _frames:
		var card := frame.card() as HeroCard
		var matches := (
			(_role_filter == ALL_ROLES or card.hero.role == _role_filter)
			and (needle.is_empty() or needle in card.search_text)
		)
		frame.visible = matches
		shown += int(matches)
		if matches and first_shown == null:
			first_shown = card
	_no_match.visible = shown == 0
	# O painel nao fica num heroi que sumiu da lista: passa para o primeiro que sobrou.
	if first_shown != null and not _is_shown(_selected):
		select_hero(first_shown.hero.id)


func _is_shown(hero: HeroData) -> bool:
	for card: HeroCard in visible_cards():
		if card.hero == hero:
			return true
	return false


func _focus_selected() -> void:
	if not is_inside_tree():
		return
	for card: HeroCard in visible_cards():
		if card.hero == _selected:
			card.grab_focus()
			# O foco rola o corpo ate o card; a tela abre no topo (busca, classes e titulo a vista).
			_scroll.scroll_vertical = 0
			return


## Painel, botao e campo do corpo com STOP engolem a roda do mouse antes da rolagem: passam a
## PASS (recebem o clique e deixam o evento subir ate o ScrollContainer).
func _let_wheel_through(root: Node) -> void:
	for child: Node in root.get_children():
		var control := child as Control
		if control != null and control.mouse_filter == Control.MOUSE_FILTER_STOP:
			control.mouse_filter = Control.MOUSE_FILTER_PASS
		_let_wheel_through(child)


func _label(text: String, type: StringName) -> Label:
	var label := Label.new()
	label.theme_type_variation = type
	label.text = text
	return label


func _on_search_text_changed(_text: String) -> void:
	_apply_filter()
