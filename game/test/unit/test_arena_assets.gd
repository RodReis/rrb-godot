extends GutTest
## SPEC-034: pilares e mato da arena usam os assets do Blender, so como visual; a
## colisao continua a da SPEC-007 e a malha cobre o cilindro do pilar.

const ARENA: String = "res://scenes/arena/arena.tscn"

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


func test_pilares_usam_o_asset_do_blender_e_cobrem_a_colisao() -> void:
	await wait_physics_frames(1)
	var crater := _arena.get_node("Crater")
	var pillars: Array[Node3D] = []
	for child: Node in crater.get_children():
		if child.scene_file_path.ends_with("crater_pillar.glb"):
			pillars.append(child as Node3D)
	assert_eq(pillars.size(), 8)
	for node: Node in crater.get_children():
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


func test_cena_nao_tem_mais_placeholder_de_pilar_nem_de_mato() -> void:
	for node: Node in _arena.find_children("*", "MeshInstance3D", true, false):
		var mesh := (node as MeshInstance3D).mesh
		assert_false(mesh is CylinderMesh or mesh is BoxMesh, "placeholder em %s" % node.name)
