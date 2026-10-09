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
