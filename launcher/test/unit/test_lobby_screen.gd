# gdlint: ignore=max-public-methods
extends GutTest
## F25: tela do Lobby (FRONTEND-LAUNCHER §3, §8; ARCHITECTURE-LAUNCHER §3.4-§3.5) com a fila sobre
## ApiClient falso: estados do console (pronto, procurando com relogio, pareado, erro com tentar
## de novo), cancelar, dados do heroi vindos de shared/data e o diorama a 30 fps que para sem foco.

const SCENE: PackedScene = preload("res://scenes/screens/lobby.tscn")
const TICKET: String = "6f1c2a52-8c1e-4d47-9d10-0a2f3b4c5d6e"
const MATCH: String = "0b7e9f00-1111-4222-8333-444455556666"
const TICKET_JSON: Dictionary = {
	"id": TICKET, "status": "searching", "createdAt": "2026-10-15T12:00:00.000Z"
}

var _api: FakeApiClient
var _queue: QueueService
var _lobby: LobbyScreen


func before_each() -> void:
	_api = FakeApiClient.new()
	add_child_autofree(_api)
	_queue = QueueService.new()
	_queue.api = _api
	add_child_autofree(_queue)
	_lobby = SCENE.instantiate() as LobbyScreen
	add_child_autofree(_lobby)
	_lobby.bind(_queue, "duelista@rrb.dev")
	watch_signals(_lobby)


func _labels_with(text: String) -> Array:
	return _lobby.find_children("*", "Label", true, false).filter(
		func(label: Label) -> bool: return label.visible and label.text.contains(text)
	)


func test_comeca_pronto_com_buscar_partida() -> void:
	assert_eq(_lobby.queue_state(), LobbyScreen.QueueState.IDLE)
	assert_string_contains(_lobby.cta().text, "BUSCAR PARTIDA")
	assert_eq(_lobby.cta().variant, CtaButton.Variant.GOLD)
	assert_eq(_labels_with("PRONTO").size(), 1)


func test_buscar_vira_cancelar_e_o_relogio_anda() -> void:
	_api.reply("POST /queue", 201, TICKET_JSON)
	await _lobby.toggle_queue()
	assert_eq(_lobby.queue_state(), LobbyScreen.QueueState.SEARCHING)
	assert_string_contains(_lobby.cta().text, "CANCELAR FILA")
	assert_eq(_lobby.cta().variant, CtaButton.Variant.DANGER)
	_queue.searching.emit(75)
	assert_eq(_labels_with("01:15").size(), 2, "celula NA FILA e faixa")


func test_cancelar_volta_ao_pronto() -> void:
	_api.reply("POST /queue", 201, TICKET_JSON)
	await _lobby.toggle_queue()
	_api.reply("DELETE /queue/" + TICKET, 204)
	await _lobby.toggle_queue()
	assert_eq(_lobby.queue_state(), LobbyScreen.QueueState.IDLE)
	assert_string_contains(_lobby.cta().text, "BUSCAR PARTIDA")


func test_pareado_trava_o_botao_e_avisa() -> void:
	_api.reply("POST /queue", 201, TICKET_JSON)
	await _lobby.toggle_queue()
	var assignment := MatchAssignment.from_dict({"host": "h", "port": 7001, "token": "t"})
	_queue.matched.emit(MATCH, assignment)
	assert_eq(_lobby.queue_state(), LobbyScreen.QueueState.MATCHED)
	assert_true(_lobby.cta().disabled)
	assert_string_contains(_lobby.banner_text(), "Oponente encontrado")


func test_backend_fora_mostra_erro_e_tentar_de_novo_entra_na_fila() -> void:
	await _lobby.toggle_queue()
	assert_eq(_lobby.queue_state(), LobbyScreen.QueueState.ERROR)
	assert_string_contains(_lobby.banner_text(), "fora do ar")
	_api.reply("POST /queue", 201, TICKET_JSON)
	await _lobby.toggle_queue()
	assert_eq(_lobby.queue_state(), LobbyScreen.QueueState.SEARCHING)


func test_servidor_no_console_e_real() -> void:
	assert_eq(_labels_with("—").size(), 1, "antes da 1a checagem")
	_lobby.set_backend_status(true, 24)
	assert_eq(_labels_with("24 ms").size(), 1)
	_lobby.set_backend_status(false, -1)
	assert_eq(_labels_with("OFFLINE").size(), 1)


func test_heroi_e_regras_vem_de_shared_data() -> void:
	var knight := load("res://shared/data/heroes/knight.tres") as HeroData
	assert_eq(_labels_with(knight.display_name.to_upper()).size(), 1)
	assert_eq(_labels_with(knight.summary).size(), 1)
	var rules := load("res://shared/data/rules/match_pacing.tres") as MatchRules
	var minutes := roundi(rules.max_match_duration / 60.0)
	assert_eq(_labels_with("limite de %d minutos" % minutes).size(), 1)


