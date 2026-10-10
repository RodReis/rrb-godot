extends GutTest
## Fase 2 com relogio injetado (ticks falsos a 30 Hz, ARCHITECTURE-GAME §8; GDB §7; CONVENTION
## §3, §4.4): TRANSITION -> PHASE2 aos 5:05, morte subita aos 9:00 com respawn desligado, fim pela
## meta de kills, pela eliminacao e pelo colapso aos 10:00 (I1: nenhuma partida passa de 10:00),
## zona ferindo so quem esta fora do circulo e so na fase 2. Rei Esqueleto saindo sem drop aos
## 5:00: test_boss (SpawnDirector.dismiss_boss, ligado ao phase1_ended no main).

const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const RULES: String = "res://shared/data/rules/match_pacing.tres"
const TICK: float = 1.0 / 30.0
const RATE: int = 30
const START: int = 1000
const P1: int = 11
const P2: int = 22
const SEED: int = 77
const NEAR: Vector3 = Vector3(1, 0, 1)
const LETHAL: int = 100000

var _rules: MatchRules
var _clock: MatchClock
var _zone: ZoneController
var _match: MatchController
var _a: Hero
var _b: Hero
var _phases: Array = []  # [from, to, tick]
var _ended: Array = []  # [winner, reason, stats, tick]


func before_each() -> void:
	_phases = []
	_ended = []
	_rules = load(RULES) as MatchRules
	_clock = MatchClock.new()
	_clock.rules = _rules
	add_child_autofree(_clock)
	_zone = ZoneController.new()
	_zone.rules = _rules
	_zone.clock = _clock
	add_child_autofree(_zone)
	_match = MatchController.new()
	_match.rules = _rules
	_match.clock = _clock
	_match.zone = _zone
	_match.match_seed = SEED
	_match.available_heroes = [&"knight"]
	add_child_autofree(_match)
	_match.phase_changed.connect(
		func(from: int, to: int, tick: int) -> void: _phases.append([from, to, tick])
	)
	_match.match_ended.connect(
		func(winner: int, reason: StringName, stats: MatchStats, tick: int) -> void:
			_ended.append([winner, reason, stats, tick])
	)
	_a = _spawn(P1, GateRules.TEAM_A, NEAR)
	_b = _spawn(P2, GateRules.TEAM_B, -NEAR)
	_match.open(START, RATE)
	_match.join(P1, GateRules.TEAM_A, false, START)
	_match.join(P2, GateRules.TEAM_B, false, START)
	_match.submit_pick(P1, &"knight", START)
	_match.submit_pick(P2, &"knight", START)


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
		_zone.update(tick, RATE)
		_match.watch_heroes(tick)


## [param killer] mata [param victim] no [param tick] (golpe pelo ledger, aplicado no tick).
func _kill(victim: Hero, killer: Hero, tick: int) -> void:
	var blow := HitEffect.new(LETHAL, killer.global_position)
	blow.attacker_id = killer.peer_id
	victim.receive_hit(tick, HitLedger.source_key(killer.peer_id, HitLedger.Slot.BASIC), blow)
	victim._rollback_tick(TICK, tick, true)
	_match.watch_heroes(tick)


func test_transicao_vira_fase_2_aos_5_05() -> void:
	_run(START, _at(305) - 1)
	assert_eq(_match.state, MatchState.State.TRANSITION)
	_run(_at(305), _at(305))
	assert_eq(_match.state, MatchState.State.PHASE2)
	var s := MatchState.State
	assert_eq(_phases.back(), [s.TRANSITION, s.PHASE2, _at(305)])


func test_respawn_desliga_aos_9_00() -> void:
	_run(START, _at(540) - 1)
	assert_eq(_match.state, MatchState.State.PHASE2)
	assert_eq(_a.respawn_off_tick, Hero.RESPAWN_ALWAYS)
	assert_eq(_a.respawn_seconds, 6.0)
	_run(_at(540), _at(540))
	assert_eq(_match.state, MatchState.State.SUDDEN_DEATH)
	assert_eq(_a.respawn_off_tick, _at(540))
	assert_eq(_b.respawn_off_tick, _at(540))


