extends GutTest
## SPEC-066 §2: o toque do botao direito pega o adversario sob o cursor, toque no chao e Esc soltam;
## segurar continua o ataque e nao repete o pedido.

const KNIGHT: PackedScene = preload("res://scenes/heroes/knight.tscn")
const TARGET_ID: int = 9
## Distancia do alvo ate a camera, ao longo do raio do cursor (u).
const REACH: float = 8.0


class StubTarget:
	extends Combatant
	var alive: bool = true
	var shown: bool = true

	func combat_id() -> int:
		return TARGET_ID

	func is_alive() -> bool:
		return alive

	func is_shown() -> bool:
		return shown


var _hero: Hero
var _camera: Camera3D
var _target: StubTarget


func before_each() -> void:
	InputActions.ensure()
	_hero = KNIGHT.instantiate() as Hero
	_hero.name = "1"
	_hero.team = GateRules.TEAM_A
	add_child_autofree(_hero)
	_camera = Camera3D.new()
	add_child_autofree(_camera)
	_camera.position = Vector3(0.0, 12.0, 8.0)
	_camera.look_at(Vector3.ZERO)
	_camera.current = true
	_target = StubTarget.new()
	_target.team = GateRules.TEAM_B
	add_child_autofree(_target)
	_under_cursor(_target)


func after_each() -> void:
	_mouse(MOUSE_BUTTON_RIGHT, false)
	_key(KEY_ESCAPE, false)


## Poe [param node] no raio que passa pelo cursor, 1 u acima dos pes (dentro da capsula de clique).
func _under_cursor(node: Node3D) -> void:
	var mouse := get_viewport().get_mouse_position()
	var origin := _camera.project_ray_origin(mouse)
	node.global_position = origin + _camera.project_ray_normal(mouse) * REACH - Vector3.UP


func _mouse(button: MouseButton, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.pressed = pressed
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _key(keycode: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	ev.pressed = pressed
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func test_toque_no_inimigo_sob_o_cursor_pede_o_alvo() -> void:
	_mouse(MOUSE_BUTTON_RIGHT, true)
	_hero.input._gather()
	assert_eq(_hero.input.target_id, TARGET_ID)
	assert_false(_hero.input.target_clear)
	assert_true(_hero.input.attack, "o toque tambem e o inicio do ataque na mira")


func test_toque_curto_entre_dois_gathers_ainda_pede_o_alvo() -> void:
	_mouse(MOUSE_BUTTON_RIGHT, true)
	_mouse(MOUSE_BUTTON_RIGHT, false)
	_hero.input._gather()
	assert_eq(_hero.input.target_id, TARGET_ID)


func test_segurar_nao_repete_o_pedido() -> void:
	_mouse(MOUSE_BUTTON_RIGHT, true)
	_hero.input._gather()
	_hero.input._gather()
	assert_eq(_hero.input.target_id, TargetRules.NONE)
	assert_false(_hero.input.target_clear)
	assert_true(_hero.input.attack, "segurado continua o ataque")


func test_toque_no_chao_solta_o_alvo() -> void:
	_target.global_position = Vector3(40.0, 0.0, 40.0)
	_mouse(MOUSE_BUTTON_RIGHT, true)
	_hero.input._gather()
	assert_eq(_hero.input.target_id, TargetRules.NONE)
	assert_true(_hero.input.target_clear)


func test_esc_solta_o_alvo() -> void:
	_key(KEY_ESCAPE, true)
	_hero.input._gather()
	assert_true(_hero.input.target_clear)


func test_aliado_nao_e_pego() -> void:
	_target.team = GateRules.TEAM_A
	_mouse(MOUSE_BUTTON_RIGHT, true)
	_hero.input._gather()
	assert_eq(_hero.input.target_id, TargetRules.NONE)
	assert_true(_hero.input.target_clear)


func test_morto_e_fora_da_vista_nao_sao_pegos() -> void:
	_target.alive = false
	_mouse(MOUSE_BUTTON_RIGHT, true)
	_hero.input._gather()
	assert_eq(_hero.input.target_id, TargetRules.NONE)
	_mouse(MOUSE_BUTTON_RIGHT, false)
	_hero.input._gather()
	_target.alive = true
	_target.shown = false
	_mouse(MOUSE_BUTTON_RIGHT, true)
	_hero.input._gather()
	assert_eq(_hero.input.target_id, TargetRules.NONE)


func test_girando_a_camera_o_toque_nao_pega_alvo() -> void:
	_mouse(MOUSE_BUTTON_LEFT, true)
	_mouse(MOUSE_BUTTON_RIGHT, true)
	_hero.input._gather()
	_mouse(MOUSE_BUTTON_LEFT, false)
	assert_eq(_hero.input.target_id, TargetRules.NONE)
