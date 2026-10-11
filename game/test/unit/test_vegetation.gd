extends GutTest
## F42 (SPEC-042): grama decorativa em MultiMesh. Prova geometrica: nenhum tufo dentro do mato
## alto (com folga, para a leitura grama x mato), nas pontes ou na cratera; 1 draw call; so
## cliente e so com graphics.grass ligado.

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
const VEGETATION: String = "res://scenes/arena/vegetation.tscn"
const GRASS_SHADER: String = "res://shared/shaders/grass_wind.gdshader"
## Folga minima em volta da caixa do mato alto (u); o builder usa 2,0.
const TALL_GRASS_CLEAR: float = 1.5
## Pegada da ponte no proprio espaco: meia largura util (x) e meio comprimento sobre o rio (z).
const BRIDGE_HALF: Vector2 = Vector2(2.5, 3.0)
## Pilares da cratera: raio 6 + raio do pilar 1,4 (SPEC-046 §2.2).
const CRATER_REACH: float = 7.4
## Spawn A (canto SO) e raio do muro em arco da base = spawn -> portao (SPEC-046 §2.4).
const SPAWN_A: Vector3 = Vector3(-24.0, 0.0, 24.0)
const BASE_ARC: float = 12.7

var _arena: Node3D
var _vegetation: Vegetation
var _tufts: PackedVector3Array


## Le os tufos do dado exportado: o servidor de renderizacao headless nao guarda o buffer do
## MultiMesh, entao get_instance_transform nao serve aqui.
func before_all() -> void:
	_arena = (load(ARENA) as PackedScene).instantiate() as Node3D
	_vegetation = (load(VEGETATION) as PackedScene).instantiate() as Vegetation
	for t: Vector4 in _vegetation.tufts:
		_tufts.append(Vector3(t.x, 0.0, t.y))


func after_all() -> void:
	_arena.free()
	_vegetation.free()


func test_arena_instancia_a_vegetacao() -> void:
	var node := _arena.get_node_or_null("Vegetation")
	assert_not_null(node)
	assert_eq(node.scene_file_path, VEGETATION)


func test_um_draw_call_com_o_shader_de_vento() -> void:
	assert_gt(_tufts.size(), 1000, "grama de verdade, nao meia duzia de tufos")
	var multimesh := Vegetation.build_multimesh(_vegetation.tufts)
	assert_eq(multimesh.instance_count, _tufts.size())
	assert_eq(multimesh.mesh.get_surface_count(), 1)
	var material := _vegetation.material_override as ShaderMaterial
	assert_not_null(material)
	assert_eq(material.shader.resource_path, GRASS_SHADER)
	assert_eq(_vegetation.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)


func test_nenhum_tufo_no_mato_alto() -> void:
	var areas := _arena.find_children("*", "Area3D", true, false)
	var checked := 0
	for node: Node in areas:
		var area := node as Area3D
		if not area.is_in_group(&"tall_grass"):
			continue
		checked += 1
		var shape := area.get_child(0) as CollisionShape3D
		var half := (shape.shape as BoxShape3D).size / 2.0
		var to_local := (area.transform * shape.transform).affine_inverse()
		var hits := 0
		for tuft: Vector3 in _tufts:
			var p := to_local * tuft
			if absf(p.x) < half.x + TALL_GRASS_CLEAR and absf(p.z) < half.z + TALL_GRASS_CLEAR:
				hits += 1
		assert_eq(hits, 0, "tufos colados no mato %s" % area.name)
	assert_gt(checked, 0)


func test_nenhum_tufo_nas_pontes() -> void:
	var bridges := _arena.get_node("Bridges").get_children()
	assert_eq(bridges.size(), 2)
	for node: Node in bridges:
		var to_local := (node as Node3D).transform.affine_inverse()
		var hits := 0
		for tuft: Vector3 in _tufts:
			var p := to_local * tuft
			if absf(p.x) <= BRIDGE_HALF.x and absf(p.z) <= BRIDGE_HALF.y:
				hits += 1
		assert_eq(hits, 0, "tufos na ponte %s" % node.name)


func test_nenhum_tufo_na_cratera() -> void:
	for tuft: Vector3 in _tufts:
		if Vector2(tuft.x, tuft.z).length() <= CRATER_REACH:
			fail_test("tufo na cratera em %s" % tuft)
			return
	pass_test("cratera limpa")


func test_nenhum_tufo_dentro_das_bases() -> void:
	for spawn: Vector3 in [SPAWN_A, -SPAWN_A]:
		for tuft: Vector3 in _tufts:
			if tuft.distance_to(spawn) < BASE_ARC:
				fail_test("tufo dentro da base em %s" % tuft)
				return
	pass_test("bases limpas")


func test_tufos_dentro_da_borda_e_espalhados() -> void:
	assert_false(_tufts.is_empty())
	if _tufts.is_empty():
		return
	var spread := Rect2(Vector2(_tufts[0].x, _tufts[0].z), Vector2.ZERO)
	for tuft: Vector3 in _tufts:
		if maxf(absf(tuft.x), absf(tuft.z)) > 40.0:
			fail_test("tufo fora da borda em %s" % tuft)
			return
		spread = spread.expand(Vector2(tuft.x, tuft.z))
	assert_gt(spread.size.x, 40.0, "espalhados pela arena, nao amontoados")
	assert_gt(spread.size.y, 40.0)


func test_so_desenha_no_cliente_com_grama_ligada() -> void:
	var on := GraphicsSettings.defaults()
	assert_true(Vegetation.wanted("windows", on))
	assert_false(Vegetation.wanted("headless", on), "servidor dedicado nao desenha")
	var off := on.duplicate()
	off[GraphicsSettings.GRASS] = false
	assert_false(Vegetation.wanted("windows", off))
