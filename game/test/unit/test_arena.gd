extends GutTest
## Criterio de aceite do F7 (SPEC-007 §6) sobre a cena gerada. Spawn em (-24, +24) e campos
## do centro em 45/225 graus: decisoes do PI de 2026-10-09.

const ARENA: String = "res://scenes/arena/arena.tscn"
const HERO_SPEED: float = 5.8
const TOLERANCE: float = 0.1
const SPAWN_TO_CENTER_S: float = 6.3
const SPAWN_TO_SPAWN_S: float = 12.7
const CAPSULE_RADIUS: float = 0.4
const CAPSULE_HEIGHT: float = 1.8
const ARROW_RADIUS: float = 0.3
const LIFT: float = 0.05
## Eixo da base A (centro -> base A) e lateral (ao longo do rio, x = z).
const AXIS_A: Vector3 = Vector3(-0.70710678, 0, 0.70710678)
const LATERAL: Vector3 = Vector3(0.70710678, 0, 0.70710678)

var _arena: Node3D


func before_all() -> void:
	_arena = (load(ARENA) as PackedScene).instantiate() as Node3D
	add_child(_arena)


func after_all() -> void:
	_arena.free()


func _local(s: float, l: float) -> Vector3:
	return AXIS_A * s + LATERAL * l


func _polar(azimuth_deg: float, r: float) -> Vector3:
	var a := deg_to_rad(azimuth_deg)
	return Vector3(-sin(a), 0, -cos(a)) * r


func _markers() -> Array[SpawnMarker]:
	var result: Array[SpawnMarker] = []
	for node: Node in _arena.find_children("*", "Marker3D", true, false):
		if node is SpawnMarker:
			result.append(node as SpawnMarker)
	return result


func _count(kind: SpawnMarker.Kind, team: int, tier: int = -1) -> int:
	var n := 0
	for m: SpawnMarker in _markers():
		if m.kind == kind and m.team == team and (tier < 0 or m.tier == tier):
			n += 1
	return n


func _hits(shape: Shape3D, from: Vector3, to: Vector3, mask: int) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), from)
	query.motion = to - from
	query.collision_mask = mask
	var result := _arena.get_world_3d().direct_space_state.cast_motion(query)
	return result[0] < 1.0


func _overlaps(shape: Shape3D, at: Vector3, mask: int) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), at)
	query.collision_mask = mask
	return not _arena.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


func _capsule() -> CapsuleShape3D:
	var capsule := CapsuleShape3D.new()
	capsule.radius = CAPSULE_RADIUS
	capsule.height = CAPSULE_HEIGHT
	return capsule


func _walk(points: Array[Vector3], mask: int) -> float:
	var lift := Vector3.UP * (CAPSULE_HEIGHT / 2 + LIFT)
	var length := 0.0
	for i: int in range(points.size() - 1):
		var blocked := _hits(_capsule(), points[i] + lift, points[i + 1] + lift, mask)
		assert_false(blocked, "trecho bloqueado: %s -> %s" % [points[i], points[i + 1]])
		length += points[i].distance_to(points[i + 1])
	return length / HERO_SPEED


func _path_a_to_center() -> Array[Vector3]:
	return [_local(33.94, 0), _local(29, 2.9), _local(21.21, 0), Vector3.ZERO]


func test_contagem_de_herois() -> void:
	assert_eq(_count(SpawnMarker.Kind.HERO, GateRules.TEAM_A), 1)
	assert_eq(_count(SpawnMarker.Kind.HERO, GateRules.TEAM_B), 1)


func test_contagem_de_monstros_por_zona() -> void:
	for team: int in [GateRules.TEAM_A, GateRules.TEAM_B]:
		assert_eq(_count(SpawnMarker.Kind.MONSTER, team, 1), 4)
		assert_eq(_count(SpawnMarker.Kind.MONSTER, team, 2), 1)
	assert_eq(_count(SpawnMarker.Kind.MONSTER, GateRules.TEAM_NEUTRAL, 2), 4)
	assert_eq(_count(SpawnMarker.Kind.MONSTER, GateRules.TEAM_NEUTRAL, 3), 2)
	assert_eq(_count(SpawnMarker.Kind.BOSS, GateRules.TEAM_NEUTRAL), 1)


func test_total_de_17_monstros_e_16_baus() -> void:
	var monsters := 0
	var chests := 0
	for m: SpawnMarker in _markers():
		if m.kind == SpawnMarker.Kind.MONSTER or m.kind == SpawnMarker.Kind.BOSS:
			monsters += 1
		elif m.kind == SpawnMarker.Kind.CHEST:
			chests += 1
	assert_eq(monsters, 17)
	assert_eq(chests, 16)


