extends SceneTree
## Renderiza a arte de cada criatura do Bestiario (FRONTEND-LAUNCHER §8.3 regra 3: a imagem
## gerada do prototipo da lugar a um render dos assets reais, ADR-0005) para
## shared/assets/ui/monsters/<id>.png. Usa o no Model da cena do monstro em game/scenes/monsters/
## (o mesmo visual do Game, sem IA nem rede), em idle, de corpo inteiro e levemente de lado sobre o
## fundo do card. Precisa de janela (nao headless) e do projeto do Game (as cenas dependem dos
## scripts dele):
##   godot --path game -s <repo>/tools/ui/render_monster_cards.gd
## Card comum 640 x 192 a 2x = 1280 x 384; o chefe ocupa 5/12 da largura (~2,7:1): 1500 x 560.

const OUT_DIR: String = "res://shared/assets/ui/monsters/"
const SCENE_PATH: String = "res://scenes/monsters/%s.tscn"
## id -> tamanho do render. O golem de canto divide a arte do golem (especie unica).
const MONSTERS: Dictionary[String, Vector2i] = {
	"skeleton_t1": Vector2i(1280, 384),
	"skeleton_warrior_t2": Vector2i(1280, 384),
	"skeleton_mage_t2": Vector2i(1280, 384),
	"wolf_t2": Vector2i(1280, 384),
	"golem_t3": Vector2i(1280, 384),
	"skeleton_king_boss": Vector2i(1500, 560),
}
const WARMUP_FRAMES: int = 20
const IDLE_HINT: String = "Idle"
## Instante da animacao idle usado como pose (s).
const POSE_TIME: float = 0.4
## Giro do modelo para a camera (graus): de lado, como a arte do prototipo.
const YAW_DEGREES: float = -22.0
const BACKDROP: Color = Color(0.090, 0.122, 0.200)
const AMBIENT: Color = Color(0.55, 0.62, 0.85)
const KEY_LIGHT: Color = Color(1.0, 0.86, 0.68)
const RIM_LIGHT: Color = Color(0.55, 0.72, 1.0)
const FILL_LIGHT: Color = Color(0.45, 0.55, 0.9)
const CAMERA_FOV: float = 24.0
## Folga em volta do modelo (1 = encosta nas bordas).
const FRAME_MARGIN: float = 1.14
## Fracao da altura do modelo que o mira desce (o modelo sobe no quadro).
const LIFT_FRACTION: float = 0.07


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var failed := false
	for monster_id: String in MONSTERS:
		if not await _render(monster_id, MONSTERS[monster_id]):
			failed = true
	quit(1 if failed else 0)


## So o visual do monstro: o no Model da cena, sem o resto (IA, rede, grupos).
func _model_of(monster_id: String) -> Node3D:
	var packed := load(SCENE_PATH % monster_id) as PackedScene
	if packed == null:
		push_error("[monster-art] sem cena para %s" % monster_id)
		return null
	var instance := packed.instantiate()
	var model := instance.get_node_or_null("Model") as Node3D
	if model != null:
		instance.remove_child(model)
	instance.free()
	return model


func _render(monster_id: String, size: Vector2i) -> bool:
	var model := _model_of(monster_id)
	if model == null:
		return false
	var viewport := SubViewport.new()
	viewport.size = size
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	world.add_child(_environment())
	# A cena vira o modelo de costas para a camera (frente em -Z): zera o giro e fica a escala.
	var scale_factor := absf(model.transform.basis.get_scale().y)
	model.transform = Transform3D(
		Basis(Vector3.UP, deg_to_rad(YAW_DEGREES)).scaled_local(Vector3.ONE * scale_factor),
		Vector3.ZERO
	)
	world.add_child(model)
	var player := model.find_child("AnimationPlayer") as AnimationPlayer
	if player != null:
		var idle := _idle_name(player)
		if idle != &"":
			player.play(idle)
			player.seek(POSE_TIME, true)
			player.pause()
	_lights(world)
	var camera := Camera3D.new()
	camera.fov = CAMERA_FOV
	world.add_child(camera)
	for i: int in 3:
		await process_frame
	_frame(camera, model, size)
	camera.current = true
	for i: int in WARMUP_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var path := "%s%s.png" % [OUT_DIR, monster_id]
	var err := image.save_png(path)
	print("[monster-art] %s %s (%s)" % [path, image.get_size(), error_string(err)])
	viewport.queue_free()
	return err == OK


## Primeira animacao de repouso do modelo ("Idle", "Unarmed_Idle"...), ou vazio.
func _idle_name(player: AnimationPlayer) -> StringName:
	for animation: StringName in player.get_animation_list():
		if IDLE_HINT in String(animation):
			player.get_animation(animation).loop_mode = Animation.LOOP_LINEAR
			return animation
	return &""


## Camera de frente e ligeiramente acima, distancia para o modelo caber na altura e na largura.
func _frame(camera: Camera3D, model: Node3D, size: Vector2i) -> void:
	var box := _bounds(model)
	var center := box.get_center()
	var half_fov := deg_to_rad(camera.fov) / 2.0
	var fit_height := box.size.y / 2.0 * FRAME_MARGIN / tan(half_fov)
	var aspect := float(size.x) / float(size.y)
	var fit_width := box.size.x / 2.0 * FRAME_MARGIN / (tan(half_fov) * aspect)
	var distance := maxf(fit_height, fit_width) + box.size.z / 2.0
	# O degrade do card cobre a parte de baixo da imagem: o modelo sobe um pouco no quadro.
	var target := center - Vector3(0.0, box.size.y * LIFT_FRACTION, 0.0)
	camera.look_at_from_position(target + Vector3(0.0, box.size.y * 0.04, distance), target)


func _bounds(model: Node3D) -> AABB:
	var found := false
	var box := AABB()
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var local := mesh.global_transform * mesh.get_aabb()
		box = local if not found else box.merge(local)
		found = true
	return box


func _environment() -> WorldEnvironment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BACKDROP
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = AMBIENT
	env.ambient_light_energy = 0.55
	var holder := WorldEnvironment.new()
	holder.environment = env
	return holder


func _lights(world: Node3D) -> void:
	var key := DirectionalLight3D.new()
	key.light_color = KEY_LIGHT
	key.light_energy = 1.4
	world.add_child(key)
	key.look_at_from_position(Vector3(-2.0, 3.0, 3.0), Vector3(0.0, 1.2, 0.0))
	var rim := DirectionalLight3D.new()
	rim.light_color = RIM_LIGHT
	rim.light_energy = 0.9
	world.add_child(rim)
	rim.look_at_from_position(Vector3(2.5, 2.5, -2.5), Vector3(0.0, 1.2, 0.0))
	var fill := DirectionalLight3D.new()
	fill.light_color = FILL_LIGHT
	fill.light_energy = 0.4
	world.add_child(fill)
	fill.look_at_from_position(Vector3(3.0, 0.5, 2.0), Vector3(0.0, 1.0, 0.0))
