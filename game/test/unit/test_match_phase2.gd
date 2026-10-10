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
		func(winner: int, reason: StringName, stats: Dictionary, tick: int) -> void:
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
	assert_true(_a.respawn_enabled)
	assert_eq(_a.respawn_seconds, 6.0)
	_run(_at(540), _at(540))
	assert_eq(_match.state, MatchState.State.SUDDEN_DEATH)
	assert_false(_a.respawn_enabled)
	assert_false(_b.respawn_enabled)


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
	var stats: Dictionary = _ended[0][2]
	assert_eq(stats[P1]["kills"], 5)
	assert_eq(stats[P2]["kills"], 0)
	assert_gt(stats[P1]["hero_damage"], 0)


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
