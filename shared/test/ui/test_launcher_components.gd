extends GutTest
## F24: componentes do Launcher (COMPONENTS.md, regra 2) — StateBox, FormRow, ModalDialog,
## ScreenHeader e ScreenFooter.


func _state_box() -> Array:
	var box: StateBox = add_child_autofree(StateBox.new())
	var content := Label.new()
	content.text = "dado"
	box.add_child(content)
	return [box, content]


func test_state_box_so_mostra_o_conteudo_em_ready() -> void:
	var pair := _state_box()
	var box: StateBox = pair[0]
	var content: Label = pair[1]
	box.set_state(StateBox.State.READY)
	assert_true(content.visible)
	box.set_state(StateBox.State.EMPTY, "Nenhuma partida ainda")
	assert_false(content.visible)


func test_state_box_erro_mostra_mensagem_e_tentar_de_novo() -> void:
	var box: StateBox = _state_box()[0]
	watch_signals(box)
	box.set_state(StateBox.State.ERROR, "Servidor fora")
	var retry := _find_button(box)
	assert_not_null(retry)
	assert_true(retry.is_visible_in_tree())
	retry.pressed.emit()
	assert_signal_emitted(box, "retry_requested")


func test_state_box_loading_espera_150_ms_para_o_spinner() -> void:
	var box: StateBox = _state_box()[0]
	box.set_state(StateBox.State.LOADING)
	assert_false(box.is_spinning(), "sem spinner antes do atraso (P5)")
	await wait_seconds(StateBox.LOADING_DELAY + 0.1)
	assert_true(box.is_spinning())


func test_state_box_ready_antes_do_atraso_nao_mostra_spinner() -> void:
	var box: StateBox = _state_box()[0]
	box.set_state(StateBox.State.LOADING)
	box.set_state(StateBox.State.READY)
	await wait_seconds(StateBox.LOADING_DELAY + 0.1)
	assert_false(box.is_spinning())


func test_form_row_erro_aparece_e_some() -> void:
	var row: FormRow = add_child_autofree(FormRow.new())
	row.bind("E-mail")
	assert_false(row.has_error())
	row.set_error("E-mail invalido")
	assert_true(row.has_error())
	row.clear_error()
	assert_false(row.has_error())


func test_form_row_controle_fica_entre_rotulo_e_erro() -> void:
	var row: FormRow = add_child_autofree(FormRow.new())
	var edit := LineEdit.new()
	row.add_child(edit)
	assert_eq(row.get_children(), [edit] as Array[Node])


func test_modal_devolve_o_botao_escolhido() -> void:
	var dialog: ModalDialog = add_child_autofree(ModalDialog.new())
	var actions: Array[DialogAction] = [
		DialogAction.make("Cancelar"), DialogAction.make("Sair", DialogAction.Kind.DANGER)
	]
	_press_later(dialog, 1)
	var index := await dialog.open("Sair do jogo?", "O Launcher fecha.", actions)
	assert_eq(index, 1)
	assert_false(dialog.visible)


func test_modal_botao_destrutivo_usa_o_tipo_danger() -> void:
	var dialog: ModalDialog = add_child_autofree(ModalDialog.new())
	var actions: Array[DialogAction] = [
		DialogAction.make("Cancelar"), DialogAction.make("Sair", DialogAction.Kind.DANGER)
	]
	var seen := {}  # lambda captura por valor: Dictionary para devolver o tipo
	var check := func() -> void:
		seen["type"] = dialog.buttons()[1].theme_type_variation
		dialog.buttons()[0].pressed.emit()
	check.call_deferred()
	await dialog.open("Sair?", "", actions)
	assert_eq(seen["type"], &"LnButtonDanger")


func test_modal_esc_cancela() -> void:
	var dialog: ModalDialog = add_child_autofree(ModalDialog.new())
	var actions: Array[DialogAction] = [DialogAction.make("Ok")]
	(func() -> void: dialog.closed.emit(ModalDialog.CANCELLED)).call_deferred()
	var index := await dialog.open("Aviso", "", actions)
	assert_eq(index, ModalDialog.CANCELLED)


func test_header_voltar_so_com_pilha_e_emite_sinal() -> void:
	var header: ScreenHeader = add_child_autofree(ScreenHeader.new())
	watch_signals(header)
	header.bind("Configuracoes", false)
	var back := _find_button(header)
	assert_false(back.visible)
	header.bind("Configuracoes", true)
	assert_true(back.visible)
	back.pressed.emit()
	assert_signal_emitted(header, "back_requested")


func test_footer_mostra_um_item_por_atalho() -> void:
	var footer: ScreenFooter = add_child_autofree(ScreenFooter.new())
	var hints: Array[HotkeyHint] = [
		HotkeyHint.make("ESC", "Voltar"), HotkeyHint.make("F1", "Ajuda")
	]
	footer.bind(hints, "pronto", "ARENA 1V1")
	await wait_process_frames(1)
	var keys := footer.find_children("*", "Label", true, false).filter(
		func(label: Node) -> bool: return (label as Label).theme_type_variation == &"LnKeyLabel"
	)
	assert_eq(keys.size(), 2)


func _press_later(dialog: ModalDialog, index: int) -> void:
	(func() -> void: dialog.buttons()[index].pressed.emit()).call_deferred()


func _find_button(root: Node) -> Button:
	var found := root.find_children("*", "Button", true, false)
	return found[0] as Button if not found.is_empty() else null
