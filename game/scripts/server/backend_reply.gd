class_name BackendReply
extends RefCounted
## Resposta do backend a uma chamada interna do servidor (BackendApi).

## Status 0 = sem resposta (rede fora, timeout, URL ruim).
const NETWORK_ERROR: int = 0
const OK_MIN: int = 200
const OK_MAX: int = 299
const SERVER_ERROR_MIN: int = 500
const TIMEOUT: int = 408
const TOO_MANY_REQUESTS: int = 429

var status: int = NETWORK_ERROR
## JSON da resposta; {} se nao veio objeto JSON.
var body: Dictionary = {}


static func of(p_status: int, p_body: Dictionary = {}) -> BackendReply:
	var reply := BackendReply.new()
	reply.status = p_status
	reply.body = p_body
	return reply


func is_ok() -> bool:
	return status >= OK_MIN and status <= OK_MAX


## Vale tentar de novo: rede, 5xx, timeout e limite de taxa. 4xx e recusa definitiva.
func is_retryable() -> bool:
	return (
		status == NETWORK_ERROR
		or status >= SERVER_ERROR_MIN
		or status == TIMEOUT
		or status == TOO_MANY_REQUESTS
	)


## Campo `code` do corpo de erro do backend (ex.: TOKEN_EXPIRED); "" se nao ha.
func code() -> String:
	var value: Variant = body.get("code")
	return value if value is String else ""
