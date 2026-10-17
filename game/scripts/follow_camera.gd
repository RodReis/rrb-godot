class_name FollowCamera
extends Camera3D
## Camera em 3a pessoa alta (PRD §3.6): atras do heroi local, inclinacao e distancia fixas,
## sem colisao. Yaw inicial do time: trava olhando [member focus] a partir de onde o heroi
## apareceu (PI 2026-10-09). Depois, com camera_orbit (botao esquerdo) segurado, o mouse gira
## 360 graus em volta do heroi; ao soltar, fica onde parou (SPEC-045). A roda do mouse e as
## teclas camera_zoom_in/out aproximam e afastam a camera em passos (SPEC-067).

## Distancia mudou por zoom do jogador (o Game grava no settings.cfg).
signal distance_changed(distance: float)

## Duracao da transicao entre dois passos de zoom.
const ZOOM_SECONDS: float = 0.12

@export var pitch_degrees: float = 45.0
@export var distance: float = UserSettings.DISTANCE_DEFAULT
## Ponto que define o yaw ao travar (centro da arena).
@export var focus: Vector3 = Vector3.ZERO
## Radianos de giro por pixel de mouse (SPEC-045 §3.7; ajuste na verificacao visual).
@export_range(0.001, 0.02, 0.0005) var orbit_sensitivity: float = 0.005

## Cinematica de abertura (IntroCamera, F69): enquanto intro_active, a pose do jogo se mistura com
## intro_pose; intro_rig_weight 0 = so a cinematica, 1 = so a camera de jogo.
var intro_active: bool = false
var intro_pose: Transform3D = Transform3D.IDENTITY
var intro_rig_weight: float = 0.0

var _yaw: float = 0.0
## Yaw da camera ao nascer (olhando o centro a partir da base): o minimapa e o radar ficam
## travados nele, com a base do time embaixo, e nao giram com o jogador (PI 2026-10-16).
var _team_yaw: float = 0.0
var _yaw_locked: bool = false
var _orbiting: bool = false
## Distancia pedida pelo zoom; [member distance] caminha ate ela pelo Tween.
var _target_distance: float = distance
var _zoom_tween: Tween
var _cursor_before_orbit: Vector2 = Vector2.ZERO
var _mouse_mode_before_orbit: Input.MouseMode = Input.MOUSE_MODE_VISIBLE


func _ready() -> void:
	_target_distance = distance
	global_position = focus + CameraRig.offset(_yaw, pitch_degrees, distance)
	look_at(focus, Vector3.UP)


func _process(_delta: float) -> void:
	var me := get_node_or_null("../Players/%d" % multiplayer.get_unique_id()) as Node3D
	if me == null:
		_yaw_locked = false
		if intro_active:
			global_transform = intro_pose
		return
	if not _yaw_locked:
		_yaw = CameraRig.yaw_towards(me.global_position, focus)
		_team_yaw = _yaw
		_yaw_locked = true
	global_position = me.global_position + CameraRig.offset(_yaw, pitch_degrees, distance)
	look_at(me.global_position, Vector3.UP)
	if intro_active:
		global_transform = intro_pose.interpolate_with(global_transform, intro_rig_weight)


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


## Inicio em _unhandled_input: clique consumido por controle da HUD nao gira (SPEC-045 §3.5);
## a roda sobre a HUD tambem nao da zoom.
func _unhandled_input(event: InputEvent) -> void:
	if _yaw_locked and not _orbiting and event.is_action_pressed(InputActions.CAMERA_ORBIT):
		_start_orbit()
	elif event.is_action_pressed(InputActions.CAMERA_ZOOM_IN):
		zoom_by(1)
	elif event.is_action_pressed(InputActions.CAMERA_ZOOM_OUT):
		zoom_by(-1)


## Orientacao fixa do minimapa e do radar (0 ate o heroi local nascer).
func team_yaw() -> float:
	return _team_yaw


## Zoom de [param steps] passos (positivo aproxima) com transicao curta, preso a faixa.
## Sem mudanca (ja no limite), nada acontece e nada e gravado.
func zoom_by(steps: int) -> void:
	var wanted := CameraRig.zoom(_target_distance, steps)
	if is_equal_approx(wanted, _target_distance):
		return
	_target_distance = wanted
	if _zoom_tween != null:
		_zoom_tween.kill()
	_zoom_tween = create_tween()
	_zoom_tween.tween_property(self, "distance", wanted, ZOOM_SECONDS)
	distance_changed.emit(wanted)


## Posicao inicial vinda do settings.cfg, sem transicao nem sinal.
func set_distance(value: float) -> void:
	if _zoom_tween != null:
		_zoom_tween.kill()
	distance = clampf(value, UserSettings.DISTANCE_MIN, UserSettings.DISTANCE_MAX)
	_target_distance = distance


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