func test_morto_aos_9_00_nao_renasce_e_perde_por_eliminacao() -> void:
	_run(START, _at(538))
	_kill(_a, _b, _at(538) + 1)
	assert_eq(_match.state, MatchState.State.PHASE2, "antes das 9:00 a morte nao encerra")
	_run(_at(538) + 2, _at(540))
	assert_eq(_match.state, MatchState.State.ENDED)
	assert_eq(_ended.size(), 1)
	assert_eq(_ended[0][0], P2)
	assert_eq(_ended[0][1], VictoryRules.ELIMINATION)
	for tick: int in range(_at(540), _at(560)):
		_a._rollback_tick(TICK, tick, true)
	assert_false(_a.is_alive(), "sem respawn")


func test_morte_na_morte_subita_encerra_na_hora() -> void:
	_run(START, _at(560))
	_kill(_b, _a, _at(560) + 1)
	assert_eq(_match.state, MatchState.State.ENDED)
	assert_eq(_ended[0][0], P1)
	assert_eq(_ended[0][1], VictoryRules.ELIMINATION)


func test_meta_de_5_kills_encerra_com_o_placar() -> void:
	_run(START, _at(310))
	var tick := _at(310) + 1
	for i: int in _rules.kill_goal:
		_kill(_b, _a, tick + i * 2)
		_b.hp = _b.attributes.max_hp  # renasce
		_match.watch_heroes(tick + i * 2 + 1)
	assert_eq(_match.state, MatchState.State.ENDED)
	assert_eq(_ended.size(), 1)
	assert_eq(_ended[0][0], P1)
	assert_eq(_ended[0][1], VictoryRules.KILL_GOAL)
	var stats: MatchStats = _ended[0][2]
	assert_eq(stats.player(P1).kills, 5)
	assert_eq(stats.player(P2).kills, 0)
	assert_gt(stats.player(P1).hero_damage, 0)


func test_kills_da_fase_1_nao_contam_para_a_meta() -> void:
	_run(START, _at(60))
	_kill(_b, _a, _at(60) + 1)
	assert_eq(_match.kills(P1), 0)
	assert_eq(_match.state, MatchState.State.PHASE1)


func test_nenhuma_partida_passa_de_10_00() -> void:
	_b.hp = roundi(_b.attributes.max_hp * 0.5)
	_run(START, _at(600) - 1)
	assert_eq(_match.state, MatchState.State.SUDDEN_DEATH)
	assert_eq(_ended, [])
	_run(_at(600), _at(600))
	assert_eq(_match.state, MatchState.State.ENDED)
	assert_eq(_ended[0][0], P1, "maior HP%")
	assert_eq(_ended[0][1], VictoryRules.COLLAPSE_HP)
	assert_eq(_ended[0][3], _at(600))
	_run(_at(600) + 1, _at(620))
	assert_eq(_ended.size(), 1, "fim so uma vez")


func test_colapso_empatado_sorteia_e_nunca_empata() -> void:
	_run(START, _at(600))
	assert_eq(_ended.size(), 1)
	assert_true(_ended[0][0] == P1 or _ended[0][0] == P2)
	assert_eq(_ended[0][1], VictoryRules.COLLAPSE_DRAW)


func test_ninguem_conectado_no_colapso_e_abandoned() -> void:
	_run(START, _at(400))
	_match.leave(P1, _at(400))
	_match.leave(P2, _at(400))
	_run(_at(400) + 1, _at(600))
	assert_eq(_ended[0][0], MatchController.NO_WINNER)
	assert_eq(_ended[0][1], VictoryRules.ABANDONED)


func test_zona_so_fere_na_fase_2_e_quem_esta_fora() -> void:
	_a.transform = Transform3D(Basis(), Vector3(30, 0, 0))  # fora de 26 u (6:00)
	_run(START, _at(299))
	assert_false(_zone.active, "fase 1 sem zona")
	_run(_at(299) + 1, _at(360))
	assert_true(_zone.active)
	var a_hp := _a.hp
	var b_hp := _b.hp
	_a._rollback_tick(TICK, _at(360) + 1, true)
	_b._rollback_tick(TICK, _at(360) + 1, true)
	var pulse := ZoneRules.damage(_a.attributes.max_hp, 0.02)
	assert_eq(a_hp - _a.hp, pulse, "2 % do HP max no minuto 1")
	assert_eq(_b.hp, b_hp, "dentro do circulo")


