extends GutTest
## F26: HistoryService (ARCHITECTURE-LAUNCHER §3.3) com ApiClient falso: GET /matches?mine=1,
## cache em memoria por sessao, erro do backend e JSON fora do contrato.

const CALL: String = "GET /matches?mine=1"
const MATCH_A: String = "0b7e9f00-1111-4222-8333-444455556666"
const MATCH_B: String = "0b7e9f00-1111-4222-8333-777788889999"
const HISTORY: Dictionary = {
	"totals": {"wins": 1, "losses": 1},
	"matches":
	[
		{
			"matchId": MATCH_A,
			"result": "win",
			"playedAt": "2026-10-15T12:10:00.000Z",
			"endReason": "kill_goal",
			"durationS": 512,
			"me":
			{
				"heroId": "ranger",
				"kills": 5,
				"finalLevel": 9,
				"deaths": 3,
				"bossKill": true,
				"setActive": "hunter"
			},
			"opponent": {"heroId": "knight", "kills": 3, "finalLevel": 8},
		},
		{
			"matchId": MATCH_B,
			"result": "interrupted",
			"playedAt": "2026-10-15T11:00:00.000Z",
			"endReason": "heartbeat_lost",
			"durationS": null,
			"me":
			{
				"heroId": null,
				"kills": 0,
				"finalLevel": 0,
				"deaths": 0,
				"bossKill": false,
				"setActive": null
			},
			"opponent": {"heroId": null, "kills": 0, "finalLevel": 0},
		},
	],
}

var _api: FakeApiClient
var _service: HistoryService


func before_each() -> void:
	_api = FakeApiClient.new()
	_api.access_token = "jwt-da-conta"
	add_child_autofree(_api)
	_service = HistoryService.new(_api)


func test_busca_as_partidas_da_propria_conta_com_o_token() -> void:
	_api.reply(CALL, 200, HISTORY)
	assert_true(await _service.fetch())
	assert_eq(_api.calls, [CALL])
	assert_eq(_api.bearers, ["jwt-da-conta"])
	var history := _service.history
	assert_eq(history.totals.wins, 1)
	assert_eq(history.totals.losses, 1)
	assert_eq(history.matches.size(), 2)
	var recent: MatchSummary = history.matches[0]
	assert_eq(recent.match_id, MATCH_A)
	assert_eq(recent.result, "win")
	assert_eq(recent.duration_s, 512)
	assert_eq(recent.me.hero_id, "ranger")
	assert_eq(recent.me.set_active, "hunter")
	assert_true(recent.me.boss_kill)
	assert_eq(recent.opponent.hero_id, "knight")
	assert_eq(recent.opponent.kills, 3)


func test_partida_interrompida_tem_campos_nulos_vazios() -> void:
	_api.reply(CALL, 200, HISTORY)
	await _service.fetch()
	var broken: MatchSummary = _service.history.matches[1]
	assert_eq(broken.result, "interrupted")
	assert_eq(broken.duration_s, -1)
	assert_eq(broken.me.hero_id, "")
	assert_eq(broken.opponent.hero_id, "")


func test_cache_por_sessao_nao_repete_a_chamada() -> void:
	_api.reply(CALL, 200, HISTORY)
	await _service.fetch()
	assert_true(await _service.fetch())
	assert_eq(_api.calls.size(), 1)


func test_force_busca_de_novo_depois_de_uma_partida() -> void:
	_api.reply(CALL, 200, HISTORY)
	_api.reply(CALL, 200, {"totals": {"wins": 2, "losses": 1}, "matches": []})
	await _service.fetch()
	assert_true(await _service.fetch(true))
	assert_eq(_api.calls.size(), 2)
	assert_eq(_service.history.totals.wins, 2)


func test_clear_descarta_o_cache_no_logout() -> void:
	_api.reply(CALL, 200, HISTORY)
	_api.reply(CALL, 200, HISTORY)
	await _service.fetch()
	_service.clear()
	assert_null(_service.history)
	await _service.fetch()
	assert_eq(_api.calls.size(), 2)


func test_backend_fora_devolve_false_com_o_codigo() -> void:
	assert_false(await _service.fetch())
	assert_eq(_service.error_code, ApiClient.OFFLINE)
	assert_null(_service.history)


func test_erro_do_backend_guarda_o_codigo() -> void:
	_api.reply(CALL, 401, {"statusCode": 401, "code": "UNAUTHORIZED", "message": "x"})
	assert_false(await _service.fetch())
	assert_eq(_service.error_code, "UNAUTHORIZED")


func test_json_fora_do_contrato_e_erro() -> void:
	_api.reply(CALL, 200, {"totals": {"wins": 1}, "matches": []})
	assert_false(await _service.fetch())
	assert_eq(_service.error_code, ApiClient.HTTP_ERROR)
	assert_null(_service.history)


func test_falha_ao_atualizar_mantem_o_cache_anterior() -> void:
	_api.reply(CALL, 200, HISTORY)
	await _service.fetch()
	assert_false(await _service.fetch(true))
	assert_not_null(_service.history)
	assert_eq(_service.error_code, ApiClient.OFFLINE)


func test_duas_telas_pedindo_juntas_fazem_uma_chamada() -> void:
	_api.reply(CALL, 200, HISTORY)
	var results: Array[bool] = []
	var ask := func() -> void: results.append(await _service.fetch())
	ask.call()
	ask.call()
	await wait_until(func() -> bool: return results.size() == 2, 2.0)
	assert_eq(_api.calls.size(), 1)
	assert_eq(results, [true, true])


func test_clear_no_meio_da_busca_descarta_a_resposta() -> void:
	_api.reply(CALL, 200, HISTORY)
	_api.during_call = func(_call: String) -> void: _service.clear()
	assert_false(await _service.fetch())
	assert_null(_service.history, "a resposta da conta anterior nao volta")
	_api.during_call = Callable()
	_api.reply(CALL, 200, {"totals": {"wins": 0, "losses": 0}, "matches": []})
	assert_true(await _service.fetch(), "nova busca depois do clear funciona")
	assert_eq(_service.history.matches.size(), 0)


func test_is_ready_so_com_historico_e_sem_erro() -> void:
	assert_false(_service.is_ready())
	_api.reply(CALL, 200, HISTORY)
	await _service.fetch()
	assert_true(_service.is_ready())
	await _service.fetch(true)
	assert_false(_service.is_ready(), "falha ao atualizar")
