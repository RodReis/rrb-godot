extends GutTest
## F35: ProfileService: le a conta (GET /users/me) e define o nickname (PUT /users/me/nickname).
## Valida o formato antes da rede e leva o erro do backend para a mensagem do campo.

const ME_PATH: String = "GET /users/me"
const SET_PATH: String = "PUT /users/me/nickname"

var _api: FakeApiClient
var _profile: ProfileService


func before_each() -> void:
	_api = FakeApiClient.new()
	add_child_autofree(_api)
	_profile = ProfileService.new(_api)


func _me(nickname: Variant) -> Dictionary:
	return {
		"id": "0b7e9f00-1111-4222-8333-444455556666",
		"email": "duelista@rrb.dev",
		"nickname": nickname,
		"createdAt": "2026-10-15T12:00:00.000Z",
	}


func test_fetch_guarda_o_perfil() -> void:
	_api.reply(ME_PATH, 200, _me("RodReis"))
	assert_true(await _profile.fetch())
	assert_eq(_profile.profile.nickname, "RodReis")
	assert_eq(_profile.profile.id, "0b7e9f00-1111-4222-8333-444455556666")
	assert_false(_profile.needs_nickname())


func test_conta_sem_nickname_e_sinalizada() -> void:
	_api.reply(ME_PATH, 200, _me(null))
	assert_true(await _profile.fetch())
	assert_true(_profile.needs_nickname())


func test_sem_perfil_carregado_nao_exige_nickname() -> void:
	assert_false(_profile.needs_nickname(), "sem dado nao ha o que exigir")


func test_fetch_falho_guarda_o_codigo_e_nao_inventa_perfil() -> void:
	assert_false(await _profile.fetch())
	assert_eq(_profile.error_code, ApiClient.OFFLINE)
	assert_null(_profile.profile)


func test_fetch_com_corpo_fora_do_contrato_falha() -> void:
	_api.reply(ME_PATH, 200, {"id": "x"})
	assert_false(await _profile.fetch())
	assert_eq(_profile.error_code, ApiClient.HTTP_ERROR)


func test_define_o_nickname_e_atualiza_o_perfil() -> void:
	_api.reply(ME_PATH, 200, _me(null))
	await _profile.fetch()
	_api.reply(SET_PATH, 200, _me("RodReis"))
	var result: ProfileService.Result = await _profile.set_nickname("RodReis")
	assert_true(result.ok)
	assert_eq(_api.bodies[1], {"nickname": "RodReis"})
	assert_eq(_profile.profile.nickname, "RodReis")
	assert_false(_profile.needs_nickname())


func test_formato_invalido_nem_chama_o_backend() -> void:
	for bad: String in ["", "ab", "a".repeat(17), "rod reis", "#RodReis", "ródrigo"]:
		var result: ProfileService.Result = await _profile.set_nickname(bad)
		assert_false(result.ok, bad)
		assert_string_contains(result.message, "3 a 16")
	assert_eq(_api.calls.size(), 0)


func test_nickname_em_uso_volta_como_erro_do_campo() -> void:
	_api.reply(SET_PATH, 409, {"code": "NICKNAME_TAKEN"})
	var result: ProfileService.Result = await _profile.set_nickname("RodReis")
	assert_false(result.ok)
	assert_true(result.on_field, "erro do campo")
	assert_string_contains(result.message, "em uso")


func test_recusado_pelo_backend_por_formato() -> void:
	_api.reply(SET_PATH, 400, {"code": "INVALID_NICKNAME"})
	var result: ProfileService.Result = await _profile.set_nickname("RodReis")
	assert_false(result.ok)
	assert_string_contains(result.message, "3 a 16")


func test_backend_fora_do_ar() -> void:
	var result: ProfileService.Result = await _profile.set_nickname("RodReis")
	assert_false(result.ok)
	assert_false(result.on_field, "erro da tela, nao do campo")
	assert_string_contains(result.message, "fora do ar")


func test_limite_de_tentativas() -> void:
	_api.reply(SET_PATH, 429, {"code": "RATE_LIMITED"})
	var result: ProfileService.Result = await _profile.set_nickname("RodReis")
	assert_string_contains(result.message, "Muitas tentativas")


func test_nickname_ja_definido_em_outro_lugar_recarrega_e_conta_como_ok() -> void:
	_api.reply(SET_PATH, 409, {"code": "NICKNAME_ALREADY_SET"})
	_api.reply(ME_PATH, 200, _me("JaTinha"))
	var result: ProfileService.Result = await _profile.set_nickname("Outro_Nome")
	assert_true(result.ok, "a conta ja tem nickname: segue para o lobby")
	assert_eq(_profile.profile.nickname, "JaTinha")


func test_codigo_desconhecido_mostra_o_codigo() -> void:
	_api.reply(SET_PATH, 500, {"code": "INTERNAL_ERROR"})
	var result: ProfileService.Result = await _profile.set_nickname("RodReis")
	assert_string_contains(result.message, "INTERNAL_ERROR")


func test_clear_esquece_o_perfil() -> void:
	_api.reply(ME_PATH, 200, _me("RodReis"))
	await _profile.fetch()
	_profile.clear()
	assert_null(_profile.profile)
	assert_eq(_profile.error_code, "")


func test_resposta_de_conta_antiga_depois_do_clear_e_descartada() -> void:
	_api.reply(ME_PATH, 200, _me("ContaAntiga"))
	_api.during_call = func(_call: String) -> void: _profile.clear()  # logout no meio da busca
	assert_false(await _profile.fetch())
	assert_null(_profile.profile)
