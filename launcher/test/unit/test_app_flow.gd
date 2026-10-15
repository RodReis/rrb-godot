# gdlint: ignore=max-public-methods
extends GutTest
## F25: fluxo do App (ARCHITECTURE-LAUNCHER §3.4, §5.2, §6) com ApiClient falso: abre no Login,
## entra no Lobby, sessao expirada volta ao Login, pareado sem executavel abandona a partida e
## mostra o erro, saida do Game fecha o overlay e trata o codigo, sair da conta. F26: o fim normal
## de uma partida online abre o Historico; treino e codigo 3 nao.

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
	_app.history = HistoryService.new(_api)
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


func test_treinar_durante_a_busca_sai_da_fila() -> void:
	var lobby := await _enter_lobby()
	_api.reply(
		"POST /queue",
		201,
		{"id": "t1", "status": "searching", "createdAt": "2026-10-15T12:00:00.000Z"}
	)
	await lobby.toggle_queue()
	assert_true(_app.queue.is_searching())
	_api.reply("DELETE /queue/t1", 204)
	lobby.practice_requested.emit()
	await wait_process_frames(1)
	assert_true(_api.calls.has("DELETE /queue/t1"))
	assert_false(_app.queue.is_searching())
	assert_eq(lobby.queue_state(), LobbyScreen.QueueState.IDLE)
	assert_push_warning("ausente")


func test_sessao_expirada_encerra_a_fila() -> void:
	var lobby := await _enter_lobby()
	_api.reply(
		"POST /queue",
		201,
		{"id": "t1", "status": "searching", "createdAt": "2026-10-15T12:00:00.000Z"}
	)
	await lobby.toggle_queue()
	_api.unauthorized.emit()
	assert_false(_app.queue.is_searching())


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


func test_fim_normal_de_partida_online_abre_o_historico() -> void:
	await _enter_lobby()
	_api.reply("GET /matches?mine=1", 200, {"totals": {"wins": 0, "losses": 0}, "matches": []})
	_app.set(&"_match_id", MATCH)  # partida online aberta (o launch real nao existe no teste)
	_app.game.exited.emit(GameProcess.EXIT_NORMAL)
	await wait_process_frames(2)
	assert_eq(_app.stack().current_route(), Router.HISTORY)
	assert_eq(_app.stack().depth(), 2, "o lobby continua embaixo")
	assert_true(_api.calls.has("GET /matches?mine=1"))


func test_fim_normal_descarta_o_cache_para_a_partida_nova_aparecer() -> void:
	await _enter_lobby()
	var stale := {"totals": {"wins": 0, "losses": 0}, "matches": []}
	_api.reply("GET /matches?mine=1", 200, stale)
	await _app.history.fetch()
	_api.reply("GET /matches?mine=1", 200, stale)
	_app.set(&"_match_id", MATCH)
	_app.game.exited.emit(GameProcess.EXIT_NORMAL)
	await wait_process_frames(2)
	assert_eq(_api.calls.count("GET /matches?mine=1"), 2)


func test_fim_normal_do_treino_volta_ao_lobby_sem_historico() -> void:
	await _enter_lobby()
	_app.game.exited.emit(GameProcess.EXIT_NORMAL)
	await wait_process_frames(2)
	assert_eq(_app.stack().current_route(), Router.LOBBY)
	assert_false(_api.calls.has("GET /matches?mine=1"))


func test_resultado_nao_reportado_avisa_e_fica_no_lobby() -> void:
	await _enter_lobby()
	_app.set(&"_match_id", MATCH)
	_app.game.exited.emit(GameProcess.EXIT_RESULT_NOT_REPORTED)
	await wait_process_frames(2)
	assert_eq(_app.stack().current_route(), Router.LOBBY)
	var toast := _app.find_children("*", "Toast", true, false)[0] as Toast
	var texts := toast.find_children("*", "Label", true, false).map(
		func(label: Label) -> String: return label.text
	)
	assert_true(texts.any(func(text: String) -> bool: return text.contains("pode demorar")))


func test_menu_do_topo_abre_o_historico() -> void:
	await _enter_lobby()
	_api.reply("GET /matches?mine=1", 200, {"totals": {"wins": 0, "losses": 0}, "matches": []})
	var bar := _app.find_children("*", "AppBar", true, false)[0] as AppBar
	bar.navigate_requested.emit(Router.HISTORY)
	await wait_process_frames(2)
	assert_eq(_app.stack().current_route(), Router.HISTORY)


func test_menu_do_topo_abre_o_guia_com_o_catalogo() -> void:
	await _enter_lobby()
	var bar := _app.find_children("*", "AppBar", true, false)[0] as AppBar
	bar.navigate_requested.emit(Router.BESTIARY)
	await wait_process_frames(2)
	assert_eq(_app.stack().current_route(), Router.BESTIARY)
	var screen := _app.stack().current() as BestiaryScreen
	assert_eq(screen.state(), StateBox.State.READY)
	assert_eq(screen.cards().size(), 6)


func test_menu_do_topo_abre_arena_e_mapa_com_o_catalogo() -> void:
	await _enter_lobby()
	var bar := _app.find_children("*", "AppBar", true, false)[0] as AppBar
	bar.navigate_requested.emit(Router.ARENA_MAP)
	await wait_process_frames(2)
	assert_eq(_app.stack().current_route(), Router.ARENA_MAP)
	var screen := _app.stack().current() as ArenaMapScreen
	assert_eq(screen.state(), StateBox.State.READY)
	assert_eq(screen.canvas().pins().size(), 21)


