extends GutTest
## F84 (SPEC-084): --arena=<variante> (argumento de dev) e a cena variante do spike visual. A
## variante so troca visual da base A (SO): colisao, marcadores e a base B ficam como na oficial.

const OFFICIAL: String = "res://scenes/arena/ilha_arcana.tscn"
const SPIKE: String = "res://scenes/arena/spike_f84.tscn"
const SPIKE_GROUP: String = "SpikeF84"
## Orcamento do spike (SPEC-084 §3): ate ~2x o teto de cenario do ADR-0006 (800) por peca.
const PIECE_TRIANGLES: int = 1600


func test_sem_arena_e_a_oficial() -> void:
	assert_eq(LaunchArgs.parse(PackedStringArray(["--offline"]))["arena"], "")


func test_arena_spike_f84() -> void:
	var r := LaunchArgs.parse(PackedStringArray(["--offline", "--arena=spike_f84"]))
	assert_eq(r["arena"], "spike_f84")


func test_arena_desconhecida_cai_na_oficial() -> void:
	var r := LaunchArgs.parse(PackedStringArray(["--arena=../../etc/passwd"]))
	assert_eq(r["arena"], "")


func test_caminho_da_variante() -> void:
	assert_eq(LaunchArgs.arena_scene("spike_f84"), SPIKE)
	assert_eq(LaunchArgs.arena_scene(""), "")


func test_variante_tem_a_mesma_colisao_da_oficial() -> void:
	var official := _load(OFFICIAL)
	var spike := _load(SPIKE)
	assert_eq(_shapes(spike), _shapes(official))


func test_variante_tem_os_mesmos_marcadores() -> void:
	var official := _load(OFFICIAL)
	var spike := _load(SPIKE)
	assert_eq(_markers(spike), _markers(official))


func test_arte_do_spike_sem_colisao_e_no_orcamento() -> void:
	var spike := _load(SPIKE)
	var group := spike.get_node_or_null(SPIKE_GROUP)
	assert_not_null(group, "variante sem o grupo %s" % SPIKE_GROUP)
	if group == null:
		return
	assert_eq(group.find_children("*", "CollisionObject3D", true, false).size(), 0)
	var meshes := spike.find_children("*", "MeshInstance3D", true, false)
	var spike_meshes := 0
	for node: Node in meshes:
		var mi := node as MeshInstance3D
		if not _is_spike(mi):
			continue
		spike_meshes += 1
		var tris := _triangles(mi.mesh)
		assert_true(tris <= PIECE_TRIANGLES, "%s: %d triangulos" % [mi.get_path(), tris])
	assert_gt(spike_meshes, 0)


func test_base_a_antiga_escondida_e_base_b_intacta() -> void:
	var spike := _load(SPIKE)
	for group: String in ["Castle", "Village"]:
		for node: Node in spike.get_node(group).get_children():
			var n3 := node as Node3D
			var so := n3.position.x < 0.0 and n3.position.z > 0.0
			assert_eq(n3.visible, not so, "%s/%s" % [group, n3.name])
	var fountain := spike.get_node("Fountains/FountainA/Model") as Node3D
	assert_false(fountain.visible)
	assert_true((spike.get_node("Fountains/FountainB/Model") as Node3D).visible)


func _load(path: String) -> Node3D:
	var node := (load(path) as PackedScene).instantiate() as Node3D
	add_child_autofree(node)
	return node


func _is_spike(node: Node) -> bool:
	var at := node
	while at != null:
		if at.name.begins_with("Spike"):
			return true
		at = at.get_parent()
	return false


## Formas de colisao do mundo como texto (caminho, tipo e transform global), em ordem.
func _shapes(root: Node3D) -> PackedStringArray:
	var out := PackedStringArray()
	for node: Node in root.find_children("*", "CollisionShape3D", true, false):
		var shape := node as CollisionShape3D
		if _is_spike(shape):
			continue
		var kind := shape.shape.get_class()
		out.append("%s %s %s" % [root.get_path_to(shape), kind, shape.global_transform])
	return out


func _markers(root: Node3D) -> PackedStringArray:
	var out := PackedStringArray()
	for node: Node in root.get_node("Markers").get_children():
		out.append("%s %s" % [node.name, (node as Node3D).position])
	return out


func _triangles(mesh: Mesh) -> int:
	var total := 0
	for s: int in range(mesh.get_surface_count()):
		var arrays := mesh.surface_get_arrays(s)
		var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		total += (index.size() if index.size() > 0 else verts.size()) / 3
	return total
