extends GutTest
## Servidor caiu ou encerrou (#102, ARCHITECTURE-GAME §6): tela de erro que pede o fim do processo
## por sinal; funciona com a arvore pausada e so aparece quando a partida ainda nao tinha acabado.

var _screen: ConnectionLostScreen


func before_each() -> void:
	_screen = add_child_autofree(ConnectionLostScreen.new())


func test_starts_hidden() -> void:
	assert_false(_screen.visible)


func test_present_shows_the_screen_and_survives_a_paused_tree() -> void:
	_screen.present()
	assert_true(_screen.visible)
	assert_eq(_screen.process_mode, Node.PROCESS_MODE_ALWAYS)


func test_exit_button_requests_exit() -> void:
	_screen.present()
	watch_signals(_screen)
	_screen.exit_button.pressed.emit()
	assert_signal_emitted(_screen, "exit_requested")


func test_cancel_action_requests_exit() -> void:
	_screen.present()
	watch_signals(_screen)
	var event := InputEventAction.new()
	event.action = &"ui_cancel"
	event.pressed = true
	_screen._unhandled_input(event)
	assert_signal_emitted(_screen, "exit_requested")


func test_cancel_is_ignored_while_hidden() -> void:
	watch_signals(_screen)
	var event := InputEventAction.new()
	event.action = &"ui_cancel"
	event.pressed = true
	_screen._unhandled_input(event)
	assert_signal_not_emitted(_screen, "exit_requested")
