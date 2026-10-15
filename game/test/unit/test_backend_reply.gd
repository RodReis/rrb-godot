extends GutTest


func test_2xx_e_sucesso_e_nao_retenta() -> void:
	for status: int in [200, 204]:
		var reply := BackendReply.of(status)
		assert_true(reply.is_ok(), str(status))
		assert_false(reply.is_retryable(), str(status))


func test_rede_e_5xx_retentam() -> void:
	for status: int in [BackendReply.NETWORK_ERROR, 500, 502, 503, 408, 429]:
		var reply := BackendReply.of(status)
		assert_false(reply.is_ok(), str(status))
		assert_true(reply.is_retryable(), str(status))


func test_4xx_e_recusa_definitiva() -> void:
	for status: int in [400, 401, 404, 409]:
		var reply := BackendReply.of(status)
		assert_false(reply.is_ok(), str(status))
		assert_false(reply.is_retryable(), str(status))


func test_code_do_corpo_de_erro() -> void:
	assert_eq(BackendReply.of(401, {"code": "TOKEN_EXPIRED"}).code(), "TOKEN_EXPIRED")
	assert_eq(BackendReply.of(401, {"code": 7}).code(), "", "codigo que nao e texto")
	assert_eq(BackendReply.of(500).code(), "")


func test_parse_corpo_json_objeto() -> void:
	var reply := BackendClient.parse_reply(200, '{"userId":"u1","seed":42}'.to_utf8_buffer())
	assert_eq(reply.status, 200)
	assert_eq(reply.body["userId"], "u1")
	assert_eq(reply.body["seed"], 42.0, "JSON numerico chega como float")


func test_parse_corpo_vazio_ou_invalido_vira_vazio() -> void:
	assert_eq(BackendClient.parse_reply(204, PackedByteArray()).body, {})
	assert_eq(BackendClient.parse_reply(502, "<html>".to_utf8_buffer()).body, {})
	assert_eq(
		BackendClient.parse_reply(200, "[1,2]".to_utf8_buffer()).body, {}, "array nao e objeto"
	)
