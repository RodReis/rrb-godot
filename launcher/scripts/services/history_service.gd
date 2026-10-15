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
## Muda no clear(): resposta de busca iniciada antes (outra conta ou sessao) e descartada.
var _epoch: int = 0


func _init(api: ApiClient) -> void:
	_api = api


## Ha historico valido e a ultima busca nao falhou.
func is_ready() -> bool:
	return history != null and error_code.is_empty()


## true = `history` pronto (cache ou backend). `force` ignora o cache. Falha ao atualizar mantem o
## historico anterior e devolve false. Sempre emite `fetch_finished` ao terminar.
func fetch(force: bool = false) -> bool:
	if _loading:
		await fetch_finished
		return is_ready()
	if history != null and not force:
		fetch_finished.emit()
		return true
	_loading = true
	var epoch := _epoch
	var response: ApiClient.Response = await _api.request(HTTPClient.METHOD_GET, PATH)
	if epoch != _epoch:
		fetch_finished.emit()  # clear() no meio (logout): nada desta resposta fica
		return false
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
	_epoch += 1
	_loading = false
	history = null
	error_code = ""
