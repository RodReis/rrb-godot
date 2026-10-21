extends GutTest
## F56 (SPEC-056, ADR-0012): a arena fica num vale — faixa externa so visual no lugar do abismo.
## Prova o que da para provar sem janela: o terreno e o riacho entram na arena sem colisao, as
## arvores vem como dado fora da ilha e sao repartidas em tiles, a neblina de distancia existe e
## as ilhotas do abismo sairam. A prova de "nenhum pixel de vazio" e a varredura de camera
## (tools/arena/valley_sweep.gd), que precisa de janela.

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
const FOREST: String = "res://scenes/arena/valley_forest.tscn"
const TILE: float = 40.0
## Quadrado da ilha (|x|, |z| <= 42) mais o labio: nenhuma arvore do vale cai dentro.
const ISLAND_HALF: float = 42.6

var _arena: Node3D
var _forest: ValleyForest


func before_all() -> void:
	_arena = (load(ARENA) as PackedScene).instantiate() as Node3D
	_forest = (load(FOREST) as PackedScene).instantiate() as ValleyForest


func after_all() -> void:
	_arena.free()
	_forest.free()


func test_arena_tem_terreno_riacho_e_floresta_do_vale() -> void:
	for node_name: String in ["Terrain", "Stream", "Forest"]:
		assert_not_null(_arena.get_node_or_null("Valley/%s" % node_name), node_name)


## F96: pedras e juncos na margem do riacho do vale, como no rio da arena (F95).
func test_riacho_do_vale_tem_margem_do_kit() -> void:
	var bank := _arena.get_node_or_null("Valley/StreamBank")
	assert_not_null(bank)
	if bank == null:
		return
	assert_gt(bank.get_child_count(), 30)
	for node: Node in bank.get_children():
		assert_string_starts_with(node.scene_file_path, "res://shared/assets/rrb/arena/kit/kit_")


func test_vale_nao_tem_colisao() -> void:
	var valley := _arena.get_node("Valley")
	assert_eq(valley.find_children("*", "CollisionObject3D", true, false).size(), 0)
	assert_eq(valley.find_children("*", "CollisionShape3D", true, false).size(), 0)


func test_terreno_do_vale_usa_o_material_do_vale() -> void:
	var terrain := _arena.get_node("Valley/Terrain")
	var meshes := terrain.find_children("*", "MeshInstance3D", true, false)
	assert_eq(meshes.size(), 1)
	var material := (meshes[0] as MeshInstance3D).get_active_material(0)
	assert_eq(material.resource_path, "res://shared/resources/materials/valley_ground.tres")


func test_terreno_do_vale_fica_fora_do_bake() -> void:
	var terrain := _arena.get_node("Valley/Terrain")
	for node: Node in terrain.find_children("*", "MeshInstance3D", true, false):
		assert_eq((node as MeshInstance3D).gi_mode, GeometryInstance3D.GI_MODE_DISABLED)


func test_floresta_tem_arvores_fora_da_ilha() -> void:
	assert_gt(_forest.trees.size(), 1500, "floresta densa")
	for tree: Vector4 in _forest.trees:
		var inside := absf(tree.x) < ISLAND_HALF and absf(tree.z) < ISLAND_HALF
		assert_false(inside, "arvore dentro da ilha em (%s, %s)" % [tree.x, tree.z])
		assert_gt(tree.w, 0.0, "escala")


func test_group_by_tile_poe_cada_arvore_em_um_so_tile() -> void:
	var trees := PackedVector4Array(
		[
			Vector4(1, 0, 1, 1),
			Vector4(39.9, 2, 5, 1),
			Vector4(40.0, 1, 5, 1),
			Vector4(-0.1, 0, -0.1, 1),
			Vector4(-80, 9, 79.9, 1),
		]
	)
	var groups := ValleyForest.group_by_tile(trees, TILE)
	assert_eq((groups[Vector2i(0, 0)] as PackedVector4Array).size(), 2)
	assert_eq((groups[Vector2i(1, 0)] as PackedVector4Array).size(), 1)
	assert_eq((groups[Vector2i(-1, -1)] as PackedVector4Array).size(), 1)
	assert_eq((groups[Vector2i(-2, 1)] as PackedVector4Array).size(), 1)
	var total := 0
	for key: Vector2i in groups.keys():
		total += (groups[key] as PackedVector4Array).size()
	assert_eq(total, trees.size())


func test_group_by_tile_da_floresta_nao_perde_arvore() -> void:
	var groups := ValleyForest.group_by_tile(_forest.trees, TILE)
	var total := 0
	for key: Vector2i in groups.keys():
		total += (groups[key] as PackedVector4Array).size()
	assert_eq(total, _forest.trees.size())
	assert_gt(groups.size(), 8, "varios tiles: o corte por frustum so ajuda com mais de um")


## O _ready sai cedo no headless; _pine() e _tile() funcionam sem entrar na arvore.
func test_pinheiro_do_vale_e_o_do_kit_com_o_material_do_vale() -> void:
	assert_eq(ValleyForest.PINE_SCENE, "res://shared/assets/rrb/arena/kit/kit_pine_far.glb")
	assert_false(FileAccess.file_exists("res://shared/assets/rrb/arena/pine_valley.glb"))


func test_pinheiro_carrega_com_o_material_do_vale() -> void:
	var pine := _forest._pine()
	assert_not_null(pine)
	var material := pine.get_active_material(0)
	assert_not_null(material, "use_external do .import perdido: copa branca")
	assert_eq(material.resource_path, "res://shared/resources/materials/kit/kit_pine_far.tres")
	pine.free()


func test_tile_monta_o_multimesh_com_o_material() -> void:
	var pine := _forest._pine()
	var data := PackedVector4Array([Vector4(50, 1, 60, 1.5), Vector4(52, 2, 61, 1.0)])
	var tile := _forest._tile(Vector2i(1, 1), data, pine)
	assert_eq(tile.multimesh.instance_count, 2)
	assert_not_null(tile.material_override)
	assert_eq(tile.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	assert_eq(tile.gi_mode, GeometryInstance3D.GI_MODE_DISABLED)
	tile.free()
	pine.free()


func test_giro_da_arvore_e_deterministico_e_em_volta_completa() -> void:
	assert_eq(ValleyForest.yaw_at(12.5, -7.25), ValleyForest.yaw_at(12.5, -7.25))
	for p: Vector2 in [Vector2(0, 0), Vector2(-60.5, 33.1), Vector2(90, -90)]:
		assert_between(ValleyForest.yaw_at(p.x, p.y), 0.0, TAU)


func test_neblina_de_distancia_esconde_o_fim_do_vale() -> void:
	var world := _arena.get_node("WorldEnvironment") as WorldEnvironment
	var env := world.environment
	assert_true(env.fog_enabled)
	assert_eq(env.fog_mode, Environment.FOG_MODE_DEPTH)
	assert_gt(env.fog_depth_end, env.fog_depth_begin)
	assert_eq(env.fog_density, 1.0, "no modo depth e a forca maxima")
	assert_lt(env.fog_depth_end, 160.0, "tudo some antes do fim do relevo (~110 u do centro)")


func test_ilhotas_do_abismo_sairam() -> void:
	assert_null(_arena.get_node_or_null("Islets"))
	assert_false(FileAccess.file_exists("res://shared/assets/rrb/arena/islet_a.glb"))
