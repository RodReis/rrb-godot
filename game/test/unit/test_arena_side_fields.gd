extends GutTest
## Campos laterais (F36, GDB §5.1/§6.2) na Ilha (SPEC-044 §3): 2 por metade — O e SO na metade
## A (x < -2), L e SE na B —, fora da base, da coroa do rio e do canal; 2 T1 + 1 T2 + 2 baus.
## Contagens totais e espelho em x: test_ilha_arcana.

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
const SPAWN_A: Vector3 = Vector3(-24, 0, -24)
const BASE_RADIUS: float = 12.7
const RIVER_RING_IN: float = 14.0
const RIVER_RING_OUT: float = 18.0
const CHANNEL_HALF: float = 2.0
const ARENA_RADIUS: float = 35.0
## Campo O fica a |z| pequeno; SO a z > 0 (SPEC-044 §3: O (-26, 0), SO (-16, +24)).
const SOUTH_FROM_Z: float = 12.0
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
	return SPAWN_A if team == GateRules.TEAM_A else Vector3(-SPAWN_A.x, 0, SPAWN_A.z)


## Marcadores de monstro/bau do time fora da base (> 12,7 u do spawn): os campos laterais.
func _lateral(team: int) -> Array[SpawnMarker]:
	var result: Array[SpawnMarker] = []
	for m: SpawnMarker in _markers():
		var content := m.kind == SpawnMarker.Kind.MONSTER or m.kind == SpawnMarker.Kind.CHEST
		if content and m.team == team and m.position.distance_to(_spawn_of(team)) > BASE_RADIUS:
			result.append(m)
	return result


func test_dois_campos_por_metade_com_2_t1_1_t2_e_2_baus() -> void:
	for team: int in [GateRules.TEAM_A, GateRules.TEAM_B]:
		for south: bool in [false, true]:
			var t1 := 0
			var t2 := 0
			var chests := 0
			for m: SpawnMarker in _lateral(team):
				if (m.position.z > SOUTH_FROM_Z) != south:
					continue
				if m.kind == SpawnMarker.Kind.CHEST:
					assert_eq(m.chest_kind, SpawnMarker.ChestKind.COMMON)
					chests += 1
				elif m.monster_id == &"skeleton_t1":
					t1 += 1
				elif m.monster_id == &"skeleton_warrior_t2":
					t2 += 1
			assert_eq([t1, t2, chests], [2, 1, 2], "time %d, sul %s" % [team, south])


## Todo campo lateral na propria metade (A: x < -2; B: x > 2), fora do canal N-S.
func test_campos_na_propria_metade() -> void:
	for team: int in [GateRules.TEAM_A, GateRules.TEAM_B]:
		var side := -1.0 if team == GateRules.TEAM_A else 1.0
		for m: SpawnMarker in _lateral(team):
			assert_gt(m.position.x * side, CHANNEL_HALF, "%s fora da metade" % m.name)


## Fora da coroa do rio, da base rival e dentro da arena.
func test_fora_da_coroa_da_base_rival_e_da_borda() -> void:
	for team: int in [GateRules.TEAM_A, GateRules.TEAM_B]:
		var rival := GateRules.TEAM_B if team == GateRules.TEAM_A else GateRules.TEAM_A
		for m: SpawnMarker in _lateral(team):
			var r := m.position.length()
			assert_gt(r, RIVER_RING_OUT, "%s na coroa do rio" % m.name)
			assert_lt(r, ARENA_RADIUS - 1.0, "%s na borda" % m.name)
			assert_gt(m.position.distance_to(_spawn_of(rival)), BASE_RADIUS, "%s na base rival" % m.name)


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
