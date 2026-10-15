extends GutTest

const MATCH_ID: String = "11111111-1111-4111-8111-111111111111"
const DIR: String = "user://test-results"

var _backend: FakeBackend
var _waits: Array[float] = []
var _reporter: ResultReporter


func before_each() -> void:
	_backend = FakeBackend.new()
	_waits = []
	_reporter = ResultReporter.new(_backend, _record_wait, DIR)
	_clean()


func after_each() -> void:
	_clean()


func _record_wait(seconds: float) -> void:
	_waits.append(seconds)


func _clean() -> void:
	var path := "%s/%s.json" % [DIR, MATCH_ID]
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(DIR)


func _result() -> Dictionary:
	return {"winnerUserId": null, "endReason": "abandoned", "durationS": 0, "players": []}


func test_resultado_aceito_sai_com_zero_sem_esperar_nem_gravar() -> void:
	_backend.result_replies = [BackendReply.of(204)]

	var code := await _reporter.report(MATCH_ID, _result())

	assert_eq(code, ExitCodes.OK)
	assert_eq(_backend.results.size(), 1)
	assert_eq(_backend.results[0]["match_id"], MATCH_ID)
	assert_eq(_backend.results[0]["result"], _result())
	assert_eq(_waits, [] as Array[float])
	assert_false(FileAccess.file_exists("%s/%s.json" % [DIR, MATCH_ID]))


func test_falha_transitoria_retenta_com_backoff_e_depois_passa() -> void:
	_backend.result_replies = [
		BackendReply.of(503), BackendReply.of(BackendReply.NETWORK_ERROR), BackendReply.of(204)
	]

	var code := await _reporter.report(MATCH_ID, _result())

	assert_eq(code, ExitCodes.OK)
	assert_eq(_backend.results.size(), 3)
	assert_eq(_waits, ResultReporter.BACKOFF_SECONDS)


func test_tres_tentativas_falhas_gravam_arquivo_e_saem_com_3() -> void:
	_backend.result_replies = [BackendReply.of(BackendReply.NETWORK_ERROR)]

	var code := await _reporter.report(MATCH_ID, _result())

	assert_eq(code, ExitCodes.RESULT_NOT_REPORTED)
	assert_push_error_count(1)
	assert_eq(_backend.results.size(), ResultReporter.ATTEMPTS)
	assert_eq(_waits.size(), ResultReporter.ATTEMPTS - 1, "nao espera depois da ultima")
	var saved: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("%s/%s.json" % [DIR, MATCH_ID])
	)
	assert_true(saved is Dictionary)
	assert_eq((saved as Dictionary)["endReason"], "abandoned")


func test_recusa_definitiva_nao_retenta_mas_grava() -> void:
	for status: int in [400, 409]:
		_clean()
		_backend.results = []
		_backend.result_replies = [BackendReply.of(status, {"code": "MATCH_NOT_RUNNING"})]

		var code := await _reporter.report(MATCH_ID, _result())

		assert_eq(code, ExitCodes.RESULT_NOT_REPORTED, str(status))
		assert_push_error("nao reportada")
		assert_eq(_backend.results.size(), 1, str(status))
		assert_true(FileAccess.file_exists("%s/%s.json" % [DIR, MATCH_ID]), str(status))


func test_backoff_cresce() -> void:
	var previous := 0.0
	for seconds: float in ResultReporter.BACKOFF_SECONDS:
		assert_gt(seconds, previous)
		previous = seconds
	assert_eq(ResultReporter.BACKOFF_SECONDS.size(), ResultReporter.ATTEMPTS - 1)
