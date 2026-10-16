extends GutTest
## F35: fluxo do perfil no App: o login busca a conta; conta sem nickname abre o Perfil antes do
## lobby (1o login); com nickname vai ao lobby com o chip do cabecalho (#nickname, avatar, V-D).
## O chip abre o Perfil para trocar o avatar; sair da conta e sessao expirada limpam o chip.

const SCENE: PackedScene = preload("res://scenes/app.tscn")
const AVATAR_DIR: String = "user://test_flow_avatars/"
const USER_ID: String = "9c2d1a77-aaaa-4bbb-8ccc-ddddeeeeffff"
const TOKENS: Dictionary = {"accessToken": "acesso", "refreshToken": "refresh"}
const HISTORY: Dictionary = {
	"totals": {"wins": 14, "losses": 6},
	"matches": [],
}

var _app: App
var _api: FakeApiClient


func before_each() -> void:
	_app = SCENE.instantiate() as App
	_api = FakeApiClient.new()
	_app.api.free()
	_app.api = _api
	_app.auth = AuthService.new(_api)
	_app.history = HistoryService.new(_api)
	_app.profile = ProfileService.new(_api)
	_app.avatars = AvatarStore.new(AVATAR_DIR)
	add_child_autofree(_app)
	await wait_process_frames(1)


func after_each() -> void:
	if DirAccess.dir_exists_absolute(AVATAR_DIR):
		for file: String in DirAccess.get_files_at(AVATAR_DIR):
			DirAccess.remove_absolute(AVATAR_DIR + file)
		DirAccess.remove_absolute(AVATAR_DIR)


func _me(nickname: Variant) -> Dictionary:
	return {
		"id": USER_ID,
		"email": "duelista@rrb.dev",
		"nickname": nickname,
		"createdAt": "2026-10-15T12:00:00.000Z",
	}


func _chip() -> ProfileChip:
	return _app.find_children("*", "ProfileChip", true, false)[0] as ProfileChip


func _login(me: Variant, history: Variant = HISTORY) -> void:
	_api.reply("POST /auth/login", 200, TOKENS)
	if me != null:
		_api.reply("GET /users/me", 200, me)
	if history != null:
		_api.reply("GET /matches?mine=1", 200, history)
	var login := _app.stack().current() as LoginScreen
	login.email_field().text = "duelista@rrb.dev"
	login.password_field().text = "senha1234"
	await login.submit()
	await wait_process_frames(2)


func test_conta_sem_nickname_abre_o_perfil_antes_do_lobby() -> void:
	await _login(_me(null))
	assert_eq(_app.stack().current_route(), Router.PROFILE)
	assert_eq(_app.stack().depth(), 1, "e a raiz: nao ha lobby embaixo para voltar")
	var screen := _app.stack().current() as ProfileScreen
	assert_eq(screen.mode(), ProfileScreen.Mode.SETUP)
	assert_false(_chip().visible, "sem nickname nao ha chip")


func test_no_primeiro_login_o_menu_de_telas_fica_escondido() -> void:
	await _login(_me(null))
	var tabs := _app.find_children("*", "Button", true, false).filter(
		func(button: Node) -> bool: return (button as Button).text == tr("HISTÓRICO")
	)
	assert_eq(tabs.size(), 1)
	assert_false((tabs[0] as Button).is_visible_in_tree(), "sem nickname nao se navega")


func test_definir_o_nickname_leva_ao_lobby_com_o_chip() -> void:
	await _login(_me(null))
	var screen := _app.stack().current() as ProfileScreen
	screen.nickname_field().text = "RodReis"
	_api.reply("PUT /users/me/nickname", 200, _me("RodReis"))
	_api.reply("GET /matches?mine=1", 200, HISTORY)
	await screen.submit()
	await wait_process_frames(2)
	assert_eq(_app.stack().current_route(), Router.LOBBY)
	assert_eq(_app.stack().depth(), 1)
	assert_true(_chip().visible)
	assert_eq(_chip().name_text(), "#RodReis")


func test_conta_com_nickname_vai_direto_ao_lobby_com_chip_e_vd() -> void:
	await _login(_me("RodReis"))
	assert_eq(_app.stack().current_route(), Router.LOBBY)
	assert_true(_chip().visible)
	assert_eq(_chip().name_text(), "#RodReis")
	assert_eq(_chip().record_label_text(), "14V–6D")
	assert_eq(_app.account_email, "duelista@rrb.dev")


