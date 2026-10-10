extends GutTest
## Criterio de aceite do F46 (SPEC-046 §6) por colisao, sobre a cena gerada da Ilha: tempos da
## capsula a 5,8 u/s (spawn -> centro; spawn -> spawn pela MID e pela TOP), rio intransponivel
## fora das 2 pontes (anel + bracos + lagoas), TOP contorna a lagoa, borda quadrada, muros de
## fechamento, portao por time, flecha nos pilares e nada referenciando o Vale Runico congelado.
## Marcadores: test_ilha_arcana. Corredores: test_arena_corridors.

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
const HERO_SPEED: float = 5.8
const TOLERANCE: float = 0.1
const SPAWN_TO_CENTER_S: float = 6.3
## Previsao da SPEC-046 §6 (≈ 12 s pela MID); o valor medido vira a referencia (DEVELOPMENT.md).
const SPAWN_TO_SPAWN_MID_S: float = 12.0
## Pela TOP (corredores O e N), medido no F46 (27,71 s): referencia registrada no DEVELOPMENT.md.
const SPAWN_TO_SPAWN_TOP_S: float = 27.7
const ARENA_HALF: float = 40.0
const CAPSULE_RADIUS: float = 0.4
const CAPSULE_HEIGHT: float = 1.8
const ARROW_RADIUS: float = 0.3
const LIFT: float = 0.05
## Eixo da base A (centro -> spawn A em (-24, +24)) e lateral (esquerda de quem olha o centro).
const AXIS_A: Vector3 = Vector3(-0.70710678, 0, 0.70710678)
const LATERAL: Vector3 = Vector3(-0.70710678, 0, -0.70710678)
const BRIDGE_AZIMUTHS: Array[float] = [135.0, 315.0]
const CRATER_ENTRIES: Array[float] = [45.0, 135.0, 225.0, 315.0]
const LAGOON_A: Vector3 = Vector3(-26, 0, -18)

var _arena: Node3D


func before_all() -> void:
	_arena = (load(ARENA) as PackedScene).instantiate() as Node3D
	add_child(_arena)


func after_all() -> void:
	_arena.free()


func _local(s: float, l: float) -> Vector3:
	return AXIS_A * s + LATERAL * l


func _rotate(v: Vector3) -> Vector3:
	return Vector3(-v.x, v.y, -v.z)


func _polar(azimuth_deg: float, r: float) -> Vector3:
	var a := deg_to_rad(azimuth_deg)
	return Vector3(-sin(a), 0, -cos(a)) * r


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


func _lift() -> Vector3:
	return Vector3.UP * (CAPSULE_HEIGHT / 2 + LIFT)


func _walk(points: Array[Vector3], mask: int) -> float:
	var length := 0.0
	for i: int in range(points.size() - 1):
		var blocked := _hits(_capsule(), points[i] + _lift(), points[i + 1] + _lift(), mask)
		assert_false(blocked, "trecho bloqueado: %s -> %s" % [points[i], points[i + 1]])
		length += points[i].distance_to(points[i + 1])
	return length / HERO_SPEED


## Spawn A -> contorna o muro da base -> portao A -> ponte SO (135 graus) -> entrada da cratera.
func _path_a_to_center() -> Array[Vector3]:
	return [_local(33.94, 0), _local(29, 2.9), _local(21.21, 0), Vector3.ZERO]


## Pela MID: spawn A -> portao A -> ponte SO -> cratera (entradas 135/315) -> ponte NE -> rotacao.
func _path_a_to_b_mid() -> Array[Vector3]:
	var half: Array[Vector3] = [_local(33.94, 0), _local(29, 2.9), _local(21.21, 0)]
	var path := half.duplicate()
	path.append(Vector3.ZERO)
	for i: int in range(half.size() - 1, -1, -1):
		path.append(_rotate(half[i]))
	return path


## Pela TOP: portao A -> contorna o arco -> corredor O (x -36) -> corredor N (z -36) -> campo
## B-bot por fora -> contorna a rocha do patio da ponte NE -> portao B pelo eixo da MID.
func _path_a_to_b_top() -> Array[Vector3]:
	return [
		_local(33.94, 0),
		_local(29, 2.9),
		_local(21.21, 0),
		Vector3(-18, 0, 8),
		Vector3(-36, 0, 6),
		Vector3(-36, 0, -36),
		Vector3(0, 0, -36),
		Vector3(4, 0, -28),
		Vector3(10.25, 0, -21.6),
		Vector3(13.4, 0, -13.4),
		_rotate(_local(21.21, 0)),
		_rotate(_local(29, 2.9)),
		_rotate(_local(33.94, 0)),
	]