func test_baus_comuns_nas_bases_e_raros_no_centro() -> void:
	for m: SpawnMarker in _markers():
		if m.kind != SpawnMarker.Kind.CHEST:
			continue
		if m.team == GateRules.TEAM_NEUTRAL:
			assert_eq(m.chest_kind, SpawnMarker.ChestKind.RARE)
		else:
			assert_eq(m.chest_kind, SpawnMarker.ChestKind.COMMON)


func test_monstros_tem_id_do_catalogo() -> void:
	for m: SpawnMarker in _markers():
		if m.kind == SpawnMarker.Kind.MONSTER or m.kind == SpawnMarker.Kind.BOSS:
			assert_ne(Ids.to_int(m.monster_id), -1, str(m.monster_id))


func test_simetria_por_rotacao_de_180_graus() -> void:
	var markers := _markers()
	for m: SpawnMarker in markers:
		var mirror := Vector3(-m.position.x, m.position.y, -m.position.z)
		var found := false
		for other: SpawnMarker in markers:
			if (
				other.position.distance_to(mirror) < 0.01
				and other.kind == m.kind
				and other.tier == m.tier
				and other.monster_id == m.monster_id
				and other.chest_kind == m.chest_kind
			):
				found = true
		assert_true(found, "sem espelho: %s em %s" % [m.name, m.position])


func test_spawn_dos_herois() -> void:
	for m: SpawnMarker in _markers():
		if m.kind == SpawnMarker.Kind.HERO:
			var expected := (
				Vector3(-24, 0, 24) if m.team == GateRules.TEAM_A else Vector3(24, 0, -24)
			)
			assert_almost_eq(m.position, expected, Vector3.ONE * 0.01)


## Fonte da base (PI 2026-10-10, #74): uma por base, do time dono, espelhada, dentro da base
## (ate 12,7 u do spawn) e dentro da arena.
func test_uma_fonte_por_base_espelhada() -> void:
	var by_team: Dictionary = {}
	for node: Node in _arena.find_children("*", "Node3D", true, false):
		if node is Fountain:
			by_team[(node as Fountain).team] = (node as Fountain).position
	assert_eq(by_team.size(), 2)
	var a: Vector3 = by_team[GateRules.TEAM_A]
	assert_almost_eq(by_team[GateRules.TEAM_B], -a, Vector3.ONE * 0.01)
	assert_lt(a.distance_to(Vector3(-24, 0, 24)), 12.7)
	assert_lt(a.length(), 35.0 - 1.0)


func test_baus_de_base_a_3u_um_do_outro() -> void:
	var chests: Array[SpawnMarker] = []
	for m: SpawnMarker in _markers():
		if m.kind == SpawnMarker.Kind.CHEST and m.team != GateRules.TEAM_NEUTRAL:
			chests.append(m)
	for a: SpawnMarker in chests:
		for b: SpawnMarker in chests:
			if a != b:
				assert_true(a.position.distance_to(b.position) >= 3.0, "%s/%s" % [a.name, b.name])


func test_toda_agua_desenhada_tem_colisao_de_rio() -> void:
	var river_at: Array[Vector3] = []
	for node: Node in _arena.get_node("River").get_children():
		river_at.append((node as Node3D).position)
	var water := 0
	for tile: Node in _arena.get_node("Tiles").get_children():
		if not tile.scene_file_path.ends_with("hex_water.gltf"):
			continue
		water += 1
		var at := (tile as Node3D).position
		var covered := false
		for p: Vector3 in river_at:
			covered = covered or Vector2(p.x, p.z).distance_to(Vector2(at.x, at.z)) < 0.01
		assert_true(covered, "agua sem colisao em %s" % at)
	assert_eq(water, river_at.size())


func test_dois_portoes_e_seis_moitas() -> void:
	var teams: Array[int] = []
	for node: Node in _arena.find_children("*", "StaticBody3D", true, false):
		if node is Gate:
			teams.append((node as Gate).team)
	teams.sort()
	assert_eq(teams, [GateRules.TEAM_A, GateRules.TEAM_B])
	var grass := 0
	for node: Node in _arena.find_children("*", "Area3D", true, false):
		if node.is_in_group(&"tall_grass"):
			grass += 1
	assert_eq(grass, 6)


