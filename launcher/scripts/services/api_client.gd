class_name ApiClient
extends Node
## HTTP JSON com o backend (ARCHITECTURE-LAUNCHER §3.3). Unico lugar do Launcher com HTTPRequest.
## Guarda a sessao (JWT) so em memoria (R-PEND-03): chamada autenticada leva o Bearer; 401 tenta
## o refresh uma vez e repete; refresh recusado limpa a sessao e emite unauthorized (o App volta
## ao login). O transporte e _send: o teste troca so ele (FakeApiClient).

## Sessao expirada e sem renovacao: o App volta ao login.
signal unauthorized
## Download em andamento (F83): bytes recebidos e total (-1 enquanto o servidor nao disse).
signal download_progressed(received: int, total: int)

## Resultado do refresh: renovou, recusado (sessao acabou) ou sem resposta (rede).
enum Refresh { OK, DENIED, OFFLINE }

## Sem resposta (rede, timeout, backend fora).
const NO_RESPONSE: int = 0
## code() de quem nao respondeu e de quem respondeu sem {code} (ex.: HTML de proxy).
const OFFLINE: String = "OFFLINE"
const HTTP_ERROR: String = "HTTP_ERROR"
const TIMEOUT_SECONDS: float = 10.0
## Backend local de dev (compose, porta 3000).
const DEFAULT_BASE_URL: String = "http://127.0.0.1:3000"
const BASE_URL_ARG: String = "--api="
## Gerado por tools/build-package.ps1 (fora do git) com a URL publica do backend; so no pacote.
const BUILD_CONFIG_PATH: String = "res://build_config.cfg"
const STATUS_UNAUTHORIZED: int = 401
const STATUS_OK_MIN: int = 200
const STATUS_OK_MAX: int = 299
## Versao do Launcher em toda chamada (F83): o backend recusa a fila abaixo de MIN_CLIENT_VERSION.
const CLIENT_VERSION_HEADER: String = "X-Client-Version"
## Intervalo do progresso do download.
const PROGRESS_SECONDS: float = 0.25

var base_url: String = DEFAULT_BASE_URL
var access_token: String = ""
var refresh_token: String = ""
var client_version: String = BuildInfo.version()

var _probe: PingProbe


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


## URL do backend: --api=<url> (depois do --) ou, sem ele, `fallback`; sem barra no fim.
static func base_url_from(
	user_args: PackedStringArray, fallback: String = DEFAULT_BASE_URL
) -> String:
	for arg: String in user_args:
		if arg.begins_with(BASE_URL_ARG):
			return arg.trim_prefix(BASE_URL_ARG).trim_suffix("/")
	return fallback


## URL embutida no pacote ([backend] url); sem o arquivo (dev), o padrao de dev.
static func embedded_base_url(path: String = BUILD_CONFIG_PATH) -> String:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return DEFAULT_BASE_URL
	var url: String = str(cfg.get_value("backend", "url", DEFAULT_BASE_URL))
	return url.trim_suffix("/") if not url.is_empty() else DEFAULT_BASE_URL


func set_tokens(tokens: AuthTokens) -> void:
	access_token = tokens.access_token
	refresh_token = tokens.refresh_token


func clear_tokens() -> void:
	access_token = ""
	refresh_token = ""


func has_session() -> bool:
	return not access_token.is_empty()


## Round trip do GET /health numa conexao que fica aberta (#233), em ms; PingProbe.FAILED se o
## backend nao respondeu. E o que o jogador ve como ping: sem DNS e TLS de cada chamada.
func ping() -> int:
	if _probe == null:
		_probe = PingProbe.new()
		add_child(_probe)  # filho: some junto com o ApiClient
	return await _probe.measure(base_url)


func request(
	method: HTTPClient.Method, path: String, body: Variant = null, authed: bool = true
) -> Response:
	var response: Response = await _send(method, path, body, authed)
	if response.status != STATUS_UNAUTHORIZED or not authed or not has_session():
		return response
	var refreshed: Refresh = await _refresh()
	if not has_session():
		return response  # saiu (logout) enquanto o refresh voltava
	match refreshed:
		Refresh.OK:
			response = await _send(method, path, body, authed)
		Refresh.OFFLINE:
			return Response.make(NO_RESPONSE, null)  # rede: a sessao continua valendo
	if response.status == STATUS_UNAUTHORIZED:
		clear_tokens()
		unauthorized.emit()
	return response


# ponytail: dois 401 simultaneos renovam duas vezes; hoje so o polling da fila e autenticado em
# paralelo. Serializar o refresh se aparecer outra chamada autenticada concorrente.
func _refresh() -> Refresh:
	if refresh_token.is_empty():
		return Refresh.DENIED
	var used := refresh_token
	var body := {"refreshToken": used}
	var response: Response = await _send(HTTPClient.METHOD_POST, "/auth/refresh", body, false)
	if response.status == NO_RESPONSE:
		return Refresh.OFFLINE
	var tokens := AuthTokens.from_dict(response.json) if response.ok() else null
	if tokens == null:
		return Refresh.DENIED
	if refresh_token != used:
		return Refresh.DENIED  # logout no meio: nao ressuscita a sessao
	set_tokens(tokens)
	return Refresh.OK


## GET de um JSON fora do backend (manifesto de atualizacao, F83), sem sessao.
func fetch_json(url: String) -> Response:
	return await _send_url(HTTPClient.METHOD_GET, url, null, false)


## Baixa [param url] para o arquivo [param path] (instalador, F83), sem timeout (o arquivo e grande)
## e emitindo download_progressed; false se a rede falhou ou o status nao e 2xx.
func download(url: String, path: String) -> bool:
	var http := HTTPRequest.new()
	http.download_file = path
	add_child(http)
	var done := [false, 0]
	http.request_completed.connect(
		func(result: int, status: int, _h: PackedStringArray, _b: PackedByteArray) -> void:
			done[1] = status if result == HTTPRequest.RESULT_SUCCESS else NO_RESPONSE
			done[0] = true
	)
	if http.request(url) != OK:
		http.queue_free()
		return false
	while not done[0]:
		await get_tree().create_timer(PROGRESS_SECONDS).timeout
		download_progressed.emit(http.get_downloaded_bytes(), http.get_body_size())
	http.queue_free()
	return done[1] >= STATUS_OK_MIN and done[1] <= STATUS_OK_MAX


## Um HTTPRequest por chamada, liberado no fim; timeout de 10 s.
func _send(method: HTTPClient.Method, path: String, body: Variant, authed: bool) -> Response:
	return await _send_url(method, base_url + path, body, authed)


func _send_url(method: HTTPClient.Method, url: String, body: Variant, authed: bool) -> Response:
	var http := HTTPRequest.new()
	http.timeout = TIMEOUT_SECONDS
	add_child(http)
	var headers := PackedStringArray(
		["Accept: application/json", "%s: %s" % [CLIENT_VERSION_HEADER, client_version]]
	)
	var payload := ""
	if body != null:
		headers.append("Content-Type: application/json")
		payload = JSON.stringify(body)
	if authed and has_session():
		headers.append("Authorization: Bearer " + access_token)
	if http.request(url, headers, method, payload) != OK:
		http.queue_free()
		return Response.make(NO_RESPONSE, null)
	var result: Array = await http.request_completed
	http.queue_free()
	if result[0] != HTTPRequest.RESULT_SUCCESS:
		return Response.make(NO_RESPONSE, null)
	var text := (result[3] as PackedByteArray).get_string_from_utf8()
	return Response.make(result[1], null if text.is_empty() else JSON.parse_string(text))
