class_name MonsterPreview3D
extends SubViewportContainer
## Preview 3D girando (COMPONENTS.md, base do HeroPreview3D): mundo proprio num SubViewport
## com camera e luz; enquadra o modelo pela altura. Recebe o no do modelo pronto (so visual);
## nao sabe de cena de monstro nem de rede. Gira so enquanto visivel.

## Graus por segundo do giro.
const TURN_SPEED: float = 30.0
## Camera: distancia e altura do olhar em multiplos da altura do modelo.
const CAMERA_DISTANCE: float = 1.7
const CAMERA_HEIGHT: float = 0.6
const LOOK_HEIGHT: float = 0.45

@onready var _stage: Node3D = %Stage
@onready var _camera: Camera3D = %Camera


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()


func _process(delta: float) -> void:
	_stage.rotate_y(deg_to_rad(TURN_SPEED) * delta)


## Troca o modelo mostrado (nulo = vazio); toca [param animation] em laco se o modelo tiver.
func show_model(model: Node3D, animation: StringName = &"Idle") -> void:
	for child: Node in _stage.get_children():
		_stage.remove_child(child)
		child.queue_free()
	_stage.rotation = Vector3.ZERO
	if model == null:
		return
	_stage.add_child(model)
	_frame(_height(model))
	var player := model.find_child("AnimationPlayer") as AnimationPlayer
	if player != null and player.has_animation(animation):
		player.get_animation(animation).loop_mode = Animation.LOOP_LINEAR
		player.play(animation)


func _frame(height: float) -> void:
	_camera.position = Vector3(0.0, height * CAMERA_HEIGHT, height * CAMERA_DISTANCE)
	_camera.look_at(Vector3(0.0, height * LOOK_HEIGHT, 0.0), Vector3.UP)


## Altura do topo das malhas acima da origem do modelo.
func _height(model: Node3D) -> float:
	var top := 0.0
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var box := mesh.global_transform * mesh.get_aabb()
		top = maxf(top, box.end.y - model.global_position.y)
	return maxf(top, 1.0)


func _on_visibility_changed() -> void:
	set_process(is_visible_in_tree())
