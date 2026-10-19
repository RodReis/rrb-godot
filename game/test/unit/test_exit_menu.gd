extends GutTest
## F80 / ADR-0020: menu do Esc no jogo. Continuar fecha; Sair pede confirmacao (o texto online
## avisa da derrota por abandono, o treino nao); confirmar so avisa por sinal. Esc com algo na
## frente (alvo selecionado, outro menu) nao abre. Aberto, o heroi local fica parado
## (PlayerInput.suspended).

var _menu: ExitMenu
var _resumed: int = 0
var _confirmed: int = 0


func before_each() -> void:
	InputActions.ensure()
	_resumed = 0
	_confirmed = 0
	_menu = ExitMenu.new()
	add_child_autofree(_menu)
	_menu.resumed.connect(func() -> void: _resumed += 1)
	_menu.leave_confirmed.connect(func() -> void: _confirmed += 1)


func after_each() -> void:
	PlayerInput.suspended = false


func _esc() -> InputEventAction:
	var event := InputEventAction.new()
	event.action = InputActions.CANCEL
	event.pressed = true
	return event


## O botao em si fica visivel; quem some e a caixa do passo (menu ou confirmacao).
func _shown(button: Button) -> bool:
	return (button.get_parent() as Control).visible


func _label_texts() -> String:
	var texts := PackedStringArray()
	for node: Node in _menu.find_children("*", "Label", true, false):
		texts.append((node as Label).text)
	return " | ".join(texts)


func test_nasce_fechado() -> void:
	assert_false(_menu.is_open())
	assert_false(PlayerInput.suspended)


func test_esc_abre_o_menu_e_para_o_heroi() -> void:
	_menu._unhandled_input(_esc())
	assert_true(_menu.is_open())
	assert_eq(_menu.step(), ExitMenu.Step.MENU)
	assert_true(PlayerInput.suspended, "heroi local parado enquanto aberto")
	assert_true(_shown(_menu.continue_button))
	assert_true(_shown(_menu.leave_button))


func test_esc_nao_abre_quando_o_main_diz_que_nao_pode() -> void:
	_menu.can_open = func() -> bool: return false  # alvo selecionado, outro menu, partida acabada
	_menu._unhandled_input(_esc())
	assert_false(_menu.is_open())
	assert_false(PlayerInput.suspended)


func test_esc_com_o_menu_aberto_continua_o_jogo() -> void:
	_menu._unhandled_input(_esc())
	_menu._unhandled_input(_esc())
	assert_false(_menu.is_open())
	assert_false(PlayerInput.suspended)
	assert_eq(_resumed, 1)


func test_botao_continuar_fecha_e_solta_o_heroi() -> void:
	_menu.open(true)
	_menu.continue_button.pressed.emit()
	assert_false(_menu.is_open())
	assert_false(PlayerInput.suspended)
	assert_eq(_resumed, 1)


func test_sair_online_pede_confirmacao_e_avisa_do_abandono() -> void:
	_menu.open(true)
	_menu.leave_button.pressed.emit()
	assert_eq(_menu.step(), ExitMenu.Step.CONFIRM)
	assert_eq(_confirmed, 0, "ainda nao saiu")
	assert_string_contains(_label_texts(), "derrota por abandono")
	assert_true(_shown(_menu.confirm_button))
	assert_false(_shown(_menu.continue_button))


func test_sair_do_treino_nao_fala_de_abandono() -> void:
	_menu.open(false)
	_menu.leave_button.pressed.emit()
	assert_string_contains(_label_texts(), "SAIR DO TREINO?")
	assert_false(_label_texts().contains("abandono"))


func test_confirmar_emite_o_sinal_e_nao_fecha_sozinho() -> void:
	_menu.open(true)
	_menu.leave_button.pressed.emit()
	_menu.confirm_button.pressed.emit()
	assert_eq(_confirmed, 1)
	assert_eq(_resumed, 0)


func test_voltar_da_confirmacao_volta_ao_menu() -> void:
	_menu.open(true)
	_menu.leave_button.pressed.emit()
	_menu.back_button.pressed.emit()
	assert_eq(_menu.step(), ExitMenu.Step.MENU)
	assert_true(_menu.is_open())
	assert_eq(_confirmed, 0)


func test_esc_na_confirmacao_volta_ao_menu_em_vez_de_fechar() -> void:
	_menu.open(true)
	_menu.leave_button.pressed.emit()
	_menu._unhandled_input(_esc())
	assert_eq(_menu.step(), ExitMenu.Step.MENU)
	assert_true(_menu.is_open())
	assert_eq(_resumed, 0)


func test_saindo_trava_os_botoes() -> void:
	_menu.open(true)
	_menu.leave_button.pressed.emit()
	_menu.show_leaving()
	assert_eq(_menu.step(), ExitMenu.Step.LEAVING)
	assert_false(_shown(_menu.confirm_button))
	assert_false(_shown(_menu.continue_button))
	_menu._unhandled_input(_esc())
	assert_true(_menu.is_open(), "saindo: Esc nao fecha")


func test_esc_online_ou_treino_vem_do_modo_definido_pelo_main() -> void:
	_menu.set_online(true)
	_menu._unhandled_input(_esc())
	_menu.leave_button.pressed.emit()
	assert_string_contains(_label_texts(), "derrota por abandono")
