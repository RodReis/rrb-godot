extends GutTest
## Telemetria do servidor no MatchController (F29, SPEC-029 §3.1): nivel congelado na saida da fase
## 1, conjunto ativo, media de ping e total de teleportes vindo do cliente. A copia que vai pela
## rede (MatchStats.from_dict) nao leva nada disso: o main usa server_stats.

const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const RULES: String = "res://shared/data/rules/match_pacing.tres"
const RATE: int = 30
const START: int = 1000
const P1: int = 11
const P2: int = 22
const STRANGER: int = 99
const NEAR: Vector3 = Vector3(1, 0, 1)
const EARLY_XP: int = 300
const LATE_XP: int = 20000

var _clock: MatchClock
var _match: MatchController
var _a: Hero
var _b: Hero


func before_each() -> void:
	var rules := (load(RULES) as MatchRules).duplicate() as MatchRules
	rules.intro_min_duration = 0.0
	_clock = MatchClock.new()
	_clock.rules = rules
	add_child_autofree(_clock)
	_match = MatchController.new()
	_match.rules = rules
	_match.clock = _clock
	_match.available_heroes = [&"knight"]
	add_child_autofree(_match)
	_a = _spawn(P1, GateRules.TEAM_A, NEAR)
	_b = _spawn(P2, GateRules.TEAM_B, -NEAR)
	_match.open(START, RATE)
	_match.join(P1, GateRules.TEAM_A, false, START)
	_match.join(P2, GateRules.TEAM_B, false, START)
	_match.submit_pick(P1, &"knight", START)
	_match.submit_pick(P2, &"knight", START)
	_match.submit_ready(P1, START)
	_match.submit_ready(P2, START)


func _spawn(peer: int, team: int, where: Vector3) -> Hero:
	var hero := (load(KNIGHT) as PackedScene).instantiate() as Hero
	hero.name = str(peer)
	hero.team = team
	hero.transform = Transform3D(Basis(), where)
	add_child_autofree(hero)
	return hero


func _at(seconds: float) -> int:
	return START + roundi(seconds * RATE)


func _run(from: int, to: int) -> void:
	for tick: int in range(from, to + 1):
		_clock.update(tick)
		_match.update(tick)
		_match.watch_heroes(tick)


func _level_of(hero: Hero, xp: int) -> int:
	return XpTable.level_for_xp(hero.xp_curve, xp)


## P2 sai pelo menu na fase 1: a partida acaba e o servidor fecha as estatisticas.
func _finish_match(tick: int) -> MatchStats:
	assert_true(_match.leave_by_menu(P2, tick))
	return _match.server_stats


func test_nivel_e_congelado_na_saida_da_fase_1() -> void:
	_run(START, _at(299))
	_a.xp = EARLY_XP
	_run(_at(300), _at(300))
	assert_eq(_match.state, MatchState.State.TRANSITION)
	_a.xp = LATE_XP
	var stats := _finish_match(_at(301))
	var at_phase1 := stats.player(P1).level_at_phase1_end
	assert_eq(at_phase1, _level_of(_a, EARLY_XP))
	assert_gt(stats.player(P1).level, at_phase1, "o nivel final continua subindo")


func test_antes_do_fim_da_fase_1_nao_ha_nivel() -> void:
	_run(START, _at(299))
	assert_eq(_match.server_stats.player(P1).level_at_phase1_end, MatchStats.NO_VALUE)


func test_quem_nao_tem_heroi_na_saida_da_fase_1_fica_sem_nivel() -> void:
	_b.remove_from_group(Hero.GROUP)
	_run(START, _at(300))
	assert_eq(_match.server_stats.player(P2).level_at_phase1_end, MatchStats.NO_VALUE)
	assert_ne(_match.server_stats.player(P1).level_at_phase1_end, MatchStats.NO_VALUE)


