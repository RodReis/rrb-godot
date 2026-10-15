extends GutTest
## F33: textos da tela Arena & Mapa (FRONTEND-LAUNCHER §8.3 regra 2). Todo numero sai de
## shared/data (MatchRules, MonsterData) e dos dados gerados da arena real; troca um .tres e o
## texto muda. Nenhum numero de exemplo do prototipo "Arena & Mapa" pode aparecer.

## Exemplos do prototipo que o GDB nao confirma ou que sairam por decisao (§8.3).
const PROTOTYPE_NUMBERS: Array[String] = [
	"432", "24 × 18", "12+4", "1.5%", "6% HP", "18g", "-1,8", "-15%", "14.5", "68°", "20s", "8s"
]
const CHEST_TOTAL: int = 28
const MONSTER_TOTAL: int = 35

var _catalog: CatalogService
var _data: ArenaMapData


func before_each() -> void:
	_catalog = CatalogService.new()
	_catalog.load_all()
	# load() entrega o Resource em cache, o mesmo dos outros testes: mutar a copia, nunca o original.
	_catalog.match_rules = _catalog.match_rules.duplicate() as MatchRules
	_data = _catalog.arena_map


func _join(rules: Array[ArenaMapTexts.Rule]) -> String:
	var lines := PackedStringArray()
	for rule: ArenaMapTexts.Rule in rules:
		lines.append(rule.title + " " + rule.text)
	return "\n".join(lines)


func _info_text(id: String) -> String:
	var info := ArenaMapTexts.poi_info(id, _data, _catalog)
	var parts := PackedStringArray([info.tag, info.title, info.text])
	for fact: PackedStringArray in info.facts:
		parts.append(" ".join(fact))
	return "\n".join(parts)


func test_catalog_loads_the_generated_arena_map() -> void:
	assert_not_null(_data)
	assert_true(_data.matches_view(), "a imagem esta velha: rode tools/ui/render_arena_map.gd")


func test_phase_windows_follow_the_rules() -> void:
	assert_eq(ArenaMapTexts.phase_one_window(_catalog.match_rules), "00:00 — 05:00")
	assert_eq(ArenaMapTexts.phase_two_window(_catalog.match_rules), "05:00 — 10:00")
	_catalog.match_rules.phase1_duration = 240.0
	assert_eq(ArenaMapTexts.phase_one_window(_catalog.match_rules), "00:00 — 04:00")
	assert_eq(ArenaMapTexts.phase_two_window(_catalog.match_rules), "04:00 — 10:00")


func test_phase_one_rules_carry_the_rule_numbers() -> void:
	var text := _join(ArenaMapTexts.phase_one_rules(_catalog.match_rules, _data))
	for expected: String in [
		"05:00", "03:00", "03:30", "8", "80 XP", str(CHEST_TOTAL), "120 HP", "30%"
	]:
		assert_string_contains(text, expected)
	assert_eq(ArenaMapTexts.phase_one_rules(_catalog.match_rules, _data).size(), 4)


func test_phase_one_rules_react_to_a_changed_resource() -> void:
	_catalog.match_rules.boss_spawn_time = 240.0
	_catalog.match_rules.phase1_kill_xp = 95
	var text := _join(ArenaMapTexts.phase_one_rules(_catalog.match_rules, _data))
	assert_string_contains(text, "04:00")
	assert_string_contains(text, "95 XP")
	assert_false(text.contains("03:30"))


func test_phase_two_rules_carry_the_zone_and_victory_numbers() -> void:
	var text := _join(ArenaMapTexts.phase_two_rules(_catalog.match_rules))
	for expected: String in ["35 u", "3,5 u", "1%", "5%", "6 s", "09:00", "5 kills", "10:00"]:
		assert_string_contains(text, expected)


func test_phase_two_rules_react_to_a_changed_resource() -> void:
	_catalog.match_rules.kill_goal = 7
	_catalog.match_rules.respawn_phase2 = 4.5
	var text := _join(ArenaMapTexts.phase_two_rules(_catalog.match_rules))
	assert_string_contains(text, "7 kills")
	assert_string_contains(text, "4,5 s")


func test_zone_steps_come_from_the_zone_table() -> void:
	var steps := ArenaMapTexts.zone_steps(_catalog.match_rules)
	assert_eq(steps.size(), 5, "o raio 0 aos 10:00 e a resolucao, nao um passo")
	assert_eq(steps[0], PackedStringArray(["05:00", "35 u", "100.0"]))
	assert_eq(steps[1][0], "06:00")
	assert_eq(steps[1][1], "26 u")
	assert_eq(steps[4][0], "09:00")
	assert_eq(steps[4][1], "3,5 u")