func test_aba_arena_do_guia_troca_a_tela_sem_empilhar() -> void:
	await _enter_lobby()
	_app.stack().push(Router.BESTIARY)
	await wait_process_frames(2)
	(_app.stack().current() as BestiaryScreen).navigate_requested.emit(Router.ARENA_MAP)
	await wait_process_frames(2)
	assert_eq(_app.stack().current_route(), Router.ARENA_MAP)
	assert_eq(_app.stack().depth(), 2, "troca a do topo")


func test_treino_da_arena_e_mapa_sai_da_fila_como_o_do_lobby() -> void:
	var lobby := await _enter_lobby()
	_api.reply(
		"POST /queue",
		201,
		{"id": "t1", "status": "searching", "createdAt": "2026-10-15T12:00:00.000Z"}
	)
	await lobby.toggle_queue()
	_app.stack().push(Router.ARENA_MAP)
	await wait_process_frames(2)
	_api.reply("DELETE /queue/t1", 204)
	(_app.stack().current() as ArenaMapScreen).practice_requested.emit()
	await wait_process_frames(1)
	assert_true(_api.calls.has("DELETE /queue/t1"))
	assert_false(_app.queue.is_searching())
	assert_push_warning("ausente")


func test_aba_da_forja_troca_a_tela_sem_empilhar() -> void:
	await _enter_lobby()
	_app.stack().push(Router.BESTIARY)
	await wait_process_frames(2)
	assert_eq(_app.stack().depth(), 2)
	(_app.stack().current() as BestiaryScreen).navigate_requested.emit(Router.FORGE)
	await wait_process_frames(2)
	assert_eq(_app.stack().current_route(), Router.FORGE)
	assert_eq(_app.stack().depth(), 2, "troca a do topo")
	assert_eq((_app.stack().current() as ForgeScreen).state(), StateBox.State.READY)


func test_item_do_menu_na_forja_troca_para_o_guia_e_o_mesmo_item_nao_recria() -> void:
	await _enter_lobby()
	_app.stack().push(Router.FORGE)
	await wait_process_frames(2)
	var bar := _app.find_children("*", "AppBar", true, false)[0] as AppBar
	bar.navigate_requested.emit(Router.BESTIARY)
	await wait_process_frames(2)
	assert_eq(_app.stack().current_route(), Router.BESTIARY)
	assert_eq(_app.stack().depth(), 2)
	var screen := _app.stack().current()
	bar.navigate_requested.emit(Router.BESTIARY)
	await wait_process_frames(2)
	assert_eq(_app.stack().current(), screen, "clicar no item ativo nao recria a tela")


func test_faixa_final_da_forja_volta_ao_lobby() -> void:
	await _enter_lobby()
	_app.stack().push(Router.FORGE)
	await wait_process_frames(2)
	(_app.stack().current() as ForgeScreen).navigate_requested.emit(Router.LOBBY)
	await wait_process_frames(2)
	assert_eq(_app.stack().current_route(), Router.LOBBY)
	assert_eq(_app.stack().depth(), 1)


func test_sair_da_conta_descarta_o_historico() -> void:
	var lobby := await _enter_lobby()
	_api.reply("GET /matches?mine=1", 200, {"totals": {"wins": 1, "losses": 0}, "matches": []})
	await _app.history.fetch()
	assert_not_null(_app.history.history)
	lobby.logout_requested.emit()
	await wait_process_frames(1)
	assert_null(_app.history.history)


func test_sessao_expirada_descarta_o_historico() -> void:
	await _enter_lobby()
	_api.reply("GET /matches?mine=1", 200, {"totals": {"wins": 1, "losses": 0}, "matches": []})
	await _app.history.fetch()
	_api.unauthorized.emit()
	assert_null(_app.history.history)


func test_saida_com_erro_de_partida_online_tambem_descarta_o_cache() -> void:
	await _enter_lobby()
	_api.reply("GET /matches?mine=1", 200, {"totals": {"wins": 0, "losses": 0}, "matches": []})
	await _app.history.fetch()
	_app.set(&"_match_id", MATCH)
	_app.game.exited.emit(GameProcess.EXIT_RESULT_NOT_REPORTED)
	assert_null(_app.history.history)


func test_fim_de_partida_com_o_historico_ja_aberto_busca_de_novo() -> void:
	await _enter_lobby()
	var empty := {"totals": {"wins": 0, "losses": 0}, "matches": []}
	_api.reply("GET /matches?mine=1", 200, empty)
	var bar := _app.find_children("*", "AppBar", true, false)[0] as AppBar
	bar.navigate_requested.emit(Router.HISTORY)
	await wait_process_frames(2)
	var old_screen := _app.stack().current()
	_api.reply("GET /matches?mine=1", 200, empty)
	_app.set(&"_match_id", MATCH)
	_app.game.exited.emit(GameProcess.EXIT_NORMAL)
	await wait_process_frames(2)
	assert_eq(_app.stack().current_route(), Router.HISTORY)
	assert_ne(_app.stack().current(), old_screen, "tela nova, com dado novo")
	assert_eq(_api.calls.count("GET /matches?mine=1"), 2)