func test_media_de_ping_vai_para_as_estatisticas() -> void:
	var ping := PingAverage.new()
	ping.add(P1, 40)
	ping.add(P1, 60)
	_match.ping = ping
	_run(START, _at(10))
	var stats := _finish_match(_at(10))
	assert_eq(stats.player(P1).avg_ping_ms, 50)
	assert_eq(stats.player(P2).avg_ping_ms, MatchStats.NO_VALUE, "sem amostra, sem valor")


func test_sem_medidor_de_ping_nao_ha_valor() -> void:
	_run(START, _at(10))
	assert_eq(_finish_match(_at(10)).player(P1).avg_ping_ms, MatchStats.NO_VALUE)


func test_conjunto_ativo_sai_das_pecas_equipadas() -> void:
	var catalog := _a.item_catalog
	var equipment := Inventory.NONE
	for item: ItemData in catalog.items:
		if item.set_id == &"guard" and item.rarity == ItemData.Rarity.COMMON:
			equipment = Inventory.equip(equipment, item)
	_a.equipment = equipment
	_run(START, _at(10))
	var stats := _finish_match(_at(10))
	assert_eq(stats.player(P1).set_active, &"guard")
	assert_eq(stats.player(P2).set_active, &"", "sem peca de conjunto")


func test_conjunto_incompleto_nao_e_ativo() -> void:
	var catalog := _a.item_catalog
	for item: ItemData in catalog.items:
		if item.set_id == &"guard" and item.slot == ItemData.Slot.HELM:
			_a.equipment = Inventory.equip(Inventory.NONE, item)
			break
	_run(START, _at(10))
	assert_eq(_finish_match(_at(10)).player(P1).set_active, &"")


func test_total_de_teleportes_do_proprio_peer_e_guardado() -> void:
	assert_true(_match._record_teleports(P1, 7))
	assert_eq(_match.server_stats.player(P1).teleports, 7)
	assert_eq(_match.server_stats.player(P2).teleports, MatchStats.NO_VALUE)


func test_zero_teleportes_e_valor_valido() -> void:
	assert_true(_match._record_teleports(P1, 0))
	assert_eq(_match.server_stats.player(P1).teleports, 0)


func test_segundo_envio_do_mesmo_peer_e_recusado() -> void:
	assert_true(_match._record_teleports(P1, 3))
	assert_false(_match._record_teleports(P1, 9))
	assert_eq(_match.server_stats.player(P1).teleports, 3)


func test_valor_fora_da_faixa_e_recusado() -> void:
	assert_false(_match._record_teleports(P1, -1))
	assert_false(_match._record_teleports(P1, TeleportCollector.MAX_TELEPORTS + 1))
	assert_eq(_match.server_stats.player(P1).teleports, MatchStats.NO_VALUE)
	assert_true(_match._record_teleports(P1, TeleportCollector.MAX_TELEPORTS), "o teto vale")


func test_recusa_nao_gasta_o_unico_envio() -> void:
	assert_false(_match._record_teleports(P1, -5))
	assert_true(_match._record_teleports(P1, 4))


func test_peer_sem_vaga_e_recusado() -> void:
	assert_false(_match._record_teleports(STRANGER, 2))
	assert_false(_match.server_stats.has(STRANGER))


func test_rpc_usa_o_peer_do_transporte_e_nao_um_argumento() -> void:
	# Sem rede, quem chama e o proprio peer local (1), que nao tem vaga: nada e gravado.
	_match.submit_teleport_count(5)
	assert_eq(_match.server_stats.player(P1).teleports, MatchStats.NO_VALUE)
	assert_eq(_match.server_stats.player(P2).teleports, MatchStats.NO_VALUE)


func test_sem_cliente_conectado_nao_ha_o_que_esperar() -> void:
	assert_false(_match._teleports_pending())


func test_estatisticas_pela_rede_nao_levam_a_telemetria() -> void:
	_a.xp = EARLY_XP
	_run(START, _at(300))
	_match._record_teleports(P1, 4)
	var copy := MatchStats.from_dict(_match.server_stats.to_dict())
	assert_eq(copy.player(P1).teleports, MatchStats.NO_VALUE)
	assert_eq(copy.player(P1).level_at_phase1_end, MatchStats.NO_VALUE)
