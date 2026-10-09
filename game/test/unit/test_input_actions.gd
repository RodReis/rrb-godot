extends GutTest

const ACTIONS: Array[String] = ["move_left", "move_right", "move_forward", "move_back", "attack"]

func test_registra_todas_as_acoes() -> void:
	InputActions.ensure()
	for action: String in ACTIONS:
		assert_true(InputMap.has_action(action), action)

func test_chamar_duas_vezes_nao_duplica_eventos() -> void:
	InputActions.ensure()
	InputActions.ensure()
	for action: String in ACTIONS:
		assert_eq(InputMap.action_get_events(action).size(), 1, action)

func test_attack_e_botao_esquerdo() -> void:
	InputActions.ensure()
	var ev := InputMap.action_get_events("attack")[0] as InputEventMouseButton
	assert_not_null(ev)
	assert_eq(ev.button_index, MOUSE_BUTTON_LEFT)