func test_spawn_ao_centro_em_6_3s() -> void:
	await wait_physics_frames(2)
	var t := _walk(_path_a_to_center(), GateRules.hero_mask(GateRules.TEAM_A))
	gut.p("spawn A -> centro: %.2f s" % t)
	assert_almost_eq(t, SPAWN_TO_CENTER_S, SPAWN_TO_CENTER_S * TOLERANCE)


func test_spawn_a_spawn_pela_mid_com_portoes_caidos() -> void:
	await wait_physics_frames(2)
	var t := _walk(_path_a_to_b_mid(), GateRules.LAYER_WORLD | GateRules.LAYER_RIVER)
	gut.p("spawn A -> spawn B pela MID: %.2f s" % t)
	assert_almost_eq(t, SPAWN_TO_SPAWN_MID_S, SPAWN_TO_SPAWN_MID_S * TOLERANCE)


func test_spawn_a_spawn_pela_top_sem_tocar_o_rio() -> void:
	await wait_physics_frames(2)
	var t := _walk(_path_a_to_b_top(), GateRules.LAYER_WORLD | GateRules.LAYER_RIVER)
	gut.p("spawn A -> spawn B pela TOP: %.2f s" % t)
	assert_almost_eq(t, SPAWN_TO_SPAWN_TOP_S, SPAWN_TO_SPAWN_TOP_S * TOLERANCE)


## 6 travessias do anel fora das pontes + 2 por braco + 1 por lagoa: nenhuma passa
## (SPEC-046 §6 item 2).
func test_rio_bloqueia_em_12_pontos() -> void:
	await wait_physics_frames(2)
	var crossings: Array[Array] = []
	for azimuth: float in [0.0, 67.5, 90.0, 180.0, 247.5, 270.0]:
		crossings.append([_polar(azimuth, 11.0), _polar(azimuth, 21.0)])
	# Braco NO: cruza o arco perto da juncao e perto da lagoa; SE por rotacao.
	var arm_a: Array[Array] = [
		[Vector3(-12, 0, -17), Vector3(-19, 0, -11)], [Vector3(-27, 0, -11), Vector3(-19, 0, -24)]
	]
	for c: Array in arm_a:
		crossings.append(c)
		crossings.append([_rotate(c[0]), _rotate(c[1])])
	# Lagoas: atravessa de norte a sul (o braco chega pelo leste).
	for flip: float in [1.0, -1.0]:
		var lagoon := LAGOON_A * flip
		crossings.append([lagoon + Vector3(0, 0, -7), lagoon + Vector3(0, 0, 7)])
	assert_eq(crossings.size(), 12)
	for c: Array in crossings:
		var a: Vector3 = c[0] + _lift()
		var b: Vector3 = c[1] + _lift()
		assert_false(_overlaps(_capsule(), a, GateRules.LAYER_RIVER), "comeca no rio: %s" % a)
		assert_false(_overlaps(_capsule(), b, GateRules.LAYER_RIVER), "termina no rio: %s" % b)
		assert_true(_hits(_capsule(), a, b, GateRules.LAYER_RIVER), "rio vazou: %s -> %s" % [a, b])


## Nos azimutes 45/225 (juncao dos bracos) nao ha ponte: o anel continua fechado.
func test_sem_ponte_nas_juncoes_dos_bracos() -> void:
	await wait_physics_frames(2)
	for azimuth: float in [45.0, 225.0]:
		var a := _polar(azimuth, 11.0) + _lift()
		var b := _polar(azimuth, 21.0) + _lift()
		assert_true(_hits(_capsule(), a, b, GateRules.LAYER_RIVER), "vazou em %s" % azimuth)


func test_duas_pontes_atravessam_o_rio() -> void:
	await wait_physics_frames(2)
	var mask := GateRules.LAYER_WORLD | GateRules.LAYER_RIVER
	for azimuth: float in BRIDGE_AZIMUTHS:
		var a := _polar(azimuth, 12.0) + _lift()
		var b := _polar(azimuth, 20.5) + _lift()
		assert_false(_hits(_capsule(), a, b, mask), "ponte bloqueada em %s" % azimuth)


## Largura util da ponte: a capsula passa a 2 u do eixo (largura efetiva ≈ 5 u).
func test_ponte_tem_5u_de_largura_util() -> void:
	await wait_physics_frames(2)
	var mask := GateRules.LAYER_WORLD | GateRules.LAYER_RIVER
	for azimuth: float in BRIDGE_AZIMUTHS:
		var axis := _polar(azimuth, 1.0)
		var side := Vector3(-axis.z, 0, axis.x)
		for offset: float in [-2.0, 2.0]:
			var a := axis * 12.0 + side * offset + _lift()
			var b := axis * 20.5 + side * offset + _lift()
			var label := "ponte %s estreita em %s" % [azimuth, offset]
			assert_false(_hits(_capsule(), a, b, mask), label)


