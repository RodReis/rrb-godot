extends GutTest

const SPAWN_A: Vector2 = Vector2(-24.0, 24.0)
const SPAWN_B: Vector2 = Vector2(24.0, -24.0)


func _hero(team: int, at: Vector2) -> Dictionary:
	return {"kind": ArenaMapPois.KIND_HERO, "team": team, "at": at}


func _monster(team: int, at: Vector2, id: String) -> Dictionary:
	return {"kind": ArenaMapPois.KIND_MONSTER, "team": team, "at": at, "monster_id": id}


func _chest(team: int, at: Vector2, chest: String) -> Dictionary:
	return {"kind": ArenaMapPois.KIND_CHEST, "team": team, "at": at, "chest_kind": chest}


func _boss() -> Dictionary:
	return {"kind": ArenaMapPois.KIND_BOSS, "team": 0, "at": Vector2.ZERO, "monster_id": "king"}


func _markers() -> Array[Dictionary]:
	var markers: Array[Dictionary] = [
		_hero(1, SPAWN_A),
		_hero(2, SPAWN_B),
		_boss(),
		_monster(1, SPAWN_A + Vector2(3, -5), "t1"),
		_monster(1, SPAWN_A + Vector2(6, -6), "t2"),
		_chest(1, SPAWN_A + Vector2(1, -9), "common"),
		_monster(2, SPAWN_B + Vector2(-3, 5), "t1"),
		_monster(2, SPAWN_B + Vector2(-6, 6), "t2"),
		_chest(2, SPAWN_B + Vector2(-1, 9), "common"),
		# campo lateral da metade A, longe da base
		_monster(1, Vector2(-26, -4), "t2"),
		_monster(1, Vector2(-23.5, -5.5), "t1"),
		_chest(1, Vector2(-23, -1.5), "common"),
		# campo lateral da metade B (rotacao de 180 graus)
		_monster(2, Vector2(26, 4), "t2"),
		_monster(2, Vector2(23.5, 5.5), "t1"),
		_chest(2, Vector2(23, 1.5), "common"),
		# campos de canto (neutros, longe do centro)
		_monster(0, Vector2(-27.5, -27.5), "golem"),
		_chest(0, Vector2(-25, -28.5), "reinforced"),
		_monster(0, Vector2(27.5, 27.5), "golem"),
		_chest(0, Vector2(25, 28.5), "reinforced"),
		# centro contestado: dois acampamentos e dois baus raros (um perto de cada)
		_monster(0, Vector2(-7, -7), "golem_t3"),
		_chest(0, Vector2(-8.8, -8.8), "rare"),
		_monster(0, Vector2(7, 7), "golem_t3"),
		_chest(0, Vector2(8.8, 8.8), "rare"),
	]
	return markers


func _build() -> Dictionary:
	var bridges: Array[Vector2] = [Vector2(-11.3, 11.3), Vector2(11.3, -11.3)]
	var grass: Array[Vector2] = [Vector2(-18, 9), Vector2(18, -9), Vector2(-12, 0)]
	var lagoons: Array[Vector2] = [Vector2(-26, -18), Vector2(26, 18)]
	var pois := ArenaMapPois.build(_markers(), bridges, grass, lagoons)
	var by_id: Dictionary = {}
	for poi: Dictionary in pois:
		by_id[poi["id"]] = poi
	return by_id


func test_ids_are_the_expected_set() -> void:
	var ids := _build().keys()
	ids.sort()
	var expected: Array = [
		"base_a",
		"base_b",
		"bridges",
		"center_fields",
		"corner_fields",
		"crater",
		"river",
		"side_fields",
		"tall_grass",
	]
	assert_eq(ids, expected)


func test_each_base_anchors_on_its_spawn_with_its_own_monsters_and_chests() -> void:
	var pois := _build()
	var base_a: Dictionary = pois["base_a"]
	var group: Dictionary = base_a["groups"][0]
	assert_eq(group["anchor"], SPAWN_A)
	assert_eq(group["monsters"], {"t1": 1, "t2": 1})
	assert_eq(group["chests"], {"common": 1})
	assert_eq(pois["base_b"]["groups"][0]["anchor"], SPAWN_B)


func test_side_fields_are_two_per_half_by_distance_from_the_base() -> void:
	var groups: Array = _build()["side_fields"]["groups"]
	assert_eq(groups.size(), 2)
	for group: Dictionary in groups:
		assert_eq(group["monsters"], {"t1": 1, "t2": 1})
		assert_eq(group["chests"], {"common": 1})


func test_corner_fields_are_neutral_clusters_outside_the_center() -> void:
	var groups: Array = _build()["corner_fields"]["groups"]
	assert_eq(groups.size(), 2)
	assert_eq(groups[0]["monsters"], {"golem": 1})
	assert_eq(groups[0]["chests"], {"reinforced": 1})


func test_center_fields_group_each_camp_with_its_chest() -> void:
	var groups: Array = _build()["center_fields"]["groups"]
	assert_eq(groups.size(), 2)
	for group: Dictionary in groups:
		assert_eq(group["monsters"], {"golem_t3": 1})
		assert_eq(group["chests"], {"rare": 1})


func test_crater_is_the_boss_marker() -> void:
	var group: Dictionary = _build()["crater"]["groups"][0]
	assert_eq(group["anchor"], Vector2.ZERO)
	assert_eq(group["monsters"], {"king": 1})


func test_terrain_pois_carry_only_anchors() -> void:
	var pois := _build()
	assert_eq(pois["bridges"]["groups"].size(), 2)
	assert_eq(pois["river"]["groups"].size(), 2)
	assert_eq(pois["tall_grass"]["groups"].size(), 3)
	assert_true(pois["bridges"]["groups"][0]["monsters"].is_empty())
	assert_true(pois["bridges"]["groups"][0]["chests"].is_empty())


func test_groups_are_ordered_by_position_for_a_stable_file() -> void:
	var first: Array = _build()["side_fields"]["groups"]
	var reversed: Array[Dictionary] = _markers()
	reversed.reverse()
	for poi: Dictionary in ArenaMapPois.build(reversed, [], [], []):
		if poi["id"] == "side_fields":
			assert_eq(poi["groups"], first)


func test_uniform_reports_fields_with_different_content() -> void:
	var pois := _build()
	assert_true(ArenaMapPois.is_uniform(pois["side_fields"]))
	var broken: Dictionary = pois["side_fields"].duplicate(true)
	broken["groups"][1]["monsters"] = {"t1": 3}
	assert_false(ArenaMapPois.is_uniform(broken))
