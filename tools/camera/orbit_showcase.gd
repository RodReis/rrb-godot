extends SceneTree
## Vitrine do giro da camera (F45, SPEC-045): sobe main.tscn offline vs bot, escolhe o heroi e
## injeta os eventos reais de mouse (Input.parse_input_event): esquerdo segurado + movimento
## horizontal (volta de 360 graus), soltar, W, clique direito (ataque) e meia volta. Imprime as
## checagens da SPEC-045 §3/§5 ([orbit] OK/FALHOU). Ferramenta de autoria (verificacao e video do
## roadmap com o Movie Maker), fora do jogo. Uso, na raiz:
##   godot --path game --resolution 1280x720 -s <repo>/tools/camera/orbit_showcase.gd
##     [--write-movie <saida>.avi --fixed-fps 30] -- --offline --bot --hero=knight
## Sai sozinha no fim. Script de SceneTree compila antes dos autoloads: heroi, MatchController e
## NetworkTime sao lidos sem tipo de classe.

const MAIN: String = "res://scenes/main.tscn"
## Mesmo valor padrao de follow_camera.gd (orbit_sensitivity).
const SENSITIVITY: float = 0.005
## Fases (segundos desde que a camera chegou ao heroi).
const ORBIT_START: float = 0.5
const ORBIT_SECONDS: float = 4.0
const WALK_START: float = 5.0
const WALK_SECONDS: float = 1.2
const ATTACK_AT: float = 6.6
const HALF_START: float = 7.2
const HALF_SECONDS: float = 1.5
const END_AT: float = 9.6

var _main: Node
var _hero_id: String = "knight"
var _hero: Node3D
var _camera: Camera3D
var _elapsed: float = -1.0
var _orbit_px_left: float = 0.0
var _phase: int = 0
var _yaw_before: float = 0.0
var _walk_from: Vector3 = Vector3.ZERO
var _walk_forward: Vector3 = Vector3.ZERO
var _failures: int = 0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--hero="):
			_hero_id = arg.trim_prefix("--hero=")
	_main = (load(MAIN) as PackedScene).instantiate()
	root.add_child(_main)
	current_scene = _main


func _process(delta: float) -> bool:
	var controller := _main.get_node("MatchController")
	if controller.get("state") == MatchState.State.HERO_PICK:
		var tick: int = root.get_node("NetworkTime").get("tick")
		controller.call("submit_pick", 1, StringName(_hero_id), tick)
	if _hero == null:
		_hero = _main.get_node_or_null("Players/1") as Node3D
		_camera = _main.get_viewport().get_camera_3d()
		return false
	_elapsed += delta
	if _elapsed < 0.0:
		return false
	_drag(delta)
	return _advance()


## Uma fase por chamada, na ordem; true encerra.
func _advance() -> bool:
	match _phase:
		0 when _elapsed >= ORBIT_START:
			_yaw_before = _camera.global_rotation.y
			_mouse(MOUSE_BUTTON_LEFT, true)
			_orbit_px_left = TAU / SENSITIVITY
			_check("cursor capturado", Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)
		1 when _elapsed >= ORBIT_START + ORBIT_SECONDS + 0.1:
			_mouse(MOUSE_BUTTON_LEFT, false)
			var turned := angle_difference(_yaw_before, _camera.global_rotation.y)
			_check("volta de 360 graus (sobra %.3f rad)" % turned, absf(turned) < 0.05)
			_check("cursor devolvido", Input.mouse_mode == Input.MOUSE_MODE_VISIBLE)
		2 when _elapsed >= WALK_START:
			_walk_from = _hero.global_position
			_walk_forward = -_camera.global_basis.z
			_walk_forward.y = 0.0
			Input.action_press(InputActions.MOVE_FORWARD)
		3 when _elapsed >= WALK_START + WALK_SECONDS:
			Input.action_release(InputActions.MOVE_FORWARD)
			var moved := _hero.global_position - _walk_from
			moved.y = 0.0
			_check(
				"W para longe da camera",
				moved.length() > 1.0 and moved.normalized().dot(_walk_forward.normalized()) > 0.9
			)
		4 when _elapsed >= ATTACK_AT:
			_mouse(MOUSE_BUTTON_RIGHT, true)
		5 when _elapsed >= ATTACK_AT + 0.15:
			# O PlayerInput le o botao no tick seguinte ao clique.
			_check("direito ataca", _hero.get("input").get("attack") == true)
			_mouse(MOUSE_BUTTON_RIGHT, false)
		6 when _elapsed >= HALF_START:
			_yaw_before = _camera.global_rotation.y
			_mouse(MOUSE_BUTTON_LEFT, true)
			_orbit_px_left = -PI / SENSITIVITY
		7 when _elapsed >= HALF_START + HALF_SECONDS + 0.1:
			_mouse(MOUSE_BUTTON_LEFT, false)
			var turned := angle_difference(_yaw_before, _camera.global_rotation.y)
			_check("meia volta para a esquerda", absf(absf(turned) - PI) < 0.05)
		8 when _elapsed >= END_AT:
			print("[orbit] fim: %s" % ("OK" if _failures == 0 else "%d FALHA(S)" % _failures))
			return true
		_:
			return false
	_phase += 1
	return false


## Movimento horizontal do mouse enquanto o esquerdo esta segurado, espalhado pela fase.
func _drag(delta: float) -> void:
	if is_zero_approx(_orbit_px_left):
		return
	var seconds := ORBIT_SECONDS if _phase <= 1 else HALF_SECONDS
	var rate := absf(TAU / SENSITIVITY if _phase <= 1 else PI / SENSITIVITY) / seconds
	var step := signf(_orbit_px_left) * minf(rate * delta, absf(_orbit_px_left))
	_orbit_px_left -= step
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(step, 0.0)
	motion.screen_relative = motion.relative
	motion.position = _center()
	Input.parse_input_event(motion)


func _mouse(button: MouseButton, pressed: bool) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = button
	click.pressed = pressed
	click.position = _center()
	Input.parse_input_event(click)
	Input.flush_buffered_events()


func _center() -> Vector2:
	return _main.get_viewport().get_visible_rect().size * 0.5


func _check(what: String, ok: bool) -> void:
	print("[orbit] %s %s (%.2f s)" % ["OK" if ok else "FALHOU", what, _elapsed])
	if not ok:
		_failures += 1
