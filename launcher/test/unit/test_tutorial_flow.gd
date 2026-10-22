# gdlint: ignore=max-public-methods
extends GutTest
## F85 (SPEC-085 §4, ADR-0029): o 1o login abre o tutorial depois do nickname; o botao Tutorial
## refaz; a fila online fica barrada no lobby ate o tutorial ou a vitoria contra o bot; ao fim do
## Game o offline_result.cfg e lido, apagado e (com sessao) enviado ao backend. ApiClient e
## GameProcess falsos.

const SCENE: PackedScene = preload("res://scenes/app.tscn")
const RESULT_PATH: String = "user://test_f85_offline_result.cfg"
const AVATAR_DIR: String = "user://test_f85_avatars/"
const TOKENS: Dictionary = {"accessToken": "acesso", "refreshToken": "refresh"}
const UNLOCK: String = "POST /users/me/queue-unlock"
const HISTORY: Dictionary = {"totals": {"wins": 0, "losses": 0}, "matches": []}
const TUTORIAL_ARGS: PackedStringArray = ["--offline", "--tutorial"]
const MATCH: String = "0b7e9f00-1111-4222-8333-444455556666"

var _app: App
var _api: FakeApiClient
var _game: FakeGameProcess


func before_each() -> void:
	_app = SCENE.instantiate() as App
	_api = FakeApiClient.new()
	_game = FakeGameProcess.new()
	_app.api.free()
	_app.api = _api
	(_app.game.get(&"_timer") as Timer).free()  # o Timer do original nunca entra na arvore
	_app.game.free()
	_app.game = _game
	_app.auth = AuthService.new(_api)
	_app.history = HistoryService.new(_api)
	_app.profile = ProfileService.new(_api)
	_app.avatars = AvatarStore.new(AVATAR_DIR)
	_app.offline_result_path = RESULT_PATH
	add_child_autofree(_app)
	await wait_process_frames(1)


func after_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RESULT_PATH))
	if DirAccess.dir_exists_absolute(AVATAR_DIR):
		for file: String in DirAccess.get_files_at(AVATAR_DIR):
			DirAccess.remove_absolute(AVATAR_DIR + file)
		DirAccess.remove_absolute(AVATAR_DIR)


func _me(nickname: Variant, unlock_reason: Variant = null) -> Dictionary:
	return {
		"id": "9c2d1a77-aaaa-4bbb-8ccc-ddddeeeeffff",
		"email": "duelista@rrb.dev",
		"nickname": nickname,
		"createdAt": "2026-10-15T12:00:00.000Z",
		"queueUnlockReason": unlock_reason,
	}


func _login(me: Dictionary) -> void:
	_api.reply("POST /auth/login", 200, TOKENS)
	_api.reply("GET /users/me", 200, me)
	_api.reply("GET /matches?mine=1", 200, HISTORY)
	var login := _app.stack().current() as LoginScreen
	login.email_field().text = "duelista@rrb.dev"
	login.password_field().text = "senha1234"
	await login.submit()
	await wait_process_frames(2)


## 1o login: define o nickname no Perfil e cai no lobby.
func _login_and_set_nickname() -> void:
	await _login(_me(null))
	var screen := _app.stack().current() as ProfileScreen
	screen.nickname_field().text = "RodReis"
	_api.reply("PUT /users/me/nickname", 200, _me("RodReis"))
	_api.reply("GET /matches?mine=1", 200, HISTORY)
	await screen.submit()
	await wait_process_frames(2)


func _lobby() -> LobbyScreen:
	return _app.stack().current() as LobbyScreen


func _toast_texts() -> Array:
	var toast := _app.find_children("*", "Toast", true, false)[0] as Toast
	return toast.find_children("*", "Label", true, false).map(
		func(label: Label) -> String: return label.text
	)


## Fim do Game com o resultado gravado pelo Game (kind/outcome); `kind` vazio = sem arquivo.
func _finish_game(kind: String, outcome: String = "") -> void:
	if not kind.is_empty():
		OfflineResult.write(kind, outcome, 2, RESULT_PATH)
	_app.game.exited.emit(GameProcess.EXIT_NORMAL)
	await wait_process_frames(3)


