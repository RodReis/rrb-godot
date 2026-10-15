extends GutTest

const MATCH_ID: String = "11111111-1111-4111-8111-111111111111"
const OTHER_MATCH: String = "22222222-2222-4222-8222-222222222222"
const USER_A: String = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"
const USER_B: String = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"
const PEER_A: int = 1001
const PEER_B: int = 1002

var _backend: FakeBackend


func before_each() -> void:
	_backend = FakeBackend.new()


func _token(match_id: String) -> String:
	var payload := Marshalls.utf8_to_base64(JSON.stringify({"match_id": match_id}))
	return "h.%s.s" % payload.replace("+", "-").replace("/", "_").rstrip("=")


func _ok(user_id: String, match_id: String = MATCH_ID) -> BackendReply:
	return BackendReply.of(200, {"matchId": match_id, "userId": user_id, "seed": 42})


func test_token_valido_admite_e_guarda_a_conta_do_peer() -> void:
	_backend.validate_replies = [_ok(USER_A)]
	var session := AuthSession.new(_backend)

	var decision := await session.admit(PEER_A, _token(MATCH_ID))

	assert_true(decision.admitted)
	assert_eq(decision.reply, AuthReply.OK)
	assert_eq(decision.user_id, USER_A)
	assert_eq(session.match_id, MATCH_ID)
	assert_eq(session.users(), {PEER_A: USER_A})
	assert_eq(_backend.validated[0]["match_id"], MATCH_ID)
	assert_eq(_backend.validated[0]["token"], _token(MATCH_ID))


func test_dois_jogadores_com_tokens_proprios() -> void:
	_backend.validate_replies = [_ok(USER_A), _ok(USER_B)]
	var session := AuthSession.new(_backend)

	await session.admit(PEER_A, _token(MATCH_ID))
	var second := await session.admit(PEER_B, _token(MATCH_ID))

	assert_true(second.admitted)
	assert_eq(session.users(), {PEER_A: USER_A, PEER_B: USER_B})


func test_token_malformado_nem_chama_o_backend() -> void:
	var session := AuthSession.new(_backend)

	var decision := await session.admit(PEER_A, "lixo")

	assert_false(decision.admitted)
	assert_eq(decision.reply, AuthReply.DENIED)
	assert_eq(_backend.validated.size(), 0)


func test_token_vazio_e_recusado() -> void:
	var decision := await AuthSession.new(_backend).admit(PEER_A, "")
	assert_false(decision.admitted)
	assert_eq(decision.reply, AuthReply.DENIED)


func test_backend_recusa_token_expirado_ou_de_partida_encerrada() -> void:
	for status: int in [401, 404, 409]:
		_backend.validate_replies = [BackendReply.of(status, {"code": "TOKEN_EXPIRED"})]
		var decision := await AuthSession.new(_backend).admit(PEER_A, _token(MATCH_ID))
		assert_false(decision.admitted, str(status))
		assert_eq(decision.reply, AuthReply.DENIED, str(status))


func test_backend_fora_do_ar_nao_e_culpa_do_token() -> void:
	for status: int in [BackendReply.NETWORK_ERROR, 500, 503]:
		_backend.validate_replies = [BackendReply.of(status)]
		var decision := await AuthSession.new(_backend).admit(PEER_A, _token(MATCH_ID))
		assert_false(decision.admitted, str(status))
		assert_eq(decision.reply, AuthReply.ERROR, str(status))


func test_segredo_interno_errado_nao_e_culpa_do_jogador() -> void:
	_backend.validate_replies = [BackendReply.of(401, {"code": "INTERNAL_UNAUTHORIZED"})]
	var decision := await AuthSession.new(_backend).admit(PEER_A, _token(MATCH_ID))
	assert_false(decision.admitted)
	assert_eq(decision.reply, AuthReply.ERROR)


func test_resposta_sem_conta_e_erro_interno() -> void:
	_backend.validate_replies = [BackendReply.of(200, {"seed": 1})]
	var decision := await AuthSession.new(_backend).admit(PEER_A, _token(MATCH_ID))
	assert_false(decision.admitted)
	assert_eq(decision.reply, AuthReply.ERROR)


func test_token_de_outra_partida_e_recusado_sem_chamar_o_backend() -> void:
	_backend.validate_replies = [_ok(USER_A)]
	var session := AuthSession.new(_backend)
	await session.admit(PEER_A, _token(MATCH_ID))

	var decision := await session.admit(PEER_B, _token(OTHER_MATCH))

	assert_false(decision.admitted)
	assert_eq(_backend.validated.size(), 1)
	assert_false(session.users().has(PEER_B))


func test_mesma_conta_em_dois_peers_ao_mesmo_tempo_e_recusada() -> void:
	_backend.validate_replies = [_ok(USER_A)]
	var session := AuthSession.new(_backend)
	await session.admit(PEER_A, _token(MATCH_ID))

	var clone := await session.admit(PEER_B, _token(MATCH_ID))

	assert_false(clone.admitted)
	assert_eq(clone.reply, AuthReply.DENIED)


func test_conta_pode_voltar_depois_de_sair_do_lobby() -> void:
	_backend.validate_replies = [_ok(USER_A)]
	var session := AuthSession.new(_backend)
	await session.admit(PEER_A, _token(MATCH_ID))
	session.release(PEER_A)

	var back := await session.admit(PEER_B, _token(MATCH_ID))

	assert_true(back.admitted)
	assert_eq(session.users()[PEER_A], USER_A, "stats do peer antigo continuam atribuidas")
	assert_eq(session.users()[PEER_B], USER_A)


func test_resposta_de_outra_partida_depois_do_await_e_recusada() -> void:
	# O backend responde com uma partida diferente da que o token alegava: nunca admite.
	_backend.validate_replies = [_ok(USER_A, OTHER_MATCH)]
	var decision := await AuthSession.new(_backend).admit(PEER_A, _token(MATCH_ID))
	assert_false(decision.admitted)


func test_modo_aberto_sem_backend_admite_qualquer_peer() -> void:
	var session := AuthSession.new(null)

	var decision := await session.admit(PEER_A, "")

	assert_true(decision.admitted)
	assert_eq(session.match_id, "")
	assert_eq(session.users(), {})


func test_codigo_de_saida_do_cliente_conforme_a_resposta() -> void:
	assert_eq(AuthReply.exit_code_for(AuthReply.DENIED), ExitCodes.AUTH)
	assert_eq(AuthReply.exit_code_for(AuthReply.ERROR), ExitCodes.INTERNAL)
	assert_eq(AuthReply.exit_code_for("qualquer coisa"), ExitCodes.INTERNAL)
