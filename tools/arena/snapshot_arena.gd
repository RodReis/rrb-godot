extends SceneTree
## Captura a arena gerada sem partida: vista de cima (ortografica) e vista em perspectiva na
## angulacao da camera do jogo. Ferramenta de autoria para a verificacao do Code e as capturas
## do roadmap (docs/roadmap/README.md). Uso (na raiz do repo, janela aberta, nao headless):
##   godot --path game --resolution 1400x1000 -s <repo>/tools/arena/snapshot_arena.gd -- <saida_sem_ext>
## Gera <saida>_topo.png e <saida>_perspectiva.png.

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
const TOP_HEIGHT: float = 90.0
const TOP_SIZE: float = 84.0
## Camera do jogo: inclinacao 45 graus, distancia 14 u (follow_camera.gd), olhando o centro da
## ponte NO a partir do portao A.
const VIEW_FROM: Vector3 = Vector3(-24.0, 11.0, -24.0)
const VIEW_AT: Vector3 = Vector3(-8.0, 0.0, -8.0)
## Frames de espera: shaders compilam e as particulas pre-processam.
const WARMUP_FRAMES: int = 40

var _out: String
var _camera: Camera3D
var _frame: int = 0
var _step: int = 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else "arena"
	var root_node := Node3D.new()
	root.add_child(root_node)
	root_node.add_child((load(ARENA) as PackedScene).instantiate())
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-1.0, 0.6, 0.0)
	sun.shadow_enabled = true
	root_node.add_child(sun)
	_camera = Camera3D.new()
	root_node.add_child(_camera)
	_camera.current = true
	_top_view()


func _top_view() -> void:
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = TOP_SIZE
	_camera.far = TOP_HEIGHT * 2.0
	_camera.transform = Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3(0, TOP_HEIGHT, 0))


func _perspective_view() -> void:
	_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	_camera.fov = 60.0
	_camera.far = 300.0
	_camera.position = VIEW_FROM
	_camera.look_at(VIEW_AT, Vector3.UP)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < WARMUP_FRAMES:
		return false
	var suffix := "_topo" if _step == 0 else "_perspectiva"
	var image := root.get_viewport().get_texture().get_image()
	var path := "%s%s.png" % [_out, suffix]
	print("[snapshot] %s -> %s" % [path, error_string(image.save_png(path))])
	_step += 1
	if _step == 1:
		_perspective_view()
		_frame = 0
		return false
	return true
