extends GutTest
## F40 sobre o F44: pilares, moitas e pontes da Ilha usam os assets do Blender so como visual;
## a colisao continua a do builder e a malha cobre o cilindro do pilar (nada de parede invisivel).

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"

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


func test_quatro_pontes_de_pedra_e_um_piso_unico() -> void:
	assert_eq(_instances_of("bridge_stone.glb").size(), 4)
	assert_eq(_instances_of("island_chassis.glb").size(), 1)
	assert_eq(_instances_of("hex_grass.gltf").size(), 0, "piso proprio, sem hexes (ADR-0006)")


func test_cena_nao_tem_placeholder_geometrico() -> void:
	for node: Node in _arena.find_children("*", "MeshInstance3D", true, false):
		var mesh := (node as MeshInstance3D).mesh
		assert_false(mesh is CylinderMesh or mesh is BoxMesh, "placeholder em %s" % node.name)
