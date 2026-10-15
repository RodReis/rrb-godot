extends GutTest
## F25: ApiClient (ARCHITECTURE-LAUNCHER §3.3): Bearer nas chamadas autenticadas, 401 tenta o
## refresh uma vez e repete; refresh recusado limpa a sessao e emite unauthorized.

const TOKENS_A: Dictionary = {"accessToken": "acesso-a", "refreshToken": "refresh-a"}
const TOKENS_B: Dictionary = {"accessToken": "acesso-b", "refreshToken": "refresh-b"}

var _api: FakeApiClient


func before_each() -> void:
	_api = FakeApiClient.new()
	add_child_autofree(_api)


func test_chamada_autenticada_leva_o_bearer() -> void:
	_api.set_tokens(AuthTokens.from_dict(TOKENS_A))
	_api.reply("GET /users/me", 200, {})
	await _api.request(HTTPClient.METHOD_GET, "/users/me")
	assert_eq(_api.bearers, ["acesso-a"] as Array[String])


func test_chamada_sem_autenticacao_nao_leva_token() -> void:
	_api.set_tokens(AuthTokens.from_dict(TOKENS_A))
	_api.reply("GET /health", 200, {"status": "ok"})
	await _api.request(HTTPClient.METHOD_GET, "/health", null, false)
	assert_eq(_api.bearers, [""] as Array[String])


func test_401_renova_o_token_e_repete_a_chamada() -> void:
	_api.set_tokens(AuthTokens.from_dict(TOKENS_A))
	_api.reply("GET /queue/t1", 401, {"code": "UNAUTHORIZED"})
	_api.reply("POST /auth/refresh", 200, TOKENS_B)
	_api.reply("GET /queue/t1", 200, {"status": "searching", "elapsedS": 4})
	watch_signals(_api)
	var response: ApiClient.Response = await _api.request(HTTPClient.METHOD_GET, "/queue/t1")
	assert_eq(response.status, 200)
	assert_eq(_api.calls, ["GET /queue/t1", "POST /auth/refresh", "GET /queue/t1"] as Array[String])
	assert_eq(_api.bodies[1], {"refreshToken": "refresh-a"})
	assert_eq(_api.bearers[2], "acesso-b")
	assert_signal_not_emitted(_api, "unauthorized")


func test_refresh_recusado_limpa_a_sessao_e_avisa() -> void:
	_api.set_tokens(AuthTokens.from_dict(TOKENS_A))
	_api.reply("GET /queue/t1", 401, {"code": "UNAUTHORIZED"})
	_api.reply("POST /auth/refresh", 401, {"code": "UNAUTHORIZED"})
	watch_signals(_api)
	var response: ApiClient.Response = await _api.request(HTTPClient.METHOD_GET, "/queue/t1")
	assert_eq(response.status, 401)
	assert_signal_emitted(_api, "unauthorized")
	assert_false(_api.has_session())


func test_401_sem_sessao_nao_e_sessao_expirada() -> void:
	_api.reply("POST /auth/login", 401, {"code": "INVALID_CREDENTIALS"})
	watch_signals(_api)
	var body := {"email": "a@b.c", "password": "x"}
	var response: ApiClient.Response = await _api.request(
		HTTPClient.METHOD_POST, "/auth/login", body, false
	)
	assert_eq(response.code(), "INVALID_CREDENTIALS")
	assert_eq(_api.calls, ["POST /auth/login"] as Array[String])
	assert_signal_not_emitted(_api, "unauthorized")


func test_sem_resposta_e_status_zero() -> void:
	var response: ApiClient.Response = await _api.request(HTTPClient.METHOD_GET, "/health")
	assert_eq(response.status, ApiClient.NO_RESPONSE)
	assert_false(response.ok())
	assert_eq(response.code(), ApiClient.OFFLINE)


func test_resposta_2xx_e_ok_e_codigo_vem_do_corpo() -> void:
	assert_true(ApiClient.Response.make(204, null).ok())
	assert_false(ApiClient.Response.make(409, {"code": "EMAIL_TAKEN"}).ok())
	assert_eq(ApiClient.Response.make(409, {"code": "EMAIL_TAKEN"}).code(), "EMAIL_TAKEN")
	assert_eq(ApiClient.Response.make(500, "html").code(), ApiClient.HTTP_ERROR)


func test_url_do_backend_vem_do_argumento() -> void:
	var args := PackedStringArray(["--api=http://10.0.0.5:3000/"])
	assert_eq(ApiClient.base_url_from(args), "http://10.0.0.5:3000")
	assert_eq(ApiClient.base_url_from(PackedStringArray()), ApiClient.DEFAULT_BASE_URL)
