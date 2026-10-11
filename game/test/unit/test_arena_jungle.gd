extends GutTest
## F40 (PI 2026-10-11): bolsoes de selva da Ilha, gerados de tools/arena/jungle.json pelo builder.
## Prova sobre a cena gerada: um colisor por vertice e por trecho de cada bolsao nas duas metades
## (simetria por rotacao), rochas cobrindo a colisao (malha nunca menor) e trilhas da selva
## livres para a capsula do heroi. Trilha e clareira invadidas e marcador inalcancavel o proprio
## builder recusa (sai com 1).

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
const JUNGLE_JSON: String = "../tools/arena/jungle.json"
const CAPSULE_RADIUS: float = 0.4
const CAPSULE_HEIGHT: float = 1.8
const LIFT: float = 0.05
## Pegada horizontal da rocha com escala 1 (art/arena/build_island.py: raio >= 1,05 no pe).
const OUTCROP_FOOT: float = 1.05
## Altura minima do modelo da rocha com escala 1 (art/arena/build_island.py, rock_outcrop_*).
const OUTCROP_MIN_HEIGHT: float = 1.35
const SAMPLE_STEP: float = 0.5

var _arena: Node3D
var _jungle: Dictionary


func before_all() -> void:
	_arena = (load(ARENA) as PackedScene).instantiate() as Node3D
	add_child(_arena)
	var path := ProjectSettings.globalize_path("res://").path_join(JUNGLE_JSON)
	_jungle = JSON.parse_string(FileAccess.get_file_as_string(path))


func after_all() -> void:
	_arena.free()


func _jungle_shapes() -> Array[CollisionShape3D]:
	var out: Array[CollisionShape3D] = []
	for node: Node in _arena.get_node("Walls").get_children():
		if node.name.begins_with("Jungle"):
			out.append(node as CollisionShape3D)
	return out


func test_um_colisor_por_vertice_e_trecho_nas_duas_metades() -> void:
	var expected := 0
	for wall: Dictionary in _jungle["walls"]:
		var n: int = (wall["points"] as Array).size()
		expected += 2 * (n + n - 1)
	assert_eq(_jungle_shapes().size(), expected)


func test_bolsoes_simetricos_por_rotacao() -> void:
	var at: Array[Vector3] = []
	for shape: CollisionShape3D in _jungle_shapes():
		at.append(shape.position)
	for p: Vector3 in at:
		var twin := Vector3(-p.x, p.y, -p.z)
		var found := at.any(func(q: Vector3) -> bool: return q.distance_to(twin) < 0.01)
		assert_true(found, "sem par rotacionado para %s" % p)


## Ao longo de cada bolsao, a cada SAMPLE_STEP, o eixo e as duas bordas da colisao (meia largura
## para cada lado) caem dentro da pegada de alguma rocha: nada de parede invisivel.
func test_rochas_cobrem_a_colisao() -> void:
	var rocks: Array[Node3D] = []
	for node: Node in _arena.get_node("Jungle").get_children():
		if node.name.begins_with("Rock"):
			rocks.append(node as Node3D)
	assert_gt(rocks.size(), 0)
	for wall: Dictionary in _jungle["walls"]:
		var half: float = wall["half_width"]
		for flip: float in [1.0, -1.0]:
			var points: Array = wall["points"]
			for i: int in range(points.size() - 1):
				var a := Vector2(points[i][0], points[i][1]) * flip
				var b := Vector2(points[i + 1][0], points[i + 1][1]) * flip
				var side := (b - a).normalized().orthogonal() * half
				var n := maxi(1, ceili(a.distance_to(b) / SAMPLE_STEP))
				for k: int in range(n + 1):
					var p := a.lerp(b, float(k) / n)
					for q: Vector2 in [p, p + side, p - side]:
						assert_true(_covered(rocks, q), "bolsao descoberto em %s" % q)


func _covered(rocks: Array[Node3D], p: Vector2) -> bool:
	for rock: Node3D in rocks:
		var foot := rock.transform.basis.get_scale().x * OUTCROP_FOOT
		if Vector2(rock.position.x, rock.position.z).distance_to(p) <= foot:
			return true
	return false


## Toda rocha e mais alta que a colisao do bolsao: nada de parede invisivel por cima da malha.
func test_rochas_mais_altas_que_a_colisao() -> void:
	var height := 0.0
	for shape: CollisionShape3D in _jungle_shapes():
		if shape.shape is CylinderShape3D:
			height = maxf(height, (shape.shape as CylinderShape3D).height)
	assert_gt(height, 0.0)
	for node: Node in _arena.get_node("Jungle").get_children():
		if node.name.begins_with("Rock"):
			var rock := node as Node3D
			var top := rock.transform.basis.get_scale().y * OUTCROP_MIN_HEIGHT
			assert_gt(top, height, "%s mais baixa que a colisao" % rock.name)


func test_trilhas_da_selva_livres_para_o_heroi() -> void:
	await wait_physics_frames(2)
	# Trilhas com "physics": false cruzam portao/muros da base ou a cratera (prova propria em
	# test_ilha_arcana_physics).
	var trails: Array = _jungle["trails"]
	for t: int in range(trails.size()):
		if not trails[t].get("physics", true):
			continue
		var radius: float = trails[t].get("clear_radius", CAPSULE_RADIUS)
		var capsule := CapsuleShape3D.new()
		capsule.radius = radius
		capsule.height = maxf(CAPSULE_HEIGHT, radius * 2.0 + LIFT)
		var lift := Vector3.UP * (capsule.height / 2 + LIFT)
		var points: Array = trails[t]["points"]
		for flip: float in [1.0, -1.0]:
			for i: int in range(points.size() - 1):
				var a := Vector3(points[i][0], 0, points[i][1]) * flip + lift
				var b := Vector3(points[i + 1][0], 0, points[i + 1][1]) * flip + lift
				assert_false(_hits(capsule, a, b), "trilha %d bloqueada: %s -> %s" % [t, a, b])


func _hits(shape: Shape3D, from: Vector3, to: Vector3) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), from)
	query.motion = to - from
	query.collision_mask = GateRules.LAYER_WORLD | GateRules.LAYER_RIVER
	return _arena.get_world_3d().direct_space_state.cast_motion(query)[0] < 1.0
