extends SceneTree
## Renderiza a imagem da tela Arena & Mapa (F33; FRONTEND-LAUNCHER §8.3 regra 3: a arte gerada do
## prototipo da lugar a um render da arena real) e os dados dos marcadores:
##   shared/assets/ui/arena_map.png  render estatico, ortografico, de dia (decisao do PI, F33)
##   shared/assets/ui/arena_map.tres ArenaMapData: enquadramento + pontos de interesse
## A imagem e os dados saem da MESMA cena (game/scenes/arena/ilha_arcana.tscn): os pontos vem dos
## SpawnMarker, das pontes e das moitas dela; so as 2 lagoas (sem no proprio) sao as de
## tools/arena/arena_dressing.gd. Regere sempre que a arena mudar. Precisa de janela (GPU) e do
## projeto do Game (a cena depende dos scripts dele). Na raiz do repo:
##   godot --path game --resolution 1920x1080 -s <repo>/tools/ui/render_arena_map.gd

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
const OUT_IMAGE: String = "res://shared/assets/ui/arena_map.png"
const OUT_DATA: String = "res://shared/assets/ui/arena_map.tres"
const IMAGE_SIZE: Vector2i = Vector2i(2048, 1152)
## Lagoas do rio (SPEC-046 §2.1): a NO e a rotacao de 180 graus dela (arena_dressing.gd LAGOON_A).
const LAGOON_A: Vector2 = Vector2(-26, -18)
## Frames de espera: shaders compilam, o lightmap carrega e a floresta do vale e criada.
const WARMUP_FRAMES: int = 60
## Luz de dia so desta foto: sol alto e de frente-esquerda (sombras para o lado, relevo legivel).
const SUN_ROTATION_DEG: Vector3 = Vector3(-52.0, 38.0, 0.0)
const SUN_ENERGY: float = 1.25
const AMBIENT: Color = Color(0.85, 0.88, 0.92)
const AMBIENT_ENERGY: float = 0.6
const EXPOSURE: float = 0.95
const CONTRAST: float = 1.12
const SATURATION: float = 1.25
## Camera longe o bastante para ficar acima da crista mais alta do vale.
const CAMERA_FAR: float = 700.0
const ARENA_NODES_TO_DROP: Array[String] = ["Ambience"]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = IMAGE_SIZE
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var arena := (load(ARENA) as PackedScene).instantiate() as Node3D
	viewport.add_child(arena)
	for node_name: String in ARENA_NODES_TO_DROP:
		var node := arena.get_node_or_null(node_name)
		if node != null:
			node.free()
	_daylight(arena)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.size = ArenaMapView.VIEW_HEIGHT
	camera.far = CAMERA_FAR
	viewport.add_child(camera)
	camera.transform = ArenaMapView.camera_transform()
	camera.current = true
	for i: int in WARMUP_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var failed := image.save_png(OUT_IMAGE) != OK
	print("[arena-map] %s %s" % [OUT_IMAGE, image.get_size()])
	var data := _data(arena)
	failed = failed or ResourceSaver.save(data, OUT_DATA) != OK
	for poi: Dictionary in data.pois:
		var uniform := ArenaMapPois.is_uniform(poi)
		print("[arena-map] %s: %d campo(s)%s" % [poi["id"], poi["groups"].size(), "" if uniform else " DIFERENTES"])
		failed = failed or not uniform
	quit(1 if failed else 0)


func _daylight(arena: Node3D) -> void:
	var world := arena.get_node("WorldEnvironment") as WorldEnvironment
	world.set_script(null)  # o ArenaEnvironment ajusta a neblina pelas configuracoes; aqui nao
	var env := world.environment.duplicate() as Environment
	env.fog_enabled = false
	env.volumetric_fog_enabled = false
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = AMBIENT
	env.ambient_light_energy = AMBIENT_ENERGY
	env.tonemap_exposure = EXPOSURE
	env.adjustment_enabled = true
	env.adjustment_contrast = CONTRAST
	env.adjustment_saturation = SATURATION
	env.glow_enabled = false
	world.environment = env
	var sun := arena.get_node("Sun") as DirectionalLight3D
	sun.rotation_degrees = SUN_ROTATION_DEG
	sun.light_energy = SUN_ENERGY
	sun.light_color = Color.WHITE


func _data(arena: Node3D) -> ArenaMapData:
	var data := ArenaMapData.new()
	data.view_pitch_degrees = ArenaMapView.PITCH_DEGREES
	data.view_height = ArenaMapView.VIEW_HEIGHT
	data.view_aspect = ArenaMapView.ASPECT
	data.image_size = IMAGE_SIZE
	var lagoons: Array[Vector2] = [LAGOON_A, -LAGOON_A]
	data.pois = ArenaMapPois.build(
		_markers(), _ground_of(arena.get_node("Bridges")), _ground_of(arena.get_node("TallGrass")), lagoons
	)
	return data


## Marcadores da arena como Dictionaries puros (o que ArenaMapPois.build espera).
func _markers() -> Array[Dictionary]:
	var markers: Array[Dictionary] = []
	for node: Node in get_nodes_in_group(SpawnMarker.GROUP):
		var marker := node as SpawnMarker
		var at := marker.global_position
		markers.append(
			{
				"kind": int(marker.kind),
				"team": marker.team,
				"at": Vector2(at.x, at.z),
				"monster_id": String(marker.monster_id),
				"chest_kind": String(ChestRules.Kind.keys()[marker.chest_kind]).to_lower(),
			}
		)
	return markers


func _ground_of(parent: Node) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for child: Node in parent.get_children():
		var node := child as Node3D
		points.append(Vector2(node.global_position.x, node.global_position.z))
	return points
