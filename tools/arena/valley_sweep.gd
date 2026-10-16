extends SceneTree
## Varredura de camera do vale (F56, ADR-0012): prova que o jogo nunca mostra o vazio em volta
## da arena. Coloca a camera na distancia e inclinacao do jogo (follow_camera.gd: 9-14 u, 45 graus,
## FOV vertical 75) com o heroi no meio de cada muro e em cada canto jogavel (8 posicoes) e gira
## de 45 em 45 graus (8 yaws = 64 quadros). O fundo vira magenta puro (sem tonemap, sem neblina
## no ceu) e cada quadro conta os pixels magenta: qualquer um e vazio. Sai com 1 se algum quadro
## mostrar vazio. Ferramenta de autoria (verificacao do Code e capturas do roadmap), janela aberta
## (nao headless). Uso, na raiz do repo:
##   godot --path game --resolution 1280x720 -s <repo>/tools/arena/valley_sweep.gd --
##     <pasta> [salvar [normal [distancia]]]
## <pasta> recebe um PNG por quadro quando o 2o argumento e "salvar" (senao so o relatorio).
## Com "normal" no 3o argumento o fundo e a luz ficam como no jogo (so as capturas, sem contagem).
## O 4o argumento e a distancia da camera em unidades (padrao 14; o zoom da SPEC-067 vai de 9 a 14).
## Troque a resolucao (ex.: 2560x1080) para provar tambem uma janela mais larga.

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
## Mesmos valores de follow_camera.gd.
const PITCH_DEG: float = 45.0
const DEFAULT_DISTANCE: float = 14.0
const FOV: float = 75.0
## Posicoes do heroi (x, z): meio de cada muro e cantos jogaveis, dentro do quadrado de 40 u.
const HERO_AT: Array[Vector2] = [
	Vector2(0, -40),
	Vector2(40, 0),
	Vector2(0, 40),
	Vector2(-40, 0),
	Vector2(-40, -40),
	Vector2(40, -40),
	Vector2(40, 40),
	Vector2(-40, 40),
]
const YAW_STEPS: int = 8
const WARMUP_FRAMES: int = 60
const SETTLE_FRAMES: int = 3
const VOID_COLOR: Color = Color(1, 0, 1)
## Canais fora destes limites nao sao o magenta puro do vazio (a imagem sai em 8 bits).
const VOID_HIGH: float = 0.95
const VOID_LOW: float = 0.08

var _frame: int = 0
var _step: int = 0
var _out_dir: String = ""
var _save: bool = false
var _normal: bool = false
var _distance: float = DEFAULT_DISTANCE
var _camera: Camera3D
var _failures: int = 0
var _worst: int = 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else ""
	_save = args.size() > 1 and args[1] == "salvar" and not _out_dir.is_empty()
	_normal = args.size() > 2 and args[2] == "normal"
	if args.size() > 3 and args[3].is_valid_float():
		_distance = args[3].to_float()
	if _save:
		DirAccess.make_dir_recursive_absolute(_out_dir)
	var holder := Node3D.new()
	root.add_child(holder)
	var arena := (load(ARENA) as PackedScene).instantiate()
	holder.add_child(arena)
	var world := arena.find_children("*", "WorldEnvironment", true, false)[0] as WorldEnvironment
	var env := world.environment
	if not _normal:
		_void_background(env)
	_camera = Camera3D.new()
	_camera.fov = FOV
	_camera.far = 4000.0
	holder.add_child(_camera)
	_camera.current = true


## Fundo magenta puro, sem tonemap, glow nem neblina no ceu: o que sobrar magenta e vazio.
func _void_background(env: Environment) -> void:
	env.background_mode = Environment.BG_COLOR
	env.background_color = VOID_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.glow_enabled = false
	env.fog_sky_affect = 0.0
	env.volumetric_fog_sky_affect = 0.0


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < WARMUP_FRAMES:
		return false
	var total := HERO_AT.size() * YAW_STEPS
	if _step >= total:
		print("[valley] %d quadros, %d com vazio, pior %d px" % [total, _failures, _worst])
		quit(1 if _failures > 0 else 0)
		return true
	var index := _step
	var hero := HERO_AT[index / YAW_STEPS]
	var yaw := TAU * (index % YAW_STEPS) / YAW_STEPS
	if (_frame - WARMUP_FRAMES) % (SETTLE_FRAMES + 1) == 0:
		_place(hero, yaw)
		return false
	if (_frame - WARMUP_FRAMES) % (SETTLE_FRAMES + 1) != SETTLE_FRAMES:
		return false
	var image := root.get_viewport().get_texture().get_image()
	var void_px := 0 if _normal else _count_void(image)
	var label := "pos(%d,%d) yaw %d" % [hero.x, hero.y, roundi(rad_to_deg(yaw))]
	print("[valley] %s -> %d px de vazio" % [label, void_px])
	if void_px > 0:
		_failures += 1
		_worst = maxi(_worst, void_px)
	if _save:
		image.save_png(
			_out_dir.path_join("pos%02d_yaw%03d.png" % [index / YAW_STEPS, roundi(rad_to_deg(yaw))])
		)
	_step += 1
	return false


## Camera atras do heroi (contra a frente do yaw), acima, olhando o heroi (follow_camera.gd).
func _place(hero: Vector2, yaw: float) -> void:
	var pitch := deg_to_rad(PITCH_DEG)
	var forward := Vector3(-sin(yaw), 0.0, -cos(yaw))
	var target := Vector3(hero.x, 0.0, hero.y)
	_camera.global_position = (
		target - forward * _distance * cos(pitch) + Vector3.UP * _distance * sin(pitch)
	)
	_camera.look_at(target, Vector3.UP)


func _count_void(image: Image) -> int:
	var count := 0
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var c := image.get_pixel(x, y)
			if c.r > VOID_HIGH and c.b > VOID_HIGH and c.g < VOID_LOW:
				count += 1
	return count
