extends SceneTree
## Renderiza as artes da tela de loading e do splash (F68, SPEC-068; FRONTEND-LAUNCHER §8.3
## regra 3: renders dos assets reais, nao arte gerada) a partir da arena real do Game:
##   shared/assets/ui/loading/arena_day.png    arena de dia (curva do DayNightProfile, noite = 0)
##   shared/assets/ui/loading/arena_night.png  arena de noite (noite = 1)
##   shared/assets/ui/loading/heroes.png       os herois em pose, no entardecer
##   shared/assets/ui/loading/splash.png       marca "Loot Start" sobre o entardecer (Launcher)
##   shared/assets/ui/login_duel.png           os herois em faixa larga para a arte do Login (F82)
## Mesma luz/ceu do ciclo dia/noite do jogo (DayNightProfile). Heroi novo: acrescente em HEROES e
## rode de novo. Precisa de janela (GPU) e do projeto do Game; na raiz do repo:
##   godot --path game --resolution 1920x1080 -s <repo>/tools/ui/render_loading.gd
##     [-- --only=<arquivo>]

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
const PROFILE: String = "res://shared/data/visual/day_night.tres"
const OUT_DIR: String = "res://shared/assets/ui/loading/"
const SIZE: Vector2i = Vector2i(1920, 1080)
## Frames de espera: shaders compilam, o lightmap carrega e a floresta do vale e criada.
const WARMUP_FRAMES: int = 90
const IDLE: StringName = &"Idle"
## Instante da animacao idle usado como pose (s), um por heroi (varia a postura da fileira).
const POSE_TIMES: Array[float] = [0.4, 0.9, 0.2, 0.7, 0.5, 1.0, 0.3, 0.8]
const ARENA_NODES_TO_DROP: Array[String] = ["Ambience"]
## Emissao dos materiais que acompanham a luz (copia de DayNight: ele usa o autoload NetworkTime,
## que nao existe quando este script compila).
const MATERIALS_DIR: String = "res://shared/resources/materials/"
const EMISSIVE_MATERIALS: Array[String] = [
	"volcanic_lava.tres",
	"arcane_river.tres",
	"arcane_crystal_magenta.tres",
	"arcane_crystal_cyan.tres",
	"arcane_crystal_green.tres",
]
const EMISSION_PARAM: StringName = &"day_night_emission"
## Dia = 0, entardecer = 0.5, noite = 1 (DayNightProfile).
const NIGHT_DAY: float = 0.0
const NIGHT_DUSK: float = 0.5
const NIGHT_NIGHT: float = 1.0
## Planos da arena: olho e alvo da camera (m), campo de visao (graus).
const WIDE_EYE: Vector3 = Vector3(-33.0, 15.0, 33.0)
const WIDE_TARGET: Vector3 = Vector3(5.0, -4.0, -5.0)
const WIDE_FOV: float = 56.0
const CAMERA_FAR: float = 900.0
## Palco dos herois: base do time A; fileira em arco voltada para a camera.
const STAGE_CENTER: Vector3 = Vector3(-22.0, 0.0, 22.0)
const STAGE_FACING: Vector3 = Vector3(-1.0, 0.0, 1.0)
## Fileira: do fim da arma do primeiro heroi ao do ultimo cabem STAGE_ROW_WIDTH (u); cada heroi
## ocupa a propria largura (quanto passa do centro para a esquerda e para a direita da tela, arma
## incluida) e a folga que sobra e dividida igual entre vizinhos. Heroi novo: medir e acrescentar em
## STAGE_EXTENTS. Mais herois = menos folga; a camera e a escala nao mudam.
const STAGE_ROW_WIDTH: float = 15.0
const STAGE_EXTENTS_DEFAULT: Vector2 = Vector2(0.6, 0.6)
const STAGE_EXTENTS: Dictionary[String, Vector2] = {
	"knight": Vector2(1.15, 0.6),
	"ranger": Vector2(0.5, 0.7),
	"barbarian": Vector2(0.7, 0.6),
	"fire_wizard": Vector2(1.15, 0.7),
	"rogue": Vector2(0.5, 0.65),
	"engineer": Vector2(0.8, 0.6),
	"druid": Vector2(0.9, 0.6),
	"berserker": Vector2(0.95, 1.65),
	"occultist": Vector2(0.85, 0.95),
	"paladin": Vector2(1.0, 0.95),
	"carrasco": Vector2(0.75, 0.9),
}
const STAGE_ARC_DEPTH: float = 0.35
const STAGE_CAMERA_BACK: float = 14.5
const STAGE_CAMERA_HEIGHT: float = 1.5
const STAGE_TARGET_HEIGHT: float = 0.4
const STAGE_FOV: float = 34.0
## Palco limpo (arena nova, F94-F96): props menores que STAGE_PROP_MAX (u, maior lado) entre a
## camera e a fileira, ate STAGE_CLEAR_SIDE (u) para cada lado, somem do render; muralha fica.
const STAGE_PROP_MAX: float = 7.0
const STAGE_CLEAR_SIDE: float = 10.0
const STAGE_CLEAR_BEHIND: float = 1.5
## Arte do Login (F82): ~2x a moldura de ~1067 x 360 px; mesma largura de cena do heroes.png (FOV
## horizontal equivalente a STAGE_FOV em 16:9) e a vista sobe para a fileira caber na faixa.
const LOGIN_ART: String = "res://shared/assets/ui/login_duel.png"
const LOGIN_SIZE: Vector2i = Vector2i(2080, 704)
const LOGIN_FOV_H: float = 57.0
const LOGIN_V_OFFSET: float = 0.7
## Luz de frente nos herois (no entardecer o sol fica atras deles e a frente some na sombra).
const KEY_COLOR: Color = Color(1.0, 0.88, 0.72)
const KEY_ENERGY: float = 1.0
const KEY_SIDE: float = 3.0
const KEY_HEIGHT: float = 5.0
## id -> [modelo, pecas escondidas] (as mesmas de tools/ui/render_hero_portraits.gd) e, opcionais, a
## escala relativa ao rig medio (a do jogo: Berserker 0,58 / demais 0,78) e o clipe de idle.
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
	"berserker": ["res://shared/assets/rrb/heroes/berserker.glb", [], 0.74, &"Idle_A"],
	"occultist": ["res://shared/assets/rrb/heroes/occultist.glb", []],
	"paladin": ["res://shared/assets/rrb/heroes/paladin.glb", []],
	# Carrasco (F98): realista, escala 1,2 no jogo; pose de descanso (o Idle e guarda de combate).
	"carrasco": ["res://shared/assets/rrb/heroes/carrasco/carrasco.glb", [], 1.54, &"Portrait"],
}
## Marca empilhada do splash (BrandLogo, F82): lado do icone e tamanho do wordmark (px @1080p).
const BRAND_ICON: float = 240.0
const BRAND_WORD: int = 120
const SCRIM: Color = Color(0.043, 0.075, 0.149, 0.45)

