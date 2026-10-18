# gdlint: ignore=max-public-methods
extends GutTest
## F33: tela Arena & Mapa (FRONTEND-LAUNCHER §3, §6, §8): estados do StateBox, um pino por marcador
## no pixel da projecao, card de detalhe que troca por clique e por teclado, as duas fases e a
## faixa de totais so com numeros de shared/data, "Treino vs Bot" por sinal.

const SCENE: PackedScene = preload("res://scenes/screens/arena_map.tscn")
## Pinos = um por campo/elemento da arena (bases 2, cratera 1, centro 2, laterais 4, canto 2,
## rio 2, pontes 2, mato 6).
const PIN_COUNT: int = 25
const BIG_PINS: int = 3
const DESIGN_SIZE: Vector2 = Vector2(1920, 1080)
## Numeros de exemplo do prototipo "Arena & Mapa" que o GDB nao confirma (§8.3 regra 2).
const PROTOTYPE_NUMBERS: Array[String] = [
	"432", "24 × 18", "12+4", "1.5%", "6% HP", "18g", "65% (", "-1,8", "-15%", "14.5", "68°", "20s"
]

var _catalog: CatalogService
var _screen: ArenaMapScreen


## Catalogo que nao carrega (arquivo ausente): a tela mostra o erro.
class BrokenCatalog:
	extends CatalogService

	func load_all() -> void:
		pass

	func is_loaded() -> bool:
		return false


## Catalogo sem o arquivo do mapa (load_all recarrega o mapa, entao o arquivo some de verdade).
class NoMapCatalog:
	extends CatalogService

	func load_all() -> void:
		super.load_all()
		arena_map = null


func before_each() -> void:
	_catalog = _fresh_catalog()
	_screen = await _open(_catalog)


func _fresh_catalog() -> CatalogService:
	var catalog := CatalogService.new()
	catalog.load_all()
	# load() entrega o Resource em cache, o mesmo dos outros testes: mutar a copia, nunca o original.
	catalog.match_rules = catalog.match_rules.duplicate() as MatchRules
	return catalog


func _open(catalog: CatalogService) -> ArenaMapScreen:
	var screen := SCENE.instantiate() as ArenaMapScreen
	screen.bind(catalog)
	# O pai do teste nao e um Control: sem um anfitriao com tamanho a tela nao teria layout.
	var host := Control.new()
	host.size = DESIGN_SIZE
	add_child_autofree(host)
	host.add_child(screen)
	await wait_process_frames(2)
	return screen


func _texts(node: Node) -> PackedStringArray:
	var found := PackedStringArray()
	for child: Node in node.find_children("*", "Label", true, false):
		found.append((child as Label).text)
	for child: Node in node.find_children("*", "Button", true, false):
		found.append((child as Button).text)
	for child: Node in node.find_children("*", "RichTextLabel", true, false):
		found.append((child as RichTextLabel).get_parsed_text())
	return found


func test_loads_to_the_ready_state() -> void:
	assert_eq(_screen.state(), StateBox.State.READY)
	assert_eq(_screen.canvas().pins().size(), PIN_COUNT)


func test_broken_catalog_shows_the_error_state() -> void:
	var broken := await _open(BrokenCatalog.new())
	assert_eq(broken.state(), StateBox.State.ERROR)


func test_missing_arena_map_shows_the_error_state() -> void:
	var screen := await _open(NoMapCatalog.new())
	assert_eq(screen.state(), StateBox.State.ERROR)


func test_retry_recovers_the_map_when_the_rest_of_the_catalog_is_loaded() -> void:
	var catalog := _fresh_catalog()
	catalog.arena_map = null
	catalog.load_all()
	assert_not_null(catalog.arena_map)


func test_stale_image_shows_the_error_state() -> void:
	var catalog := _fresh_catalog()
	catalog.arena_map = catalog.arena_map.duplicate() as ArenaMapData
	catalog.arena_map.view_height += 1.0
	var screen := await _open(catalog)
	assert_eq(screen.state(), StateBox.State.ERROR)


func test_pins_sit_on_the_projected_marker_pixel() -> void:
	var canvas := _screen.canvas()
	assert_gt(canvas.size.x, 0.0)
	for pin: MapPin in canvas.pins():
		var expected := canvas.uv_of(pin) * canvas.size - pin.size / 2.0
		assert_almost_eq(pin.position.x, expected.x, 0.01)
		assert_almost_eq(pin.position.y, expected.y, 0.01)


func test_base_a_is_bottom_left_and_base_b_top_right_on_screen() -> void:
	var canvas := _screen.canvas()
	var a := canvas.uv_of(canvas.pins_of(ArenaMapPois.BASE_A)[0])
	var b := canvas.uv_of(canvas.pins_of(ArenaMapPois.BASE_B)[0])
	assert_lt(a.x, b.x)
	assert_gt(a.y, b.y)


func test_only_the_landmarks_are_big() -> void:
	var big := 0
	for pin: MapPin in _screen.canvas().pins():
		if pin.is_big():
			big += 1
	assert_eq(big, BIG_PINS)


func test_opens_on_the_crater_like_the_prototype() -> void:
	var card := _screen.detail_card()
	assert_eq(card.poi_id(), ArenaMapPois.CRATER)
	assert_string_contains(card.title_text(), "Rei Esqueleto")
	for pin: MapPin in _screen.canvas().pins_of(ArenaMapPois.CRATER):
		assert_true(pin.selected)


func test_first_focus_is_the_selected_pin() -> void:
	await wait_process_frames(2)
	assert_true(_screen.canvas().pins_of(ArenaMapPois.CRATER)[0].has_focus())


