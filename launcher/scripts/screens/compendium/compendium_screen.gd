class_name CompendiumScreen
extends LauncherScreen
## Base do Compendio (Bestiario e Forja; FRONTEND-LAUNCHER §8, prototipos "Guia & Bestiario" e
## "Equipamentos & Forja" de docs/prd/telas/). Cabecalho fixo com titulo, fita de contadores, as
## abas do compendio e, no Bestiario, os filtros; abaixo, o corpo rola dentro da propria tela
## (§8.4: sem rolagem de pagina). As abas sao rotas: a tela emite navigate_requested e o App
## troca a tela do topo. Os numeros vem do CatalogService (shared/data), nunca da cena.

## Pedido de ir para outra tela do compendio (ou ao lobby); quem navega e o App.
signal navigate_requested(route: StringName)

enum Tab { BESTIARY, FORGE }

## Brilhos do cabecalho do prototipo: primary-container/10 de 384 px (canto superior direito) e
## secondary/10 de 320 px.
const GLOW_ALPHA: float = 0.07
const GLOW_GOLD_SIZE: float = 384.0
const GLOW_GOLD_INSET: float = -96.0
const GLOW_CYAN_SIZE: float = 320.0
const GLOW_CYAN_RIGHT: float = 640.0
const GLOW_CYAN_BOTTOM: float = -80.0
## Rolagem por teclado: fracao da altura visivel por passo (setas) e por pagina.
const ARROW_SCROLL: float = 0.25
const PAGE_SCROLL: float = 0.9
const TAB_ROUTES: Dictionary[Tab, StringName] = {
	Tab.BESTIARY: Router.BESTIARY, Tab.FORGE: Router.FORGE
}
const NO_CATALOG: String = "Não foi possível carregar o catálogo do jogo."

var catalog: CatalogService

var _header: ScreenHeader = ScreenHeader.new()
var _tab_chips: Dictionary[Tab, FilterChip] = {}
var _filters: HBoxContainer = HBoxContainer.new()
var _ribbon: PanelContainer = PanelContainer.new()
var _state: StateBox = StateBox.new()
var _scroll: ScrollContainer = ScrollContainer.new()
var _body: VBoxContainer = VBoxContainer.new()
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
	_body.theme_type_variation = &"LnVGapXl"
	_body.size_flags_horizontal = SIZE_EXPAND_FILL
	gutter.add_child(_body)
	_state.set_state(StateBox.State.IDLE)
	_tab_chips[_current_tab()].grab_focus.call_deferred()
	if catalog != null:
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


## Liga a tela ao catalogo e monta (ou mostra o erro se o catalogo nao carregou).
func bind(service: CatalogService) -> void:
	catalog = service
	if is_node_ready():
		refresh()


## Carrega o catalogo (de novo, se falhou) e monta o corpo uma unica vez.
func refresh() -> void:
	if catalog == null:
		return
	catalog.load_all()
	if not catalog.is_loaded():
		_state.set_state(StateBox.State.ERROR, tr(NO_CATALOG))
		return
	if not _built:
		_built = true
		_bind_header()
		_build_ribbon()
		_ribbon.visible = true
		_build_tabs_labels()
		_build_filters(_filters)
		_build_body(_body)
	_state.set_state(StateBox.State.READY)


func state() -> StateBox.State:
	return _state.state


func tab_chip(tab: Tab) -> FilterChip:
	return _tab_chips[tab]


func scroll_position() -> int:
	return _scroll.scroll_vertical


## Rola o corpo (captura e teste); alem do fim vai ate o fim.
func scroll_to(pixels: int) -> void:
	_scroll.scroll_vertical = pixels


## Texto da fita de contadores: [rotulo, valor, unidade] por celula (para teste e captura).
func ribbon_texts() -> Array[PackedStringArray]:
	var texts: Array[PackedStringArray] = []
	for cell: Array in _ribbon_cells():
		texts.append(PackedStringArray([cell[0], cell[1], cell[2]]))
	return texts