var _profile: DayNightProfile


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_profile = load(PROFILE) as DayNightProfile
	var failed := false
	var only := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only = arg.get_slice("=", 1)
	if only.is_empty() or only == "arena_day":
		failed = not await _arena_shot("arena_day", NIGHT_DAY) or failed
	if only.is_empty() or only == "arena_night":
		failed = not await _arena_shot("arena_night", NIGHT_NIGHT) or failed
	if only.is_empty() or only == "heroes":
		failed = not await _heroes_shot(OUT_DIR + "heroes.png", NIGHT_DUSK) or failed
	if only.is_empty() or only == "login_duel":
		failed = not await _heroes_shot(LOGIN_ART, NIGHT_DUSK, LOGIN_SIZE) or failed
	if only.is_empty() or only == "splash":
		failed = not await _splash("splash", NIGHT_DUSK) or failed
	quit(1 if failed else 0)


func _arena_shot(file: String, night: float) -> bool:
	var viewport := _new_viewport()
	_new_arena(viewport, night)
	_wide_camera(viewport)
	return _save(await _capture(viewport), file)


## Fileira dos herois; [param size] diferente de SIZE = faixa larga do Login (largura fixa).
func _heroes_shot(path: String, night: float, size: Vector2i = SIZE) -> bool:
	var viewport := _new_viewport(size)
	var arena := _new_arena(viewport, night)
	var facing := STAGE_FACING.normalized()
	var across := Vector3.UP.cross(facing).normalized()
	_clear_stage(arena, facing, across)
	var ids := HEROES.keys()
	var extents: Array[Vector2] = []
	var used := 0.0
	for id: String in ids:
		extents.append(STAGE_EXTENTS.get(id, STAGE_EXTENTS_DEFAULT) as Vector2)
		used += extents[-1].x + extents[-1].y
	var gap := maxf(0.0, (STAGE_ROW_WIDTH - used) / maxf(1.0, ids.size() - 1.0))
	var cursor := -(used + gap * (ids.size() - 1)) * 0.5
	for i: int in ids.size():
		var offset := cursor + extents[i].x
		cursor = offset + extents[i].y + gap
		var at := STAGE_CENTER + across * offset - facing * absf(offset) * STAGE_ARC_DEPTH
		_place_hero(viewport, ids[i], at, facing, POSE_TIMES[i % POSE_TIMES.size()])
	var camera := Camera3D.new()
	camera.fov = STAGE_FOV
	if size != SIZE:
		camera.keep_aspect = Camera3D.KEEP_WIDTH
		camera.fov = LOGIN_FOV_H
		camera.v_offset = LOGIN_V_OFFSET
	camera.far = CAMERA_FAR
	viewport.add_child(camera)
	var eye := STAGE_CENTER + facing * STAGE_CAMERA_BACK + Vector3.UP * STAGE_CAMERA_HEIGHT
	camera.look_at_from_position(eye, STAGE_CENTER + Vector3.UP * STAGE_TARGET_HEIGHT)
	camera.current = true
	var key := DirectionalLight3D.new()
	key.light_color = KEY_COLOR
	key.light_energy = KEY_ENERGY
	viewport.add_child(key)
	key.look_at_from_position(eye - across * KEY_SIDE + Vector3.UP * KEY_HEIGHT, STAGE_CENTER)
	return _save_to(await _capture(viewport), path)


