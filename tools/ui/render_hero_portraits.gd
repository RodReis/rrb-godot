extends SceneTree
## Renderiza o retrato 1:1 de cada heroi (FRONTEND-LAUNCHER §8.3 regra 3: a imagem gerada do
## prototipo do Historico da lugar a um render dos assets reais, ADR-0005) para
## shared/assets/ui/heroes/<id>.png. Mesmo modelo e pecas escondidas do Game (game/scenes/heroes/),
## em idle, sobre o fundo BG_LOW. Precisa de janela (nao headless):
##   godot --path launcher -s <repo>/tools/ui/render_hero_portraits.gd [-- --only=<id>]
## Duas saidas por heroi: o retrato 128 x 128 (2x o maior uso, o de 64 px do destaque), do peito
## para cima, e o retrato grande 512 x 512 da Tela Herois (F71), de corpo inteiro, em
## shared/assets/ui/heroes/large/<id>.png.

const OUT_DIR: String = "res://shared/assets/ui/heroes/"
const OUT_DIR_LARGE: String = "res://shared/assets/ui/heroes/large/"
const SIZE: Vector2i = Vector2i(128, 128)
const SIZE_LARGE: Vector2i = Vector2i(512, 512)
const WARMUP_FRAMES: int = 20
const IDLE: StringName = &"Idle"
## Instante da animacao idle usado como pose (s).
const POSE_TIME: float = 0.4
## id -> [cena, pecas escondidas] (as mesmas de game/scenes/heroes/<id>.tscn) e, opcionais, a
## escala do modelo (o Barbarian_Large do Berserker e ~1,9x mais alto que o rig medio), o clipe
## de idle e o giro em graus (o escudo do Carrasco, F98, cobre o rosto de frente).
## SMALL_CAMERAS: olho, alvo e giro (graus) proprios do retrato 128 (o Carrasco tem proporcao
## realista: a camera comum, feita para a cabeca grande dos KayKit, pega o corpo todo; de frente,
## o escudo da pose de descanso fica ao lado).
const HEROES: Dictionary[String, Array] = {
	"knight":
	[
		"res://shared/assets/kaykit/adventurers/Knight.glb",
		[&"1H_Sword_Offhand", &"2H_Sword", &"Rectangle_Shield", &"Round_Shield", &"Spike_Shield"]
	],
	"ranger": ["res://shared/assets/rrb/heroes/ranger.glb", []],
	"barbarian":
	[
		"res://shared/assets/kaykit/adventurers/Barbarian.glb",
		[&"1H_Axe", &"1H_Axe_Offhand", &"Barbarian_Round_Shield", &"Mug"]
	],
	"fire_wizard":
	[
		"res://shared/assets/kaykit/adventurers/Mage.glb",
		[&"1H_Wand", &"Spellbook", &"Spellbook_open"]
	],
	"rogue": ["res://shared/assets/rrb/heroes/rogue.glb", []],
	"engineer": ["res://shared/assets/rrb/heroes/engineer.glb", []],
	"druid": ["res://shared/assets/rrb/heroes/druid.glb", []],
	"berserker": ["res://shared/assets/rrb/heroes/berserker.glb", [], 0.48, &"Idle_A"],
	"occultist": ["res://shared/assets/rrb/heroes/occultist.glb", []],
	"paladin": ["res://shared/assets/rrb/heroes/paladin.glb", []],
	"carrasco":
	["res://shared/assets/rrb/heroes/carrasco/carrasco.glb", [], 0.9, &"Portrait", 35.0],
}
const SMALL_CAMERAS: Dictionary[String, Array] = {
	"carrasco": [Vector3(0.0, 1.4, 1.35), Vector3(0.0, 1.3, 0.0), 0.0],
}
const BACKDROP: Color = Color(0.075, 0.106, 0.180)
const AMBIENT: Color = Color(0.55, 0.62, 0.85)
const KEY_LIGHT: Color = Color(1.0, 0.86, 0.68)
const RIM_LIGHT: Color = Color(0.55, 0.72, 1.0)
const CAMERA_EYE: Vector3 = Vector3(0.0, 1.62, 3.1)
const CAMERA_TARGET: Vector3 = Vector3(0.0, 1.38, 0.0)
const CAMERA_EYE_LARGE: Vector3 = Vector3(0.0, 1.45, 6.6)
const CAMERA_TARGET_LARGE: Vector3 = Vector3(0.0, 1.12, 0.0)
const CAMERA_FOV: float = 26.0
## Retrato grande: a figura (modelo + arma) ocupa a mesma fracao do quadro em todos os herois, para
## nenhum parecer maior que os outros na Tela Herois.
const FIT_HEIGHT: float = 0.78
const FIT_WIDTH: float = 0.86
const FIT_FRAMES: int = 4
## Diferenca por canal (0..1) abaixo da qual o pixel conta como fundo.
const INK_TOLERANCE: float = 0.02


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR_LARGE))
	var failed := false
	var only := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only = arg.get_slice("=", 1)
	for hero_id: String in HEROES:
		if not only.is_empty() and hero_id != only:
			continue
		var small: Array = SMALL_CAMERAS.get(hero_id, [CAMERA_EYE, CAMERA_TARGET])
		var turn: float = small[2] if small.size() > 2 else -1.0
		if not await _render(hero_id, OUT_DIR, SIZE, small[0], small[1], false, turn):
			failed = true
		if not await _render(
			hero_id, OUT_DIR_LARGE, SIZE_LARGE, CAMERA_EYE_LARGE, CAMERA_TARGET_LARGE, true
		):
			failed = true
	quit(1 if failed else 0)


