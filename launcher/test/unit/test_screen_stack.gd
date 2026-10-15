extends GutTest
## F24: pilha de telas (ARCHITECTURE-LAUNCHER §3.4): push/pop/replace, Esc = pop, a tela de baixo
## guarda o estado e so a de cima esta visivel.

var _stack: ScreenStack


func before_each() -> void:
	_stack = add_child_autofree(ScreenStack.new())
	_stack.scenes = {&"a": _scene(), &"b": _scene(), &"c": _scene()}


func _scene() -> PackedScene:
	var screen := LauncherScreen.new()
	var scene := PackedScene.new()
	scene.pack(screen)
	screen.free()
	return scene


func test_push_mostra_so_a_tela_de_cima() -> void:
	var a := _stack.push(&"a")
	var b := _stack.push(&"b")
	assert_eq(_stack.depth(), 2)
	assert_eq(_stack.current_route(), &"b")
	assert_false(a.visible)
	assert_true(b.visible)


func test_pop_volta_para_a_de_baixo_com_o_mesmo_no() -> void:
	var a := _stack.push(&"a")
	_stack.push(&"b")
	assert_true(_stack.pop())
	assert_eq(_stack.current(), a)
	assert_true(a.visible)


func test_pop_na_raiz_nao_faz_nada() -> void:
	_stack.push(&"a")
	assert_false(_stack.pop())
	assert_eq(_stack.depth(), 1)


func test_replace_troca_a_de_cima() -> void:
	_stack.push(&"a")
	_stack.push(&"b")
	_stack.replace(&"c")
	assert_eq(_stack.depth(), 2)
	assert_eq(_stack.current_route(), &"c")


func test_push_da_mesma_rota_nao_empilha_de_novo() -> void:
	var a := _stack.push(&"a")
	assert_eq(_stack.push(&"a"), a)
	assert_eq(_stack.depth(), 1)


func test_rota_sem_cena_nao_empilha() -> void:
	assert_null(_stack.push(&"nao_existe"))
	assert_eq(_stack.depth(), 0)
	assert_push_error("rota")


func test_voltar_so_aparece_com_tela_abaixo() -> void:
	var a := _stack.push(&"a") as LauncherScreen
	assert_false(a.can_go_back)
	var b := _stack.push(&"b") as LauncherScreen
	assert_true(b.can_go_back)


func test_back_requested_da_tela_desempilha() -> void:
	_stack.push(&"a")
	var b := _stack.push(&"b") as LauncherScreen
	b.back_requested.emit()
	assert_eq(_stack.current_route(), &"a")


func test_esc_desempilha() -> void:
	_stack.push(&"a")
	_stack.push(&"b")
	var esc := InputEventAction.new()
	esc.action = &"ui_cancel"
	esc.pressed = true
	_stack._unhandled_input(esc)
	assert_eq(_stack.depth(), 1)


func test_avisa_a_rota_a_cada_troca() -> void:
	watch_signals(_stack)
	_stack.push(&"a")
	_stack.push(&"b")
	_stack.pop()
	assert_signal_emit_count(_stack, "screen_changed", 3)
	assert_signal_emitted_with_parameters(_stack, "screen_changed", [&"a"])


func test_travada_esc_nao_desempilha() -> void:
	_stack.push(&"a")
	_stack.push(&"b")
	_stack.locked = true
	var esc := InputEventAction.new()
	esc.action = &"ui_cancel"
	esc.pressed = true
	_stack._unhandled_input(esc)
	assert_eq(_stack.depth(), 2)