func test_conta_e_sair() -> void:
	assert_eq(_labels_with("duelista@rrb.dev").size(), 1)
	var logout := _lobby.find_children("*", "Button", true, false).filter(
		func(button: Button) -> bool: return button.text.contains("Sair")
	)
	(logout[0] as Button).pressed.emit()
	assert_signal_emitted(_lobby, "logout_requested")


func test_diorama_desenha_visivel_e_para_sem_foco() -> void:
	await wait_process_frames(1)
	var diorama := _lobby.diorama()
	assert_true(diorama.is_running())
	diorama.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_false(diorama.is_running())
	diorama.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	assert_true(diorama.is_running())
	_lobby.visible = false
	assert_false(diorama.is_running())


func test_versao_nova_barra_a_fila_e_pede_atualizacao() -> void:
	_lobby.set_update_required("v0.3.0")
	_api.reply("POST /queue", 201, TICKET_JSON)
	await _lobby.toggle_queue()
	assert_does_not_have(_api.calls, "POST /queue", "nem chega ao backend")
	assert_signal_emitted(_lobby, "update_requested")
	assert_eq(_lobby.queue_state(), LobbyScreen.QueueState.ERROR)
	assert_string_contains(_lobby.banner_text(), "v0.3.0")


func test_backend_recusa_versao_velha_com_mensagem_propria() -> void:
	_api.reply("POST /queue", 426, {"code": "CLIENT_OUTDATED", "message": "Atualize"})
	await _lobby.toggle_queue()
	assert_string_contains(_lobby.banner_text(), "versão nova")


func test_backend_recusa_versao_velha_no_itch_manda_atualizar_pelo_app_do_itch() -> void:
	_lobby.channel = BuildInfo.CHANNEL_ITCH
	_api.reply("POST /queue", 426, {"code": "CLIENT_OUTDATED", "message": "Atualize"})
	await _lobby.toggle_queue()
	assert_string_contains(_lobby.banner_text(), "itch.io")
	assert_false(_lobby.banner_text().contains("Setup"), "o itch nao oferece o instalador")


func test_backend_recusa_versao_velha_no_site_nao_cita_o_itch() -> void:
	_api.reply("POST /queue", 426, {"code": "CLIENT_OUTDATED", "message": "Atualize"})
	await _lobby.toggle_queue()
	assert_false(_lobby.banner_text().contains("itch.io"))


func _level_buttons() -> Array:
	return _lobby.find_children("*", "Button", true, false).filter(
		func(b: Button) -> bool: return ["Fácil", "Médio", "Difícil"].has(b.text)
	)


func _levels_visible() -> bool:
	return _level_buttons().all(func(b: Button) -> bool: return b.is_visible_in_tree())


func test_jogar_nao_mostra_nivel_do_bot_nem_botao_iniciar() -> void:
	assert_eq(_lobby.mode(), LobbyScreen.Mode.PLAY)
	assert_false(_levels_visible())
	var iniciar := _lobby.find_children("*", "Button", true, false).filter(
		func(b: Button) -> bool: return b.text == "Iniciar"
	)
	assert_eq(iniciar.size(), 0, "o botao azul Iniciar saiu; vale o amarelo")


func test_aba_treino_mostra_niveis_e_o_amarelo_inicia_o_treino() -> void:
	_lobby.select_mode(LobbyScreen.Mode.TRAIN)
	assert_true(_levels_visible())
	assert_eq(
		_level_buttons().map(func(b: Button) -> String: return b.text),
		["Fácil", "Médio", "Difícil"]
	)
	assert_eq(_lobby.bot_difficulty(), 2)
	assert_true((_level_buttons()[1] as Button).button_pressed)
	assert_string_contains(_lobby.cta().text, "INICIAR TREINO")
	assert_eq(_lobby.cta().variant, CtaButton.Variant.GOLD)
	_lobby.cta().pressed.emit()
	assert_signal_emitted(_lobby, "practice_requested")
	assert_eq(_lobby.queue_state(), LobbyScreen.QueueState.IDLE, "treino nao entra na fila")
	assert_eq(_api.calls.size(), 0)


func test_voltar_para_jogar_restaura_o_botao_da_fila() -> void:
	_lobby.select_mode(LobbyScreen.Mode.TRAIN)
	_lobby.select_mode(LobbyScreen.Mode.PLAY)
	assert_string_contains(_lobby.cta().text, "BUSCAR PARTIDA")
	assert_false(_levels_visible())


func test_escolher_nivel_avisa_e_nao_inicia_o_treino() -> void:
	_lobby.select_mode(LobbyScreen.Mode.TRAIN)
	(_level_buttons()[2] as Button).pressed.emit()
	assert_signal_emitted_with_parameters(_lobby, "bot_difficulty_changed", [3])
	assert_signal_not_emitted(_lobby, "practice_requested")
	assert_eq(_lobby.bot_difficulty(), 3)


