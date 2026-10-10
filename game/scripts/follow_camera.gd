extends Camera3D
## Camera em 3a pessoa alta (PRD §3.6): atras do heroi local, inclinacao e distancia fixas,
## sem colisao. Yaw fixo do time: trava olhando [member focus] a partir de onde o heroi
## apareceu (PI 2026-10-09) e nao gira depois.

@export var pitch_degrees: float = 45.0
@export var distance: float = 14.0
## Ponto que define o yaw ao travar (centro da arena).
@export var focus: Vector3 = Vector3.ZERO

var _yaw: float = 0.0
var _yaw_locked: bool = false


func _ready() -> void:
	global_position = focus + CameraRig.offset(_yaw, pitch_degrees, distance)
	look_at(focus, Vector3.UP)


func _process(_delta: float) -> void:
	var me := get_node_or_null("../Players/%d" % multiplayer.get_unique_id()) as Node3D
	if me == null:
		_yaw_locked = false
		return
	if not _yaw_locked:
		_yaw = CameraRig.yaw_towards(me.global_position, focus)
		_yaw_locked = true
	global_position = me.global_position + CameraRig.offset(_yaw, pitch_degrees, distance)
	look_at(me.global_position, Vector3.UP)
