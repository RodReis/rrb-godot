extends GutTest
## F35: chip de perfil do cabecalho (prototipo Menu Principal, sem ELO): #nickname, avatar local
## (ou o icone padrao) e a linha de V-D do historico. So aparece com nickname; clicar ou Enter
## abre o Perfil.

var _bar: AppBar


func before_each() -> void:
	_bar = AppBar.new()
	add_child_autofree(_bar)
	await wait_process_frames(1)


func _avatar() -> Texture2D:
	return AvatarStore.preset_texture("hero:knight")


func test_chip_comeca_escondido() -> void:
	assert_false(_bar.profile_chip().visible)


func test_mostra_o_hashtag_nickname_e_o_avatar() -> void:
	_bar.set_profile("RodReis", _avatar())
	var chip := _bar.profile_chip()
	assert_true(chip.visible)
	assert_eq(chip.name_text(), "#RodReis")
	assert_true(chip.has_avatar())


func test_sem_avatar_escolhido_usa_o_icone_padrao() -> void:
	_bar.set_profile("RodReis", null)
	assert_true(_bar.profile_chip().visible)
	assert_false(_bar.profile_chip().has_avatar())


func test_sem_nickname_o_chip_nao_aparece() -> void:
	_bar.set_profile("", null)
	assert_false(_bar.profile_chip().visible)


func test_vd_no_lugar_do_elo() -> void:
	_bar.set_profile("RodReis", null)
	assert_eq(_bar.profile_chip().record_label_text(), "", "sem historico, sem linha")
	_bar.set_profile_record(14, 6)
	assert_eq(_bar.profile_chip().record_label_text(), "14V–6D")
	_bar.set_profile_record(0, 0)
	assert_eq(_bar.profile_chip().record_label_text(), "0V–0D")


func test_formato_do_vd() -> void:
	assert_eq(ProfileChip.record_text(28, 16), "28V–16D")


func test_limpar_esconde_e_esquece_o_vd() -> void:
	_bar.set_profile("RodReis", null)
	_bar.set_profile_record(14, 6)
	_bar.clear_profile()
	assert_false(_bar.profile_chip().visible)
	assert_eq(_bar.profile_chip().record_label_text(), "")


func test_clique_emite_o_pedido_de_perfil() -> void:
	_bar.set_profile("RodReis", null)
	watch_signals(_bar)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	_bar.profile_chip()._gui_input(click)
	assert_signal_emitted(_bar, "profile_requested")


func test_enter_com_foco_tambem_abre() -> void:
	_bar.set_profile("RodReis", null)
	watch_signals(_bar)
	var accept := InputEventAction.new()
	accept.action = &"ui_accept"
	accept.pressed = true
	_bar.profile_chip()._gui_input(accept)
	assert_signal_emitted(_bar, "profile_requested")


func test_chip_e_focavel_para_teclado() -> void:
	_bar.set_profile("RodReis", null)
	assert_eq(_bar.profile_chip().focus_mode, Control.FOCUS_ALL)


func test_menu_de_telas_nao_ganha_item_de_perfil() -> void:
	assert_false(Router.NAV.has(Router.PROFILE), "o perfil abre pelo chip, nao pelo menu")
	assert_true(Router.has_route(Router.PROFILE))
