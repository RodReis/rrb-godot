extends GutTest
## Criterio de aceite do F44 (SPEC-044 §6) por colisao, sobre a cena gerada da Ilha: tempos da
## capsula a 5,8 u/s, rio intransponivel fora das 4 pontes (anel + canal N-S), portao por time,
## flecha nos pilares e nada referenciando o Vale Runico congelado. Marcadores: test_ilha_arcana.

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
const HERO_SPEED: float = 5.8
const TOLERANCE: float = 0.1
const SPAWN_TO_CENTER_S: float = 6.3
## Previsao da SPEC-044 §6 (≈ 10,5 s); o valor medido vira a referencia (DEVELOPMENT.md).
const SPAWN_TO_SPAWN_S: float = 11.1
const CAPSULE_RADIUS: float = 0.4
const CAPSULE_HEIGHT: float = 1.8
const ARROW_RADIUS: float = 0.3
const LIFT: float = 0.05
## Eixo da base A (centro -> spawn A em (-24, -24)) e lateral (esquerda de quem olha o centro).
const AXIS_A: Vector3 = Vector3(-0.70710678, 0, -0.70710678)
const LATERAL: Vector3 = Vector3(0.70710678, 0, -0.70710678)
const BRIDGE_AZIMUTHS: Array[float] = [45.0, 135.0, 225.0, 315.0]

var _arena: Node3D


func before_all() -> void:
	_arena = (load(ARENA) as PackedScene).instantiate() as Node3D
	add_child(_arena)


func after_all() -> void:
	_arena.free()


func _local(s: float, l: float) -> Vector3:
	return AXIS_A * s + LATERAL * l


func _mirror(v: Vector3) -> Vector3:
	return Vector3(-v.x, v.y, v.z)


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


## Spawn A -> contorna o muro da base -> portao A -> ponte NO (45 graus) -> entrada da cratera.
func _path_a_to_center() -> Array[Vector3]:
	return [_local(33.94, 0), _local(29, 2.9), _local(21.21, 0), Vector3.ZERO]


## Spawn A -> portao A -> ponte NO -> contorna o campo Norte pelo anel -> ponte NE -> espelho.
func _path_a_to_b() -> Array[Vector3]:
	var half: Array[Vector3] = [
		_local(33.94, 0),
		_local(29, 2.9),
		_local(21.21, 0),
		_polar(45.0, 13.0),
		Vector3(-6, 0, -11.5),
	]
	var path := half.duplicate()
	for i: int in range(half.size() - 1, -1, -1):
		path.append(_mirror(half[i]))
	return path


func test_spawn_ao_centro_em_6_3s() -> void:
	await wait_physics_frames(2)
	var t := _walk(_path_a_to_center(), GateRules.hero_mask(GateRules.TEAM_A))
	gut.p("spawn A -> centro: %.2f s" % t)
	assert_almost_eq(t, SPAWN_TO_CENTER_S, SPAWN_TO_CENTER_S * TOLERANCE)


func test_spawn_a_spawn_pela_ilha_com_portoes_caidos() -> void:
	await wait_physics_frames(2)
	var t := _walk(_path_a_to_b(), GateRules.LAYER_WORLD | GateRules.LAYER_RIVER)
	gut.p("spawn A -> spawn B pela ilha: %.2f s" % t)
	assert_almost_eq(t, SPAWN_TO_SPAWN_S, SPAWN_TO_SPAWN_S * TOLERANCE)


## 8 travessias do anel fora das pontes + 4 do canal N-S: nenhuma passa (SPEC-044 §6 item 2).
func test_rio_bloqueia_em_12_pontos() -> void:
	await wait_physics_frames(2)
	var crossings: Array[Array] = []
	# 0 e 180 graus cairiam no canal N-S (tambem rio): usa 10 e 190.
	for azimuth: float in [10.0, 22.5, 67.5, 90.0, 112.5, 157.5, 190.0, 270.0]:
		crossings.append([_polar(azimuth, 11.0), _polar(azimuth, 21.0)])
	for z: float in [-24.0, -30.0, 24.0, 30.0]:
		crossings.append([Vector3(-6, 0, z), Vector3(6, 0, z)])
	assert_eq(crossings.size(), 12)
	for c: Array in crossings:
		var a: Vector3 = c[0] + _lift()
		var b: Vector3 = c[1] + _lift()
		assert_false(_overlaps(_capsule(), a, GateRules.LAYER_RIVER), "comeca no rio: %s" % a)
		assert_false(_overlaps(_capsule(), b, GateRules.LAYER_RIVER), "termina no rio: %s" % b)
		assert_true(_hits(_capsule(), a, b, GateRules.LAYER_RIVER), "rio vazou: %s -> %s" % [a, b])


func test_quatro_pontes_atravessam_o_rio() -> void:
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
	for azimuth: float in BRIDGE_AZIMUTHS:
		var blocked := _hits(
			arrow,
			_polar(azimuth, 9.0) + height,
			_polar(azimuth, 3.0) + height,
			GateRules.LAYER_WORLD
		)
		assert_false(blocked, "entrada %s bloqueada" % azimuth)


## ADR-0008: o Vale Runico congelado nao e referenciado por producao nem por teste.
func test_nada_referencia_a_cena_legacy() -> void:
	assert_true(FileAccess.file_exists("res://scenes/arena/legacy/vale_runico.tscn"))
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