func test_bind_do_nivel_lembrado_marca_sem_avisar() -> void:
	_lobby.bind_bot_difficulty(1)
	assert_eq(_lobby.bot_difficulty(), 1)
	assert_true((_level_buttons()[0] as Button).button_pressed)
	assert_signal_not_emitted(_lobby, "bot_difficulty_changed")


## F85 (SPEC-085 §4): botao Tutorial e fila bloqueada ate o tutorial ou a vitoria contra o bot.
func _buttons_with(text: String) -> Array:
	return _lobby.find_children("*", "Button", true, false).filter(
		func(b: Button) -> bool: return b.is_visible_in_tree() and b.text.contains(text)
	)


func test_botao_tutorial_no_submenu_avisa_o_app() -> void:
	var buttons := _buttons_with("TUTORIAL")
	assert_eq(buttons.size(), 1)
	(buttons[0] as Button).pressed.emit()
	assert_signal_emitted(_lobby, "tutorial_requested")
	assert_eq(_lobby.queue_state(), LobbyScreen.QueueState.IDLE, "tutorial nao entra na fila")


func test_fila_nasce_liberada_e_so_o_app_bloqueia() -> void:
	assert_false(_lobby.queue_locked())


func test_fila_bloqueada_mostra_o_motivo_e_nao_chama_a_rede() -> void:
	_lobby.set_queue_locked(true)
	_api.reply("POST /queue", 201, TICKET_JSON)
	await _lobby.toggle_queue()
	assert_does_not_have(_api.calls, "POST /queue", "nem chega ao backend")
	assert_eq(_lobby.queue_state(), LobbyScreen.QueueState.ERROR)
	assert_string_contains(_lobby.banner_text(), "tutorial")
	assert_string_contains(_lobby.banner_text(), "bot")


func test_fila_bloqueada_oferece_tutorial_e_treino() -> void:
	_lobby.set_queue_locked(true)
	assert_eq(_buttons_with("Fazer tutorial").size(), 0, "so aparecem com o aviso")
	await _lobby.toggle_queue()
	assert_eq(_buttons_with("Fazer tutorial").size(), 1)
	assert_eq(_buttons_with("Treinar contra bot").size(), 1)
	assert_eq(_buttons_with("Tentar de novo").size(), 0, "tentar de novo nao adianta")


func test_fazer_tutorial_do_aviso_avisa_o_app() -> void:
	_lobby.set_queue_locked(true)
	await _lobby.toggle_queue()
	(_buttons_with("Fazer tutorial")[0] as Button).pressed.emit()
	assert_signal_emitted(_lobby, "tutorial_requested")


func test_treinar_contra_bot_do_aviso_abre_a_aba_de_treino_e_limpa_o_aviso() -> void:
	_lobby.set_queue_locked(true)
	await _lobby.toggle_queue()
	(_buttons_with("Treinar contra bot")[0] as Button).pressed.emit()
	assert_eq(_lobby.mode(), LobbyScreen.Mode.TRAIN)
	assert_eq(_lobby.queue_state(), LobbyScreen.QueueState.IDLE)
	assert_eq(_lobby.banner_text(), "")
	assert_eq(_buttons_with("Fazer tutorial").size(), 0)
	assert_signal_not_emitted(_lobby, "practice_requested", "escolhe o nivel antes de iniciar")


func test_treino_continua_liberado_com_a_fila_bloqueada() -> void:
	_lobby.set_queue_locked(true)
	_lobby.select_mode(LobbyScreen.Mode.TRAIN)
	_lobby.cta().pressed.emit()
	assert_signal_emitted(_lobby, "practice_requested")


func test_liberar_a_fila_tira_o_aviso_e_volta_ao_fluxo_normal() -> void:
	_lobby.set_queue_locked(true)
	await _lobby.toggle_queue()
	_lobby.set_queue_locked(false)
	assert_eq(_lobby.queue_state(), LobbyScreen.QueueState.IDLE)
	assert_eq(_buttons_with("Fazer tutorial").size(), 0)
	_api.reply("POST /queue", 201, TICKET_JSON)
	await _lobby.toggle_queue()
	assert_eq(_lobby.queue_state(), LobbyScreen.QueueState.SEARCHING)


func test_liberar_a_fila_nao_apaga_outro_erro() -> void:
	await _lobby.toggle_queue()  # backend fora
	_lobby.set_queue_locked(false)
	assert_eq(_lobby.queue_state(), LobbyScreen.QueueState.ERROR)
	assert_string_contains(_lobby.banner_text(), "fora do ar")


func test_backend_recusa_fila_bloqueada_com_a_mesma_mensagem() -> void:
	_api.reply("POST /queue", 403, {"code": "QUEUE_LOCKED", "message": "Bloqueada"})
	await _lobby.toggle_queue()
	assert_eq(_lobby.queue_state(), LobbyScreen.QueueState.ERROR)
	assert_string_contains(_lobby.banner_text(), "tutorial")
	assert_eq(_buttons_with("Fazer tutorial").size(), 1)
	assert_true(_lobby.queue_locked(), "o proximo clique nem chama o backend")
