class_name FakeApiClient
extends ApiClient
## ApiClient falso (ARCHITECTURE-LAUNCHER §7): troca so o transporte. Respostas prontas por
## "METODO /caminho", em fila (cada chamada consome a primeira); sem resposta = backend fora.
## Grava cada chamada, o corpo e o token que foi junto.

const METHOD_NAMES: Dictionary[HTTPClient.Method, String] = {
	HTTPClient.METHOD_GET: "GET",
	HTTPClient.METHOD_POST: "POST",
	HTTPClient.METHOD_DELETE: "DELETE",
}

var calls: Array[String] = []
var bodies: Array = []
## Token Bearer enviado em cada chamada ("" = sem Authorization).
var bearers: Array[String] = []
## Chamado com "METODO /caminho" no meio de cada chamada (simula algo acontecendo enquanto a
## resposta nao volta, como o logout durante o refresh).
var during_call: Callable = Callable()

var _replies: Dictionary[String, Array] = {}


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
