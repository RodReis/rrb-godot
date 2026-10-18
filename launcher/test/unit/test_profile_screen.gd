# gdlint: ignore=max-public-methods
extends GutTest
## F35: tela Perfil (FRONTEND-LAUNCHER §3.2, §6). SETUP = 1o login (nickname obrigatorio, avatar
## opcional); EDIT = so o avatar. Estados: idle (formulario), loading (salvando), error (no campo
## ou na faixa), ready (avatar escolhido). Nickname validado como no backend; avatar so local.

const SCENE: PackedScene = preload("res://scenes/screens/profile.tscn")
const AVATAR_DIR: String = "user://test_profile_screen_avatars/"
const USER_ID: String = "9c2d1a77-aaaa-4bbb-8ccc-ddddeeeeffff"
const SET_PATH: String = "PUT /users/me/nickname"

var _api: FakeApiClient
var _profile: ProfileService
var _avatars: AvatarStore
var _catalog: CatalogService
var _screen: ProfileScreen


func before_each() -> void:
	_api = FakeApiClient.new()
	add_child_autofree(_api)
	_profile = ProfileService.new(_api)
	_avatars = AvatarStore.new(AVATAR_DIR)
	_catalog = CatalogService.new()
	_catalog.load_all()


func after_each() -> void:
	if DirAccess.dir_exists_absolute(AVATAR_DIR):
		for file: String in DirAccess.get_files_at(AVATAR_DIR):
			DirAccess.remove_absolute(AVATAR_DIR + file)
		DirAccess.remove_absolute(AVATAR_DIR)


func _account(nickname: Variant) -> Dictionary:
	return {
		"id": USER_ID,
		"email": "duelista@rrb.dev",
		"nickname": nickname,
		"createdAt": "2026-10-15T12:00:00.000Z",
	}


func _open(mode: ProfileScreen.Mode, nickname: Variant = null) -> ProfileScreen:
	_profile.profile = UserProfile.from_dict(_account(nickname))
	_screen = SCENE.instantiate() as ProfileScreen
	add_child_autofree(_screen)
	_screen.bind(_profile, _avatars, _catalog, mode)
	await wait_process_frames(2)
	return _screen


func _texts(node: Node) -> Array[String]:
	var texts: Array[String] = []
	for label: Node in node.find_children("*", "Label", true, false):
		if (label as Label).is_visible_in_tree():
			texts.append((label as Label).text)
	return texts


func _has_text(node: Node, part: String) -> bool:
	return _texts(node).any(func(text: String) -> bool: return text.contains(part))


func _png_file(width: int, height: int) -> String:
	var path := "user://test_profile_upload_%d.png" % Time.get_ticks_usec()
	var image := Image.create_empty(width, height, false, Image.FORMAT_RGB8)
	image.fill(Color.GREEN)
	image.save_png(path)
	return path


func _write(path: String, bytes: PackedByteArray) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(bytes)
	file.close()


func test_setup_pede_o_nickname_e_nao_tem_voltar() -> void:
	await _open(ProfileScreen.Mode.SETUP)
	assert_eq(_screen.title_text(), "ESCOLHA SEU NICKNAME")
	assert_true(_screen.nickname_field().editable)
	assert_eq(_screen.nickname_field().text, "")
	assert_eq(_screen.nickname_field().max_length, NicknameRules.MAX_LENGTH)
	assert_string_contains(_screen.submit_button().text, "CONFIRMAR NICKNAME")
	assert_true(_has_text(_screen, "De 3 a 16 caracteres"), "regra do formato visivel")
	assert_false(_has_text(_screen, "ELO"), "sem ELO (R-PEND-02)")


func test_setup_foca_o_campo_do_nickname() -> void:
	await _open(ProfileScreen.Mode.SETUP)
	assert_true(_screen.nickname_field().has_focus())


