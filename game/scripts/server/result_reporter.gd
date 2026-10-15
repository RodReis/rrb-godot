class_name ResultReporter
extends RefCounted
## Entrega o MatchResult ao backend no fim da partida (ARCHITECTURE-GAME §6). Falha de rede ou
## 5xx: ate ATTEMPTS tentativas com backoff. Recusa definitiva (4xx) nao adianta repetir. Se nao
## entregou, grava user://results/<match_id>.json (o orquestrador coleta pelo volume) e o
## processo sai com ExitCodes.RESULT_NOT_REPORTED.

const ATTEMPTS: int = 3
## Espera antes da 2a e da 3a tentativa.
const BACKOFF_SECONDS: Array[float] = [1.0, 2.0]
const RESULTS_DIR: String = "user://results"

var _api: BackendApi
## Coroutine func(seconds: float) -> void; nos testes, um registro sem espera.
var _wait: Callable
var _dir: String


func _init(api: BackendApi, wait: Callable, dir: String = RESULTS_DIR) -> void:
	_api = api
	_wait = wait
	_dir = dir


## Codigo de saida do processo: OK se o backend aceitou, RESULT_NOT_REPORTED se nao.
func report(match_id: String, result: Dictionary) -> int:
	var reply: BackendReply
	for attempt: int in ATTEMPTS:
		reply = await _api.post_result(match_id, result)
		if not reply.is_retryable():
			break
		if attempt < ATTEMPTS - 1:
			await _wait.call(BACKOFF_SECONDS[attempt])
	if reply.is_ok():
		return ExitCodes.OK
	push_error(
		"[result] partida %s nao reportada (status %d %s)" % [match_id, reply.status, reply.code()]
	)
	_save(match_id, result)
	return ExitCodes.RESULT_NOT_REPORTED


func _save(match_id: String, result: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(_dir)
	var path := "%s/%s.json" % [_dir, match_id]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("[result] nao gravou %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return
	file.store_string(JSON.stringify(result))
	print("[result] resultado gravado em %s" % path)
