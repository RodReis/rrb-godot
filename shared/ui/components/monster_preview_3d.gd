class_name MonsterPreview3D
extends SubViewportContainer
## Preview 3D girando (COMPONENTS.md, base do HeroPreview3D): mundo proprio num SubViewport
## com camera e luz de 3 pontos (key quente, fill fria, rim dourada); enquadra o modelo pela
## altura. Recebe o no do modelo pronto (so visual); nao sabe de cena de monstro nem de rede.
## Gira so enquanto visivel; com giro 0 e camera mais perto vira retrato (selecao de herois).

## Graus por segundo do giro (0 = parado, de frente).
@export var turn_speed: float = 30.0
## Camera: distancia, altura e altura do olhar em multiplos da altura do modelo.
@export var camera_distance: float = 1.7
@export var camera_height: float = 0.6
@export var look_height: float = 0.45
## Altura de enquadramento fixa em m (0 = mede o topo da malha). Retratos de herois usam a mesma
## altura: o rig KayKit e igual, e chapeu/capuz nao encolhem o corpo na moldura.
@export var frame_height: float = 0.0
## Giro inicial do modelo em graus (180 = de frente para a camera nos KayKit).
@export var facing: float = 0.0

@onready var _stage: Node3D = %Stage
@onready var _camera: Camera3D = %Camera


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()


func _process(delta: float) -> void:
	_stage.rotate_y(deg_to_rad(turn_speed) * delta)


## Troca o modelo mostrado (nulo = vazio); toca em laco a meta "idle" do modelo (clipe proprio do
## heroi, Berserker F75) ou [param animation], se o modelo tiver.
func show_model(model: Node3D, animation: StringName = &"Idle") -> void:
	for child: Node in _stage.get_children():
		_stage.remove_child(child)
		child.queue_free()
	_stage.rotation = Vector3(0.0, deg_to_rad(facing), 0.0)
	if model == null:
		return
	_stage.add_child(model)
	_frame(frame_height if frame_height > 0.0 else _height(model))
	var clip: StringName = model.get_meta(&"idle", animation)
	var player := model.find_child("AnimationPlayer") as AnimationPlayer
	if player != null and player.has_animation(clip):
		player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
		player.play(clip)


## Enquadra so a faixa de altura [param band] (x = baixo, y = topo, em m): a camera mira o meio
## dela, na distancia em que ela enche a altura do quadro; o modelo gira [param turn] graus alem do
## facing.
func frame_band(band: Vector2, turn: float = 0.0) -> void:
	_stage.rotation = Vector3(0.0, deg_to_rad(facing + turn), 0.0)
	var middle := (band.x + band.y) / 2.0
	var distance := (band.y - band.x) / 2.0 / tan(deg_to_rad(_camera.fov) / 2.0)
	_camera.position = Vector3(0.0, middle, distance)
	_camera.look_at(Vector3(0.0, middle, 0.0), Vector3.UP)


func _frame(height: float) -> void:
	_camera.position = Vector3(0.0, height * camera_height, height * camera_distance)
	_camera.look_at(Vector3(0.0, height * look_height, 0.0), Vector3.UP)


## Altura do topo das malhas acima da origem do modelo.
func _height(model: Node3D) -> float:
	var top := 0.0
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var box := mesh.global_transform * mesh.get_aabb()
		top = maxf(top, box.end.y - model.global_position.y)
	return maxf(top, 1.0)


func _on_visibility_changed() -> void:
	set_process(is_visible_in_tree() and not is_zero_approx(turn_speed))
