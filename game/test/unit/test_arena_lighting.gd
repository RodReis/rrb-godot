extends GutTest
## F38 (SPEC-038): a arena e dona da ambientacao (sol, WorldEnvironment, LightmapGI bakeado e
## ReflectionProbe); main.tscn nao tem mais luz propria. Valores iniciais do guia; sombra e AO
## suavizados no F39 (PI 2026-10-10, sem toon); luz realista e sombria no F40 (PI 2026-10-11):
## exposicao e ambiente mais baixos e frios, sol frio mais inclinado, neblina mais densa.

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
const MAIN: String = "res://scenes/main.tscn"
## Cenario fixo importado com "Static Lightmaps" (UV2 gerado no import).
const STATIC_ASSET: String = "res://shared/assets/rrb/arena/island_chassis.glb"

var _arena: Node3D


func before_all() -> void:
	_arena = (load(ARENA) as PackedScene).instantiate() as Node3D


func after_all() -> void:
	_arena.free()


func test_sol_da_arena() -> void:
	var sun := _arena.get_node("Sun") as DirectionalLight3D
	assert_not_null(sun)
	assert_true(sun.shadow_enabled)
	assert_almost_eq(sun.light_energy, 1.05, 0.001)
	assert_eq(sun.light_color, Color(0.8, 0.85, 0.95))
	assert_almost_eq(sun.rotation_degrees, Vector3(-38, 38, 0), Vector3.ONE * 0.01)
	assert_almost_eq(sun.shadow_blur, 3.0, 0.001)
	assert_eq(sun.directional_shadow_mode, DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS)
	assert_almost_eq(sun.directional_shadow_max_distance, 65.0, 0.001)


func test_environment_da_arena() -> void:
	var world := _arena.get_node("WorldEnvironment") as WorldEnvironment
	assert_true(world is ArenaEnvironment, "script que aplica o settings.cfg")
	var env := world.environment
	assert_eq(env.tonemap_mode, Environment.TONE_MAPPER_ACES)
	assert_between(env.tonemap_exposure, 0.85, 1.0)
	assert_true(env.ssao_enabled)
	assert_almost_eq(env.ssao_radius, 1.5, 0.001)
	assert_almost_eq(env.ssao_intensity, 1.4, 0.001)
	assert_almost_eq(env.ambient_light_energy, 0.72, 0.001)
	assert_true(env.ssil_enabled)
	assert_true(env.glow_enabled)
	assert_almost_eq(env.glow_hdr_threshold, 1.05, 0.001)
	assert_eq(env.glow_blend_mode, Environment.GLOW_BLEND_MODE_SOFTLIGHT)
	assert_true(env.volumetric_fog_enabled)
	assert_almost_eq(env.volumetric_fog_density, 0.016, 0.0001)


func test_lightmap_bakeado_e_reflection_probe() -> void:
	var lightmap := _arena.get_node("LightmapGI") as LightmapGI
	assert_not_null(lightmap)
	assert_not_null(lightmap.light_data, "rode tools/bake-lightmap.ps1")
	var probes := _arena.find_children("*", "ReflectionProbe", true, false)
	assert_eq(probes.size(), 1)


## Bake velho (builder mudou nomes/malhas sem rebake): usuario que nao resolve, ou malha estatica
## nova fora do bake. Rode tools/bake-lightmap.ps1.
func test_lightmap_casa_com_a_cena() -> void:
	var lightmap := _arena.get_node("LightmapGI") as LightmapGI
	var data := lightmap.light_data
	if data == null:
		fail_test("sem LightmapGIData")
		return
	for i: int in range(data.get_user_count()):
		var node := lightmap.get_node_or_null(data.get_user_path(i)) as MeshInstance3D
		assert_not_null(node, "usuario %d: %s" % [i, data.get_user_path(i)])
	var statics := 0
	for node: Node in _arena.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.gi_mode == GeometryInstance3D.GI_MODE_STATIC and mi.mesh != null:
			statics += 1
	assert_eq(data.get_user_count(), statics, "malhas estaticas x usuarios do bake")


func test_main_nao_tem_luz_propria() -> void:
	var main := (load(MAIN) as PackedScene).instantiate()
	for child: Node in main.get_children():
		assert_false(child is DirectionalLight3D, "o sol vem da arena: %s" % child.name)
	main.free()


func test_cenario_fixo_tem_uv2() -> void:
	var scene := (load(STATIC_ASSET) as PackedScene).instantiate()
	var meshes := scene.find_children("*", "MeshInstance3D", true, false)
	assert_gt(meshes.size(), 0)
	for node: Node in meshes:
		var mesh := (node as MeshInstance3D).mesh as ArrayMesh
		var format := mesh.surface_get_format(0)
		assert_true(format & Mesh.ARRAY_FORMAT_TEX_UV2 != 0, "%s sem UV2" % node.name)
	scene.free()
