extends GutTest
## Corredores livres da SPEC-046 §2.3 sobre a cena gerada: nenhum colisor de muro/rocha/rio nem
## moita (tall_grass) dentro das bandas TOP (O/N), BOT (S/L) e MID alem da tolerancia que o
## builder tambem aplica; o corredor O/N e andavel de ponta a ponta com a capsula. O builder
## sai com 1 na mesma violacao; este teste prova sobre o .tscn que o jogo carrega.

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
## Bandas da metade A como Rect2 (x, z, largura, altura); BOT e a rotacao de 180 graus.
const TOP_A: Array[Rect2] = [Rect2(-40, -40, 8, 55), Rect2(-40, -40, 55, 8)]
## MID: 8 u entre portao e ponte (|t| 18..20,71 ao longo da diagonal) e 4 u na ilha (|t| <= 14).
const MID_OUTER: Vector2 = Vector2(18.0, 20.71)
const MID_OUTER_HALF: float = 4.0
const MID_ISLAND: Vector2 = Vector2(-14.0, 14.0)
const MID_ISLAND_HALF: float = 2.0
## O fim do arco (x -33) e o muro de fechamento encostam na banda TOP: 1,5 u tolerados (builder
## idem); a largura util fica >= 6,5 u nesse ponto.
const TOLERANCE: float = 1.5
const CAPSULE_RADIUS: float = 0.4
const CAPSULE_HEIGHT: float = 1.8
const LIFT: float = 0.05

var _arena: Node3D


func before_all() -> void:
	_arena = (load(ARENA) as PackedScene).instantiate() as Node3D
	add_child(_arena)


func after_all() -> void:
	_arena.free()


func _shapes(body_name: String) -> Array[CollisionShape3D]:
	var result: Array[CollisionShape3D] = []
	var body := _arena.get_node_or_null(body_name)
	if body == null:
		return result
	for node: Node in body.find_children("*", "CollisionShape3D", true, false):
		result.append(node as CollisionShape3D)
	return result


## Vertices do colisor no plano (x, z) do mundo.
func _corners(shape_node: CollisionShape3D) -> PackedVector2Array:
	var points := PackedVector3Array()
	var shape := shape_node.shape
	if shape is BoxShape3D:
		var half: Vector3 = (shape as BoxShape3D).size / 2
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				points.append(Vector3(half.x * sx, 0, half.z * sz))
	elif shape is CylinderShape3D:
		var r := (shape as CylinderShape3D).radius
		for i: int in range(16):
			points.append(Vector3(cos(TAU * i / 16) * r, 0, sin(TAU * i / 16) * r))
	elif shape is ConvexPolygonShape3D:
		points = (shape as ConvexPolygonShape3D).points
	var corners := PackedVector2Array()
	for p: Vector3 in points:
		var w := shape_node.global_transform * p
		corners.append(Vector2(w.x, w.z))
	return corners


func _overlap(corners: PackedVector2Array, axis: Vector2, span: Vector2) -> float:
	var lo := INF
	var hi := -INF
	for c: Vector2 in corners:
		var t := c.dot(axis)
		lo = minf(lo, t)
		hi = maxf(hi, t)
	return minf(hi, span.y) - maxf(lo, span.x)


func _depth_in_rect(corners: PackedVector2Array, r: Rect2) -> float:
	var dx := _overlap(corners, Vector2.RIGHT, Vector2(r.position.x, r.end.x))
	var dz := _overlap(corners, Vector2.DOWN, Vector2(r.position.y, r.end.y))
	return minf(dx, dz)


func _depth_in_mid(corners: PackedVector2Array, along: Vector2, half: float) -> float:
	var t := _overlap(corners, Vector2(1, -1).normalized(), along)
	var n := _overlap(corners, Vector2(1, 1).normalized(), Vector2(-half, half))
	return minf(t, n)


func test_top_e_bot_sem_colisor_nem_moita() -> void:
	for body: String in ["Walls", "River", "Crater", "TallGrass"]:
		for shape: CollisionShape3D in _shapes(body):
			var corners := _corners(shape)
			for flip: float in [1.0, -1.0]:
				for rect: Rect2 in TOP_A:
					var band := rect if flip > 0 else Rect2(-rect.end, rect.size)
					var depth := _depth_in_rect(corners, band)
					var label := (
						"%s/%s invade %s por %.2f u" % [body, shape.get_parent().name, band, depth]
					)
					assert_true(depth <= TOLERANCE, label)


func test_mid_sem_muro_rocha_nem_moita() -> void:
	for body: String in ["Walls", "Crater", "TallGrass"]:
		for shape: CollisionShape3D in _shapes(body):
			var corners := _corners(shape)
			var bands: Array[Array] = [
				[MID_OUTER, MID_OUTER_HALF],
				[-Vector2(MID_OUTER.y, MID_OUTER.x), MID_OUTER_HALF],
				[MID_ISLAND, MID_ISLAND_HALF],
			]
			for band: Array in bands:
				var depth := _depth_in_mid(corners, band[0], band[1])
				var label := "%s/%s invade a MID %s" % [body, shape.get_parent().name, band[0]]
				assert_true(depth <= TOLERANCE, label)


## A capsula percorre o corredor O e o N pelo meio (x -36 / z -36) sem bater em nada.
func test_corredor_top_andavel_de_ponta_a_ponta() -> void:
	await wait_physics_frames(2)
	var capsule := CapsuleShape3D.new()
	capsule.radius = CAPSULE_RADIUS
	capsule.height = CAPSULE_HEIGHT
	var lift := Vector3.UP * (CAPSULE_HEIGHT / 2 + LIFT)
	var path: Array[Vector3] = [Vector3(-36, 0, 13), Vector3(-36, 0, -36), Vector3(13, 0, -36)]
	for i: int in range(path.size() - 1):
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = capsule
		query.transform = Transform3D(Basis(), path[i] + lift)
		query.motion = path[i + 1] - path[i]
		query.collision_mask = GateRules.LAYER_WORLD | GateRules.LAYER_RIVER
		var result := _arena.get_world_3d().direct_space_state.cast_motion(query)
		assert_eq(result[0], 1.0, "corredor bloqueado em %s -> %s" % [path[i], path[i + 1]])
