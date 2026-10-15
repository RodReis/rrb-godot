class_name BackendClient
extends BackendApi
## HTTP interno do servidor dedicado ao backend. O segredo compartilhado vai no cabecalho
## x-internal-secret e vem de variavel de ambiente: nunca do cliente, nunca em log
## (ARCHITECTURE-LAUNCHER §4.4). Uma requisicao por chamada, entao validate de dois peers e o
## heartbeat podem correr juntos.

const SECRET_HEADER: String = "x-internal-secret"
const TIMEOUT_SECONDS: float = 5.0
## Posicoes do sinal HTTPRequest.request_completed.
const COMPLETED_RESULT: int = 0
const COMPLETED_STATUS: int = 1
const COMPLETED_BODY: int = 3

## Node que hospeda os HTTPRequest (precisa estar na arvore).
var _host: Node
var _base_url: String
var _secret: String


func _init(host: Node, base_url: String, secret: String) -> void:
	_host = host
	_base_url = base_url.trim_suffix("/")
	_secret = secret


## Status HTTP + corpo JSON viram uma BackendReply; corpo que nao e objeto JSON vira {}.
static func parse_reply(status: int, raw_body: PackedByteArray) -> BackendReply:
	var parser := JSON.new()  # parse_string loga erro no motor quando o corpo nao e JSON
	if parser.parse(raw_body.get_string_from_utf8()) != OK or not parser.data is Dictionary:
		return BackendReply.of(status)
	return BackendReply.of(status, parser.data)


func validate(match_id: String, token: String) -> BackendReply:
	return await _post("/internal/matches/%s/validate" % match_id, {"token": token})


func heartbeat(match_id: String) -> BackendReply:
	return await _post("/internal/matches/%s/heartbeat" % match_id, {})


func post_result(match_id: String, result: Dictionary) -> BackendReply:
	return await _post("/internal/matches/%s/result" % match_id, result)


func _post(path: String, body: Dictionary) -> BackendReply:
	var request := HTTPRequest.new()
	request.timeout = TIMEOUT_SECONDS
	_host.add_child(request)
	var headers := PackedStringArray(
		["Content-Type: application/json", "%s: %s" % [SECRET_HEADER, _secret]]
	)
	var err := request.request(
		_base_url + path, headers, HTTPClient.METHOD_POST, JSON.stringify(body)
	)
	if err != OK:
		push_warning("[backend] %s: pedido nao saiu (%s)" % [path, error_string(err)])
		request.queue_free()
		return BackendReply.of(BackendReply.NETWORK_ERROR)
	var done: Array = await request.request_completed
	request.queue_free()
	if done[COMPLETED_RESULT] != HTTPRequest.RESULT_SUCCESS:
		push_warning("[backend] %s: sem resposta (resultado %d)" % [path, done[COMPLETED_RESULT]])
		return BackendReply.of(BackendReply.NETWORK_ERROR)
	return parse_reply(done[COMPLETED_STATUS], done[COMPLETED_BODY])