func test_primeiro_login_abre_o_tutorial_depois_do_nickname() -> void:
	await _login(_me(null))
	assert_eq(_game.launched.size(), 0, "ainda no Perfil: nada abre antes do nickname")
	var screen := _app.stack().current() as ProfileScreen
	screen.nickname_field().text = "RodReis"
	_api.reply("PUT /users/me/nickname", 200, _me("RodReis"))
	_api.reply("GET /matches?mine=1", 200, HISTORY)
	await screen.submit()
	await wait_process_frames(2)
	assert_eq(_app.stack().current_route(), Router.LOBBY)
	assert_eq(_game.launched, [TUTORIAL_ARGS] as Array[PackedStringArray])
	assert_true(_app.match_overlay().visible, "mesmo overlay de partida do treino")
	assert_true(_app.stack().locked)


func test_pular_o_tutorial_volta_ao_lobby_com_a_fila_bloqueada() -> void:
	await _login_and_set_nickname()
	await _finish_game("tutorial", "quit")
	assert_eq(_app.stack().current_route(), Router.LOBBY)
	assert_false(_app.match_overlay().visible)
	assert_false(_app.stack().locked)
	assert_true(_lobby().queue_locked())
	assert_eq(_game.launched.size(), 1, "o tutorial abre uma vez so")


func test_login_de_conta_com_nickname_nao_abre_o_tutorial() -> void:
	await _login(_me("RodReis"))
	assert_eq(_app.stack().current_route(), Router.LOBBY)
	assert_eq(_game.launched.size(), 0)


func test_perfil_aberto_pelo_chip_nao_abre_o_tutorial() -> void:
	await _login(_me("RodReis"))
	_app.stack().push(Router.PROFILE)
	await wait_process_frames(2)
	await (_app.stack().current() as ProfileScreen).submit()
	await wait_process_frames(2)
	assert_eq(_app.stack().current_route(), Router.LOBBY)
	assert_eq(_game.launched.size(), 0)


func test_tutorial_sem_executavel_mostra_o_erro_como_no_treino() -> void:
	_game.launch_result = -1
	await _login(_me("RodReis"))
	_lobby().tutorial_requested.emit()
	await wait_process_frames(2)
	assert_eq(_game.launched.size(), 1)
	assert_true(_toast_texts().has("Instalação incompleta: o jogo não foi encontrado."))
	assert_false(_app.match_overlay().visible)


func test_botao_tutorial_do_lobby_abre_o_tutorial() -> void:
	await _login(_me("RodReis", "history"))
	_lobby().tutorial_requested.emit()
	await wait_process_frames(2)
	assert_eq(_game.launched, [TUTORIAL_ARGS] as Array[PackedStringArray])
	assert_true(_app.match_overlay().visible)


func test_tutorial_sai_da_fila_antes() -> void:
	await _login(_me("RodReis", "history"))
	_api.reply(
		"POST /queue",
		201,
		{"id": "t1", "status": "searching", "createdAt": "2026-10-15T12:00:00.000Z"}
	)
	await _lobby().toggle_queue()
	_api.reply("DELETE /queue/t1", 204)
	_lobby().tutorial_requested.emit()
	await wait_process_frames(2)
	assert_true(_api.calls.has("DELETE /queue/t1"))
	assert_false(_app.queue.is_searching())
	assert_eq(_game.launched.size(), 1)


func test_nao_abre_o_tutorial_com_o_jogo_rodando() -> void:
	await _login(_me("RodReis"))
	_game.running = true
	_lobby().tutorial_requested.emit()
	await wait_process_frames(2)
	assert_eq(_game.launched.size(), 0)


func test_treino_continua_liberado_com_a_fila_bloqueada() -> void:
	await _login(_me("RodReis"))
	_lobby().practice_requested.emit()
	await wait_process_frames(2)
	assert_eq(_game.launched.size(), 1)
	assert_true("--bot" in _game.launched[0])


func test_conta_bloqueada_bloqueia_a_fila_no_lobby() -> void:
	await _login(_me("RodReis"))
	assert_true(_lobby().queue_locked())
	await _lobby().toggle_queue()
	assert_does_not_have(_api.calls, "POST /queue")
	assert_eq(_lobby().queue_state(), LobbyScreen.QueueState.ERROR)
	assert_string_contains(_lobby().banner_text(), "tutorial")


func test_conta_liberada_segue_o_fluxo_antigo_da_fila() -> void:
	await _login(_me("RodReis", "history"))
	assert_false(_lobby().queue_locked())
	_api.reply(
		"POST /queue",
		201,
		{"id": "t1", "status": "searching", "createdAt": "2026-10-15T12:00:00.000Z"}
	)
	await _lobby().toggle_queue()
	assert_true(_app.queue.is_searching())


