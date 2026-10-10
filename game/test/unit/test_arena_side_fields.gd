extends GutTest
## Campos laterais (F36, GDB §5.1/§6.2) sobre a cena gerada: 2 por metade, nos cantos NO e SE,
## um de cada lado do rio, fora da coroa, do patio e da base; equidistantes do spawn da metade.
## Contagens totais e simetria de 180 graus: test_arena.

const ARENA: String = "res://scenes/arena/arena.tscn"
## Eixo da base A (centro -> base A) e lateral (ao longo do rio, x = z).
const AXIS_A: Vector3 = Vector3(-0.70710678, 0, 0.70710678)
const LATERAL: Vector3 = Vector3(0.70710678, 0, 0.70710678)
## Spawn da base nos eixos (s, l) do time e raio da base (spawn -> portao), SPEC-007 §2.
const SPAWN_LOCAL: Vector2 = Vector2(33.94, 0)
const BASE_RADIUS: float = 12.7
const RIVER_RING_IN: float = 14.0
const RIVER_RING_OUT: float = 18.0
const ARENA_RADIUS: float = 35.0
## Patio, portao e ponte ficam a ate 2,5 u do eixo da base; folga para o campo lateral.
const YARD_HALF_WIDTH: float = 10.0
const TOLERANCE: float = 0.1
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


## Posicao (s, l) do marcador nos eixos da base do proprio time (B = rotacao de 180 graus).
func _team_local(m: SpawnMarker) -> Vector2:
	var p := m.position if m.team != GateRules.TEAM_B else -m.position
	return Vector2(p.dot(AXIS_A), p.dot(LATERAL))


## Marcadores de monstro/bau do time fora da base (> 12,7 u do spawn): os campos laterais.
func _lateral(team: int) -> Array[SpawnMarker]:
	var result: Array[SpawnMarker] = []
	for m: SpawnMarker in _markers():
		var content := m.kind == SpawnMarker.Kind.MONSTER or m.kind == SpawnMarker.Kind.CHEST
		if content and m.team == team and _team_local(m).distance_to(SPAWN_LOCAL) > BASE_RADIUS:
			result.append(m)
	return result


func test_dois_campos_por_metade_com_2_t1_1_t2_e_2_baus() -> void:
	for team: int in [GateRules.TEAM_A, GateRules.TEAM_B]:
		for side: float in [-1.0, 1.0]:
			var t1 := 0
			var t2 := 0
			var chests := 0
			for m: SpawnMarker in _lateral(team):
				if signf(_team_local(m).y) != side:
					continue
				if m.kind == SpawnMarker.Kind.CHEST:
					assert_eq(m.chest_kind, SpawnMarker.ChestKind.COMMON)
					chests += 1
				elif m.monster_id == &"skeleton_t1":
					t1 += 1
				elif m.monster_id == &"skeleton_warrior_t2":
					t2 += 1
			assert_eq([t1, t2, chests], [2, 1, 2], "time %d, lado %d" % [team, side])


## Um campo de cada metade em cada canto: NO (x < 0, z < 0) e SE (x > 0, z > 0).
func test_um_campo_de_cada_lado_do_rio_nos_cantos_no_e_se() -> void:
	for team: int in [GateRules.TEAM_A, GateRules.TEAM_B]:
		var corners: Dictionary = {}
		for m: SpawnMarker in _lateral(team):
			var corner := "NO" if m.position.x < 0 and m.position.z < 0 else "?"
			if m.position.x > 0 and m.position.z > 0:
				corner = "SE"
			assert_ne(corner, "?", "%s fora dos cantos NO/SE" % m.name)
			corners[corner] = true
		assert_eq(corners.size(), 2, "time %d" % team)


## Fora da ilha e da coroa do rio, do patio/ponte, da base e dentro da arena.
func test_fora_da_coroa_do_patio_da_base_e_da_borda() -> void:
	for team: int in [GateRules.TEAM_A, GateRules.TEAM_B]:
		for m: SpawnMarker in _lateral(team):
			var r := m.position.length()
			assert_gt(r, RIVER_RING_OUT, "%s na coroa do rio" % m.name)
			assert_lt(r, ARENA_RADIUS - 1.0, "%s na borda" % m.name)
			assert_gt(absf(_team_local(m).y), YARD_HALF_WIDTH, "%s no patio" % m.name)
			var other := -SPAWN_LOCAL  # spawn do outro time nos eixos deste
			assert_gt(_team_local(m).distance_to(other), BASE_RADIUS, "%s na base rival" % m.name)


## Os 2 campos de cada metade a mesma distancia do spawn da metade (+-10 %).
func test_campos_da_metade_equidistantes_do_spawn() -> void:
	for team: int in [GateRules.TEAM_A, GateRules.TEAM_B]:
		var sums: Dictionary = {-1.0: Vector2.ZERO, 1.0: Vector2.ZERO}
		var counts: Dictionary = {-1.0: 0, 1.0: 0}
		for m: SpawnMarker in _lateral(team):
			var side := signf(_team_local(m).y)
			sums[side] += _team_local(m)
			counts[side] += 1
		var near: float = (sums[-1.0] / counts[-1.0]).distance_to(SPAWN_LOCAL)
		var far: float = (sums[1.0] / counts[1.0]).distance_to(SPAWN_LOCAL)
		gut.p("time %d: campos a %.1f u e %.1f u do spawn" % [team, near, far])
		assert_almost_eq(near, far, maxf(near, far) * TOLERANCE)


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
