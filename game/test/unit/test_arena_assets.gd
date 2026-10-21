extends GutTest
## F40 sobre o F46: moitas e pontes da Ilha usam os assets do Blender so como visual; a colisao
## continua a do builder e a malha cobre a colisao (nada de parede invisivel). Pilares: F60.

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
## Normais a menos de ~1 grau contam como a mesma.
const SMOOTH_DOT: float = 0.9998
## Vertices a menos de 1 mm contam como a mesma posicao.
const POSITION_SNAP: float = 0.001
## Parcela minima de vertices coincidentes com a mesma normal por asset.
const SMOOTH_SHARE: float = 0.7
## Maior fator de comprimento aceito num modulo de muralha (#130).
const MAX_WALL_STRETCH: float = 1.5

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


## F60 (ADR-0014): centro livre, sem pilares nem corpo de colisao da cratera; o magma fica.
func test_centro_sem_pilares_e_com_magma() -> void:
	assert_eq(_instances_of("obsidian_pillar.glb").size(), 0)
	assert_null(_arena.get_node_or_null("Crater"))
	assert_eq(_instances_of("lava_lake.glb").size(), 1)


func test_moitas_usam_o_asset_do_tamanho_certo() -> void:
	var counts: Dictionary = {"kit_grass_4x4.glb": 0, "kit_grass_4x3.glb": 0}
	for node: Node in _arena.find_children("*", "Area3D", true, false):
		if not node.is_in_group(&"tall_grass"):
			continue
		var visual := node.get_node_or_null("Visual")
		assert_not_null(visual, "moita sem visual: %s" % node.name)
		var file := visual.scene_file_path.get_file()
		assert_true(counts.has(file), "asset inesperado: %s" % file)
		counts[file] = counts.get(file, 0) + 1
	assert_eq(counts, {"kit_grass_4x4.glb": 8, "kit_grass_4x3.glb": 2})


## Kit do F46 (decisao do PI 2026-10-10) no estilo do ADR-0030 (F94): torreao por time no canto,
## casas de pedra na base, praca e portal nas duas bases.
func test_torreao_por_time_e_casas_na_base() -> void:
	assert_eq(_instances_of("kit/kit_keep.glb").size(), 2)
	assert_eq(_instances_of("kit/kit_house_stone.glb").size(), 4)
	assert_eq(_instances_of("kit/kit_plaza.glb").size(), 2)
	assert_eq(_instances_of("kit/kit_gate.glb").size(), 2)


## F94: o tecido do time (estandarte, escudo, flamula) e ciano na base A e dourado na B.
func test_tecido_do_time_por_base() -> void:
	for keep: Node3D in _instances_of("kit/kit_keep.glb"):
		var files: Array[String] = []
		for node: Node in keep.find_children("*", "MeshInstance3D", true, false):
			var mi := node as MeshInstance3D
			for i: int in range(mi.get_surface_override_material_count()):
				files.append(mi.get_active_material(i).resource_path.get_file())
		var expected := "kit_cloth.tres" if keep.global_position.x < 0.0 else "kit_cloth_b.tres"
		assert_has(files, expected, "%s" % keep.name)


## #130: o modulo de muralha (2 u) so muda de comprimento no proprio eixo X: sem cisalhamento
## nem espessura/altura alteradas (escala global num muro diagonal ou ao longo de Z deformava a
## peca), e repetido em vez de esticado (uma peca por vao de 28,5 u virava rampa lisa).
func test_muralha_em_modulos_sem_deformar() -> void:
	var modules := _instances_of("kit/kit_wall.glb")
	modules.append_array(_instances_of("kit/kit_wall_low.glb"))
	assert_gt(modules.size(), 0)
	for node: Node3D in modules:
		var basis := node.global_basis
		var label := "%s em %s" % [node.name, node.global_position]
		assert_almost_eq(basis.x.dot(basis.z), 0.0, 0.001, "cisalhado: " + label)
		assert_almost_eq(basis.y, Vector3.UP, Vector3.ONE * 0.001, "altura/inclinacao: " + label)
		assert_almost_eq(basis.z.length(), 1.0, 0.001, "espessura: " + label)
		assert_lt(basis.x.length(), MAX_WALL_STRETCH, "esticado: " + label)


