class_name PingProbe
extends Node
## Round trip do GET /health numa conexao que fica aberta (#233). O HTTPRequest abre uma conexao
## nova a cada chamada e o que ele mede inclui DNS e handshake TLS (229 ms contra 16 ms de ping
## real no VPS de Sao Paulo); aqui so conta a requisicao e a resposta. Quem reconecta (1a medida,
## servidor fechou por ociosidade, URL nova) nao cobra a conexao da medida. O ApiClient e o unico
## dono (ARCHITECTURE-LAUNCHER §3.3), como filho: espera o proximo quadro por um sinal proprio, que
## para junto com ele. Esperar o process_frame da arvore retomaria a corrotina de um objeto ja
## liberado (erro ao fechar o Launcher no meio de uma medida). O App filtra com PingFilter.

signal frame_ticked

## Sem resposta (rede, timeout, status fora de 2xx).
const FAILED: int = -1
const PATH: String = "/health"
const HTTPS_PORT: int = 443
const HTTP_PORT: int = 80
const TIMEOUT_MSEC: int = 10000
const USEC_PER_MSEC: float = 1000.0
const HEADERS: PackedStringArray = ["Accept: application/json"]
const STATUS_OK_MIN: int = 200
const STATUS_OK_MAX: int = 299
## Estados em que a conexao nao volta sozinha: a chamada falha.
const DEAD: Array[HTTPClient.Status] = [
	HTTPClient.STATUS_DISCONNECTED,
	HTTPClient.STATUS_CANT_RESOLVE,
	HTTPClient.STATUS_CANT_CONNECT,
	HTTPClient.STATUS_CONNECTION_ERROR,
	HTTPClient.STATUS_TLS_HANDSHAKE_ERROR,
]

var _client: HTTPClient
var _url: String = ""


## "https://host[:porta][/...]" -> {host, port, tls}. Sem porta: 443 em https, 80 em http.
static func parse_url(url: String) -> Dictionary:
	var tls := url.begins_with("https://")
	var authority := url.trim_prefix("https://").trim_prefix("http://").split("/")[0]
	var parts := authority.split(":")
	var port := int(parts[1]) if parts.size() > 1 else (HTTPS_PORT if tls else HTTP_PORT)
	return {"host": parts[0], "port": port, "tls": tls}


## ms do GET /health em [param base_url], ou FAILED. Uma conexao que ja estava aberta e falhou (o
## servidor a fechou por ociosidade) e refeita uma vez, sem aparecer como erro.
func measure(base_url: String) -> int:
	var reused := _is_open(base_url)
	var ms := await _try(base_url)
	if ms == FAILED and reused:
		ms = await _try(base_url)
	if ms == FAILED:
		close()
	return ms


func close() -> void:
	if _client != null:
		_client.close()
	_client = null
	_url = ""


func _is_open(base_url: String) -> bool:
	if _client == null or _url != base_url:
		return false
	_client.poll()
	return _client.get_status() == HTTPClient.STATUS_CONNECTED


## Conexao nova: uma requisicao de aquecimento, que nao conta (a 1a depois do handshake e bem mais
## lenta que as seguintes), e so a proxima e medida. Servidor sem keep-alive fecha a conexao depois
## do aquecimento: nao ha o que reaproveitar, mede numa conexao nova (so o GET entra na medida).
func _try(base_url: String) -> int:
	if not _is_open(base_url):
		if not await _connect(base_url) or await _exchange() == FAILED:
			return FAILED
		await _next_frame()  # da tempo de o poll ver o servidor fechar a conexao
		if not _is_open(base_url) and not await _connect(base_url):
			return FAILED
	return await _exchange()


## Um GET /health na conexao aberta: ms da requisicao e da resposta, ou FAILED.
func _exchange() -> int:
	var started := Time.get_ticks_usec()
	if _client.request(HTTPClient.METHOD_GET, PATH, HEADERS) != OK:
		return FAILED
	if not await _until([HTTPClient.STATUS_BODY, HTTPClient.STATUS_CONNECTED]):
		return FAILED
	if not _client.has_response():
		return FAILED
	var code := _client.get_response_code()
	while _client.get_status() == HTTPClient.STATUS_BODY:
		_client.poll()
		# So espera um quadro sem dado: o corpo costuma vir junto com os cabecalhos.
		if _client.read_response_body_chunk().is_empty() and not await _next_frame():
			return FAILED
	var elapsed := roundi((Time.get_ticks_usec() - started) / USEC_PER_MSEC)
	return elapsed if code >= STATUS_OK_MIN and code <= STATUS_OK_MAX else FAILED


func _connect(base_url: String) -> bool:
	close()
	_client = HTTPClient.new()
	_url = base_url
	var target := parse_url(base_url)
	var tls := TLSOptions.client() if target["tls"] else null
	if _client.connect_to_host(target["host"], target["port"], tls) != OK:
		return false
	return await _until([HTTPClient.STATUS_CONNECTED])


## Faz poll ate o estado ser um dos [param wanted]; falha em estado morto ou no timeout.
func _until(wanted: Array[HTTPClient.Status]) -> bool:
	var deadline := Time.get_ticks_msec() + TIMEOUT_MSEC
	while Time.get_ticks_msec() < deadline:
		_client.poll()
		var status := _client.get_status()
		if status in wanted:
			return true
		if status in DEAD:
			return false
		if not await _next_frame():
			return false
	return false


func _process(_delta: float) -> void:
	frame_ticked.emit()


func _next_frame() -> bool:
	if not is_inside_tree():
		return false
	await frame_ticked
	return true