func test_clicking_a_pin_swaps_the_detail_card() -> void:
	var pin := _screen.canvas().pins_of(ArenaMapPois.BASE_A)[0]
	pin.pressed.emit()
	assert_eq(_screen.selected_poi(), ArenaMapPois.BASE_A)
	assert_eq(_screen.detail_card().title_text(), "Base A")
	assert_true(pin.selected)
	for other: MapPin in _screen.canvas().pins_of(ArenaMapPois.CRATER):
		assert_false(other.selected)


func test_every_pin_is_reachable_by_keyboard() -> void:
	for pin: MapPin in _screen.canvas().pins():
		assert_eq(pin.focus_mode, Control.FOCUS_ALL, pin.poi_id)
		assert_false(pin.tooltip_text.is_empty(), pin.poi_id)


func test_accept_key_on_a_focused_pin_selects_it() -> void:
	var pin := _screen.canvas().pins_of(ArenaMapPois.TALL_GRASS)[0]
	pin.grab_focus()
	var press := InputEventKey.new()
	press.keycode = KEY_ENTER
	press.pressed = true
	Input.parse_input_event(press)
	await wait_process_frames(2)
	var release := InputEventAction.new()
	release.action = &"ui_accept"
	release.pressed = false
	Input.parse_input_event(release)
	await wait_process_frames(1)
	assert_eq(_screen.selected_poi(), ArenaMapPois.TALL_GRASS)


func test_small_pin_shows_its_label_only_with_focus_or_mouse() -> void:
	var pins := _screen.canvas().pins_of(ArenaMapPois.TALL_GRASS)
	assert_false(pins[0].label_visible())
	pins[0].grab_focus()
	assert_true(pins[0].label_visible())
	pins[0].pressed.emit()
	assert_false(pins[1].label_visible(), "so o pino clicado mostra o rotulo, nao todos do ponto")


func test_phase_cards_follow_the_rules() -> void:
	var one := _screen.phase_card(PhaseCard.Kind.PREPARATION)
	var two := _screen.phase_card(PhaseCard.Kind.CONFRONTATION)
	assert_eq(one.window_text(), "00:00 — 05:00")
	assert_eq(two.window_text(), "05:00 — 10:00")
	assert_eq(one.rule_count(), 4)
	assert_eq(two.rule_count(), 4)
	assert_string_contains(" ".join(one.rule_texts()), "03:30")
	assert_string_contains(" ".join(two.rule_texts()), "5 kills")


func test_header_has_the_description_from_the_rules() -> void:
	var text := "\n".join(_texts(_screen))
	assert_string_contains(text, "5 min de farm e 5 min de zona mortal")


func test_zone_rule_survives_incomplete_zone_data() -> void:
	var catalog := _fresh_catalog()
	catalog.match_rules.zone_radius = PackedFloat64Array()
	catalog.match_rules.zone_times = PackedFloat64Array()
	catalog.match_rules.zone_damage_pct = PackedFloat64Array()
	var screen := await _open(catalog)
	assert_eq(screen.state(), StateBox.State.READY)
	assert_eq(screen.phase_card(PhaseCard.Kind.CONFRONTATION).rule_count(), 4)


func test_phase_cards_react_to_a_changed_resource() -> void:
	var catalog := _fresh_catalog()
	catalog.match_rules.phase1_duration = 240.0
	catalog.match_rules.kill_goal = 7
	var screen := await _open(catalog)
	assert_eq(screen.phase_card(PhaseCard.Kind.PREPARATION).window_text(), "00:00 — 04:00")
	assert_eq(screen.phase_card(PhaseCard.Kind.CONFRONTATION).window_text(), "04:00 — 10:00")
	assert_string_contains(
		" ".join(screen.phase_card(PhaseCard.Kind.CONFRONTATION).rule_texts()), "7 kills"
	)


func test_changing_a_resource_changes_the_selected_card() -> void:
	var catalog := _fresh_catalog()
	catalog.match_rules.boss_spawn_time = 270.0
	var screen := await _open(catalog)
	assert_string_contains(screen.detail_card().body_text(), "04:30")


func test_practice_button_emits_the_signal() -> void:
	watch_signals(_screen)
	_screen.practice_button().pressed.emit()
	assert_signal_emitted(_screen, "practice_requested")


func test_footer_totals_come_from_the_real_arena() -> void:
	var text := " ".join(_texts(_screen))
	assert_string_contains(text, "35")
	assert_string_contains(text, "28")
	assert_string_contains(text, "Rei Esqueleto")


func test_no_prototype_example_number_survives() -> void:
	var text := "\n".join(_texts(_screen))
	for number: String in PROTOTYPE_NUMBERS:
		assert_false(text.contains(number), "numero de exemplo do prototipo: " + number)


func test_removed_prototype_elements_are_gone() -> void:
	var text := "\n".join(_texts(_screen)).to_upper()
	for removed: String in [
		"ROTAS DE FARM", "SIMULAR TEMPESTADE", "ZOOM ISOMÉTRICO", "TORRES", "A1"
	]:
		assert_false(text.contains(removed), removed)


func test_theme_has_the_arena_types() -> void:
	var theme := ThemeDB.get_project_theme()
	for type: StringName in [
		&"LnAmFrame",
		&"LnAmBar",
		&"LnAmCardLow",
		&"LnAmPhase",
		&"LnAmChip",
		&"LnAmFact",
		&"LnAmPinLabel",
		&"LnAmFillGold",
		&"LnAmGlyphOnCyan",
		&"LnAmPinOnError",
		&"LnAmTagMuted",
		&"LnAmDotError",
		&"LnAmRule",
	]:
		assert_true(
			theme.is_type_variation(type, theme.get_type_variation_base(type)), String(type)
		)
		assert_ne(theme.get_type_variation_base(type), &"", String(type))