func test_zona_desliga_no_fim() -> void:
	_run(START, _at(600))
	assert_false(_zone.active)


func test_respawn_feito_antes_das_9_00_sobrevive_a_ressimulacao() -> void:
	var sd := _at(540)
	_run(START, sd - 10)
	_kill(_b, _a, sd - 9)
	_b.respawn_ticks = 2  # renasce em sd - 7
	var saved := _b.respawn_ticks
	for tick: int in range(sd - 8, sd - 6):
		_b._rollback_tick(TICK, tick, true)
	assert_true(_b.is_alive(), "renasceu antes das 9:00")
	_run(sd - 8, sd)
	assert_eq(_match.state, MatchState.State.SUDDEN_DEATH)
	_b.hp = 0  # o rollback restaura o estado de sd - 9 e ressimula
	_b.respawn_ticks = saved
	for tick: int in range(sd - 8, sd - 6):
		_b._rollback_tick(TICK, tick, false)
	assert_true(_b.is_alive(), "ressimular ticks de antes das 9:00 ainda renasce")
	_b.hp = 0
	_b.respawn_ticks = 1
	_b._rollback_tick(TICK, sd + 1, true)
	assert_false(_b.is_alive(), "depois das 9:00 nao renasce")


func test_morte_no_tick_das_9_00_conta_o_kill_antes_de_julgar() -> void:
	var sd := _at(540)
	_run(START, sd - 1)
	var blow := HitEffect.new(LETHAL, _a.global_position)
	blow.attacker_id = P1
	_b.receive_hit(sd, HitLedger.source_key(P1, HitLedger.Slot.BASIC), blow)
	_b._rollback_tick(TICK, sd, true)
	_run(sd, sd)
	assert_eq(_ended.size(), 1)
	assert_eq(_ended[0][0], P1)
	var stats: MatchStats = _ended[0][2]
	assert_eq(stats.player(P1).kills, 1, "kill registrado antes do fim")


## HUD da fase 2 (F17): kill da fase 2 vira kill_scored com o total, antes do fim da partida.
func test_kill_scored_so_na_fase_2_com_o_total() -> void:
	var scored: Array = []  # [peer, total, tick]
	_match.kill_scored.connect(
		func(peer: int, total: int, tick: int) -> void: scored.append([peer, total, tick])
	)
	_run(START, _at(60))
	_kill(_b, _a, _at(60) + 1)
	assert_eq(scored, [], "fase 1 nao conta")
	_b.hp = _b.attributes.max_hp  # renasce
	_run(_at(60) + 2, _at(310))
	_kill(_b, _a, _at(310) + 1)
	_b.hp = _b.attributes.max_hp
	_match.watch_heroes(_at(310) + 2)
	_kill(_b, _a, _at(310) + 3)
	assert_eq(scored, [[P1, 1, _at(310) + 1], [P1, 2, _at(310) + 3]])


func test_kill_scored_da_meta_chega_antes_do_fim() -> void:
	var order: Array[String] = []
	_match.kill_scored.connect(func(_p: int, _t: int, _k: int) -> void: order.append("kill"))
	_match.match_ended.connect(
		func(_w: int, _r: StringName, _s: MatchStats, _k: int) -> void: order.append("fim")
	)
	_run(START, _at(310))
	for i: int in _rules.kill_goal:
		_kill(_b, _a, _at(310) + 1 + i * 2)
		_b.hp = _b.attributes.max_hp
		_match.watch_heroes(_at(310) + 2 + i * 2)
	assert_eq(order.back(), "fim")
	assert_eq(order[order.size() - 2], "kill")


## zone_updated: 1 vez por segundo desde os 5:00, em todo peer (no cliente a zona nao fere).
func test_zone_updated_a_cada_segundo_da_fase_2() -> void:
	var updates: Array = []  # [radius, next_radius, damage_pct, t_next, tick]
	_zone.zone_updated.connect(
		func(radius: float, next: float, pct: float, t_next: float, tick: int) -> void:
			updates.append([radius, next, pct, t_next, tick])
	)
	_run(START, _at(300) - 1)
	assert_eq(updates, [], "fase 1 sem zona")
	_run(_at(300), _at(300) + RATE)
	assert_eq(updates.size(), 2, "5:00 e 5:01")
	assert_almost_eq(updates[0][0] as float, 35.0, 0.001)
	assert_almost_eq(updates[0][1] as float, 26.0, 0.001)
	assert_almost_eq(updates[0][2] as float, 0.01, 0.0001)
	assert_almost_eq(updates[0][3] as float, 60.0, 0.001)
	assert_eq(updates[0][4], _at(300))
	assert_almost_eq(updates[1][3] as float, 59.0, 0.001)


