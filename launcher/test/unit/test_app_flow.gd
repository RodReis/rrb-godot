extends GutTest
## F25: fluxo do App (ARCHITECTURE-LAUNCHER §3.4, §5.2, §6) com ApiClient falso: abre no Login,
## entra no Lobby, sessao expirada volta ao Login, pareado sem executavel abandona a partida e
## mostra o erro, saida do Game fecha o overlay e trata o codigo, sair da conta.

const SCENE: PackedScene = preload("res://scenes/app.tscn")
const MATCH: String = "0b7e9f00-1111-4222-8333-444455556666"
const TOKENS: Dictionary = {"accessToken": "acesso", "refreshToken": "refresh"}

var _app: App
var _api: FakeApiClient


func before_each() -> void:
	_app = SCENE.instantiate() as App
	_api = FakeApiClient.new()
	_app.api.free()
	_app.api = _api
	_app.auth = AuthService.new(_api)
	add_child_autofree(_app)
	await wait_process_frames(1)


func _enter_lobby() -> LobbyScreen:
	_api.reply("POST /auth/login", 200, TOKENS)
	var login := _app.stack().current() as LoginScreen
	login.email_field().text = "duelista@rrb.dev"
	login.password_field().text = "senha1234"
	await login.submit()
	return _app.stack().current() as LobbyScreen


func test_sem_sessao_abre_no_login() -> void:
	assert_eq(_app.stack().current_route(), Router.LOGIN)


func test_login_leva_ao_lobby_como_raiz() -> void:
	var lobby := await _enter_lobby()
	assert_not_null(lobby)
	assert_eq(_app.stack().depth(), 1)
	assert_eq(_app.account_email, "duelista@rrb.dev")


func test_sessao_expirada_volta_ao_login() -> void:
	await _enter_lobby()
	_api.unauthorized.emit()
	assert_eq(_app.stack().current_route(), Router.LOGIN)
	assert_eq(_app.account_email, "")


func test_pareado_sem_executavel_abandona_e_mostra_erro() -> void:
	var lobby := await _enter_lobby()
	_api.reply("POST /matches/%s/abandon" % MATCH, 204)
	var assignment := MatchAssignment.from_dict({"host": "127.0.0.1", "port": 7001, "token": "t"})
	_app.queue.matched.emit(MATCH, assignment)
	await wait_process_frames(1)
	assert_true(_api.calls.has("POST /matches/%s/abandon" % MATCH))
	assert_eq(lobby.queue_state(), LobbyScreen.QueueState.ERROR)
	assert_string_contains(lobby.banner_text(), "Instalação incompleta")
	assert_false(_app.match_overlay().visible)
	assert_push_warning("ausente")


func test_saida_do_game_fecha_o_overlay_e_destrava() -> void:
	var lobby := await _enter_lobby()
	_app.match_overlay().open(false)
	_app.stack().locked = true
	_app.game.exited.emit(0)
	assert_false(_app.match_overlay().visible)
	assert_false(_app.stack().locked)
	assert_eq(lobby.queue_state(), LobbyScreen.QueueState.IDLE)


func test_encerrar_pelo_overlay_pede_confirmacao_e_nao_acusa_erro() -> void:
	await _enter_lobby()
	_app.match_overlay().open(false)
	_app.match_overlay().end_requested.emit()
	await wait_process_frames(2)
	var modal := _app.find_children("*", "ModalDialog", true, false)[0] as ModalDialog
	assert_true(modal.visible, "confirma antes de matar o processo")
	modal.buttons()[1].pressed.emit()
	await wait_process_frames(2)
	_app.game.exited.emit(GameProcess.KILLED)
	var toast := _app.find_children("*", "Toast", true, false)[0] as Toast
	var texts := toast.find_children("*", "Label", true, false).map(
		func(label: Label) -> String: return label.text
	)
	assert_true(texts.has("Jogo encerrado."), str(texts))
	assert_false(_app.match_overlay().visible)


func test_sair_da_conta_volta_ao_login() -> void:
	var lobby := await _enter_lobby()
	lobby.logout_requested.emit()
	await wait_process_frames(1)
	assert_eq(_app.stack().current_route(), Router.LOGIN)
	assert_false(_app.auth.is_logged_in())


func test_status_do_backend_vem_do_health() -> void:
	_api.reply("GET /health", 200, {"status": "ok"})
	await _app.check_backend()
	var bar := _app.find_children("*", "AppBar", true, false)[0] as AppBar
	assert_string_contains(bar.backend_status_text(), "ONLINE")
