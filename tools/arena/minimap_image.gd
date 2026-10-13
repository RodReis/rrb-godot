extends SceneTree
## Gera a imagem do minimapa (F65, ADR-0014): a arena vista de cima, ortografica, com luz de dia
## forte, sem neblina, sem particulas e sem noite. O Minimap so desenha esta imagem (sempre clara,
## tambem de noite); nada de camera ao vivo. Rode de novo quando a arena mudar (builder ou .glb).
## Precisa de janela (GPU), como o snapshot_arena.gd. Uso (na raiz do repo):
##   godot --path game --resolution 1024x1024 -s <repo>/tools/arena/minimap_image.gd
## Saida: shared/assets/rrb/arena/minimap_arena.webp, cobrindo +-Minimap world_extent (42 u).

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
const OUT: String = "res://shared/assets/rrb/arena/minimap_arena.webp"
## Meia largura do mundo na imagem: a mesma do Minimap (quadrado jogavel de 40 u + beira).
const EXTENT: float = 42.0
const HEIGHT: float = 80.0
const SIDE: int = 1024
const WEBP_QUALITY: float = 0.9
## Luz de dia so desta foto: sol quase a pino (sombras curtas), ambiente moderado e cor mais viva
## (claro sem lavar: o PI achou a 1a versao clara demais e sem nitidez).
const SUN_ROTATION_DEG: Vector3 = Vector3(-70.0, -30.0, 0.0)
const SUN_ENERGY: float = 1.1
const AMBIENT: Color = Color(0.85, 0.88, 0.92)
const AMBIENT_ENERGY: float = 0.55
const EXPOSURE: float = 0.9
const CONTRAST: float = 1.2
const SATURATION: float = 1.35
## Frames de espera: shaders compilam e o lightmap carrega.
const WARMUP_FRAMES: int = 40

var _frame: int = 0


func _initialize() -> void:
	root.size = Vector2i(SIDE, SIDE)
	var arena := (load(ARENA) as PackedScene).instantiate() as Node3D
	root.add_child(arena)
	for name: String in ["Ambience", "Valley"]:
		var node := arena.get_node_or_null(name)
		if node != null:
			node.free()
	_daylight(arena)
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = EXTENT * 2.0
	camera.far = HEIGHT * 2.0
	camera.transform = Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3(0, HEIGHT, 0))
	camera.current = true


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


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < WARMUP_FRAMES:
		return false
	var image := root.get_viewport().get_texture().get_image()
	image.resize(SIDE, SIDE, Image.INTERPOLATE_LANCZOS)
	var err := image.save_webp(ProjectSettings.globalize_path(OUT), true, WEBP_QUALITY)
	print("[minimap] %s -> %s" % [OUT, error_string(err)])
	return true
