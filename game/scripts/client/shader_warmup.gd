class_name ShaderWarmup
extends Node
## Pre-aquecimento de shaders antes do connect (F38; bloco visual regra 3; APRENDIZADOS #4).
## O ubershader do 4.4+ cobre a compilacao de pipeline, mas o shader em si (GLSL -> SPIR-V/DXIL)
## e as cenas carregadas so durante a partida (herois, monstros, baus spawnados depois do
## connect) ainda compilam no 1o uso: o cliente trava no sync inicial e o rollback pode ficar
## preso (`past the history limit`). Doc: tutorials/performance/pipeline_compilations (4.7),
## "hidden instancing" + "feature warm-up".
## Como: copia so a parte visual (GeometryInstance3D, sem script; particula emitindo) dessas cenas
## e dos shaders criados em codigo para um SubViewport oculto, com o Environment da arena e um sol
## com sombra, e renderiza FRAMES quadros. Depois libera tudo. No headless nao faz nada.

signal finished(copies: int)

## Pastas com cenas que nascem depois do connect (Hero.SCENE_PATH, SpawnDirector.SCENE_PATH, VFX
## de combate do F41).
const SCENE_DIRS: Array[String] = [
	"res://scenes/heroes/", "res://scenes/monsters/", "res://scenes/vfx/"
]
const SCENES: Array[String] = ["res://scenes/world/chest.tscn"]
## Shaders spatial cujo material e criado em codigo (WorldHealthBar, FogOfWar, parede da zona da
## fase 2) ou que so desenham depois de montados (VFX do F41: fita, fantasma, particula). Todo
## spatial de res://scenes/ tem de estar aqui (test_shader_warmup).
const SHADERS: Array[String] = [
	"res://scenes/ui/world_health_bar.gdshader",
	"res://scenes/world/fog_of_war.gdshader",
	"res://scenes/world/zone_wall.gdshader",
	"res://scenes/vfx/area_indicator.gdshader",
	"res://scenes/vfx/ghost.gdshader",
	"res://scenes/vfx/shield_wall.gdshader",
	"res://scenes/vfx/shockwave.gdshader",
]
## Quadros desenhados com tudo na tela (compilacao acontece no 1o; folga para o resto).
const FRAMES: int = 4
## Teto em tempo real: janela minimizada nao desenha e o warm-up e otimizacao, nunca bloqueio.
const TIMEOUT_MS: int = 5000
const VIEWPORT_SIZE: Vector2i = Vector2i(256, 256)
## Grade das copias na frente da camera, todas dentro do frustum.
const GRID_COLUMNS: int = 6
const GRID_STEP: float = 2.5
const CAMERA_DISTANCE: float = 14.0


## Caminhos de todas as cenas aquecidas.
static func scene_paths() -> PackedStringArray:
	var paths := PackedStringArray()
	for dir: String in SCENE_DIRS:
		for file: String in ResourceLoader.list_directory(dir):
			if file.get_extension() == "tscn":
				paths.append(dir + file)
	paths.append_array(SCENES)
	return paths


## Renderiza as copias por FRAMES quadros e emite finished com quantas foram aquecidas.
## environment: o da arena (mesmos recursos de pos = mesmas variantes de shader).
func run(environment: Environment) -> int:
	if DisplayServer.get_name() == "headless":
		finished.emit(0)
		return 0
	var started := Time.get_ticks_msec()
	var viewport := _make_viewport(environment)
	add_child(viewport)
	var copies := _fill(viewport)
	var drawn_at_start := Engine.get_frames_drawn()
	while Engine.get_frames_drawn() - drawn_at_start < FRAMES:
		if Time.get_ticks_msec() - started > TIMEOUT_MS:
			push_warning("[warmup] sem desenhar %d quadros em %d ms; segue" % [FRAMES, TIMEOUT_MS])
			break
		await get_tree().process_frame
	viewport.queue_free()
	print("[warmup] %d instancias aquecidas em %d ms" % [copies, Time.get_ticks_msec() - started])
	finished.emit(copies)
	return copies


func _make_viewport(environment: Environment) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.name = "WarmupViewport"
	viewport.own_world_3d = true
	viewport.size = VIEWPORT_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = get_viewport().msaa_3d
	var camera := Camera3D.new()
	camera.position = Vector3(0, CAMERA_DISTANCE * 0.5, CAMERA_DISTANCE)
	viewport.add_child(camera)
	camera.look_at_from_position(camera.position, Vector3.ZERO, Vector3.UP)
	camera.current = true
	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-48, 38, 0)
	viewport.add_child(sun)
	if environment != null:
		var world := WorldEnvironment.new()
		world.environment = environment
		viewport.add_child(world)
	return viewport


func _fill(viewport: SubViewport) -> int:
	var copies: Array[GeometryInstance3D] = []
	for path: String in scene_paths():
		var instance := (load(path) as PackedScene).instantiate()
		_collect_visuals(instance, instance, Transform3D.IDENTITY, copies)
		instance.free()
	for path: String in SHADERS:
		var material := ShaderMaterial.new()
		material.shader = load(path)
		var quad := MeshInstance3D.new()
		quad.mesh = QuadMesh.new()
		quad.material_override = material
		copies.append(quad)
	for i: int in range(copies.size()):
		var copy := copies[i]
		var row := floorf(float(i) / GRID_COLUMNS)
		var cell := Vector3(i % GRID_COLUMNS - GRID_COLUMNS * 0.5, 0, -row)
		copy.transform.origin += cell * GRID_STEP
		if copy is GPUParticles3D:
			(copy as GPUParticles3D).emitting = true  # compila o shader de processo da particula
		viewport.add_child(copy)
	return copies.size()


## Copia sem script (nem filhos) de cada GeometryInstance3D, com a transformacao relativa a raiz
## da cena. A instancia original nunca entra na arvore: _ready dos scripts nao roda.
static func _collect_visuals(
	node: Node, root: Node, parent_xform: Transform3D, out: Array[GeometryInstance3D]
) -> void:
	var xform := parent_xform
	if node is Node3D and node != root:
		xform = parent_xform * (node as Node3D).transform
	if node is GeometryInstance3D:
		var copy := node.duplicate(0) as GeometryInstance3D
		for child: Node in copy.get_children():
			copy.remove_child(child)
			child.free()
		copy.transform = xform
		out.append(copy)
	for child: Node in node.get_children():
		_collect_visuals(child, root, xform, out)