func test_lobby_reaberto_pela_pilha_reflete_a_conta() -> void:
	await _login(_me("RodReis"))
	_app.stack().push(Router.SETTINGS)
	await wait_process_frames(2)
	_app.profile.profile.queue_unlock_reason = "tutorial"  # liberou com outra tela por cima
	_app.stack().pop()
	await wait_process_frames(2)
	assert_false(_lobby().queue_locked())


func test_tutorial_concluido_libera_a_fila() -> void:
	await _login(_me("RodReis"))
	_api.reply(UNLOCK, 200, _me("RodReis", "tutorial"))
	await _finish_game("tutorial", "completed")
	assert_eq(_api.bodies[_api.calls.find(UNLOCK)], {"reason": "tutorial"})
	assert_false(FileAccess.file_exists(RESULT_PATH), "arquivo apagado")
	assert_true(_app.profile.queue_unlocked())
	assert_false(_lobby().queue_locked())
	assert_true(_toast_texts().has("Fila online liberada."))


func test_vitoria_contra_o_bot_libera_a_fila() -> void:
	await _login(_me("RodReis"))
	_api.reply(UNLOCK, 200, _me("RodReis", "bot_win"))
	await _finish_game("bot", "win")
	assert_eq(_api.bodies[_api.calls.find(UNLOCK)], {"reason": "bot_win"})
	assert_false(_lobby().queue_locked())


func test_derrota_saida_e_tutorial_pulado_nao_enviam_mas_apagam_o_arquivo() -> void:
	await _login(_me("RodReis"))
	var cases: Array[Array] = [["bot", "loss"], ["bot", "quit"], ["tutorial", "quit"]]
	for result: Array in cases:
		await _finish_game(result[0], result[1])
		assert_false(FileAccess.file_exists(RESULT_PATH), str(result))
	assert_does_not_have(_api.calls, UNLOCK)
	assert_true(_lobby().queue_locked())


func test_sem_arquivo_nao_envia() -> void:
	await _login(_me("RodReis"))
	await _finish_game("")
	assert_does_not_have(_api.calls, UNLOCK)


func test_conta_ja_liberada_nao_reenvia() -> void:
	await _login(_me("RodReis", "history"))
	await _finish_game("bot", "win")
	assert_does_not_have(_api.calls, UNLOCK)
	assert_false(FileAccess.file_exists(RESULT_PATH))


func test_sem_sessao_nao_envia_mas_apaga_o_arquivo() -> void:
	assert_eq(_app.stack().current_route(), Router.LOGIN)
	await _finish_game("bot", "win")
	assert_does_not_have(_api.calls, UNLOCK)
	assert_false(FileAccess.file_exists(RESULT_PATH))


func test_falha_ao_liberar_avisa_e_mantem_a_fila_bloqueada() -> void:
	await _login(_me("RodReis"))
	await _finish_game("tutorial", "completed")  # sem resposta: backend fora
	assert_true(_api.calls.has(UNLOCK))
	assert_true(_lobby().queue_locked())
	assert_false(FileAccess.file_exists(RESULT_PATH))
	assert_true(
		_toast_texts().any(
			func(text: String) -> bool: return text.contains("Não foi possível liberar")
		)
	)
	assert_eq(_lobby().queue_state(), LobbyScreen.QueueState.IDLE, "o app segue normal")


func test_fim_de_partida_online_segue_intacto_e_ainda_apaga_o_arquivo() -> void:
	await _login(_me("RodReis"))
	_app.result_retry_seconds = 0.0
	_app.set(&"_match_id", MATCH)
	await _finish_game("bot", "loss")
	assert_false(FileAccess.file_exists(RESULT_PATH))
	assert_eq(_app.stack().current_route(), Router.LOBBY)
	assert_false(_app.match_overlay().visible)


func test_backend_recusa_fila_bloqueada_mesmo_com_launcher_desatualizado() -> void:
	await _login(_me("RodReis", "history"))
	_api.reply("POST /queue", 403, {"code": "QUEUE_LOCKED"})
	await _lobby().toggle_queue()
	assert_string_contains(_lobby().banner_text(), "tutorial")
	assert_true(_lobby().queue_locked())
