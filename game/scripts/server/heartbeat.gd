class_name Heartbeat
extends Node
## Sinal de vida do servidor ao backend a cada 10 s enquanto a partida corre
## (POST /internal/matches/:id/heartbeat). 3 faltas e o backend aborta a partida e recicla o
## container (ARCHITECTURE-LAUNCHER §4.2); por isso falha aqui so e registrada, uma vez por
## sequencia de falhas.

const INTERVAL_SECONDS: float = 10.0

var _api: BackendApi
var _match_id: String = ""
var _timer: Timer
var _failing: bool = false


func is_running() -> bool:
	return _timer != null and not _timer.is_stopped()


func start(api: BackendApi, match_id: String) -> void:
	_api = api
	_match_id = match_id
	if _timer == null:
		_timer = Timer.new()
		_timer.wait_time = INTERVAL_SECONDS
		_timer.timeout.connect(_on_timer_timeout)
		add_child(_timer)
	_timer.start()


func stop() -> void:
	if _timer != null:
		_timer.stop()


func _on_timer_timeout() -> void:
	var reply := await _api.heartbeat(_match_id)
	if reply.is_ok():
		_failing = false
	elif not _failing:
		_failing = true
		push_warning(
			(
				"[heartbeat] backend nao aceitou o sinal de vida (status %d %s)"
				% [reply.status, reply.code()]
			)
		)
