extends GutTest
## F40 sobre o F46: pilares, moitas e pontes da Ilha usam os assets do Blender so como visual;
## a colisao continua a do builder e a malha cobre o cilindro do pilar (nada de parede invisivel).

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
## Normais a menos de ~1 grau contam como a mesma.
const SMOOTH_DOT: float = 0.9998
## Vertices a menos de 1 mm contam como a mesma posicao.
const POSITION_SNAP: float = 0.001
## Parcela minima de vertices coincidentes com a mesma normal por asset.
const SMOOTH_SHARE: float = 0.7

var _arena: Node3D


func before_all() -> void:
	_arena = (load(ARENA) as PackedScene).instantiate() as Node3D
	add_child(_arena)


func after_all() -> void:
	_arena.free()


func _visual_aabb(root: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var part: AABB = mi.global_transform * mi.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return box


func _instances_of(file: String) -> Array[Node3D]:
	var result: Array[Node3D] = []
	for node: Node in _arena.find_children("*", "Node3D", true, false):
		if node.scene_file_path.ends_with(file):
			result.append(node as Node3D)
	return result


func test_pilares_de_obsidiana_cobrem_a_colisao() -> void:
	await wait_physics_frames(1)
	var pillars := _instances_of("obsidian_pillar.glb")
	assert_eq(pillars.size(), 8)
	for node: Node in _arena.get_node("Crater").get_children():
		var shape_node := node as CollisionShape3D
		if shape_node == null:
			continue
		var cylinder := shape_node.shape as CylinderShape3D
		var center := shape_node.global_position
		var half := Vector3(cylinder.radius, cylinder.height / 2, cylinder.radius)
		var needed := AABB(center - half, half * 2)
		var covered := false
		for pillar: Node3D in pillars:
			covered = covered or _visual_aabb(pillar).grow(0.01).encloses(needed)
		assert_true(covered, "pilar sem malha cobrindo a colisao em %s" % center)


func test_moitas_usam_o_asset_do_tamanho_certo() -> void:
	var counts: Dictionary = {"tall_grass_4x4.glb": 0, "tall_grass_4x3.glb": 0}
	for node: Node in _arena.find_children("*", "Area3D", true, false):
		if not node.is_in_group(&"tall_grass"):
			continue
		var visual := node.get_node_or_null("Visual")
		assert_not_null(visual, "moita sem visual: %s" % node.name)
		var file := visual.scene_file_path.get_file()
		assert_true(counts.has(file), "asset inesperado: %s" % file)
		counts[file] = counts.get(file, 0) + 1
	assert_eq(counts, {"tall_grass_4x4.glb": 4, "tall_grass_4x3.glb": 2})


## Kit do F46 (decisao do PI 2026-10-10): torreao por time no canto e casas de pedra na base.
func test_torreao_por_time_e_casas_na_base() -> void:
	assert_eq(_instances_of("castle_keep_a.glb").size(), 1)
	assert_eq(_instances_of("castle_keep_b.glb").size(), 1)
	assert_eq(_instances_of("stone_house.glb").size(), 4)


func test_duas_pontes_de_pedra_e_um_piso_unico() -> void:
	assert_eq(_instances_of("bridge_stone.glb").size(), 2)
	assert_eq(_instances_of("island_chassis.glb").size(), 1)
	assert_eq(_instances_of("hex_grass.gltf").size(), 0, "piso proprio, sem hexes (ADR-0006)")


func test_cena_nao_tem_placeholder_geometrico() -> void:
	for node: Node in _arena.find_children("*", "MeshInstance3D", true, false):
		var mesh := (node as MeshInstance3D).mesh
		assert_false(mesh is CylinderMesh or mesh is BoxMesh, "placeholder em %s" % node.name)


## F39 (PI 2026-10-10): terreno e cenario proprio com smooth shading por angulo (60 graus) no
## Blender — sem os triangulos marcados do sombreamento chapado. Terreno e pecas organicas ficam
## lisos; o castelo (quinas de 90 graus) continua de quina viva.
func test_terreno_e_cenario_com_smooth_shading() -> void:
	for asset: String in ["island_chassis", "boulder", "islet_a"]:
		var root := (
			(load("res://shared/assets/rrb/arena/%s.glb" % asset) as PackedScene).instantiate()
		)
		var mesh := (
			(root.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh
		)
		var share := _smooth_share(mesh.surface_get_arrays(0))
		gut.p("%s: %.0f%% dos vertices coincidentes com a mesma normal" % [asset, share * 100.0])
		assert_gt(share, SMOOTH_SHARE, asset)
		root.free()


## Entre vertices na mesma posicao (a malha separa vertice por face, UV ou quina), parcela que
## tem a mesma normal: no sombreamento chapado so coincide em face coplanar.
func _smooth_share(arrays: Array) -> float:
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var first: Dictionary[Vector3, Vector3] = {}
	var same := 0
	var shared := 0
	for v: int in range(vertices.size()):
		var at := vertices[v].snappedf(POSITION_SNAP)
		if not first.has(at):
			first[at] = normals[v]
			continue
		shared += 1
		if first[at].dot(normals[v]) > SMOOTH_DOT:
			same += 1
	return float(same) / maxi(shared, 1)
