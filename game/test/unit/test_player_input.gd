extends GutTest
## SPEC-045 §5.1: o botao esquerdo gira a camera e nao ataca; o direito ataca.

var _input: PlayerInput


func before_each() -> void:
	InputActions.ensure()
	var hero := Node3D.new()
	_input = PlayerInput.new()
	hero.add_child(_input)
	add_child_autofree(hero)


func after_each() -> void:
	_mouse(MOUSE_BUTTON_LEFT, false)
	_mouse(MOUSE_BUTTON_RIGHT, false)


func _mouse(button: MouseButton, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.pressed = pressed
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func test_esquerdo_segurado_nao_ataca() -> void:
	_mouse(MOUSE_BUTTON_LEFT, true)
	_input._gather()
	assert_false(_input.attack)


func test_direito_segurado_ataca() -> void:
	_mouse(MOUSE_BUTTON_RIGHT, true)
	_input._gather()
	assert_true(_input.attack)


func test_mira_fica_parada_durante_o_giro() -> void:
	_input.aim = Vector3.RIGHT
	_input.aim_distance = 5.0
	_mouse(MOUSE_BUTTON_LEFT, true)
	_input._gather()
	assert_eq(_input.aim, Vector3.RIGHT)
	assert_eq(_input.aim_distance, 5.0)
