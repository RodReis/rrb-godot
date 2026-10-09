class_name PlayerInput
extends BaseNetInput
## Coleta input do jogador local. O netfox chama _gather so no peer dono deste node.
## Movimento relativo a camera; mira pelo mouse ou pelo analogico direito, conforme o
## ultimo dispositivo usado (troca em tempo real).

static var autopilot: bool = false

var movement: Vector3 = Vector3.ZERO
var aim: Vector3 = Vector3.ZERO
var attack: bool = false
var skill_q: bool = false
var skill_e: bool = false
var skill_r: bool = false

var _gamepad: bool = false
var _last_stick_aim: Vector3 = Vector3.ZERO


func _input(event: InputEvent) -> void:
	_gamepad = InputDevice.uses_gamepad(event, _gamepad)


func _gather() -> void:
	if autopilot:
		_gather_autopilot()
		return
	var yaw := _camera_yaw()
	var v := Input.get_vector(
		InputActions.MOVE_LEFT,
		InputActions.MOVE_RIGHT,
		InputActions.MOVE_FORWARD,
		InputActions.MOVE_BACK
	)
	movement = CameraRig.to_world(v, yaw)
	attack = Input.is_action_pressed(InputActions.PRIMARY_ATTACK)
	skill_q = Input.is_action_pressed(InputActions.SKILL_Q)
	skill_e = Input.is_action_pressed(InputActions.SKILL_E)
	skill_r = Input.is_action_pressed(InputActions.SKILL_R)
	aim = _stick_aim(yaw) if _gamepad else _mouse_aim()


func _camera_yaw() -> float:
	var camera := get_viewport().get_camera_3d()
	return camera.global_rotation.y if camera else 0.0


func _mouse_aim() -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Vector3.ZERO
	var mouse := get_viewport().get_mouse_position()
	var player := get_parent() as Node3D
	return AimMath.aim_on_ground(
		camera.project_ray_origin(mouse), camera.project_ray_normal(mouse), player.global_position
	)


## Mira do analogico direito; solto, mantem a ultima direcao.
func _stick_aim(yaw: float) -> Vector3:
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		return _last_stick_aim
	var stick := Vector2(
		Input.get_joy_axis(pads[0], JOY_AXIS_RIGHT_X), Input.get_joy_axis(pads[0], JOY_AXIS_RIGHT_Y)
	)
	var dir := AimMath.stick_aim(stick, yaw)
	if not dir.is_zero_approx():
		_last_stick_aim = dir
	return _last_stick_aim


func _gather_autopilot() -> void:
	var t := NetworkTime.tick * 0.05
	movement = Vector3(cos(t), 0.0, sin(t))
	aim = movement
	attack = NetworkTime.tick % 45 == 0
