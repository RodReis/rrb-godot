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