func test_zone_steps_and_rule_survive_incomplete_zone_data() -> void:
	_catalog.match_rules.zone_radius = PackedFloat64Array()
	_catalog.match_rules.zone_times = PackedFloat64Array([0.0, 60.0])
	assert_eq(ArenaMapTexts.zone_steps(_catalog.match_rules).size(), 0)
	assert_eq(ArenaMapTexts.phase_two_rules(_catalog.match_rules).size(), 4)
	_catalog.match_rules.zone_radius = PackedFloat64Array([35.0, 26.0, 17.5])
	assert_eq(ArenaMapTexts.zone_steps(_catalog.match_rules).size(), 2, "sem tempo, sem passo")


func test_header_chips_and_phase_note_use_the_rules() -> void:
	var chips := ArenaMapTexts.header_chips(_catalog.match_rules)
	assert_eq(chips[0][1], "10:00")
	assert_eq(chips[1][1], "35")
	assert_eq(chips[2][1], "5")
	assert_eq(ArenaMapTexts.phase_one_note(_catalog.match_rules)[1], "80 XP")


func test_strip_stats_count_the_real_arena() -> void:
	var stats := ArenaMapTexts.strip_stats(_data, _catalog)
	assert_eq(stats[0][1], str(MONSTER_TOTAL))
	assert_eq(stats[1][1], str(CHEST_TOTAL))
	assert_eq(stats[2][1], "6")
	assert_eq(stats[3][1], "1 Rei Esqueleto")


func test_every_poi_has_a_card_with_text() -> void:
	for id: String in ArenaMapPois.ORDER:
		var info := ArenaMapTexts.poi_info(id, _data, _catalog)
		assert_eq(info.id, id)
		assert_false(info.title.is_empty(), id)
		assert_false(info.tag.is_empty(), id)
		assert_false(info.text.is_empty(), id)
		assert_false(info.facts.is_empty(), id)


func test_unknown_poi_returns_an_empty_card() -> void:
	assert_eq(ArenaMapTexts.poi_info("nao_existe", _data, _catalog).id, "")


func test_crater_card_follows_the_boss_and_the_clock() -> void:
	var text := _info_text(ArenaMapPois.CRATER)
	for expected: String in [
		"Rei Esqueleto", "2.400 HP", "550 XP", "03:30", "03:00", "05:00", "100%"
	]:
		assert_string_contains(text, expected)
	_catalog.match_rules.boss_spawn_time = 270.0
	assert_string_contains(_info_text(ArenaMapPois.CRATER), "04:30")


func test_base_card_counts_the_real_markers() -> void:
	var text := _info_text(ArenaMapPois.BASE_A)
	for expected: String in [
		"Base A", "4× Esqueleto", "1× Esqueleto Guerreiro", "6 baús comuns", "05:00"
	]:
		assert_string_contains(text, expected)
	assert_string_contains(_info_text(ArenaMapPois.BASE_B), "Base B")


func test_side_and_corner_cards_use_the_respawn_rule() -> void:
	assert_string_contains(_info_text(ArenaMapPois.SIDE_FIELDS), "90 s")
	assert_string_contains(_info_text(ArenaMapPois.CORNER_FIELDS), "Lobo")
	assert_string_contains(_info_text(ArenaMapPois.CORNER_FIELDS), "50%")
	_catalog.match_rules.monster_respawn_phase1 = 60.0
	assert_string_contains(_info_text(ArenaMapPois.SIDE_FIELDS), "60 s")


func test_grass_card_uses_the_reveal_and_vision_rules() -> void:
	var text := _info_text(ArenaMapPois.TALL_GRASS)
	assert_string_contains(text, "1,5 s")
	assert_string_contains(text, "12 u")
	assert_string_contains(text, "6")


func test_terrain_cards_count_the_real_elements() -> void:
	assert_string_contains(_info_text(ArenaMapPois.BRIDGES), "2 pontes")
	assert_string_contains(_info_text(ArenaMapPois.RIVER), "2 lagoas")


func test_pin_label_of_the_boss_carries_the_spawn_time() -> void:
	assert_eq(ArenaMapTexts.pin_label(ArenaMapPois.CRATER, _catalog.match_rules), "BOSS 03:30")
	assert_eq(ArenaMapTexts.pin_label(ArenaMapPois.BASE_A, _catalog.match_rules), "BASE A")


func test_no_prototype_example_number_survives() -> void:
	var all := PackedStringArray()
	all.append(_join(ArenaMapTexts.phase_one_rules(_catalog.match_rules, _data)))
	all.append(_join(ArenaMapTexts.phase_two_rules(_catalog.match_rules)))
	for id: String in ArenaMapPois.ORDER:
		all.append(_info_text(id))
	for stat: Array in ArenaMapTexts.strip_stats(_data, _catalog):
		all.append(" ".join(PackedStringArray([stat[0], stat[1]])))
	var text := "\n".join(all)
	for number: String in PROTOTYPE_NUMBERS:
		assert_false(text.contains(number), "numero de exemplo do prototipo: " + number)
