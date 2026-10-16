class_name PlayerInput
extends BaseNetInput
## Coleta input do jogador local. O netfox chama _gather so no peer dono deste node.
## Movimento relativo a camera; mira pelo mouse ou pelo analogico direito, conforme o
## ultimo dispositivo usado (troca em tempo real).

## learn sem pedido.
const LEARN_NONE: int = -1
## chest_pick sem clique.
const PICK_NONE: int = -1
## Esfera de clique em cada adversario: centro a esta altura (u) do chao, raio do corpo + margem.
const PICK_HEIGHT: float = 1.0
const PICK_MARGIN: float = 0.5

static var autopilot: bool = false
## Tela por cima da partida (bestiario, F13): o heroi fica parado; a partida nao pausa.
static var suspended: bool = false

var movement: Vector3 = Vector3.ZERO
var aim: Vector3 = Vector3.ZERO
## Distancia da mira no chao (u): onde cai a area do R da Arqueira. Gamepad manda INF (o servidor
## limita ao alcance da habilidade, InputRules.sanitize_distance).
var aim_distance: float = 0.0
var attack: bool = false
var skill_q: bool = false
var skill_e: bool = false
var skill_r: bool = false
## Slot (SkillRules.SLOT_*) em que gastar um ponto neste tick, ou LEARN_NONE. So no tick em que
## o Ctrl+tecla foi apertado: segurar nao gasta varios pontos.
var learn: int = LEARN_NONE
## F pressionado neste tick; o Hero conta o toque que abre o bau.
var interact_hold: bool = false
## Item do menu do bau clicado neste tick (indice em Chest.choices), ou PICK_NONE. Vai mesmo com
## o heroi suspenso pelo menu (F61).
var chest_pick: int = PICK_NONE
## Alvo a travar (F66, SPEC-066 §2): combat_id do heroi adversario ou monstro clicado, ou
## TargetRules.NONE. Vale so no tick do clique (como learn); o servidor valida e guarda o travado.
var target_id: int = TargetRules.NONE
## Soltar o alvo neste tick: Esc ou clique no chao.
var target_clear: bool = false

## Servidor: o jogador deste heroi caiu; o input fica vazio (Hero.mark_disconnected).
var disconnected: bool = false

var _learn_held: int = LEARN_NONE
var _pending_pick: int = PICK_NONE
var _attack_held: bool = false
var _cancel_held: bool = false

var _gamepad: bool = false
var _last_stick_aim: Vector3 = Vector3.ZERO


func _input(event: InputEvent) -> void:
	_gamepad = InputDevice.uses_gamepad(event, _gamepad)


## O BaseNetInput liga um lambda em NetworkTime.before_tick_loop e so o solta quando o node e
## liberado. Se o servidor sai, o heroi deixa a arvore antes disso e o lambda ainda roda
## (is_multiplayer_authority erra fora da arvore).
func _exit_tree() -> void:
	for connection: Dictionary in NetworkTime.before_tick_loop.get_connections():
		var hook: Callable = connection["callable"]
		if hook.get_object() == self:
			NetworkTime.before_tick_loop.disconnect(hook)


## Clique no menu do bau (ChestChoiceMenu): sai no proximo tick, uma vez.
func queue_pick(index: int) -> void:
	_pending_pick = index


func _gather() -> void:
	chest_pick = _pending_pick
	_pending_pick = PICK_NONE
	if disconnected:
		chest_pick = PICK_NONE
	if suspended or disconnected:
		_gather_idle()
		return
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
	interact_hold = Input.is_action_pressed(InputActions.INTERACT)
	_gather_learn()
	if _gamepad:
		aim = _stick_aim(yaw)
		aim_distance = INF
	elif not Input.is_action_pressed(InputActions.CAMERA_ORBIT):
		# Girando a camera o cursor fica capturado: a mira mantem o ultimo valor (SPEC-045 §3).
		_gather_mouse_aim()
	_gather_target()


## Ctrl+Q tambem casa com skill_q (Godot ignora modificador extra): aprender nao lanca a skill.
func _gather_learn() -> void:
	var held := LEARN_NONE
	for slot: int in InputActions.LEARN.size():
		if Input.is_action_pressed(InputActions.LEARN[slot]):
			held = slot
	learn = held if held != _learn_held else LEARN_NONE
	_learn_held = held
	if held != LEARN_NONE:
		skill_q = false
		skill_e = false
		skill_r = false


## Alvo (F66): o toque no botao de ataque pega o adversario sob o cursor (no gamepad, o mais perto
## da mira); toque no chao e Esc soltam. Segurar o botao continua o ataque na mira (SPEC-045).
func _gather_target() -> void:
	target_id = TargetRules.NONE
	target_clear = false
	var pressed := Input.is_action_pressed(InputActions.PRIMARY_ATTACK)
	var tapped := pressed and not _attack_held
	_attack_held = pressed
	var cancelled := Input.is_action_pressed(InputActions.CANCEL) and not _cancel_held
	_cancel_held = Input.is_action_pressed(InputActions.CANCEL)
	target_clear = cancelled
	if tapped and not Input.is_action_pressed(InputActions.CAMERA_ORBIT):
		_tap_target()


func _tap_target() -> void:
	var hero := get_parent() as Hero
	var camera := get_viewport().get_camera_3d()
	if hero == null or camera == null:
		return
	var enemies: Array[Combatant] = []
	var centers := PackedVector3Array()
	var radii := PackedFloat32Array()
	for node: Node in get_tree().get_nodes_in_group(Combatant.TARGETS_GROUP):
		var other := node as Combatant
		if other.team == hero.team or not other.is_alive() or not other.seen_by(hero):
			continue
		enemies.append(other)
		centers.append(other.global_position + Vector3.UP * PICK_HEIGHT)
		radii.append(other.body_radius() + PICK_MARGIN)
	var index := TargetPick.NOT_FOUND
	if _gamepad:
		index = TargetPick.nearest_to_direction(hero.global_position, aim, centers)
	else:
		var mouse := get_viewport().get_mouse_position()
		index = TargetPick.pick(
			camera.project_ray_origin(mouse), camera.project_ray_normal(mouse), centers, radii
		)
	if index == TargetPick.NOT_FOUND:
		target_clear = true
	else:
		target_id = enemies[index].combat_id()


func _gather_idle() -> void:
	movement = Vector3.ZERO
	aim_distance = 0.0
	target_id = TargetRules.NONE
	target_clear = true
	attack = false
	skill_q = false
	skill_e = false
	skill_r = false
	learn = LEARN_NONE
	interact_hold = false


func _camera_yaw() -> float:
	var camera := get_viewport().get_camera_3d()
	return camera.global_rotation.y if camera else 0.0


func _gather_mouse_aim() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		aim = Vector3.ZERO
		aim_distance = 0.0
		return
	var mouse := get_viewport().get_mouse_position()
	var origin := camera.project_ray_origin(mouse)
	var ray := camera.project_ray_normal(mouse)
	var player := (get_parent() as Node3D).global_position
	aim = AimMath.aim_on_ground(origin, ray, player)
	aim_distance = AimMath.offset_on_ground(origin, ray, player).length()


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
