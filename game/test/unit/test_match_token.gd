extends GutTest

const ID: String = "11111111-1111-4111-8111-111111111111"


## JWT so no formato: o servidor nao confere assinatura (quem confere e o backend).
func _token(payload: Dictionary) -> String:
	var header := _b64url('{"alg":"HS256","typ":"JWT"}')
	return "%s.%s.assinatura" % [header, _b64url(JSON.stringify(payload))]


func _b64url(text: String) -> String:
	return Marshalls.utf8_to_base64(text).replace("+", "-").replace("/", "_").rstrip("=")


func test_le_o_match_id_do_payload() -> void:
	assert_eq(MatchToken.match_id(_token({"typ": "match", "match_id": ID})), ID)


func test_payload_com_tamanhos_de_base64_variados() -> void:
	for pad: String in ["", "x", "xy", "xyz"]:
		var token := _token({"match_id": ID, "pad": pad})
		assert_eq(MatchToken.match_id(token), ID, "pad '%s'" % pad)


func test_sem_match_id_ou_de_tipo_errado() -> void:
	assert_eq(MatchToken.match_id(_token({"typ": "match"})), "")
	assert_eq(MatchToken.match_id(_token({"match_id": 7})), "")


func test_id_que_nao_e_uuid_e_recusado() -> void:
	# vira caminho de URL e nome de arquivo: nada de ../ ou ?
	for bad: String in [
		"../../etc/passwd",
		ID + "/x",
		ID.replace("-", ""),
		"",
		"xxxxxxxx-1111-4111-8111-111111111111"
	]:
		assert_eq(MatchToken.match_id(_token({"match_id": bad})), "", bad)


func test_lixo_nao_quebra() -> void:
	for bad: String in ["", "lixo", "a.b", "a.b.c.d", "a.%%%.c", "a." + _b64url("[1]") + ".c"]:
		assert_eq(MatchToken.match_id(bad), "", bad)


func test_token_enorme_e_recusado() -> void:
	var huge := _token({"match_id": ID, "pad": "x".repeat(MatchToken.MAX_LENGTH)})
	assert_eq(MatchToken.match_id(huge), "")