func _can_go_back_changed() -> void:
	if is_node_ready() and _built:
		_bind_header()


## Virtual: aba desta tela.
func _current_tab() -> Tab:
	return Tab.BESTIARY


## Virtual: [titulo, sobretitulo, icone, descricao] do cabecalho.
func _header_texts() -> Array[String]:
	return ["", "", "", ""]


## Virtual: celulas da fita [rotulo, valor, unidade, tipo do valor].
func _ribbon_cells() -> Array[Array]:
	return []


## Virtual: filtros e busca ao lado das abas.
func _build_filters(_slot: HBoxContainer) -> void:
	pass


## Virtual: conteudo que rola.
func _build_body(_content: VBoxContainer) -> void:
	pass


func _build_header() -> void:
	_header.back_requested.connect(back_requested.emit)
	_header.use_compact_kicker()
	_header.add_glow(
		Color(UiTokens.GOLD, GLOW_ALPHA), GLOW_GOLD_SIZE, GLOW_GOLD_INSET, GLOW_GOLD_INSET
	)
	_header.add_glow(
		Color(UiTokens.CYAN, GLOW_ALPHA), GLOW_CYAN_SIZE, GLOW_CYAN_RIGHT, GLOW_CYAN_BOTTOM, true
	)
	_header.right_slot.add_child(_ribbon)
	var strip := PanelContainer.new()
	strip.theme_type_variation = &"LnCpTabStrip"
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapXs"
	strip.add_child(row)
	var group := ButtonGroup.new()
	var specs: Array[Array] = [[Tab.BESTIARY, UiIcons.SKULL], [Tab.FORGE, UiIcons.SHIELD]]
	for spec: Array in specs:
		var chip := FilterChip.new("", spec[1], FilterChip.ICON_INACTIVE_DEFAULT)
		chip.button_group = group
		chip.set_count(FilterChip.NO_COUNT)
		chip.pressed.connect(_on_tab_pressed.bind(spec[0]))
		row.add_child(chip)
		_tab_chips[spec[0]] = chip
	_tab_chips[Tab.BESTIARY].set_label_text(tr("Bestiário"))
	_tab_chips[Tab.FORGE].set_label_text(tr("Equipamentos & Sets"))
	_ribbon.visible = false
	_tab_chips[_current_tab()].set_pressed_no_signal(true)
	_tab_chips[_current_tab()].refresh()
	_header.bottom_slot.add_child(strip)
	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	_header.bottom_slot.add_child(spacer)
	_filters.theme_type_variation = &"LnHGapSm"
	_header.bottom_slot.add_child(_filters)
	_header.show_bottom_slot()
	_bind_header()


func _bind_header() -> void:
	var texts := _header_texts()
	_header.bind(texts[0], can_go_back, texts[1], texts[2], texts[3])


## Rotulos das abas com a contagem real: "Bestiario (6 monstros)".
func _build_tabs_labels() -> void:
	var species := catalog.monster_species().size()
	_tab_chips[Tab.BESTIARY].set_label_text(tr("Bestiário (%d monstros)") % species)
	_tab_chips[Tab.FORGE].set_label_text(
		tr("Equipamentos & Sets (%d itens)") % catalog.items.size()
	)


## Fita de contadores (bg-lowest, divisores entre celulas): rotulo, valor grande e unidade.
func _build_ribbon() -> void:
	_ribbon.theme_type_variation = &"LnRibbon"
	_ribbon.size_flags_vertical = SIZE_SHRINK_END
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapMd"
	_ribbon.add_child(row)
	var cells := _ribbon_cells()
	for i: int in cells.size():
		if i > 0:
			var divider := VSeparator.new()
			divider.theme_type_variation = &"LnDividerV"
			row.add_child(divider)
		var cell: Array = cells[i]
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


func _on_tab_pressed(tab: Tab) -> void:
	if tab != _current_tab():
		navigate_requested.emit(TAB_ROUTES[tab])
