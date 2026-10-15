class_name LobbyDiorama
extends SubViewportContainer
## Diorama 3D do lobby (ARCHITECTURE-LAUNCHER §3.5, FRONTEND-LAUNCHER §4): mundo proprio num
## SubViewport com arena hexagonal reduzida, o heroi em destaque em idle sobre um pedestal com aro
## dourado, tochas e cristais. E o fundo do lobby no enquadramento do prototipo (Menu Principal:
## heroi a esquerda, arena ao crepusculo). Renderiza a 30 fps e para sem foco ou invisivel.
## DUEL: Cavaleiro x Arqueira frente a frente (arte do Login, tools/launcher/render_login_art.gd).

enum Mode { LOBBY, DUEL }

const FPS: float = 30.0
const KNIGHT_SCENE: String = "res://shared/assets/kaykit/adventurers/Knight.glb"
const RANGER_SCENE: String = "res://shared/assets/rrb/heroes/ranger.glb"
## Pecas do pack que o Cavaleiro nao usa (mesma lista do visual do heroi no Game).
const KNIGHT_HIDDEN: Array[StringName] = [
	&"1H_Sword_Offhand", &"2H_Sword", &"Rectangle_Shield", &"Round_Shield", &"Spike_Shield"
]
const IDLE: StringName = &"Idle"
const HEX_TILE: String = "res://shared/assets/kaykit/medieval_hexagon/hex_grass.gltf"
const TORCH: String = "res://shared/assets/rrb/arena/torch_post.glb"
const WALL: String = "res://shared/assets/rrb/arena/castle_wall_a.glb"
const TOWER: String = "res://shared/assets/rrb/arena/castle_tower_a.glb"
const CRYSTAL: String = "res://shared/assets/rrb/arena/crystal_large.glb"
## Aneis de hexagonos do piso em volta do pedestal.
const FLOOR_RINGS: int = 4
## Pedestal hexagonal (pedra escura) e o aro dourado emissivo do prototipo (stroke #f59e0b).
const PEDESTAL_RADIUS: float = 1.1
const PEDESTAL_HEIGHT: float = 0.35
const RIM_HEIGHT: float = 0.05
const RIM_GROW: float = 0.06
const RIM_ENERGY: float = 2.5
const STONE: Color = Color(0.090, 0.122, 0.200)
## Ceu ao crepusculo e neblina azul-noite (fundo navy do prototipo).
const SKY: Color = Color(0.035, 0.055, 0.11)
const AMBIENT: Color = Color(0.40, 0.48, 0.72)
const AMBIENT_ENERGY: float = 0.16
const FOG_DENSITY: float = 0.045
const MOON: Color = Color(0.62, 0.72, 1.0)
const MOON_ENERGY: float = 0.22
const RIM_LIGHT: Color = Color(1.0, 0.76, 0.45)
const RIM_LIGHT_ENERGY: float = 3.0
## Tochas: laranja, tremendo em torno da energia base (ruido barato, sem alocacao).
const FIRE: Color = Color(1.0, 0.55, 0.2)
const FIRE_ENERGY: float = 2.2
const FIRE_RANGE: float = 5.0
const FIRE_FLICKER: float = 0.35
const FIRE_HEIGHT: float = 1.6
const CRYSTAL_LIGHT: Color = Color(0.45, 0.7, 1.0)
const CRYSTAL_ENERGY: float = 1.6
## Camera: o heroi fica no terco esquerdo (coluna do heroi no prototipo).
const CAMERA_FOV: float = 38.0
const LOBBY_EYE: Vector3 = Vector3(4.4, 3.2, 11.0)
const LOBBY_TARGET: Vector3 = Vector3(3.6, 1.4, 0.0)
const DUEL_EYE: Vector3 = Vector3(0.0, 1.9, 5.0)
const DUEL_TARGET: Vector3 = Vector3(0.0, 0.9, 0.0)
const DUEL_GAP: float = 1.5
## Heroi levemente virado para a camera.
const HERO_FACING_DEG: float = 18.0
## Pontos de tochas, muralhas, torres e cristais (x, z; giro em graus) atras do heroi.
const TORCHES: Array[Vector2] = [Vector2(-3.2, -2.4), Vector2(3.6, -2.8), Vector2(7.2, -1.6)]
const WALLS: Array[Vector3] = [
	Vector3(-4.0, -7.0, 0.0), Vector3(2.0, -8.0, 0.0), Vector3(8.0, -7.0, 0.0)
]
const TOWERS: Array[Vector3] = [Vector3(-8.0, -6.0, 0.0), Vector3(12.0, -6.0, 0.0)]
const CRYSTALS: Array[Vector2] = [Vector2(-5.5, -4.0), Vector2(9.5, -3.5)]