## TOP contorna a lagoa NO: do campo A-top ao corredor N sem tocar o rio (SPEC-046 §6 item 2).
func test_top_contorna_a_lagoa_sem_tocar_o_rio() -> void:
	await wait_physics_frames(2)
	var path: Array[Vector3] = [
		Vector3(-26, 0, -4), Vector3(-36, 0, -8), Vector3(-36, 0, -36), Vector3(-20, 0, -36)
	]
	var t := _walk(path, GateRules.LAYER_WORLD | GateRules.LAYER_RIVER)
	gut.p("campo A-top -> corredor N pela TOP: %.2f s" % t)
	assert_gt(t, 0.0)


## Borda: a capsula para antes de max(|x|, |z|) passar de 40 u nos 4 lados (SPEC-046 §6 item 3).
func test_borda_quadrada_segura_nos_4_lados() -> void:
	await wait_physics_frames(2)
	var mask := GateRules.LAYER_WORLD
	var sides: Array[Array] = [
		[Vector3(-36, 0, -10), Vector3(-45, 0, -10)],
		[Vector3(36, 0, 10), Vector3(45, 0, 10)],
		[Vector3(-10, 0, -36), Vector3(-10, 0, -45)],
		[Vector3(10, 0, 36), Vector3(10, 0, 45)],
	]
	for s: Array in sides:
		var from: Vector3 = s[0] + _lift()
		var to: Vector3 = s[1] + _lift()
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = _capsule()
		query.transform = Transform3D(Basis(), from)
		query.motion = to - from
		query.collision_mask = mask
		var result := _arena.get_world_3d().direct_space_state.cast_motion(query)
		assert_lt(result[0], 1.0, "saiu pela borda em %s" % to)
		var stop := from + (to - from) * result[0]
		var reach := maxf(absf(stop.x), absf(stop.z)) + CAPSULE_RADIUS
		assert_lt(reach, ARENA_HALF + 0.01, "passou de 40 u: %s" % stop)


## Muros de fechamento: nao se sai da base por fora do arco (SPEC-046 §6 item 4).
func test_muros_de_fechamento_prendem_a_base() -> void:
	await wait_physics_frames(2)
	var mask := GateRules.hero_mask(GateRules.TEAM_A)
	var exits: Array[Array] = [
		[Vector3(-36.5, 0, 18), Vector3(-36.5, 0, 12)],
		[Vector3(-18, 0, 36.5), Vector3(-12, 0, 36.5)],
	]
	for e: Array in exits:
		var a: Vector3 = e[0] + _lift()
		var b: Vector3 = e[1] + _lift()
		assert_true(_hits(_capsule(), a, b, mask), "saiu da base por %s" % b)


func test_portao_barra_so_o_adversario_ate_cair() -> void:
	await wait_physics_frames(2)
	var outside := _local(18.5, 0) + _lift()
	var inside := _local(24, 0) + _lift()
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
	for azimuth: float in CRATER_ENTRIES:
		var blocked := _hits(
			arrow,
			_polar(azimuth, 9.0) + height,
			_polar(azimuth, 3.0) + height,
			GateRules.LAYER_WORLD
		)
		assert_false(blocked, "entrada %s bloqueada" % azimuth)


## ADR-0008/0009: o Vale Runico congelado nao e referenciado; a Ilha v1 ficou so em tag
## (nenhuma pasta legacy/ nova).
func test_nada_referencia_a_cena_legacy_e_so_ha_uma_cena_congelada() -> void:
	assert_true(FileAccess.file_exists("res://scenes/arena/legacy/vale_runico.tscn"))
	var legacy := DirAccess.get_files_at("res://scenes/arena/legacy")
	var scenes: Array[String] = []
	for file: String in legacy:
		if file.ends_with(".tscn"):
			scenes.append(file)
	assert_eq(scenes, ["vale_runico.tscn"] as Array[String])
	var offenders: Array[String] = []
	for dir: String in ["res://scripts", "res://scenes", "res://test"]:
		_scan_for_legacy(dir, offenders)
	assert_eq(offenders, [] as Array[String])


func _scan_for_legacy(dir_path: String, offenders: Array[String]) -> void:
	if dir_path.ends_with("/legacy"):
		return
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub: String in dir.get_directories():
		_scan_for_legacy(dir_path.path_join(sub), offenders)
	for file: String in dir.get_files():
		if not (file.ends_with(".gd") or file.ends_with(".tscn")):
			continue
		var path := dir_path.path_join(file)
		if path == get_script().resource_path:
			continue
		if FileAccess.get_file_as_string(path).contains("arena/legacy"):
			offenders.append(path)