func test_sem_historico_o_chip_nao_inventa_vd() -> void:
	await _login(_me("RodReis"), null)
	assert_true(_chip().visible)
	assert_eq(_chip().record_label_text(), "")


func test_nao_carregar_a_conta_fica_no_login_sem_sessao() -> void:
	await _login(null)
	assert_eq(_app.stack().current_route(), Router.LOGIN)
	assert_false(_app.auth.is_logged_in(), "sem a conta nao ha sessao util")
	var toast := _app.find_children("*", "Toast", true, false)[0] as Toast
	var texts := toast.find_children("*", "Label", true, false).map(
		func(label: Label) -> String: return label.text
	)
	assert_true(texts.any(func(text: String) -> bool: return text.contains("carregar sua conta")))


func test_chip_abre_o_perfil_so_para_trocar_o_avatar() -> void:
	await _login(_me("RodReis"))
	_chip().pressed.emit()
	await wait_process_frames(2)
	assert_eq(_app.stack().current_route(), Router.PROFILE)
	assert_eq(_app.stack().depth(), 2, "empilha sobre o lobby: Esc volta")
	var screen := _app.stack().current() as ProfileScreen
	assert_eq(screen.mode(), ProfileScreen.Mode.EDIT)
	assert_eq(screen.nickname_field().text, "RodReis")
	assert_false(screen.nickname_field().editable, "nickname ja definido nao se troca")


func test_chip_nao_empilha_o_perfil_duas_vezes() -> void:
	await _login(_me("RodReis"))
	_chip().pressed.emit()
	await wait_process_frames(2)
	_chip().pressed.emit()
	await wait_process_frames(2)
	assert_eq(_app.stack().depth(), 2)


func test_trocar_o_avatar_atualiza_o_chip() -> void:
	await _login(_me("RodReis"))
	assert_false(_chip().has_avatar())
	_chip().pressed.emit()
	await wait_process_frames(2)
	var screen := _app.stack().current() as ProfileScreen
	screen.select_preset("hero:knight")
	assert_true(_chip().has_avatar())
	assert_eq(_app.avatars.choice(USER_ID), "hero:knight")


func test_concluir_no_perfil_volta_ao_lobby() -> void:
	await _login(_me("RodReis"))
	_chip().pressed.emit()
	await wait_process_frames(2)
	var screen := _app.stack().current() as ProfileScreen
	await screen.submit()
	await wait_process_frames(2)
	assert_eq(_app.stack().current_route(), Router.LOBBY)


func test_sair_da_conta_limpa_o_chip_e_o_perfil() -> void:
	await _login(_me("RodReis"))
	var lobby := _app.stack().current() as LobbyScreen
	lobby.logout_requested.emit()
	await wait_process_frames(2)
	assert_eq(_app.stack().current_route(), Router.LOGIN)
	assert_false(_chip().visible)
	assert_null(_app.profile.profile)
	assert_eq(_chip().record_label_text(), "", "o V-D da conta anterior nao fica")


func test_sessao_expirada_limpa_o_chip() -> void:
	await _login(_me("RodReis"))
	_api.unauthorized.emit()
	await wait_process_frames(1)
	assert_eq(_app.stack().current_route(), Router.LOGIN)
	assert_false(_chip().visible)
	assert_null(_app.profile.profile)


func test_historico_que_nao_carrega_apaga_o_vd_velho_do_chip() -> void:
	await _login(_me("RodReis"))
	assert_eq(_chip().record_label_text(), "14V–6D")
	_app.history.clear()
	_app.call("_refresh_record")  # sem resposta do backend: a busca falha
	await wait_process_frames(2)
	assert_eq(_chip().record_label_text(), "", "nao deixa numero velho como se fosse atual")


func test_sessao_expirada_durante_o_nickname_nao_quebra() -> void:
	await _login(_me(null))
	var screen := _app.stack().current() as ProfileScreen
	screen.nickname_field().text = "RodReis"
	_api.during_call = func(call: String) -> void:
		if call == "PUT /users/me/nickname":
			_api.unauthorized.emit()
	await screen.submit()
	await wait_process_frames(2)
	assert_eq(_app.stack().current_route(), Router.LOGIN)
	assert_null(_app.profile.profile)