@export var mode: Mode = Mode.LOBBY

var _viewport: SubViewport = SubViewport.new()
var _world: Node3D = Node3D.new()
var _fires: Array[OmniLight3D] = []
var _clock: float = 0.0
var _since_frame: float = 0.0
var _focused: bool = true


func _ready() -> void:
	stretch = true
	mouse_filter = MOUSE_FILTER_IGNORE
	_viewport.own_world_3d = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_viewport)
	_viewport.add_child(_world)
	_build()
	visibility_changed.connect(_refresh_running)
	_refresh_running()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_focused = false
		_refresh_running()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_focused = true
		_refresh_running()


func _process(delta: float) -> void:
	_clock += delta
	for i: int in _fires.size():
		var phase := float(i) * TAU / float(_fires.size())
		var flicker := sin(_clock * 11.0 + phase) * 0.6 + sin(_clock * 23.0 + phase * 2.0) * 0.4
		_fires[i].light_energy = FIRE_ENERGY * (1.0 + flicker * FIRE_FLICKER)
	_since_frame += delta
	if _since_frame >= 1.0 / FPS:
		_since_frame = 0.0
		_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


## Esta desenhando (visivel e com foco)? A cena do jogo e o teste leem isto.
func is_running() -> bool:
	return is_processing()


## Desenha um quadro agora (captura da arte do Login).
func render_now() -> void:
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func viewport_texture() -> ViewportTexture:
	return _viewport.get_texture()


func _refresh_running() -> void:
	var running := is_visible_in_tree() and _focused
	set_process(running)
	_viewport.process_mode = PROCESS_MODE_INHERIT if running else PROCESS_MODE_DISABLED


func _build() -> void:
	_environment()
	_floor()
	if mode == Mode.LOBBY:
		_pedestal(Vector3.ZERO)
		_hero(KNIGHT_SCENE, KNIGHT_HIDDEN, Vector3(0.0, PEDESTAL_HEIGHT, 0.0), HERO_FACING_DEG)
		_camera(LOBBY_EYE, LOBBY_TARGET)
	else:
		var left := Vector3(-DUEL_GAP, 0.0, 0.0)
		var right := Vector3(DUEL_GAP, 0.0, 0.0)
		_hero(KNIGHT_SCENE, KNIGHT_HIDDEN, left, 90.0 - HERO_FACING_DEG)
		_hero(RANGER_SCENE, [] as Array[StringName], right, -90.0 + HERO_FACING_DEG)
		_camera(DUEL_EYE, DUEL_TARGET)
	for spot: Vector2 in TORCHES:
		_torch(Vector3(spot.x, 0.0, spot.y))
	for wall: Vector3 in WALLS:
		_prop(WALL, Vector3(wall.x, 0.0, wall.y), wall.z)
	for tower: Vector3 in TOWERS:
		_prop(TOWER, Vector3(tower.x, 0.0, tower.y), tower.z)
	for spot: Vector2 in CRYSTALS:
		_crystal(Vector3(spot.x, 0.0, spot.y))


func _environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = AMBIENT
	env.ambient_light_energy = AMBIENT_ENERGY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.fog_enabled = true
	env.fog_light_color = SKY
	env.fog_density = FOG_DENSITY
	env.glow_enabled = true
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	_world.add_child(world_env)
	var moon := DirectionalLight3D.new()
	moon.light_color = MOON
	moon.light_energy = MOON_ENERGY
	moon.shadow_enabled = true
	moon.rotation_degrees = Vector3(-50.0, -30.0, 0.0)
	_world.add_child(moon)
	var rim := SpotLight3D.new()
	rim.light_color = RIM_LIGHT
	rim.light_energy = RIM_LIGHT_ENERGY
	rim.spot_range = 8.0
	rim.position = Vector3(-1.5, 3.5, -3.0)
	_world.add_child(rim)
	rim.look_at(Vector3(0.0, 1.0, 0.0))


