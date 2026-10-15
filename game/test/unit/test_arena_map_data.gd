extends GutTest
## F33: shared/assets/ui/arena_map.tres (dados da tela Arena & Mapa do Launcher) bate com a arena
## real: os pontos de interesse gravados sao os que a cena gera hoje, o enquadramento e o do codigo
## e os ids de SpawnMarker.Kind e ChestRules.Kind que o gerador usa nao mudaram. Falhou? Rode
##   godot --path game --resolution 1920x1080 -s <repo>/tools/ui/render_arena_map.gd

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
const DATA: String = "res://shared/assets/ui/arena_map.tres"

var _arena: Node3D
var _data: ArenaMapData


func before_all() -> void:
	_arena = (load(ARENA) as PackedScene).instantiate() as Node3D
	add_child(_arena)
	_data = load(DATA) as ArenaMapData


func after_all() -> void:
	_arena.free()


func test_saved_pois_are_the_ones_the_scene_generates_today() -> void:
	assert_not_null(_data)
	var fresh := ArenaMapSource.pois(_arena)
	assert_eq(_data.pois.size(), fresh.size())
	for i: int in mini(_data.pois.size(), fresh.size()):
		var saved: Dictionary = _data.pois[i]
		assert_eq(saved["id"], fresh[i]["id"])
		var saved_groups: Array = saved["groups"]
		var fresh_groups: Array = fresh[i]["groups"]
		assert_eq(saved_groups.size(), fresh_groups.size(), saved["id"])
		for j: int in mini(saved_groups.size(), fresh_groups.size()):
			var a: Dictionary = saved_groups[j]
			var b: Dictionary = fresh_groups[j]
			assert_almost_eq((a["anchor"] as Vector2).x, (b["anchor"] as Vector2).x, 0.001)
			assert_almost_eq((a["anchor"] as Vector2).y, (b["anchor"] as Vector2).y, 0.001)
			assert_eq(a["monsters"], b["monsters"], saved["id"])
			assert_eq(a["chests"], b["chests"], saved["id"])


func test_saved_view_is_the_one_in_code() -> void:
	assert_true(_data.matches_view(), "a imagem esta velha: rode tools/ui/render_arena_map.gd")


func test_every_group_of_a_poi_has_the_same_content() -> void:
	for poi: Dictionary in _data.pois:
		assert_true(ArenaMapPois.is_uniform(poi), poi["id"])


func test_marker_kinds_match_the_generator_constants() -> void:
	assert_eq(int(SpawnMarker.Kind.HERO), ArenaMapPois.KIND_HERO)
	assert_eq(int(SpawnMarker.Kind.MONSTER), ArenaMapPois.KIND_MONSTER)
	assert_eq(int(SpawnMarker.Kind.CHEST), ArenaMapPois.KIND_CHEST)
	assert_eq(int(SpawnMarker.Kind.BOSS), ArenaMapPois.KIND_BOSS)


func test_chest_kind_names_match_the_launcher_texts() -> void:
	# ArenaMapTexts.CHEST_NAMES (Launcher) usa estas chaves: ChestRules.Kind em minusculas.
	var names: Array[String] = []
	for key: String in ChestRules.Kind.keys():
		names.append(key.to_lower())
	names.sort()
	assert_eq(names, ["common", "rare", "reinforced"] as Array[String])


func test_map_counts_match_the_gdb_distribution() -> void:
	var chests := 0
	var monsters := 0
	for poi: Dictionary in _data.pois:
		for group: Dictionary in poi["groups"]:
			for kind: String in group["chests"]:
				chests += int(group["chests"][kind])
			for id: String in group["monsters"]:
				monsters += int(group["monsters"][id])
	assert_eq(chests, 28, "GDB §6.2: 28 baus")
	assert_eq(monsters, 35, "GDB §5.1: 34 monstros + o Rei Esqueleto")


func test_every_anchor_projects_inside_the_image() -> void:
	for poi: Dictionary in _data.pois:
		for group: Dictionary in poi["groups"]:
			var uv := ArenaMapView.world_to_uv(group["anchor"])
			assert_between(uv.x, 0.0, 1.0, poi["id"])
			assert_between(uv.y, 0.0, 1.0, poi["id"])
