class_name PlayerInput
extends BaseNetInput
## Coleta input do jogador local. O netfox chama _gather so no peer dono deste node.

static var autopilot: bool = false

var movement: Vector3 = Vector3.ZERO
var aim: Vector3 = Vector3.ZERO
var attack: bool = false

func _gather() -> void:
	if autopilot:
		_gather_autopilot()
		return
	var v := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	movement = Vector3(v.x, 0.0, v.y)
	attack = Input.is_action_pressed("attack")
	aim = _mouse_aim()

func _mouse_aim() -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Vector3.ZERO
	var mouse := get_viewport().get_mouse_position()
	var player := get_parent() as Node3D
	return AimMath.aim_on_ground(camera.project_ray_origin(mouse), camera.project_ray_normal(mouse), player.global_position)

func _gather_autopilot() -> void:
	var t := NetworkTime.tick * 0.05
	movement = Vector3(cos(t), 0.0, sin(t))
	aim = movement
	attack = NetworkTime.tick % 45 == 0
