extends SceneTree
## Passeio de camera sobre a grama decorativa (F42) na angulacao da camera do jogo (45 graus,
## 14 u: follow_camera.gd), passando pelo mato alto do centro: verificacao visual (grama x mato,
## vento) e video do roadmap. Ferramenta de autoria. Uso (na raiz do repo, janela aberta):
##   godot --path game --resolution 1280x720 --write-movie <saida>.avi --fixed-fps 30
##     --quit-after 330 -s <repo>/tools/arena/grass_showcase.gd
## Sem --write-movie, roda em tempo real e repete o passeio.

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
const DISTANCE: float = 14.0
const PITCH_DEG: float = 45.0
## Alvo da camera vai de FROM a TO (x, z) em SECONDS: campo de grama oeste da ilha ate o mato
## alto do centro (azimute 90, raio 12).
const FROM: Vector2 = Vector2(-11.0, 8.0)
const TO: Vector2 = Vector2(-11.0, -6.0)
const SECONDS: float = 11.0

var _camera: Camera3D
var _elapsed: float = 0.0


func _initialize() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	stage.add_child((load(ARENA) as PackedScene).instantiate())
	_camera = Camera3D.new()
	stage.add_child(_camera)
	_camera.current = true
	_place(0.0)


func _process(delta: float) -> bool:
	_elapsed = fmod(_elapsed + delta, SECONDS)
	_place(_elapsed / SECONDS)
	return false


func _place(t: float) -> void:
	var at := FROM.lerp(TO, smoothstep(0.0, 1.0, t))
	var target := Vector3(at.x, 0.0, at.y)
	var pitch := deg_to_rad(PITCH_DEG)
	var offset := Vector3(0.0, sin(pitch), cos(pitch)) * DISTANCE
	_camera.look_at_from_position(target + offset, target, Vector3.UP)