func test_grade_de_avatares_sao_os_retratos_reais() -> void:
	await _open(ProfileScreen.Mode.SETUP)
	var ids := _screen.preset_ids()
	assert_eq(ids.size(), 13, "7 herois + 6 monstros com retrato")
	assert_true(ids.has("hero:knight"))
	assert_true(ids.has("hero:druid"))
	assert_true(ids.has("monster:wolf_t2"))
	assert_eq(_screen.preset_tile("hero:knight").tooltip_text, HistoryFormat.hero_name("knight"))
	var art := _screen.preset_tile("hero:knight").get_child(0) as TextureRect
	assert_not_null(art.texture, "retrato dentro da ficha")


func test_formato_invalido_mostra_erro_no_campo_sem_chamar_o_backend() -> void:
	await _open(ProfileScreen.Mode.SETUP)
	_screen.nickname_field().text = "ab"
	await _screen.submit()
	assert_string_contains(_screen.nickname_error(), "3 a 16")
	assert_eq(_api.calls.size(), 0)


func test_digitar_limpa_o_erro() -> void:
	await _open(ProfileScreen.Mode.SETUP)
	_screen.nickname_field().text = "ab"
	await _screen.submit()
	_screen.nickname_field().text_changed.emit("abc")
	assert_eq(_screen.nickname_error(), "")


func test_nickname_em_uso_volta_no_campo() -> void:
	await _open(ProfileScreen.Mode.SETUP)
	_screen.nickname_field().text = "RodReis"
	_api.reply(SET_PATH, 409, {"code": "NICKNAME_TAKEN"})
	await _screen.submit()
	assert_string_contains(_screen.nickname_error(), "em uso")
	assert_eq(_screen.banner_text(), "")
	assert_false(_screen.submit_button().disabled, "pode tentar outro")


func test_servidor_fora_mostra_a_faixa_nao_o_campo() -> void:
	await _open(ProfileScreen.Mode.SETUP)
	_screen.nickname_field().text = "RodReis"
	await _screen.submit()
	assert_eq(_screen.nickname_error(), "")
	assert_string_contains(_screen.banner_text(), "fora do ar")


func test_sucesso_emite_completed() -> void:
	await _open(ProfileScreen.Mode.SETUP)
	watch_signals(_screen)
	_screen.nickname_field().text = "RodReis"
	_api.reply(SET_PATH, 200, _account("RodReis"))
	await _screen.submit()
	assert_signal_emitted(_screen, "completed")
	assert_eq(_api.bodies[0], {"nickname": "RodReis"})


func test_enter_no_campo_envia() -> void:
	await _open(ProfileScreen.Mode.SETUP)
	watch_signals(_screen)
	_screen.nickname_field().text = "RodReis"
	_api.reply(SET_PATH, 200, _account("RodReis"))
	_screen.nickname_field().text_submitted.emit("RodReis")
	await wait_process_frames(2)
	assert_signal_emitted(_screen, "completed")


func test_salvando_trava_o_botao_e_mostra_o_estado() -> void:
	await _open(ProfileScreen.Mode.SETUP)
	_screen.nickname_field().text = "RodReis"
	_api.reply(SET_PATH, 200, _account("RodReis"))
	var seen: Dictionary = {}
	_api.during_call = func(_call: String) -> void:
		seen["disabled"] = _screen.submit_button().disabled
		seen["text"] = _screen.submit_button().text
		seen["editable"] = _screen.nickname_field().editable
	await _screen.submit()
	assert_true(seen["disabled"], "durante o envio o botao fica travado")
	assert_string_contains(seen["text"], "SALVANDO")
	assert_false(seen["editable"])


func test_escolher_retrato_mostra_no_avatar_grande_e_guarda_local() -> void:
	await _open(ProfileScreen.Mode.SETUP)
	assert_false(_screen.preview_has_image(), "sem escolha: icone padrao")
	watch_signals(_screen)
	_screen.preset_tile("hero:ranger").pressed.emit()
	assert_true(_screen.preview_has_image())
	assert_eq(_avatars.choice(USER_ID), "hero:ranger")
	assert_signal_emitted(_screen, "avatar_changed")
	assert_eq(_api.calls.size(), 0, "o avatar nunca vai ao backend")


