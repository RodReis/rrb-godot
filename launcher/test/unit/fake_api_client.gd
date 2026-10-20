class_name FakeApiClient
extends ApiClient
## ApiClient falso (ARCHITECTURE-LAUNCHER §7): troca so o transporte. Respostas prontas por
## "METODO /caminho", em fila (cada chamada consome a primeira); sem resposta = backend fora.
## Grava cada chamada, o corpo e o token que foi junto.

const METHOD_NAMES: Dictionary[HTTPClient.Method, String] = {
	HTTPClient.METHOD_GET: "GET",
	HTTPClient.METHOD_POST: "POST",
	HTTPClient.METHOD_PUT: "PUT",
	HTTPClient.METHOD_DELETE: "DELETE",
}

## Ping devolvido por ping() quando ha resposta de "GET /health".
const FAKE_PING_MS: int = 12

var calls: Array[String] = []
var bodies: Array = []
## Token Bearer enviado em cada chamada ("" = sem Authorization).
var bearers: Array[String] = []
## Chamado com "METODO /caminho" no meio de cada chamada (simula algo acontecendo enquanto a
## resposta nao volta, como o logout durante o refresh).
var during_call: Callable = Callable()

## download(): grava estes bytes no destino e devolve download_ok (sem rede).
var download_bytes: PackedByteArray = PackedByteArray()
var download_ok: bool = true
var downloads: Array[String] = []

var _replies: Dictionary[String, Array] = {}


## Ping falso: consome a resposta de "GET /health" (como o ping de verdade consome a rede) e devolve
## FAKE_PING_MS; sem resposta, FAILED.
func ping() -> int:
	var response: Response = await _send(HTTPClient.METHOD_GET, "/health", null, false)
	return FAKE_PING_MS if response.ok() else PingProbe.FAILED


## Manifesto falso: resposta de "GET <url absoluta>".
func fetch_json(url: String) -> Response:
	return await _send(HTTPClient.METHOD_GET, url, null, false)


func download(url: String, path: String) -> bool:
	downloads.append(url)
	if download_ok:
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_buffer(download_bytes)
		file.close()
	return download_ok


func reply(call: String, status: int, json: Variant = null) -> void:
	if not _replies.has(call):
		_replies[call] = []
	_replies[call].append(Response.make(status, json))


func _send(method: HTTPClient.Method, path: String, body: Variant, authed: bool) -> Response:
	var call := "%s %s" % [METHOD_NAMES[method], path]
	calls.append(call)
	bodies.append(body)
	bearers.append(access_token if authed else "")
	if during_call.is_valid():
		during_call.call(call)
	var queue: Array = _replies.get(call, [])
	if queue.is_empty():
		return Response.make(NO_RESPONSE, null)
	return queue.pop_front()