func test_spawn_ao_centro_em_6_3s() -> void:
	await wait_physics_frames(2)
	var t := _walk(_path_a_to_center(), GateRules.hero_mask(GateRules.TEAM_A))
	gut.p("spawn A -> centro: %.2f s" % t)
	assert_almost_eq(t, SPAWN_TO_CENTER_S, SPAWN_TO_CENTER_S * TOLERANCE)


func test_spawn_a_spawn_em_12_7s_com_portoes_caidos() -> void:
	await wait_physics_frames(2)
	var path := _path_a_to_center()
	var back := _path_a_to_center()
	back.reverse()
	for i: int in range(1, back.size()):
		path.append(-back[i])
	var t := _walk(path, GateRules.LAYER_WORLD | GateRules.LAYER_RIVER)
	gut.p("spawn A -> spawn B: %.2f s" % t)
	assert_almost_eq(t, SPAWN_TO_SPAWN_S, SPAWN_TO_SPAWN_S * TOLERANCE)


func test_rio_bloqueia_em_8_pontos() -> void:
	await wait_physics_frames(2)
	var lift := Vector3.UP * (CAPSULE_HEIGHT / 2 + LIFT)
	var crossings: Array[Array] = []
	for r: float in [24.0, 30.0]:
		for side: float in [-1.0, 1.0]:
			var on_river := LATERAL * r * side
			crossings.append([on_river - AXIS_A * 6, on_river + AXIS_A * 6])
	for azimuth: float in [0.0, 90.0, 180.0, 270.0]:
		crossings.append([_polar(azimuth, 11.0), _polar(azimuth, 21.0)])
	for c: Array in crossings:
		var a: Vector3 = c[0] + lift
		var b: Vector3 = c[1] + lift
		assert_false(_overlaps(_capsule(), a, GateRules.LAYER_RIVER), "comeca no rio: %s" % a)
		assert_false(_overlaps(_capsule(), b, GateRules.LAYER_RIVER), "termina no rio: %s" % b)
		assert_true(_hits(_capsule(), a, b, GateRules.LAYER_RIVER), "rio vazou: %s -> %s" % [a, b])


func test_pontes_atravessam_o_rio() -> void:
	await wait_physics_frames(2)
	var lift := Vector3.UP * (CAPSULE_HEIGHT / 2 + LIFT)
	var mask := GateRules.LAYER_WORLD | GateRules.LAYER_RIVER
	for azimuth: float in [135.0, 315.0]:
		var a := _polar(azimuth, 12.0) + lift
		var b := _polar(azimuth, 20.5) + lift
		assert_false(_hits(_capsule(), a, b, mask), "ponte bloqueada em %s" % azimuth)


func test_portao_barra_so_o_adversario_ate_cair() -> void:
	await wait_physics_frames(2)
	var lift := Vector3.UP * (CAPSULE_HEIGHT / 2 + LIFT)
	var outside := _local(18.5, 0) + lift
	var inside := _local(24, 0) + lift
	assert_false(_hits(_capsule(), outside, inside, GateRules.hero_mask(GateRules.TEAM_A)))
	assert_true(_hits(_capsule(), outside, inside, GateRules.hero_mask(GateRules.TEAM_B)))
	var gate_a: Gate = null
	for node: Node in _arena.find_children("*", "StaticBody3D", true, false):
		if node is Gate and (node as Gate).team == GateRules.TEAM_A:
			gate_a = node as Gate
	gate_a.fall()
	await wait_physics_frames(2)
	assert_false(_hits(_capsule(), outside, inside, GateRules.hero_mask(GateRules.TEAM_B)))


func test_flecha_bate_nos_pilares_e_passa_nas_entradas() -> void:
	await wait_physics_frames(2)
	var arrow := SphereShape3D.new()
	arrow.radius = ARROW_RADIUS
	var height := Vector3.UP
	for azimuth: float in [0.0, 10.48, 79.52, 90.0, 180.0, 270.0]:
		var blocked := _hits(
			arrow,
			_polar(azimuth, 9.0) + height,
			_polar(azimuth, 3.0) + height,
			GateRules.LAYER_WORLD
		)
		assert_true(blocked, "flecha passou entre pilares em %s" % azimuth)
	for azimuth: float in [45.0, 135.0, 225.0, 315.0]:
		var blocked := _hits(
			arrow,
			_polar(azimuth, 9.0) + height,
			_polar(azimuth, 3.0) + height,
			GateRules.LAYER_WORLD
		)
		assert_false(blocked, "entrada %s bloqueada" % azimuth)
