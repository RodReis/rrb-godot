class_name AuthService
extends RefCounted
## Login e cadastro por e-mail e senha (ARCHITECTURE-LAUNCHER §3.3). Valida localmente antes da
## rede (FRONTEND-LAUNCHER §3.2) e traduz o erro do backend para o campo do formulario. A sessao
## (JWT) mora so em memoria, no ApiClient: login a cada abertura (R-PEND-03).

enum Field { NONE, EMAIL, PASSWORD }

## Regra de senha do cadastro = a do backend (RegisterDto: 8-128, letra e numero).
const PASSWORD_MIN: int = 8
const PASSWORD_MAX: int = 128
const EMAIL_PATTERN: String = "^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$"
const LETTER_PATTERN: String = "\\p{L}"
const DIGIT_PATTERN: String = "\\d"
## Codigo do backend (ou da validacao local) -> [campo, mensagem].
const ERRORS: Dictionary[String, Array] = {
	"INVALID_EMAIL": [Field.EMAIL, "Informe um e-mail válido."],
	"EMPTY_PASSWORD": [Field.PASSWORD, "Informe a senha."],
	"WEAK_PASSWORD":
	[Field.PASSWORD, "A senha precisa de 8 caracteres ou mais, com letra e número."],
	"PASSWORD_TOO_LONG": [Field.PASSWORD, "A senha pode ter no máximo 128 caracteres."],
	"INVALID_CREDENTIALS": [Field.PASSWORD, "E-mail ou senha incorretos."],
	"EMAIL_TAKEN": [Field.EMAIL, "Este e-mail já tem conta. Use a aba Entrar."],
	"RATE_LIMITED": [Field.NONE, "Muitas tentativas. Aguarde um pouco e tente de novo."],
	"OFFLINE": [Field.NONE, "Servidor fora do ar. Tente de novo em instantes."],
	"VALIDATION_FAILED": [Field.NONE, "Dados inválidos. Confira e-mail e senha."],
}
const UNEXPECTED: String = "Erro inesperado do servidor (%s)."

var _api: ApiClient
var _email_regex: RegEx = RegEx.create_from_string(EMAIL_PATTERN)
var _letter_regex: RegEx = RegEx.create_from_string(LETTER_PATTERN)
var _digit_regex: RegEx = RegEx.create_from_string(DIGIT_PATTERN)


## Resultado de login/cadastro: ok, ou o campo do erro e a mensagem pronta para a tela.
class Result:
	extends RefCounted
	var ok: bool = false
	var field: Field = Field.NONE
	var message: String = ""


func _init(api: ApiClient) -> void:
	_api = api


func is_logged_in() -> bool:
	return _api.has_session()


func login(email: String, password: String) -> Result:
	var invalid := _validate(email, password, false)
	if invalid != null:
		return invalid
	return await _authenticate("/auth/login", email, password)


func register(email: String, password: String) -> Result:
	var invalid := _validate(email, password, true)
	if invalid != null:
		return invalid
	return await _authenticate("/auth/register", email, password)


func logout() -> void:
	_api.clear_tokens()


func _authenticate(path: String, email: String, password: String) -> Result:
	var body := {"email": email.strip_edges(), "password": password}
	var response: ApiClient.Response = await _api.request(HTTPClient.METHOD_POST, path, body, false)
	if not response.ok():
		return _error(response.code())
	var tokens := AuthTokens.from_dict(response.json)
	if tokens == null:
		return _error(ApiClient.HTTP_ERROR)
	_api.set_tokens(tokens)
	var result := Result.new()
	result.ok = true
	return result


## null = pode chamar o backend. No login so exige senha nao vazia (a regra e do cadastro).
func _validate(email: String, password: String, is_register: bool) -> Result:
	if _email_regex.search(email.strip_edges()) == null:
		return _error("INVALID_EMAIL")
	if password.is_empty():
		return _error("EMPTY_PASSWORD")
	if not is_register:
		return null
	if password.length() > PASSWORD_MAX:
		return _error("PASSWORD_TOO_LONG")
	var weak := password.length() < PASSWORD_MIN
	if weak or _letter_regex.search(password) == null or _digit_regex.search(password) == null:
		return _error("WEAK_PASSWORD")
	return null


func _error(code: String) -> Result:
	var result := Result.new()
	if ERRORS.has(code):
		result.field = ERRORS[code][0]
		result.message = tr(ERRORS[code][1])
	else:
		result.message = tr(UNEXPECTED) % code
	return result
