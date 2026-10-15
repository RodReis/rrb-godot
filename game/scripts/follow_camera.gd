class_name FollowCamera
extends Camera3D
## Camera em 3a pessoa alta (PRD §3.6): atras do heroi local, inclinacao e distancia fixas,
## sem colisao. Yaw inicial do time: trava olhando [member focus] a partir de onde o heroi
## apareceu (PI 2026-10-09). Depois, com camera_orbit (botao esquerdo) segurado, o mouse gira
## 360 graus em volta do heroi; ao soltar, fica onde parou (SPEC-045).

@export var pitch_degrees: float = 45.0
@export var distance: float = 14.0
## Ponto que define o yaw ao travar (centro da arena).
@export var focus: Vector3 = Vector3.ZERO
## Radianos de giro por pixel de mouse (SPEC-045 §3.7; ajuste na verificacao visual).
@export_range(0.001, 0.02, 0.0005) var orbit_sensitivity: float = 0.005

var _yaw: float = 0.0
var _yaw_locked: bool = false
var _orbiting: bool = false
var _cursor_before_orbit: Vector2 = Vector2.ZERO
var _mouse_mode_before_orbit: Input.MouseMode = Input.MOUSE_MODE_VISIBLE


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


## Movimento e soltura chegam aqui antes da HUD: a HUD nao trava o giro ja iniciado.
func _input(event: InputEvent) -> void:
	if not _orbiting:
		return
	var motion := event as InputEventMouseMotion
	if motion:
		# screen_relative: pixels da tela, sem a escala do stretch (o giro nao muda com a janela).
		_yaw = CameraRig.orbit(_yaw, motion.screen_relative.x, orbit_sensitivity)
	elif event.is_action_released(InputActions.CAMERA_ORBIT):
		_stop_orbit()


## Inicio em _unhandled_input: clique consumido por controle da HUD nao gira (SPEC-045 §3.5).
func _unhandled_input(event: InputEvent) -> void:
	if _yaw_locked and not _orbiting and event.is_action_pressed(InputActions.CAMERA_ORBIT):
		_start_orbit()


## Camera sai da arvore no meio do giro (fim de partida, troca de cena): nao deixa o cursor preso.
func _exit_tree() -> void:
	if _orbiting:
		_orbiting = false
		Input.mouse_mode = _mouse_mode_before_orbit


func _notification(what: int) -> void:
	# Janela perdeu o foco no meio do giro: o release nao chega; devolve o cursor.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and _orbiting:
		_stop_orbit()


func _start_orbit() -> void:
	_orbiting = true
	_cursor_before_orbit = get_viewport().get_mouse_position()
	_mouse_mode_before_orbit = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _stop_orbit() -> void:
	_orbiting = false
	Input.mouse_mode = _mouse_mode_before_orbit
	get_viewport().warp_mouse(_cursor_before_orbit)
