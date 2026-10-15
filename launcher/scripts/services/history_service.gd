class_name HistoryService
extends RefCounted
## Historico da propria conta (ARCHITECTURE-LAUNCHER §3.3, §4.2 passo 8): GET /matches?mine=1 ->
## MatchHistory, com cache em memoria por sessao. A tela le `history`; o App faz `clear()` quando
## uma partida online acaba e no logout. Nao toca em tela.

## Uma busca terminou (quem chamou durante outra espera por ela).
signal fetch_finished

const PATH: String = "/matches?mine=1"

## Ultimo historico valido; null = ainda nao buscado (ou limpo).
var history: MatchHistory = null
## Codigo do ultimo erro (ApiClient.OFFLINE, UNAUTHORIZED, HTTP_ERROR...); "" depois de um sucesso.
var error_code: String = ""

var _api: ApiClient
var _loading: bool = false


func _init(api: ApiClient) -> void:
	_api = api


## true = `history` pronto (cache ou backend). `force` ignora o cache. Falha ao atualizar mantem o
## historico anterior e devolve false.
func fetch(force: bool = false) -> bool:
	if _loading:
		await fetch_finished
		return error_code.is_empty()
	if history != null and not force:
		return true
	_loading = true
	var response: ApiClient.Response = await _api.request(HTTPClient.METHOD_GET, PATH)
	var parsed := MatchHistory.from_dict(response.json) if response.ok() else null
	if parsed != null:
		history = parsed
		error_code = ""
	else:
		error_code = response.code() if not response.ok() else ApiClient.HTTP_ERROR
	_loading = false
	fetch_finished.emit()
	return parsed != null


func clear() -> void:
	history = null
	error_code = ""