func test_zone_updated_tambem_no_cliente_sem_ferir() -> void:
	var client := ZoneController.new()
	client.rules = _rules
	client.clock = _clock
	add_child_autofree(client)
	var count := [0]
	client.zone_updated.connect(
		func(_r: float, _n: float, _p: float, _t: float, _k: int) -> void: count[0] += 1
	)
	_clock.update(START)
	client.update(_at(300), RATE)
	assert_false(client.active)
	assert_eq(count[0], 1)


## Vinheta (PATTERNS P8): o flag de "fora da zona" e do servidor, no estado do heroi; vale
## ate o pulso seguinte com folga e zera dentro do circulo.
func test_pulso_da_zona_liga_o_flag_fora_da_zona() -> void:
	_a.transform = Transform3D(Basis(), Vector3(30, 0, 0))
	_run(START, _at(360))
	_a._rollback_tick(TICK, _at(360) + 1, true)
	_b._rollback_tick(TICK, _at(360) + 1, true)
	assert_gt(_a.zone_ticks, RATE, "dura mais que o intervalo entre pulsos")
	assert_eq(_b.zone_ticks, 0, "dentro do circulo")
	for tick: int in range(_at(360) + 2, _at(360) + 2 + _a.zone_ticks):
		_a._rollback_tick(TICK, tick, true)
	assert_eq(_a.zone_ticks, 0, "sem pulso novo, apaga")


## F18: o servidor soma as estatisticas da partida e as manda no match_ended. Morte conta nas
## duas fases (kill so na fase 2); monstro, bau e boss so de quem tem vaga; nivel, dano,
## equipamento e heroi saem do estado no fim; duracao pelo relogio.
func test_estatisticas_somadas_no_servidor_chegam_no_fim() -> void:
	_run(START, _at(60))
	_match.report_monster_killed(P1, _at(60))
	_match.report_monster_killed(P1, _at(61))
	_match.report_monster_killed(0, _at(61))  # sem vaga: ignorado
	_match.report_chest_opened(P2, -5, _at(62))
	_match.report_chest_opened(P2, -6, _at(63))
	_match.report_chest_opened(P1, -7, _at(64))
	_kill(_a, _b, _at(100))
	_a.hp = _a.attributes.max_hp  # renasce
	_match.watch_heroes(_at(100) + 1)
	_run(_at(100) + 2, _at(215))
	_match.report_boss_killed(P1, _at(215))
	_run(_at(215) + 1, _at(310))
	var sword := Ids.to_int(&"sword_t2")
	_a.equipment = Vector4i(sword, Ids.NONE, Ids.NONE, Ids.NONE)
	var tick := _at(310) + 1
	for i: int in _rules.kill_goal:
		_kill(_b, _a, tick + i * 2)
		_b.hp = _b.attributes.max_hp
		_match.watch_heroes(tick + i * 2 + 1)
	var end_tick: int = _ended[0][3]
	var stats: MatchStats = _ended[0][2]
	var a := stats.player(P1)
	var b := stats.player(P2)
	assert_eq(stats.players().size(), 2)
	assert_almost_eq(stats.duration, float(end_tick - START) / RATE, 0.001)
	assert_eq([a.kills, b.kills], [_rules.kill_goal, 0], "kill da fase 1 nao conta")
	assert_eq([a.deaths, b.deaths], [1, _rules.kill_goal], "morte conta nas duas fases")
	assert_eq([a.monsters, b.monsters], [2, 0])
	assert_eq([a.chests, b.chests], [1, 2])
	assert_eq([a.boss_killed, b.boss_killed], [true, false])
	assert_eq(a.hero, Ids.to_int(&"knight"))
	assert_eq(a.level, _a.level)
	assert_eq(a.equipment, _a.equipment)
	assert_gt(a.hero_damage, 0)
	assert_eq(b.damage_taken, a.hero_damage, "o unico dano de B veio de A")
	assert_eq(a.damage_taken, b.hero_damage)
