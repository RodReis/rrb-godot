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


func _click(button: MouseButton) -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.pressed = true
	return ev


func test_ataque_primario_e_botao_direito() -> void:
	# SPEC-045 §2: o esquerdo passou para o giro da camera.
	InputActions.ensure()
	assert_true(InputMap.event_is_action(_click(MOUSE_BUTTON_RIGHT), InputActions.PRIMARY_ATTACK))
	assert_false(InputMap.event_is_action(_click(MOUSE_BUTTON_LEFT), InputActions.PRIMARY_ATTACK))


func test_giro_da_camera_e_botao_esquerdo_so_no_mouse() -> void:
	InputActions.ensure()
	assert_eq(InputActions.CAMERA_ORBIT, &"camera_orbit")
	assert_true(InputMap.event_is_action(_click(MOUSE_BUTTON_LEFT), InputActions.CAMERA_ORBIT))
	assert_false(InputMap.event_is_action(_click(MOUSE_BUTTON_RIGHT), InputActions.CAMERA_ORBIT))
	assert_eq(InputMap.action_get_events(InputActions.CAMERA_ORBIT).size(), 1)


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


func _key(key: Key, ctrl: bool) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	ev.ctrl_pressed = ctrl
	ev.pressed = true
	return ev


func test_ponto_de_habilidade_em_ctrl_mais_tecla_da_skill() -> void:
	# PI 2026-10-09 (F9): so teclado; gamepad entra com os botoes +Q/+E/+R da HUD (F13).
	InputActions.ensure()
	var keys: Array[Key] = [KEY_Q, KEY_E, KEY_R]
	for i: int in InputActions.LEARN.size():
		var action := InputActions.LEARN[i]
		assert_true(InputMap.event_is_action(_key(keys[i], true), action), action)
		assert_false(InputMap.event_is_action(_key(keys[i], false), action), action)


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


func test_rotulo_da_tecla_segue_o_remapeamento() -> void:
	InputActions.ensure()
	var values := UserSettings.rebind(UserSettings.defaults(), InputActions.SKILL_Q, KEY_Z)
	SettingsApplier.apply_controls(values)
	assert_eq(InputActions.key_label(InputActions.SKILL_Q), "Z")
	assert_eq(InputActions.skill_labels(), ["Z", "E", "R"] as Array[String])
	SettingsApplier.apply_controls(UserSettings.defaults())
	assert_eq(InputActions.key_label(InputActions.SKILL_Q), "Q")


func _wheel(button: MouseButton) -> InputEventMouseButton:
	var ev := _click(button)
	ev.factor = 1.0
	return ev


func test_zoom_da_camera_tem_duas_acoes_com_tecla_e_roda() -> void:
	InputActions.ensure()
	assert_eq(InputActions.CAMERA_ZOOM_IN, &"camera_zoom_in")
	assert_eq(InputActions.CAMERA_ZOOM_OUT, &"camera_zoom_out")
	assert_true(_has_key(InputActions.CAMERA_ZOOM_IN, KEY_EQUAL))
	assert_true(_has_key(InputActions.CAMERA_ZOOM_OUT, KEY_MINUS))
	assert_true(
		InputMap.event_is_action(_wheel(MOUSE_BUTTON_WHEEL_UP), InputActions.CAMERA_ZOOM_IN)
	)
	assert_true(
		InputMap.event_is_action(_wheel(MOUSE_BUTTON_WHEEL_DOWN), InputActions.CAMERA_ZOOM_OUT)
	)
	assert_false(
		InputMap.event_is_action(_wheel(MOUSE_BUTTON_WHEEL_DOWN), InputActions.CAMERA_ZOOM_IN)
	)


func test_zoom_chamar_ensure_duas_vezes_nao_duplica_eventos() -> void:
	InputActions.ensure()
	var before := InputMap.action_get_events(InputActions.CAMERA_ZOOM_IN).size()
	InputActions.ensure()
	assert_eq(InputMap.action_get_events(InputActions.CAMERA_ZOOM_IN).size(), before)


func test_remapear_zoom_troca_a_tecla_e_guarda_a_roda() -> void:
	InputActions.ensure()
	var values := UserSettings.rebind(UserSettings.defaults(), InputActions.CAMERA_ZOOM_IN, KEY_Z)
	SettingsApplier.apply_controls(values)
	assert_eq(InputActions.key_label(InputActions.CAMERA_ZOOM_IN), "Z")
	assert_true(
		InputMap.event_is_action(_wheel(MOUSE_BUTTON_WHEEL_UP), InputActions.CAMERA_ZOOM_IN)
	)
	SettingsApplier.apply_controls(UserSettings.defaults())
	assert_eq(InputActions.key_label(InputActions.CAMERA_ZOOM_IN), "Equal")
