# gdlint: ignore=max-public-methods
extends GutTest
## F25: fluxo do App (ARCHITECTURE-LAUNCHER §3.4, §5.2, §6) com ApiClient falso: abre no Login,
## entra no Lobby, sessao expirada volta ao Login, pareado sem executavel abandona a partida e
## mostra o erro, saida do Game fecha o overlay e trata o codigo, sair da conta. F70: o fim normal
## de uma partida online volta ao lobby com o card "Resultado da partida" (espera a partida no
## GET /matches, 3 tentativas); treino e codigo 3 nao abrem o card.

const SCENE: PackedScene = preload("res://scenes/app.tscn")
const MATCH: String = "0b7e9f00-1111-4222-8333-444455556666"
## Minimo do splash nos testes (o do produto e 3 s).
const SPLASH_MIN_TEST: float = 0.3
const TOKENS: Dictionary = {"accessToken": "acesso", "refreshToken": "refresh"}
const ME: Dictionary = {
	"id": "9c2d1a77-aaaa-4bbb-8ccc-ddddeeeeffff",
	"email": "duelista@rrb.dev",
	"nickname": "RodReis",
	"createdAt": "2026-10-15T12:00:00.000Z",
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
	_app.avatars = AvatarStore.new("user://test_app_avatars/")
	_app.splash_min_seconds = SPLASH_MIN_TEST
	add_child_autofree(_app)
	await wait_process_frames(1)


## GET /matches?mine=1 com a partida MATCH (ou sem ela, se `with_match` for falso).
func _history_json(with_match: bool, wins: int = 1, losses: int = 0) -> Dictionary:
	var matches: Array = []
	if with_match:
		(
			matches
			. append(
				{
					"matchId": MATCH,
					"result": "win",
					"playedAt": "2026-10-16T12:10:00.000Z",
					"endReason": "kill_goal",
					"durationS": 508,
					"me":
					{
						"heroId": "knight",
						"kills": 5,
						"finalLevel": 9,
						"deaths": 3,
						"bossKill": false,
						"setActive": null,
					},
					"opponent":
					{"heroId": "ranger", "kills": 3, "finalLevel": 8, "nickname": "Rival"},
				}
			)
		)
	return {"totals": {"wins": wins, "losses": losses}, "matches": matches}


## Fim da partida online MATCH com o Game saindo com `code`; sem espera entre as tentativas.
func _end_online_match(code: int = GameProcess.EXIT_NORMAL) -> void:
	_app.result_retry_seconds = 0.0
	_app.set(&"_match_id", MATCH)  # partida online aberta (o launch real nao existe no teste)
	_app.game.exited.emit(code)


func _wait_result_card() -> MatchResultCard:
	var card := _app.result_card()
	await wait_until(
		func() -> bool: return card.state() in [StateBox.State.READY, StateBox.State.ERROR], 3.0
	)
	return card


func _enter_lobby() -> LobbyScreen:
	_api.reply("POST /auth/login", 200, TOKENS)
	_api.reply("GET /users/me", 200, ME)
	var login := _app.stack().current() as LoginScreen
	login.email_field().text = "duelista@rrb.dev"
	login.password_field().text = "senha1234"
	await login.submit()
	await wait_process_frames(1)
	return _app.stack().current() as LobbyScreen


func test_sem_sessao_abre_no_login() -> void:
	assert_eq(_app.stack().current_route(), Router.LOGIN)
	var bar := _app.find_children("*", "AppBar", true, false)[0] as AppBar
	assert_false(bar.brand_visible(), "no Login a marca fica so no meio da tela")


func test_login_leva_ao_lobby_como_raiz() -> void:
	var lobby := await _enter_lobby()
	assert_not_null(lobby)
	assert_eq(_app.stack().depth(), 1)
	var bar := _app.find_children("*", "AppBar", true, false)[0] as AppBar
	assert_true(bar.brand_visible())
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


## #233: o chip mostra o ping da conexao aberta (nao o tempo de uma chamada com DNS e TLS) e o menor
## das ultimas amostras; backend fora some com o numero.
func test_chip_mostra_o_ping_da_conexao_aberta() -> void:
	_api.reply("GET /health", 200, {"status": "ok"})
	await _app.check_backend()
	var bar := _app.find_children("*", "AppBar", true, false)[0] as AppBar
	assert_string_contains(bar.backend_status_text(), "%d ms" % FakeApiClient.FAKE_PING_MS)


func test_backend_fora_tira_o_ping_do_chip() -> void:
	await _app.check_backend()  # sem resposta de /health
	var bar := _app.find_children("*", "AppBar", true, false)[0] as AppBar
	assert_false(bar.backend_status_text().contains(" ms"))
	assert_false(bar.backend_status_text().contains("ONLINE"))


func test_splash_espera_o_minimo_mesmo_com_o_backend_ja_respondido() -> void:
	# A checagem do _ready ja voltou (before_each), mas o minimo do splash ainda nao passou.
	var splash := _app.find_children("*", "BootSplash", true, false)[0] as BootSplash
	assert_false(splash.is_dismissed())
	await wait_seconds(SPLASH_MIN_TEST + 0.1)
	assert_true(splash.is_dismissed())
	await wait_seconds(BootSplash.FADE_SECONDS + 0.3)
	assert_eq(_app.find_children("*", "BootSplash", true, false).size(), 0)
	await _app.check_backend()  # splash ja liberado: a checagem a cada 10 s nao pode quebrar
	assert_not_null(_app.stack().current())


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
	assert_eq(screen.canvas().pins().size(), 25)


func test_menu_do_topo_abre_a_tela_herois_com_o_catalogo() -> void:
	await _enter_lobby()
	var bar := _app.find_children("*", "AppBar", true, false)[0] as AppBar
	bar.navigate_requested.emit(Router.HEROES)
	await wait_process_frames(2)
	assert_eq(_app.stack().current_route(), Router.HEROES)
	var screen := _app.stack().current() as HeroesScreen
	assert_eq(screen.state(), StateBox.State.READY)
	assert_eq(screen.cards().size(), 10)


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


func test_fim_normal_online_volta_ao_lobby_com_o_card_do_resultado() -> void:
	await _enter_lobby()
	_api.reply("GET /matches?mine=1", 200, _history_json(true, 3, 2))
	_end_online_match()
	var card := await _wait_result_card()
	assert_eq(_app.stack().current_route(), Router.LOBBY)
	assert_eq(_app.stack().depth(), 1, "sem Historico empilhado")
	assert_true(card.visible)
	assert_eq(card.state(), StateBox.State.READY)
	assert_eq(card.result(), MatchCard.WIN)


func test_card_atualiza_o_vd_do_chip_do_cabecalho() -> void:
	await _enter_lobby()
	_api.reply("GET /matches?mine=1", 200, _history_json(true, 3, 2))
	_end_online_match()
	await _wait_result_card()
	var bar := _app.find_children("*", "AppBar", true, false)[0] as AppBar
	assert_eq(bar.profile_chip().record_label_text(), "3V–2D")


func test_partida_que_demora_2_s_aparece() -> void:
	await _enter_lobby()
	var base := _api.calls.count("GET /matches?mine=1")
	_api.reply("GET /matches?mine=1", 200, _history_json(false, 0, 0))
	_api.reply("GET /matches?mine=1", 200, _history_json(false, 0, 0))
	_api.reply("GET /matches?mine=1", 200, _history_json(true))
	_end_online_match()
	var card := await _wait_result_card()
	assert_eq(card.state(), StateBox.State.READY)
	assert_eq(_api.calls.count("GET /matches?mine=1"), base + 3)


func test_partida_que_nao_aparece_em_3_tentativas_mostra_o_erro() -> void:
	await _enter_lobby()
	var base := _api.calls.count("GET /matches?mine=1")
	for i: int in 3:
		_api.reply("GET /matches?mine=1", 200, _history_json(false, 0, 0))
	_end_online_match()
	var card := await _wait_result_card()
	assert_eq(card.state(), StateBox.State.ERROR)
	assert_eq(_api.calls.count("GET /matches?mine=1"), base + 3, "3 tentativas, nem mais")
	assert_eq(_app.stack().current_route(), Router.LOBBY)


func test_backend_fora_ao_buscar_o_resultado_mostra_o_erro() -> void:
	await _enter_lobby()
	_end_online_match()  # sem resposta nenhuma: backend fora
	var card := await _wait_result_card()
	assert_eq(card.state(), StateBox.State.ERROR)


func test_fim_normal_descarta_o_cache_para_a_partida_nova_aparecer() -> void:
	await _enter_lobby()
	_api.reply("GET /matches?mine=1", 200, _history_json(false, 0, 0))
	await _app.history.fetch()
	assert_not_null(_app.history.history)
	_api.reply("GET /matches?mine=1", 200, _history_json(true))
	_end_online_match()
	var card := await _wait_result_card()
	assert_eq(card.state(), StateBox.State.READY, "buscou de novo em vez de usar o cache velho")


func test_fim_normal_do_treino_volta_ao_lobby_sem_card() -> void:
	await _enter_lobby()
	var base := _api.calls.count("GET /matches?mine=1")  # o chip do cabecalho busca o V-D (F35)
	_app.game.exited.emit(GameProcess.EXIT_NORMAL)
	await wait_process_frames(3)
	assert_eq(_app.stack().current_route(), Router.LOBBY)
	assert_false(_app.result_card().visible)
	assert_eq(_api.calls.count("GET /matches?mine=1"), base, "treino nao grava partida: nada novo")


func test_resultado_nao_reportado_nao_abre_o_card() -> void:
	await _enter_lobby()
	_end_online_match(GameProcess.EXIT_RESULT_NOT_REPORTED)
	await wait_process_frames(3)
	assert_false(_app.result_card().visible, "o aviso do codigo 3 e separado do card")


func test_fim_com_outra_tela_aberta_volta_ao_lobby() -> void:
	await _enter_lobby()
	_app.stack().push(Router.BESTIARY)
	await wait_process_frames(2)
	_api.reply("GET /matches?mine=1", 200, _history_json(true))
	_end_online_match()
	await _wait_result_card()
	assert_eq(_app.stack().current_route(), Router.LOBBY)
	assert_eq(_app.stack().depth(), 1)


func test_jogar_de_novo_entra_na_fila_uma_vez_so() -> void:
	var lobby := await _enter_lobby()
	_api.reply("GET /matches?mine=1", 200, _history_json(true))
	_end_online_match()
	var card := await _wait_result_card()
	_api.reply(
		"POST /queue",
		201,
		{"id": "t1", "status": "searching", "createdAt": "2026-10-15T12:00:00.000Z"}
	)
	card.play_again_button().pressed.emit()
	card.play_again_button().pressed.emit()
	await wait_process_frames(3)
	assert_eq(_api.calls.count("POST /queue"), 1)
	assert_false(card.visible, "o card fecha ao entrar na fila")
	assert_true(_app.queue.is_searching())
	assert_eq(lobby.queue_state(), LobbyScreen.QueueState.SEARCHING)


func test_ver_historico_fecha_o_card_e_abre_o_historico() -> void:
	await _enter_lobby()
	_api.reply("GET /matches?mine=1", 200, _history_json(true))
	_end_online_match()
	var card := await _wait_result_card()
	card.history_button().pressed.emit()
	await wait_process_frames(3)
	assert_false(card.visible)
	assert_eq(_app.stack().current_route(), Router.HISTORY)
	assert_eq(_app.stack().depth(), 2, "o lobby continua embaixo")


func test_erro_leva_ao_historico_tambem() -> void:
	await _enter_lobby()
	_end_online_match()
	var card := await _wait_result_card()
	card.history_button().pressed.emit()
	await wait_process_frames(3)
	assert_eq(_app.stack().current_route(), Router.HISTORY)


func test_tentar_de_novo_do_erro_busca_a_partida_outra_vez() -> void:
	await _enter_lobby()
	_end_online_match()
	var card := await _wait_result_card()
	assert_eq(card.state(), StateBox.State.ERROR)
	_api.reply("GET /matches?mine=1", 200, _history_json(true))
	card.retry_requested.emit()
	await wait_until(func() -> bool: return card.state() == StateBox.State.READY, 3.0)
	assert_eq(card.result(), MatchCard.WIN)


func test_esc_no_carregando_nao_deixa_o_card_reabrir_depois() -> void:
	await _enter_lobby()
	_api.reply("GET /matches?mine=1", 200, _history_json(true))
	_end_online_match()
	_app.result_card().close()  # o jogador fechou enquanto a partida ainda era buscada
	await wait_process_frames(5)
	assert_false(_app.result_card().visible)


func test_sair_da_conta_fecha_o_card() -> void:
	var lobby := await _enter_lobby()
	_api.reply("GET /matches?mine=1", 200, _history_json(true))
	_end_online_match()
	await _wait_result_card()
	lobby.logout_requested.emit()
	await wait_process_frames(2)
	assert_false(_app.result_card().visible)
	assert_eq(_app.stack().current_route(), Router.LOGIN)


func test_sessao_expirada_fecha_o_card() -> void:
	await _enter_lobby()
	_api.reply("GET /matches?mine=1", 200, _history_json(true))
	_end_online_match()
	await _wait_result_card()
	_api.unauthorized.emit()
	assert_false(_app.result_card().visible)
