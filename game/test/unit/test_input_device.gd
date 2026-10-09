extends GutTest


func _stick(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	return ev


func test_mouse_e_teclado_viram_teclado_mouse() -> void:
	assert_false(InputDevice.uses_gamepad(InputEventMouseMotion.new(), true))
	assert_false(InputDevice.uses_gamepad(InputEventKey.new(), true))
	assert_false(InputDevice.uses_gamepad(InputEventMouseButton.new(), true))


func test_botao_do_gamepad_vira_gamepad() -> void:
	assert_true(InputDevice.uses_gamepad(InputEventJoypadButton.new(), false))


func test_analogico_fora_da_zona_morta_vira_gamepad() -> void:
	assert_true(InputDevice.uses_gamepad(_stick(JOY_AXIS_LEFT_X, 0.6), false))


func test_ruido_do_analogico_nao_troca_o_dispositivo() -> void:
	assert_false(InputDevice.uses_gamepad(_stick(JOY_AXIS_RIGHT_Y, 0.05), false))
	assert_true(InputDevice.uses_gamepad(_stick(JOY_AXIS_RIGHT_Y, 0.05), true))


func test_outro_evento_mantem_o_dispositivo() -> void:
	assert_true(InputDevice.uses_gamepad(InputEventAction.new(), true))