func test_a_ficha_do_avatar_atual_vem_marcada() -> void:
	_avatars.use_preset(USER_ID, "monster:wolf_t2")
	await _open(ProfileScreen.Mode.SETUP)
	assert_true(_screen.preset_tile("monster:wolf_t2").button_pressed)
	assert_false(_screen.preset_tile("hero:knight").button_pressed)


func test_upload_valido_vira_o_avatar_256() -> void:
	await _open(ProfileScreen.Mode.SETUP)
	watch_signals(_screen)
	var path := _png_file(400, 300)
	_screen.load_avatar_file(path)
	DirAccess.remove_absolute(path)
	assert_true(_screen.preview_has_image())
	assert_eq(_avatars.choice(USER_ID), AvatarStore.UPLOAD)
	assert_eq(_avatars.texture(USER_ID).get_size(), Vector2(256, 256))
	assert_signal_emitted(_screen, "avatar_changed")
	assert_eq(_screen.banner_text(), "")
	for preset: String in _screen.preset_ids():
		assert_false(_screen.preset_tile(preset).button_pressed, preset)


func test_upload_invalido_mostra_a_faixa_e_nao_muda_o_avatar() -> void:
	await _open(ProfileScreen.Mode.SETUP)
	watch_signals(_screen)
	var path := "user://test_profile_upload_ruim_%d.png" % Time.get_ticks_usec()
	_write(path, "nao sou imagem".to_utf8_buffer())
	_screen.load_avatar_file(path)
	DirAccess.remove_absolute(path)
	assert_string_contains(_screen.banner_text(), "PNG ou JPG")
	assert_false(_screen.preview_has_image())
	assert_eq(_avatars.choice(USER_ID), "")
	assert_signal_not_emitted(_screen, "avatar_changed")


func test_upload_acima_de_1_mb_mostra_a_faixa() -> void:
	await _open(ProfileScreen.Mode.SETUP)
	var path := "user://test_profile_upload_grande_%d.png" % Time.get_ticks_usec()
	var big := PackedByteArray()
	big.resize(AvatarImage.MAX_BYTES + 1)
	_write(path, big)
	_screen.load_avatar_file(path)
	DirAccess.remove_absolute(path)
	assert_string_contains(_screen.banner_text(), "1 MB")
	assert_eq(_avatars.choice(USER_ID), "")


func test_botao_de_enviar_imagem_existe_e_explica_o_destino() -> void:
	await _open(ProfileScreen.Mode.SETUP)
	assert_string_contains(_screen.upload_button().text, "ENVIAR IMAGEM")
	assert_true(_has_text(_screen, "Fica só neste computador"))


func test_edit_trava_o_nickname_e_conclui_voltando() -> void:
	await _open(ProfileScreen.Mode.EDIT, "RodReis")
	assert_eq(_screen.title_text(), "SEU PERFIL")
	assert_eq(_screen.nickname_field().text, "RodReis")
	assert_false(_screen.nickname_field().editable)
	assert_false(_has_text(_screen, "De 3 a 16 caracteres"), "a regra so vale na definicao")
	assert_string_contains(_screen.submit_button().text, "CONCLUIR")
	watch_signals(_screen)
	await _screen.submit()
	assert_signal_emitted(_screen, "back_requested")
	assert_eq(_api.calls.size(), 0, "concluir nao chama o backend")


func test_edit_foca_a_primeira_ficha_de_avatar() -> void:
	await _open(ProfileScreen.Mode.EDIT, "RodReis")
	var first := _screen.preset_tile(_screen.preset_ids()[0])
	assert_true(first.has_focus())


func test_tela_sem_servicos_nao_quebra() -> void:
	var bare := SCENE.instantiate() as ProfileScreen
	add_child_autofree(bare)
	await wait_process_frames(2)
	await bare.submit()
	bare.select_preset("hero:knight")
	bare.load_avatar_file("user://nao_existe.png")
	assert_eq(bare.preset_ids().size(), 0)
