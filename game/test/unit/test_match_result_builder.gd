extends GutTest

const USER_A: String = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"
const USER_B: String = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"
const PEER_A: int = 1001
const PEER_B: int = 1002


func _users() -> Dictionary[int, String]:
	return {PEER_A: USER_A, PEER_B: USER_B}


func _stats() -> MatchStats:
	var stats := MatchStats.new()
	stats.duration = 540.4
	var a := stats.player(PEER_A)
	a.hero = Ids.to_int(&"ranger")
	a.kills = 5
	a.deaths = 2
	a.level = 9
	a.hero_damage = 1234
	a.damage_taken = 800
	a.monsters = 12
	a.chests = 3
	a.boss_killed = true
	var b := stats.player(PEER_B)
	b.hero = Ids.to_int(&"knight")
	b.kills = 2
	b.deaths = 5
	b.level = 7
	return stats


func test_monta_o_resultado_com_as_contas_dos_peers() -> void:
	var result := MatchResultBuilder.build(_stats(), PEER_A, VictoryRules.KILL_GOAL, 777, _users())
	assert_eq(result["winnerUserId"], USER_A)
	assert_eq(result["endReason"], "kill_goal")
	assert_eq(result["durationS"], 540)
	assert_eq(result["seed"], 777)
	var players: Array = result["players"]
	assert_eq(players.size(), 2)
	assert_eq(
		players[0],
		{
			"userId": USER_A,
			"heroId": "ranger",
			"kills": 5,
			"deaths": 2,
			"finalLevel": 9,
			"damageDealt": 1234,
			"damageTaken": 800,
			"monstersKilled": 12,
			"chestsOpened": 3,
			"bossKill": true,
		}
	)
	assert_eq(players[1]["userId"], USER_B)
	assert_eq(players[1]["heroId"], "knight")
	assert_false(players[1]["bossKill"])


func test_duracao_arredonda_para_inteiro() -> void:
	var stats := _stats()
	stats.duration = 540.6
	assert_eq(MatchResultBuilder.build(stats, PEER_A, &"kill_goal", 1, _users())["durationS"], 541)


func test_sem_vencedor_o_vencedor_e_nulo() -> void:
	var result := MatchResultBuilder.build(
		_stats(), VictoryRules.NO_WINNER, VictoryRules.ABANDONED, 1, _users()
	)
	assert_null(result["winnerUserId"])
	assert_eq(result["endReason"], "abandoned")


func test_vencedor_sem_conta_conhecida_vira_nulo() -> void:
	var result := MatchResultBuilder.build(_stats(), 9999, &"kill_goal", 1, _users())
	assert_null(result["winnerUserId"])


func test_jogador_sem_heroi_ou_sem_conta_fica_fora() -> void:
	var stats := _stats()
	stats.player(PEER_B).hero = Ids.NONE
	var only_a := MatchResultBuilder.build(stats, PEER_A, &"abandoned", 1, _users())
	assert_eq((only_a["players"] as Array).size(), 1)
	var no_accounts: Dictionary[int, String] = {}
	var none := MatchResultBuilder.build(_stats(), PEER_A, &"abandoned", 1, no_accounts)
	assert_eq(none["players"], [])


func test_o_resultado_serializa_em_json_de_ida_e_volta() -> void:
	var result := MatchResultBuilder.build(_stats(), PEER_A, &"kill_goal", 777, _users())
	var again: Variant = JSON.parse_string(JSON.stringify(result))
	assert_true(again is Dictionary)
	assert_eq((again as Dictionary)["winnerUserId"], USER_A)
