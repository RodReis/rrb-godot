extends GutTest
## F25: QueueService (ARCHITECTURE-LAUNCHER §3.3, §6) com ApiClient falso: entra na fila, segue o
## polling ate matched, cancela, trata ticket ja pareado, fila duplicada e backend fora.

const TICKET: String = "6f1c2a52-8c1e-4d47-9d10-0a2f3b4c5d6e"
const MATCH: String = "0b7e9f00-1111-4222-8333-444455556666"
const TICKET_JSON: Dictionary = {
	"id": TICKET, "status": "searching", "createdAt": "2026-10-15T12:00:00.000Z"
}
const ASSIGNMENT: Dictionary = {"host": "127.0.0.1", "port": 7003, "token": "tok"}

var _api: FakeApiClient
var _queue: QueueService


func before_each() -> void:
	_api = FakeApiClient.new()
	add_child_autofree(_api)
	_queue = QueueService.new()
	_queue.api = _api
	add_child_autofree(_queue)
	watch_signals(_queue)


func _join() -> void:
	_api.reply("POST /queue", 201, TICKET_JSON)
	await _queue.join()


func test_entrar_comeca_procurando_e_liga_o_polling() -> void:
	await _join()
	assert_signal_emitted_with_parameters(_queue, "searching", [0])
	assert_true(_queue.is_searching())
	assert_false(_queue.poll_timer().is_stopped())
	assert_eq(_queue.poll_timer().wait_time, QueueService.POLL_SECONDS)


func test_polling_ate_matched() -> void:
	await _join()
	_api.reply("GET /queue/" + TICKET, 200, {"status": "searching", "elapsedS": 2})
	_api.reply(
		"GET /queue/" + TICKET,
		200,
		{"status": "matched", "elapsedS": 4, "matchId": MATCH, "assignment": ASSIGNMENT}
	)
	await _queue.poll()
	assert_signal_emitted_with_parameters(_queue, "searching", [2])
	await _queue.poll()
	assert_signal_emitted(_queue, "matched")
	var params: Array = get_signal_parameters(_queue, "matched")
	assert_eq(params[0], MATCH)
	assert_eq((params[1] as MatchAssignment).port, 7003)
	assert_false(_queue.is_searching())
	assert_true(_queue.poll_timer().is_stopped())


func test_cancelar_sai_da_fila() -> void:
	await _join()
	_api.reply("DELETE /queue/" + TICKET, 204)
	await _queue.leave()
	assert_signal_emitted(_queue, "cancelled")
	assert_false(_queue.is_searching())
	assert_true(_queue.poll_timer().is_stopped())


func test_cancelar_depois_de_pareado_segue_para_a_partida() -> void:
	await _join()
	_api.reply("DELETE /queue/" + TICKET, 409, {"code": "ALREADY_MATCHED"})
	_api.reply(
		"GET /queue/" + TICKET,
		200,
		{"status": "matched", "elapsedS": 3, "matchId": MATCH, "assignment": ASSIGNMENT}
	)
	await _queue.leave()
	assert_signal_not_emitted(_queue, "cancelled")
	assert_signal_emitted(_queue, "matched")


func test_cancelar_com_backend_fora_cancela_localmente() -> void:
	await _join()
	await _queue.leave()
	assert_signal_emitted(_queue, "cancelled")


func test_conta_ja_na_fila_falha() -> void:
	_api.reply("POST /queue", 409, {"code": "ALREADY_QUEUED"})
	await _queue.join()
	assert_signal_emitted_with_parameters(_queue, "failed", ["ALREADY_QUEUED"])
	assert_false(_queue.is_searching())


func test_backend_fora_ao_entrar_falha() -> void:
	await _queue.join()
	assert_signal_emitted_with_parameters(_queue, "failed", [ApiClient.OFFLINE])


func test_uma_falha_de_rede_no_polling_nao_derruba_a_fila() -> void:
	await _join()
	await _queue.poll()
	assert_signal_not_emitted(_queue, "failed")
	assert_true(_queue.is_searching())


func test_falhas_seguidas_no_polling_encerram_a_fila() -> void:
	await _join()
	for i: int in QueueService.MAX_POLL_FAILURES:
		await _queue.poll()
	assert_signal_emitted_with_parameters(_queue, "failed", [ApiClient.OFFLINE])
	assert_false(_queue.is_searching())


func test_ticket_cancelado_pelo_servidor() -> void:
	await _join()
	_api.reply("GET /queue/" + TICKET, 200, {"status": "cancelled", "elapsedS": 12})
	await _queue.poll()
	assert_signal_emitted(_queue, "cancelled")
	assert_false(_queue.is_searching())


func test_matched_sem_servidor_e_falha() -> void:
	await _join()
	_api.reply("GET /queue/" + TICKET, 200, {"status": "matched", "elapsedS": 3, "matchId": MATCH})
	await _queue.poll()
	assert_signal_emitted_with_parameters(_queue, "failed", [QueueService.MATCH_GONE])


func test_resposta_fora_do_contrato_e_falha() -> void:
	await _join()
	_api.reply("GET /queue/" + TICKET, 200, {"status": "voando"})
	await _queue.poll()
	assert_signal_emitted_with_parameters(_queue, "failed", [ApiClient.HTTP_ERROR])