## Piso: aneis de hexagonos em volta da origem, com o passo medido pelo AABB do tile.
func _floor() -> void:
	var tile_scene := load(HEX_TILE) as PackedScene
	var probe := tile_scene.instantiate() as Node3D
	var box := _aabb(probe)
	probe.free()
	var width := box.size.x
	var depth := box.size.z
	var pointy := depth > width
	for q: int in range(-FLOOR_RINGS, FLOOR_RINGS + 1):
		for r: int in range(-FLOOR_RINGS, FLOOR_RINGS + 1):
			if absi(q + r) > FLOOR_RINGS:
				continue
			var tile := tile_scene.instantiate() as Node3D
			if pointy:
				tile.position = Vector3(width * (q + r * 0.5), 0.0, depth * 0.75 * r)
			else:
				tile.position = Vector3(width * 0.75 * q, 0.0, depth * (r + q * 0.5))
			tile.position.y = -box.end.y
			_world.add_child(tile)


func _pedestal(at: Vector3) -> void:
	var stone := StandardMaterial3D.new()
	stone.albedo_color = STONE
	stone.roughness = 0.85
	var body := MeshInstance3D.new()
	body.mesh = _hex_prism(PEDESTAL_RADIUS, PEDESTAL_HEIGHT, stone)
	body.position = at + Vector3(0.0, PEDESTAL_HEIGHT * 0.5, 0.0)
	_world.add_child(body)
	var gold := StandardMaterial3D.new()
	gold.albedo_color = UiTokens.GOLD
	gold.emission_enabled = true
	gold.emission = UiTokens.GOLD
	gold.emission_energy_multiplier = RIM_ENERGY
	var rim := MeshInstance3D.new()
	rim.mesh = _hex_prism(PEDESTAL_RADIUS + RIM_GROW, RIM_HEIGHT, gold)
	rim.position = at + Vector3(0.0, PEDESTAL_HEIGHT - RIM_HEIGHT * 0.5, 0.0)
	_world.add_child(rim)


func _hex_prism(radius: float, height: float, material: Material) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 6
	mesh.rings = 1
	mesh.material = material
	return mesh


func _hero(path: String, hidden: Array[StringName], at: Vector3, facing_deg: float) -> void:
	var model := (load(path) as PackedScene).instantiate() as Node3D
	model.position = at
	model.rotation_degrees.y = facing_deg
	_world.add_child(model)
	for part: StringName in hidden:
		var node := model.find_child(part) as Node3D
		if node != null:
			node.hide()
	var player := model.find_child("AnimationPlayer") as AnimationPlayer
	if player != null and player.has_animation(IDLE):
		player.get_animation(IDLE).loop_mode = Animation.LOOP_LINEAR
		player.play(IDLE)


func _torch(at: Vector3) -> void:
	_prop(TORCH, at, 0.0)
	var fire := OmniLight3D.new()
	fire.light_color = FIRE
	fire.light_energy = FIRE_ENERGY
	fire.omni_range = FIRE_RANGE
	fire.position = at + Vector3(0.0, FIRE_HEIGHT, 0.0)
	_world.add_child(fire)
	_fires.append(fire)


func _crystal(at: Vector3) -> void:
	_prop(CRYSTAL, at, 0.0)
	var glow := OmniLight3D.new()
	glow.light_color = CRYSTAL_LIGHT
	glow.light_energy = CRYSTAL_ENERGY
	glow.omni_range = FIRE_RANGE
	glow.position = at + Vector3(0.0, 1.2, 0.0)
	_world.add_child(glow)


func _prop(path: String, at: Vector3, yaw_deg: float) -> void:
	var prop := (load(path) as PackedScene).instantiate() as Node3D
	prop.position = at
	prop.rotation_degrees.y = yaw_deg
	_world.add_child(prop)


func _camera(eye: Vector3, target: Vector3) -> void:
	var camera := Camera3D.new()
	camera.fov = CAMERA_FOV
	_world.add_child(camera)
	camera.position = eye
	camera.look_at(target)


static func _aabb(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for child: Node in node.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		var local := mesh.get_aabb()
		if first:
			box = local
			first = false
		else:
			box = box.merge(local)
	return box