## Esconde os props pequenos na frente da fileira (entre ela e a camera).
func _clear_stage(arena: Node3D, facing: Vector3, across: Vector3) -> void:
	for node: Node in arena.find_children("*", "GeometryInstance3D", true, false):
		var geometry := node as GeometryInstance3D
		var box := geometry.global_transform * geometry.get_aabb()
		if box.size[box.get_longest_axis_index()] > STAGE_PROP_MAX:
			continue
		var rel := box.get_center() - STAGE_CENTER
		var ahead := rel.dot(facing)
		if ahead < -STAGE_CLEAR_BEHIND or ahead > STAGE_CAMERA_BACK:
			continue
		if absf(rel.dot(across)) < STAGE_CLEAR_SIDE:
			geometry.visible = false


## O splash e o entardecer da arena com o nome do jogo por cima (Control no proprio viewport).
func _splash(file: String, night: float) -> bool:
	var viewport := _new_viewport()
	_new_arena(viewport, night)
	_wide_camera(viewport)
	var scrim := ColorRect.new()
	scrim.color = SCRIM
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(scrim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.add_child(BrandLogo.make(BRAND_ICON, BRAND_WORD, true))
	viewport.add_child(center)
	return _save(await _capture(viewport), file)


func _wide_camera(viewport: SubViewport) -> void:
	var camera := Camera3D.new()
	camera.fov = WIDE_FOV
	camera.far = CAMERA_FAR
	viewport.add_child(camera)
	camera.look_at_from_position(WIDE_EYE, WIDE_TARGET)
	camera.current = true


func _new_viewport(size: Vector2i = SIZE) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = size
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	return viewport


## Arena da partida com a luz do [param night] do ciclo dia/noite (mesma amostragem do DayNight).
func _new_arena(viewport: SubViewport, night: float) -> Node3D:
	var arena := (load(ARENA) as PackedScene).instantiate() as Node3D
	viewport.add_child(arena)
	for node_name: String in ARENA_NODES_TO_DROP:
		var node := arena.get_node_or_null(node_name)
		if node != null:
			node.free()
	var key := DayNightKey.new()
	_profile.sample(night, key)
	var world := arena.get_node("WorldEnvironment") as WorldEnvironment
	world.set_script(null)  # o ArenaEnvironment ajusta a neblina pelas configuracoes; aqui nao
	var env := world.environment.duplicate() as Environment
	world.environment = env
	var sun := arena.get_node("Sun") as DirectionalLight3D
	sun.rotation_degrees = Vector3(key.sun_pitch_deg, key.sun_yaw_deg, 0.0)
	sun.light_color = key.sun_color
	sun.light_energy = key.sun_energy
	sun.shadow_blur = key.sun_shadow_blur
	env.ambient_light_color = key.ambient_color
	env.ambient_light_energy = key.ambient_energy
	env.tonemap_exposure = key.exposure
	env.volumetric_fog_density = key.fog_density
	env.volumetric_fog_albedo = key.fog_albedo
	env.fog_light_color = key.fog_albedo
	if env.sky != null and env.sky.sky_material is ShaderMaterial:
		var sky := env.sky.duplicate() as Sky
		var material := (sky.sky_material as ShaderMaterial).duplicate() as ShaderMaterial
		material.set_shader_parameter(&"day_amount", key.sky_day)
		material.set_shader_parameter(&"sun_direction", sun.basis.z)
		sky.sky_material = material
		env.sky = sky
	for file: String in EMISSIVE_MATERIALS:
		var emissive := load(MATERIALS_DIR + file) as ShaderMaterial
		emissive.set_shader_parameter(EMISSION_PARAM, key.emission_scale)
	return arena


func _place_hero(
	viewport: SubViewport, hero_id: String, at: Vector3, facing: Vector3, pose_time: float
) -> void:
	var spec: Array = HEROES[hero_id]
	var model := (load(spec[0]) as PackedScene).instantiate() as Node3D
	viewport.add_child(model)
	for part: StringName in spec[1]:
		var node := model.find_child(part) as Node3D
		if node != null:
			node.hide()
	model.look_at_from_position(at, at - facing)
	if spec.size() > 2:  # depois do look_at, que zera a escala
		model.scale = Vector3.ONE * (spec[2] as float)
	var player := model.find_child("AnimationPlayer") as AnimationPlayer
	var idle: StringName = spec[3] if spec.size() > 3 else IDLE
	if player != null and player.has_animation(idle):
		player.play(idle)
		player.seek(pose_time, true)
		player.pause()


func _capture(viewport: SubViewport) -> Image:
	for i: int in WARMUP_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	viewport.queue_free()
	return image


func _save(image: Image, file: String) -> bool:
	return _save_to(image, "%s%s.png" % [OUT_DIR, file])


func _save_to(image: Image, path: String) -> bool:
	var err := image.save_png(path)
	print("[loading] %s %s (%s)" % [path, image.get_size(), error_string(err)])
	return err == OK
