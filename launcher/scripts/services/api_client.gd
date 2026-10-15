class_name ApiClient
extends Node
## HTTP JSON com o backend (ARCHITECTURE-LAUNCHER §3.3). Unico lugar do Launcher com HTTPRequest.
## Guarda a sessao (JWT) so em memoria (R-PEND-03): chamada autenticada leva o Bearer; 401 tenta
## o refresh uma vez e repete; refresh recusado limpa a sessao e emite unauthorized (o App volta
## ao login). O transporte e _send: o teste troca so ele (FakeApiClient).

## Sessao expirada e sem renovacao: o App volta ao login.
signal unauthorized

## Sem resposta (rede, timeout, backend fora).
const NO_RESPONSE: int = 0
## code() de quem nao respondeu e de quem respondeu sem {code} (ex.: HTML de proxy).
const OFFLINE: String = "OFFLINE"
const HTTP_ERROR: String = "HTTP_ERROR"
const TIMEOUT_SECONDS: float = 10.0
## Backend local de dev (compose, porta 3000). O pacote do F28 passa --api=<url publica>.
const DEFAULT_BASE_URL: String = "http://127.0.0.1:3000"
const BASE_URL_ARG: String = "--api="
const STATUS_UNAUTHORIZED: int = 401
const STATUS_OK_MIN: int = 200
const STATUS_OK_MAX: int = 299

var base_url: String = DEFAULT_BASE_URL
var access_token: String = ""
var refresh_token: String = ""


## Resposta: status HTTP (0 = sem resposta) e o JSON do corpo (null se vazio ou invalido).
class Response:
	extends RefCounted
	var status: int = NO_RESPONSE
	var json: Variant = null

	static func make(p_status: int, p_json: Variant) -> Response:
		var response := Response.new()
		response.status = p_status
		response.json = p_json
		return response

	func ok() -> bool:
		return status >= STATUS_OK_MIN and status <= STATUS_OK_MAX

	## Codigo de erro do contrato do backend ({statusCode, code, message}).
	func code() -> String:
		if status == NO_RESPONSE:
			return OFFLINE
		if json is Dictionary and (json as Dictionary).get("code") is String:
			return (json as Dictionary)["code"]
		return HTTP_ERROR


## URL do backend: --api=<url> (depois do --) ou o padrao de dev; sem barra no fim.
static func base_url_from(user_args: PackedStringArray) -> String:
	for arg: String in user_args:
		if arg.begins_with(BASE_URL_ARG):
			return arg.trim_prefix(BASE_URL_ARG).trim_suffix("/")
	return DEFAULT_BASE_URL


func set_tokens(tokens: AuthTokens) -> void:
	access_token = tokens.access_token
	refresh_token = tokens.refresh_token


func clear_tokens() -> void:
	access_token = ""
	refresh_token = ""


func has_session() -> bool:
	return not access_token.is_empty()


func request(
	method: HTTPClient.Method, path: String, body: Variant = null, authed: bool = true
) -> Response:
	var response: Response = await _send(method, path, body, authed)
	if response.status != STATUS_UNAUTHORIZED or not authed or not has_session():
		return response
	if await _refresh():
		response = await _send(method, path, body, authed)
	if response.status == STATUS_UNAUTHORIZED:
		clear_tokens()
		unauthorized.emit()
	return response


# ponytail: dois 401 simultaneos renovam duas vezes; hoje so o polling da fila e autenticado em
# paralelo. Serializar o refresh se aparecer outra chamada autenticada concorrente.
func _refresh() -> bool:
	if refresh_token.is_empty():
		return false
	var body := {"refreshToken": refresh_token}
	var response: Response = await _send(HTTPClient.METHOD_POST, "/auth/refresh", body, false)
	var tokens := AuthTokens.from_dict(response.json) if response.ok() else null
	if tokens == null:
		return false
	set_tokens(tokens)
	return true


## Um HTTPRequest por chamada, liberado no fim; timeout de 10 s.
func _send(method: HTTPClient.Method, path: String, body: Variant, authed: bool) -> Response:
	var http := HTTPRequest.new()
	http.timeout = TIMEOUT_SECONDS
	add_child(http)
	var headers := PackedStringArray(["Accept: application/json"])
	var payload := ""
	if body != null:
		headers.append("Content-Type: application/json")
		payload = JSON.stringify(body)
	if authed and has_session():
		headers.append("Authorization: Bearer " + access_token)
	if http.request(base_url + path, headers, method, payload) != OK:
		http.queue_free()
		return Response.make(NO_RESPONSE, null)
	var result: Array = await http.request_completed
	http.queue_free()
	if result[0] != HTTPRequest.RESULT_SUCCESS:
		return Response.make(NO_RESPONSE, null)
	var text := (result[3] as PackedByteArray).get_string_from_utf8()
	return Response.make(result[1], null if text.is_empty() else JSON.parse_string(text))
