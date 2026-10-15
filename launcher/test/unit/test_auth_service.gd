extends GutTest
## F25: AuthService (ARCHITECTURE-LAUNCHER §3.3): login e cadastro com ApiClient falso, validacao
## local antes da rede (regra de senha do backend: 8+ caracteres, letra e numero), erro do backend
## (400/409/401) no campo certo e sessao so em memoria.

const EMAIL: String = "duelista@rrb.dev"
const PASSWORD: String = "senha1234"
const TOKENS: Dictionary = {"accessToken": "acesso", "refreshToken": "refresh"}

var _api: FakeApiClient
var _auth: AuthService


func before_each() -> void:
	_api = FakeApiClient.new()
	add_child_autofree(_api)
	_auth = AuthService.new(_api)


func test_login_ok_abre_a_sessao() -> void:
	_api.reply("POST /auth/login", 200, TOKENS)
	var result: AuthService.Result = await _auth.login(" %s " % EMAIL, PASSWORD)
	assert_true(result.ok)
	assert_true(_auth.is_logged_in())
	assert_eq(_api.access_token, "acesso")
	assert_eq(_api.bodies[0], {"email": EMAIL, "password": PASSWORD})


func test_login_com_senha_errada_mostra_erro_na_senha() -> void:
	_api.reply("POST /auth/login", 401, {"code": "INVALID_CREDENTIALS"})
	var result: AuthService.Result = await _auth.login(EMAIL, "errada123")
	assert_false(result.ok)
	assert_eq(result.field, AuthService.Field.PASSWORD)
	assert_string_contains(result.message, "incorretos")
	assert_false(_auth.is_logged_in())


func test_cadastro_ok_ja_entra() -> void:
	_api.reply("POST /auth/register", 201, TOKENS)
	var result: AuthService.Result = await _auth.register(EMAIL, PASSWORD)
	assert_true(result.ok)
	assert_true(_auth.is_logged_in())


func test_cadastro_com_email_em_uso_mostra_erro_no_email() -> void:
	_api.reply("POST /auth/register", 409, {"code": "EMAIL_TAKEN"})
	var result: AuthService.Result = await _auth.register(EMAIL, PASSWORD)
	assert_eq(result.field, AuthService.Field.EMAIL)
	assert_string_contains(result.message, "já tem conta")


func test_cadastro_recusado_pelo_backend_mostra_erro_na_senha() -> void:
	_api.reply("POST /auth/register", 400, {"code": "WEAK_PASSWORD"})
	var result: AuthService.Result = await _auth.register(EMAIL, PASSWORD)
	assert_eq(result.field, AuthService.Field.PASSWORD)


func test_senha_fraca_no_cadastro_nem_chama_o_backend() -> void:
	for weak: String in ["abc123", "somenteletras", "12345678"]:
		var result: AuthService.Result = await _auth.register(EMAIL, weak)
		assert_eq(result.field, AuthService.Field.PASSWORD, weak)
	assert_eq(_api.calls.size(), 0)


func test_email_invalido_nem_chama_o_backend() -> void:
	for bad: String in ["", "sem-arroba", "a@b", "a b@c.d"]:
		var result: AuthService.Result = await _auth.login(bad, PASSWORD)
		assert_eq(result.field, AuthService.Field.EMAIL, bad)
	assert_eq(_api.calls.size(), 0)


func test_login_aceita_qualquer_senha_nao_vazia() -> void:
	_api.reply("POST /auth/login", 401, {"code": "INVALID_CREDENTIALS"})
	await _auth.login(EMAIL, "curta")
	assert_eq(_api.calls, ["POST /auth/login"] as Array[String])
	var empty: AuthService.Result = await _auth.login(EMAIL, "")
	assert_eq(empty.field, AuthService.Field.PASSWORD)


func test_backend_fora_e_erro_geral() -> void:
	var result: AuthService.Result = await _auth.login(EMAIL, PASSWORD)
	assert_false(result.ok)
	assert_eq(result.field, AuthService.Field.NONE)
	assert_string_contains(result.message, "fora do ar")


func test_resposta_sem_tokens_nao_abre_sessao() -> void:
	_api.reply("POST /auth/login", 200, {"accessToken": "so-um"})
	var result: AuthService.Result = await _auth.login(EMAIL, PASSWORD)
	assert_false(result.ok)
	assert_false(_auth.is_logged_in())


func test_sair_esquece_a_sessao() -> void:
	_api.reply("POST /auth/login", 200, TOKENS)
	await _auth.login(EMAIL, PASSWORD)
	_auth.logout()
	assert_false(_auth.is_logged_in())
	assert_eq(_api.refresh_token, "")