func _render(
	hero_id: String,
	out_dir: String,
	size: Vector2i,
	eye: Vector3,
	target: Vector3,
	fit: bool = false,
	turn: float = -1.0
) -> bool:
	var spec: Array = HEROES[hero_id]
	var viewport := SubViewport.new()
	viewport.size = size
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	world.add_child(_environment())
	var model := (load(spec[0]) as PackedScene).instantiate() as Node3D
	world.add_child(model)
	if spec.size() > 2:
		model.scale = Vector3.ONE * (spec[2] as float)
	if turn >= 0.0:
		model.rotation_degrees.y = turn
	elif spec.size() > 4:
		model.rotation_degrees.y = spec[4] as float
	for part: StringName in spec[1]:
		var node := model.find_child(part) as Node3D
		if node != null:
			node.hide()
	var player := model.find_child("AnimationPlayer") as AnimationPlayer
	var idle: StringName = spec[3] if spec.size() > 3 else IDLE
	if player != null and player.has_animation(idle):
		player.play(idle)
		player.seek(POSE_TIME, true)
		player.pause()
	_lights(world)
	var camera := Camera3D.new()
	camera.fov = CAMERA_FOV
	world.add_child(camera)
	camera.look_at_from_position(eye, target)
	camera.current = true
	for i: int in WARMUP_FRAMES:
		await process_frame
	if fit:
		await RenderingServer.frame_post_draw
		_fit_camera(viewport, camera, target)
		for i: int in FIT_FRAMES:
			await process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var path := "%s%s.png" % [out_dir, hero_id]
	var err := image.save_png(path)
	print("[portrait] %s %s (%s)" % [path, image.get_size(), error_string(err)])
	viewport.queue_free()
	return err == OK


## Enquadra o corpo todo com a mesma folga em todos: mede a tinta (pixels diferentes do fundo) de
## um render de prova e ajusta distancia e centro da camera. A caixa dos meshes nao serve: a de um
## mesh com pele (skin) e maior que o corpo visivel.
func _fit_camera(viewport: SubViewport, camera: Camera3D, target: Vector3) -> void:
	var ink := _ink_bounds(viewport.get_texture().get_image())
	var size := float(viewport.size.y)
	var scale_needed := maxf(
		float(ink.size.y) / (FIT_HEIGHT * size), float(ink.size.x) / (FIT_WIDTH * size)
	)
	var offset_px := Vector2(ink.get_center()) - Vector2(viewport.size) / 2.0
	var distance := camera.global_position.distance_to(target)
	var world_per_px := 2.0 * distance * tan(deg_to_rad(CAMERA_FOV) / 2.0) / size
	var shift := (
		camera.global_transform.basis.x * offset_px.x * world_per_px
		- camera.global_transform.basis.y * offset_px.y * world_per_px
	)
	var new_target := target + shift
	var eye := new_target + camera.global_transform.basis.z * distance * scale_needed
	camera.look_at_from_position(eye, new_target)


## Caixa dos pixels que nao sao o fundo.
func _ink_bounds(image: Image) -> Rect2i:
	var found := Rect2i()
	var first := true
	for y: int in image.get_height():
		for x: int in image.get_width():
			if _is_background(image.get_pixel(x, y)):
				continue
			var spot := Rect2i(x, y, 1, 1)
			found = spot if first else found.expand(Vector2i(x, y))
			first = false
	return found


func _is_background(pixel: Color) -> bool:
	return (
		absf(pixel.r - BACKDROP.r) < INK_TOLERANCE
		and absf(pixel.g - BACKDROP.g) < INK_TOLERANCE
		and absf(pixel.b - BACKDROP.b) < INK_TOLERANCE
	)


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
