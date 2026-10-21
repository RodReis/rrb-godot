extends GutTest
## Campos laterais (F36, GDB §5.1/§6.2) na Ilha (SPEC-046 §2.5): 4 campos nos quadrantes entre
## as rotas — A-top (-26, -4) e A-bot (+4, +26) na metade A (z > x), B por rotacao —, fora da
## base, do rio e das lagoas; 2 T1 + 1 T2 + 2 baus cada, 2 rochas. Contagens totais e rotacao:
## test_ilha_arcana. Corredores: test_arena_corridors.

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
const SPAWN_A: Vector3 = Vector3(-24, 0, 24)
const BASE_RADIUS: float = 12.7
## Base com os baus de fora do muro e os esqueletos de guarda do portao (PI 2026-10-21, F95).
const BASE_REACH: float = 16.5
const RIVER_RING_IN: float = 14.0
const RIVER_RING_OUT: float = 18.0
const ARENA_HALF: float = 40.0
const FIELD_CENTERS_A: Array[Vector3] = [Vector3(-26, 0, -4), Vector3(4, 0, 26)]
## Raio em que o conteudo de um campo fica em volta do centro (offsets do builder <= 4 u).
const FIELD_REACH: float = 4.5
const LAGOON_A: Vector3 = Vector3(-26, 0, -18)
const LAGOON_RADIUS: float = 5.0
const FIELD_TO_LAGOON: float = 6.0
const CAPSULE_RADIUS: float = 0.4
const CAPSULE_HEIGHT: float = 1.8
const LIFT: float = 0.05

var _arena: Node3D


func before_all() -> void:
	_arena = (load(ARENA) as PackedScene).instantiate() as Node3D
	add_child(_arena)


func after_all() -> void:
	_arena.free()


func _markers() -> Array[SpawnMarker]:
	var result: Array[SpawnMarker] = []
	for node: Node in _arena.find_children("*", "Marker3D", true, false):
		if node is SpawnMarker:
			result.append(node as SpawnMarker)
	return result


func _spawn_of(team: int) -> Vector3:
	return SPAWN_A if team == GateRules.TEAM_A else -SPAWN_A


func _fields_of(team: int) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for c: Vector3 in FIELD_CENTERS_A:
		result.append(c if team == GateRules.TEAM_A else -c)
	return result


## Marcadores de monstro/bau do time fora da base (> 12,7 u do spawn): os campos laterais.
func _lateral(team: int) -> Array[SpawnMarker]:
	var result: Array[SpawnMarker] = []
	for m: SpawnMarker in _markers():
		var content := m.kind == SpawnMarker.Kind.MONSTER or m.kind == SpawnMarker.Kind.CHEST
		if content and m.team == team and m.position.distance_to(_spawn_of(team)) > BASE_REACH:
			result.append(m)
	return result


func test_dois_campos_por_metade_com_2_t1_1_t2_e_2_baus() -> void:
	for team: int in [GateRules.TEAM_A, GateRules.TEAM_B]:
		for center: Vector3 in _fields_of(team):
			var t1 := 0
			var t2 := 0
			var chests := 0
			for m: SpawnMarker in _lateral(team):
				if m.position.distance_to(center) > FIELD_REACH:
					continue
				if m.kind == SpawnMarker.Kind.CHEST:
					assert_eq(m.chest_kind, ChestRules.Kind.COMMON)
					chests += 1
				elif m.monster_id == &"skeleton_t1":
					t1 += 1
				elif m.monster_id == &"skeleton_warrior_t2":
					t2 += 1
			assert_eq([t1, t2, chests], [2, 1, 2], "time %d, campo %s" % [team, center])


## Todo marcador lateral pertence a um dos 2 campos (nas posicoes da SPEC-046 §2.5).
func test_todo_lateral_em_um_campo() -> void:
	for team: int in [GateRules.TEAM_A, GateRules.TEAM_B]:
		for m: SpawnMarker in _lateral(team):
			var near := false
			for center: Vector3 in _fields_of(team):
				near = near or m.position.distance_to(center) <= FIELD_REACH
			assert_true(near, "%s fora dos campos" % m.name)


## Todo campo lateral na propria metade (A: z > x; B: z < x).
func test_campos_na_propria_metade() -> void:
	for team: int in [GateRules.TEAM_A, GateRules.TEAM_B]:
		var side := 1.0 if team == GateRules.TEAM_A else -1.0
		for m: SpawnMarker in _lateral(team):
			assert_gt((m.position.z - m.position.x) * side, 2.0, "%s fora da metade" % m.name)


## Fora da coroa do rio, longe das lagoas, fora da base rival e dentro do quadrado.
func test_fora_do_rio_da_base_rival_e_da_borda() -> void:
	for team: int in [GateRules.TEAM_A, GateRules.TEAM_B]:
		var rival := GateRules.TEAM_B if team == GateRules.TEAM_A else GateRules.TEAM_A
		for m: SpawnMarker in _lateral(team):
			var r := m.position.length()
			assert_gt(r, RIVER_RING_OUT, "%s na coroa do rio" % m.name)
			var reach := maxf(absf(m.position.x), absf(m.position.z))
			assert_lt(reach, ARENA_HALF - 1.0, "%s na borda" % m.name)
			assert_gt(
				m.position.distance_to(_spawn_of(rival)), BASE_RADIUS, "%s na base rival" % m.name
			)
			for flip: float in [1.0, -1.0]:
				var gap := m.position.distance_to(LAGOON_A * flip) - LAGOON_RADIUS
				assert_gt(gap, FIELD_TO_LAGOON - FIELD_REACH, "%s perto da lagoa" % m.name)


## Nenhum marcador (de qualquer zona) no rio (colisao) nem na coroa 14-18 u.
func test_nenhum_marcador_no_rio() -> void:
	await wait_physics_frames(2)
	var capsule := CapsuleShape3D.new()
	capsule.radius = CAPSULE_RADIUS
	capsule.height = CAPSULE_HEIGHT
	var lift := Vector3.UP * (CAPSULE_HEIGHT / 2 + LIFT)
	var space := _arena.get_world_3d().direct_space_state
	for m: SpawnMarker in _markers():
		var r := m.position.length()
		assert_false(r > RIVER_RING_IN and r <= RIVER_RING_OUT, "%s na coroa do rio" % m.name)
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = capsule
		query.transform = Transform3D(Basis(), m.position + lift)
		query.collision_mask = GateRules.LAYER_RIVER
		assert_true(space.intersect_shape(query, 1).is_empty(), "%s no rio" % m.name)
