extends GutTest
## MatchStats (F18): modelo da tela de fim. Vai do servidor aos clientes como Dictionary no
## match_ended; o cliente so aceita campo conhecido, do tipo certo, e no maximo um jogador por
## vaga. A soma durante a partida (kill, dano, bau, boss) e provada em test_match_phase2.

const P1: int = 11
const P2: int = 22


func _filled() -> MatchStats:
	var stats := MatchStats.new()
	stats.duration = 468.5
	var a := stats.player(P1)
	a.hero = Ids.to_int(&"knight")
	a.kills = 5
	a.deaths = 3
	a.level = 9
	a.hero_damage = 4250
	a.damage_taken = 4800
	a.monsters = 7
	a.chests = 5
	a.boss_killed = true
	a.equipment = Vector4i(Ids.to_int(&"sword_t2"), Ids.NONE, Ids.NONE, Ids.NONE)
	stats.player(P2).hero = Ids.to_int(&"ranger")
	return stats


func test_player_cria_uma_vez_por_peer() -> void:
	var stats := MatchStats.new()
	stats.player(P1).deaths += 1
	stats.player(P1).deaths += 1
	assert_eq(stats.player(P1).deaths, 2)
	assert_eq(stats.players().size(), 1)
	assert_true(stats.has(P1))
	assert_false(stats.has(P2))


func test_ida_e_volta_pela_rede_preserva_tudo() -> void:
	var sent := _filled()
	var got := MatchStats.from_dict(sent.to_dict())
	assert_almost_eq(got.duration, 468.5, 0.001)
	assert_eq(got.players().size(), 2)
	var a := got.player(P1)
	assert_eq(a.peer, P1)
	assert_eq(a.hero, Ids.to_int(&"knight"))
	assert_eq(
		[a.kills, a.deaths, a.level, a.hero_damage, a.damage_taken, a.monsters, a.chests],
		[5, 3, 9, 4250, 4800, 7, 5]
	)
	assert_true(a.boss_killed)
	assert_eq(a.equipment, Vector4i(Ids.to_int(&"sword_t2"), Ids.NONE, Ids.NONE, Ids.NONE))
	assert_false(got.player(P2).boss_killed)


func test_campo_de_tipo_errado_ou_desconhecido_e_ignorado() -> void:
	var data := _filled().to_dict()
	var entry: Dictionary = (data["players"] as Array)[0]
	entry["kills"] = "cinco"
	entry["hack"] = 1
	data["duration"] = "x"
	var got := MatchStats.from_dict(data)
	assert_eq(got.player(entry["peer"]).kills, 0)
	assert_eq(got.duration, 0.0)


func test_lixo_na_rede_vira_estatistica_vazia() -> void:
	assert_eq(MatchStats.from_dict({}).players().size(), 0)
	assert_eq(MatchStats.from_dict({"players": "x"}).players().size(), 0)
	assert_eq(MatchStats.from_dict({"players": [1, "a", {}]}).players().size(), 0, "sem peer")


func test_no_maximo_um_jogador_por_vaga() -> void:
	var data := {"players": [{"peer": 1}, {"peer": 2}, {"peer": 3}]}
	assert_eq(MatchStats.from_dict(data).players().size(), MatchStats.MAX_PLAYERS)
	assert_eq(MatchStats.MAX_PLAYERS, MatchController.SLOT_TEAMS.size())


func test_oponente_de_quem_joga() -> void:
	var stats := _filled()
	assert_eq(stats.opponent_of(P1).peer, P2)
	assert_eq(stats.opponent_of(P2).peer, P1)
	assert_null(MatchStats.new().opponent_of(P1))