## F50 (PI 2026-10-11) no kit do F94: patio de cada base com 2 sobrados, 2 casinhas e 1 galpao,
## e a caixa de colisao do MegaKit coberta pela malha nova.
func test_patio_cobrindo_a_colisao() -> void:
	await wait_physics_frames(1)
	var expected := {
		"kit/kit_house_long.glb": 4, "kit/kit_house_small.glb": 4, "kit/kit_yard.glb": 2
	}
	var boxes: Array[AABB] = []
	for child: Node in _arena.get_node("Walls").get_children():
		var shape_node := child as CollisionShape3D
		if shape_node != null and shape_node.shape is BoxShape3D:
			var size := (shape_node.shape as BoxShape3D).size
			boxes.append(shape_node.global_transform * AABB(-size / 2, size))
	for file: String in expected:
		var instances := _instances_of(file)
		assert_eq(instances.size(), expected[file], file)
		for node: Node3D in instances:
			var visual := _visual_aabb(node).grow(0.05)
			var covered := false
			for box: AABB in boxes:
				covered = covered or (visual.has_point(box.get_center()) and visual.encloses(box))
			assert_true(covered, "%s sem caixa de colisao coberta pela malha" % node.name)


func test_duas_pontes_de_pedra_e_um_piso_unico() -> void:
	assert_eq(_instances_of("kit/kit_bridge.glb").size(), 2)
	assert_eq(_instances_of("island_chassis.glb").size(), 1)
	assert_eq(_instances_of("hex_grass.gltf").size(), 0, "piso proprio, sem hexes (ADR-0006)")


## F40 (PI 2026-10-11, realista e sombrio): chao com o shader de terreno (texturas CC0 misturadas
## pela mascara 512 x 512 gerada pelo builder); castelo, rochas e pinheiros com PBR triplanar.
func test_terreno_e_cenario_com_material_realista() -> void:
	var expected := {
		"island_chassis.glb": "terrain.tres",
		"kit/kit_wall.glb": "kit_stone.tres",
		"kit/kit_outcrop_a.glb": "kit_cliff.tres",
		"kit/kit_pine.glb": "kit_pine.tres",
	}
	for file: String in expected:
		var instances := _instances_of(file)
		assert_gt(instances.size(), 0, file)
		var mi := (
			instances[0].find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
		)
		var paths: Array[String] = []
		for i: int in range(mi.get_surface_override_material_count()):
			paths.append(mi.get_active_material(i).resource_path.get_file())
		assert_has(paths, expected[file], file)
	var terrain := load("res://shared/resources/materials/terrain.tres") as ShaderMaterial
	var splat := terrain.get_shader_parameter("splat_map") as Texture2D
	assert_not_null(splat, "rode o builder (mascara do terreno)")
	assert_eq(splat.get_size(), Vector2(512, 512))


func test_cena_nao_tem_placeholder_geometrico() -> void:
	for node: Node in _arena.find_children("*", "MeshInstance3D", true, false):
		var mesh := (node as MeshInstance3D).mesh
		assert_false(mesh is CylinderMesh or mesh is BoxMesh, "placeholder em %s" % node.name)


## F39 (PI 2026-10-10): terreno e cenario proprio com smooth shading por angulo (60 graus) no
## Blender — sem os triangulos marcados do sombreamento chapado. Terreno e pecas organicas ficam
## lisos; o castelo (quinas de 90 graus) continua de quina viva.
func test_terreno_e_cenario_com_smooth_shading() -> void:
	for asset: String in ["island_chassis", "kit/kit_boulder"]:
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
