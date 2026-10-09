extends GutTest

## Nomes de CONVENTION.md §6.
const NAMES: Array[StringName] = [
	&"move_forward",
	&"move_back",
	&"move_left",
	&"move_right",
	&"primary_attack",
	&"skill_q",
	&"skill_e",
	&"skill_r",
	&"interact",
	&"dodge",
	&"scoreboard",
	&"cancel",
	&"open_bestiary",
]


func test_registra_todas_as_acoes_da_convention() -> void:
	InputActions.ensure()
	for action: StringName in NAMES:
		assert_true(InputMap.has_action(action), action)


func test_lista_de_acoes_e_a_da_convention() -> void:
	assert_eq(InputActions.ALL, NAMES)


func test_chamar_duas_vezes_nao_duplica_eventos() -> void:
	InputActions.ensure()
	var before: Dictionary = {}
	for action: StringName in NAMES:
		before[action] = InputMap.action_get_events(action).size()
	InputActions.ensure()
	for action: StringName in NAMES:
		assert_eq(InputMap.action_get_events(action).size(), before[action], action)


func test_movimento_em_wasd() -> void:
	InputActions.ensure()
	var ev := InputMap.action_get_events(InputActions.MOVE_FORWARD)[0] as InputEventKey
	assert_eq(ev.physical_keycode, KEY_W)


func test_ataque_primario_e_botao_esquerdo() -> void:
	InputActions.ensure()
	var ev := InputMap.action_get_events(InputActions.PRIMARY_ATTACK)[0] as InputEventMouseButton
	assert_not_null(ev)
	assert_eq(ev.button_index, MOUSE_BUTTON_LEFT)


func _events(action: StringName) -> Array[InputEvent]:
	InputActions.ensure()
	return InputMap.action_get_events(action)


func _has_key(action: StringName, key: Key) -> bool:
	for ev: InputEvent in _events(action):
		if ev is InputEventKey and (ev as InputEventKey).physical_keycode == key:
			return true
	return false


func _has_button(action: StringName, button: JoyButton) -> bool:
	for ev: InputEvent in _events(action):
		if ev is InputEventJoypadButton and (ev as InputEventJoypadButton).button_index == button:
			return true
	return false


func _has_axis(action: StringName, axis: JoyAxis, direction: float) -> bool:
	for ev: InputEvent in _events(action):
		if ev is InputEventJoypadMotion:
			var motion := ev as InputEventJoypadMotion
			if motion.axis == axis and signf(motion.axis_value) == direction:
				return true
	return false


func test_toda_acao_tem_teclado_ou_mouse_e_gamepad() -> void:
	for action: StringName in NAMES:
		var pc := false
		var pad := false
		for ev: InputEvent in _events(action):
			pc = pc or ev is InputEventKey or ev is InputEventMouseButton
			pad = pad or ev is InputEventJoypadButton or ev is InputEventJoypadMotion
		assert_true(pc, "%s sem teclado/mouse" % action)
		assert_true(pad, "%s sem gamepad" % action)


func test_teclas_da_dv() -> void:
	assert_true(_has_key(InputActions.SKILL_Q, KEY_Q))
	assert_true(_has_key(InputActions.SKILL_E, KEY_E))
	assert_true(_has_key(InputActions.SKILL_R, KEY_R))
	assert_true(_has_key(InputActions.INTERACT, KEY_F))
	assert_true(_has_key(InputActions.DODGE, KEY_SPACE))
	assert_true(_has_key(InputActions.SCOREBOARD, KEY_TAB))
	assert_true(_has_key(InputActions.CANCEL, KEY_ESCAPE))
	assert_true(_has_key(InputActions.OPEN_BESTIARY, KEY_B))


func test_gamepad_da_dv() -> void:
	assert_true(_has_axis(InputActions.MOVE_FORWARD, JOY_AXIS_LEFT_Y, -1.0))
	assert_true(_has_axis(InputActions.MOVE_BACK, JOY_AXIS_LEFT_Y, 1.0))
	assert_true(_has_axis(InputActions.MOVE_LEFT, JOY_AXIS_LEFT_X, -1.0))
	assert_true(_has_axis(InputActions.MOVE_RIGHT, JOY_AXIS_LEFT_X, 1.0))
	assert_true(_has_axis(InputActions.PRIMARY_ATTACK, JOY_AXIS_TRIGGER_RIGHT, 1.0))
	assert_true(_has_axis(InputActions.SKILL_R, JOY_AXIS_TRIGGER_LEFT, 1.0))
	assert_true(_has_button(InputActions.SKILL_Q, JOY_BUTTON_LEFT_SHOULDER))
	assert_true(_has_button(InputActions.SKILL_E, JOY_BUTTON_RIGHT_SHOULDER))
	assert_true(_has_button(InputActions.INTERACT, JOY_BUTTON_X))
	assert_true(_has_button(InputActions.DODGE, JOY_BUTTON_A))
	assert_true(_has_button(InputActions.SCOREBOARD, JOY_BUTTON_BACK))
	assert_true(_has_button(InputActions.CANCEL, JOY_BUTTON_B))
	assert_true(_has_button(InputActions.OPEN_BESTIARY, JOY_BUTTON_DPAD_UP))
