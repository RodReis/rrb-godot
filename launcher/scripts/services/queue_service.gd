class_name QueueService
extends Node
## Fila 1x1 (ARCHITECTURE-LAUNCHER §3.3): POST /queue e polling de GET /queue/:ticket a cada 2 s
## (sem WebSocket na fatia, PRD D10; o polling e o sinal de vida do ticket no backend). Emite e nao
## toca em tela. Fila longa continua procurando ate o jogador cancelar (§6).

signal searching(elapsed_s: int)
signal matched(match_id: String, assignment: MatchAssignment)
signal cancelled
## Codigo do backend (ALREADY_QUEUED, TICKET_NOT_FOUND...), ApiClient.OFFLINE ou MATCH_GONE.
signal failed(reason: String)

const POLL_SECONDS: float = 2.0
## Falhas de rede seguidas no polling ate desistir (~6 s; o backend expira o ticket em 10 s).
const MAX_POLL_FAILURES: int = 3
## Pareado, mas a partida ja acabou ou o servidor saiu da memoria do backend.
const MATCH_GONE: String = "MATCH_GONE"
const STATUS_CONFLICT: int = 409

var api: ApiClient

var _ticket: String = ""
## POST /queue em andamento (duplo clique nao abre dois tickets).
var _joining: bool = false
var _failures: int = 0
var _timer: Timer = Timer.new()


func _ready() -> void:
	_timer.wait_time = POLL_SECONDS
	_timer.timeout.connect(poll)
	add_child(_timer)


func is_searching() -> bool:
	return not _ticket.is_empty()


func poll_timer() -> Timer:
	return _timer


func join() -> void:
	if is_searching() or _joining:
		return
	_joining = true
	var response: ApiClient.Response = await api.request(HTTPClient.METHOD_POST, "/queue")
	_joining = false
	var ticket := QueueTicket.from_dict(response.json) if response.ok() else null
	if ticket == null:
		failed.emit(response.code() if not response.ok() else ApiClient.HTTP_ERROR)
		return
	_ticket = ticket.id
	_failures = 0
	_timer.start()
	searching.emit(0)


## Cancela. Ja pareado (409): consulta na hora e segue para matched. Backend fora: cancela aqui
## (o ticket sem polling expira sozinho no backend).
func leave() -> void:
	if not is_searching():
		return
	_timer.stop()
	var response: ApiClient.Response = await api.request(
		HTTPClient.METHOD_DELETE, "/queue/" + _ticket
	)
	if response.status == STATUS_CONFLICT:
		await poll()
		return
	_finish()
	cancelled.emit()


func poll() -> void:
	if not is_searching():
		return
	var ticket := _ticket
	var response: ApiClient.Response = await api.request(HTTPClient.METHOD_GET, "/queue/" + ticket)
	if ticket != _ticket:
		return  # cancelado ou encerrado enquanto a consulta voltava
	if response.status == ApiClient.NO_RESPONSE:
		_failures += 1
		if _failures >= MAX_POLL_FAILURES:
			_fail(ApiClient.OFFLINE)
		return
	_failures = 0
	var status := TicketStatus.from_dict(response.json) if response.ok() else null
	if status == null:
		_fail(response.code() if not response.ok() else ApiClient.HTTP_ERROR)
	elif status.status == "searching":
		searching.emit(status.elapsed_s)
	elif status.status == "cancelled":
		_finish()
		cancelled.emit()
	elif status.assignment == null:
		# Partida existe sem servidor para esta conta: libera para a proxima fila (§6).
		_finish()
		if not status.match_id.is_empty():
			await api.request(HTTPClient.METHOD_POST, "/matches/%s/abandon" % status.match_id)
		failed.emit(MATCH_GONE)
	else:
		_finish()
		matched.emit(status.match_id, status.assignment)


## Esquece a fila sem falar com o backend (sessao expirada ou logout): o ticket sem polling
## expira sozinho no backend.
func reset() -> void:
	_finish()
	_joining = false


func _fail(reason: String) -> void:
	_finish()
	failed.emit(reason)


func _finish() -> void:
	_timer.stop()
	_ticket = ""
