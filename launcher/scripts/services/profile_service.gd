class_name ProfileService
extends RefCounted
## Perfil da conta (F35, ARCHITECTURE-LAUNCHER §3.3): le a conta (GET /users/me) e define o
## nickname (PUT /users/me/nickname) uma unica vez, no 1o login e registra a fila online liberada
## (POST /users/me/queue-unlock, F85). Valida o formato antes da rede
## (FRONTEND-LAUNCHER §3.2, mesma regra do backend) e traduz o erro para a mensagem do campo.
## A sessao e o cache moram em memoria; o App faz clear() no logout.

## Codigo do backend (ou da validacao local) -> mensagem para o campo do formulario.
const ERRORS: Dictionary[String, String] = {
	"INVALID_NICKNAME": "Use de 3 a 16 caracteres: letras, números e _.",
	"NICKNAME_TAKEN": "Este nickname já está em uso. Escolha outro.",
	"RATE_LIMITED": "Muitas tentativas. Aguarde um pouco e tente de novo.",
	"OFFLINE": "Servidor fora do ar. Tente de novo em instantes.",
	"VALIDATION_FAILED": "Nickname inválido. Confira e tente de novo.",
}
const UNEXPECTED: String = "Erro inesperado do servidor (%s)."
const FIELD_CODES: Array[String] = ["INVALID_NICKNAME", "NICKNAME_TAKEN", "VALIDATION_FAILED"]
const ME_PATH: String = "/users/me"
const NICKNAME_PATH: String = "/users/me/nickname"
const ALREADY_SET: String = "NICKNAME_ALREADY_SET"
const QUEUE_UNLOCK_PATH: String = "/users/me/queue-unlock"

## Conta carregada; null = ainda nao buscada (ou limpa).
var profile: UserProfile = null
## Codigo do ultimo erro do fetch (ApiClient.OFFLINE, HTTP_ERROR...); "" depois de um sucesso.
var error_code: String = ""

var _api: ApiClient
## Muda no clear(): resposta de busca iniciada antes (outra conta) e descartada.
var _epoch: int = 0


## Resultado de set_nickname: ok, ou a mensagem pronta; `on_field` = o erro e do campo do
## nickname (formato, em uso); senao e da tela (servidor fora, limite de tentativas).
class Result:
	extends RefCounted
	var ok: bool = false
	var on_field: bool = false
	var message: String = ""


func _init(api: ApiClient) -> void:
	_api = api


## A conta ja carregada ainda nao tem nickname: o App leva para a tela de definir (1o login).
func needs_nickname() -> bool:
	return profile != null and profile.nickname.is_empty()


## A fila online esta liberada na conta (queueUnlockReason preenchido); sem conta carregada, nao.
func queue_unlocked() -> bool:
	return profile != null and not profile.queue_unlock_reason.is_empty()


## GET /users/me. true = `profile` pronto; falha guarda o codigo e nao inventa perfil.
func fetch() -> bool:
	var epoch := _epoch
	var response: ApiClient.Response = await _api.request(HTTPClient.METHOD_GET, ME_PATH)
	if epoch != _epoch:
		return false  # clear() no meio (logout): nada desta resposta fica
	var parsed := UserProfile.from_dict(response.json) if response.ok() else null
	if parsed == null:
		error_code = response.code() if not response.ok() else ApiClient.HTTP_ERROR
		return false
	profile = parsed
	error_code = ""
	return true


## Define o nickname (so no 1o login; o backend recusa troca). Formato errado nem chama a rede.
func set_nickname(nickname: String) -> Result:
	if not NicknameRules.is_valid(nickname):
		return _error("INVALID_NICKNAME")
	var epoch := _epoch
	var body := {"nickname": nickname}
	var response: ApiClient.Response = await _api.request(
		HTTPClient.METHOD_PUT, NICKNAME_PATH, body
	)
	if epoch != _epoch:
		return _error(ApiClient.OFFLINE)  # logout no meio: a tela ja saiu
	if response.code() == ALREADY_SET:
		# Definido em outro lugar: a conta tem nickname, entao segue (recarrega para exibi-lo).
		return _ok() if await fetch() and not needs_nickname() else _error(ALREADY_SET)
	var updated := UserProfile.from_dict(response.json) if response.ok() else null
	if updated == null:
		return _error(response.code() if not response.ok() else ApiClient.HTTP_ERROR)
	profile = updated
	return _ok()


## Registra a liberacao da fila (`reason`: "tutorial" | "bot_win", OfflineResult.REASON_*). O
## backend e idempotente e devolve a conta atualizada. false = rede ou recusa: `profile` nao muda.
func unlock_queue(reason: String) -> bool:
	var epoch := _epoch
	var response: ApiClient.Response = await _api.request(
		HTTPClient.METHOD_POST, QUEUE_UNLOCK_PATH, {"reason": reason}
	)
	if epoch != _epoch:
		return false  # logout no meio: a conta que voltou nao e a mesma
	var updated := UserProfile.from_dict(response.json) if response.ok() else null
	if updated == null:
		return false
	profile = updated
	return true


func clear() -> void:
	_epoch += 1
	profile = null
	error_code = ""


func _ok() -> Result:
	var result := Result.new()
	result.ok = true
	return result


func _error(code: String) -> Result:
	var result := Result.new()
	result.on_field = code in FIELD_CODES
	result.message = tr(ERRORS[code]) if ERRORS.has(code) else tr(UNEXPECTED) % code
	return result
