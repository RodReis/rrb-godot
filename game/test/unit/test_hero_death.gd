extends GutTest
## Morte de heroi (GDB §3.3, CONVENTION §4.1): na fase 1 renasce em 8 s na propria base com HP
## cheio e sem perder itens, nao conta kill e o matador ganha 80 XP; na fase 2 (a partir da
## TRANSITION) conta kill. Morto nao anda, nao bloqueia e nao e alvo.

const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const RULES: String = "res://shared/data/rules/match_pacing.tres"
const TICK: float = 1.0 / 30.0
const RATE: int = 30
const START: int = 1000
const VICTIM: int = 11
const KILLER: int = 22
const HOME: Vector3 = Vector3(-20, 0, 15)
const AWAY: Vector3 = Vector3(5, 0, 5)
const LETHAL: int = 100000

var _rules: MatchRules
var _match: MatchController
var _clock: MatchClock
var _victim: Hero
var _killer: Hero
var _deaths: Array = []  # [peer, killer, tick]


func before_each() -> void:
	_deaths = []
	_rules = load(RULES) as MatchRules
	_clock = MatchClock.new()
	_clock.rules = _rules
	add_child_autofree(_clock)
	_match = MatchController.new()
	_match.rules = _rules
	_match.clock = _clock
	_match.available_heroes = [&"knight"]
	add_child_autofree(_match)
	_match.player_died.connect(
		func(peer: int, killer: int, tick: int) -> void: _deaths.append([peer, killer, tick])
	)
	_victim = _spawn(VICTIM, GateRules.TEAM_A, HOME)
	_killer = _spawn(KILLER, GateRules.TEAM_B, -HOME)
	_match.open(START, RATE)
	_match.join(VICTIM, GateRules.TEAM_A, false, START)
	_match.join(KILLER, GateRules.TEAM_B, false, START)
	_match.submit_pick(VICTIM, &"knight", START)
	_match.submit_pick(KILLER, &"knight", START)
	_victim.transform = Transform3D(Basis(), AWAY)


func _spawn(peer: int, team: int, where: Vector3) -> Hero:
	var hero := (load(KNIGHT) as PackedScene).instantiate() as Hero
	hero.name = str(peer)
	hero.team = team
	hero.transform = Transform3D(Basis(), where)
	add_child_autofree(hero)
	return hero


## Golpe letal do matador no [param tick], aplicado pela vitima no proprio tick.
func _kill(tick: int) -> void:
	var blow := HitEffect.new(LETHAL, _killer.global_position)
	blow.attacker_id = KILLER
	_victim.receive_hit(tick, HitLedger.source_key(KILLER, HitLedger.Slot.BASIC), blow)
	_victim._rollback_tick(TICK, tick, true)


func test_fase_1_configura_respawn_de_8_s() -> void:
	assert_eq(_match.state, MatchState.State.PHASE1)
	assert_eq(_victim.respawn_seconds, 8.0)


func test_morto_fica_inerte_e_fora_de_alcance() -> void:
	_kill(START)
	assert_false(_victim.is_alive())
	assert_eq(_victim.hp, 0)
	assert_eq(_victim.killer_id, KILLER)
	assert_eq(_victim.collision_layer, 0)
	_victim.input.movement = Vector3.FORWARD
	_victim._rollback_tick(TICK, START + 1, true)
	assert_eq(_victim.global_position, AWAY, "morto nao anda")
	assert_false(_killer._enemies().has(_victim), "morto nao e alvo")


func test_renasce_na_base_8_s_depois_com_hp_cheio_e_os_itens() -> void:
	_victim.equipment = Vector4i(Ids.to_int(&"sword_t1"), Ids.NONE, Ids.NONE, Ids.NONE)
	_kill(START)
	var respawn := START + 8 * RATE
	for tick: int in range(START + 1, respawn):
		_victim._rollback_tick(TICK, tick, true)
	assert_false(_victim.is_alive(), "ainda morto um tick antes")
	_victim._rollback_tick(TICK, respawn, true)
	assert_true(_victim.is_alive())
	assert_eq(_victim.hp, _victim.attributes.max_hp)
	assert_eq(_victim.global_position, HOME)
	assert_eq(_victim.equipment.x, Ids.to_int(&"sword_t1"), "sem perda de itens")
	assert_ne(_victim.collision_layer, 0)


func test_morte_na_fase_1_da_80_xp_ao_matador_e_nao_conta_kill() -> void:
	var xp_before := _killer.xp
	_kill(START)
	_match.watch_heroes(START)
	_killer._rollback_tick(TICK, START + 1, true)
	assert_eq(_killer.xp, xp_before + 80)
	assert_eq(_match.kills(KILLER), 0)
	assert_eq(_deaths, [[VICTIM, KILLER, START]])


func test_morte_e_avisada_uma_vez_por_queda() -> void:
	_kill(START)
	_match.watch_heroes(START)
	_match.watch_heroes(START + 1)
	_victim._rollback_tick(TICK, START + 1, true)
	_match.watch_heroes(START + 2)
	assert_eq(_deaths.size(), 1)


func test_morte_por_monstro_nao_da_xp_a_heroi() -> void:
	var xp_before := _killer.xp
	var blow := HitEffect.new(LETHAL)
	_victim.receive_hit(START, HitLedger.source_key(-3, HitLedger.Slot.BASIC), blow)
	_victim._rollback_tick(TICK, START, true)
	_match.watch_heroes(START)
	_killer._rollback_tick(TICK, START + 1, true)
	assert_eq(_killer.xp, xp_before)
	assert_eq(_deaths, [[VICTIM, 0, START]])


func test_na_transicao_a_morte_conta_kill() -> void:
	var five_minutes := START + 300 * RATE
	_clock.update(five_minutes)
	assert_eq(_match.state, MatchState.State.TRANSITION)
	assert_eq(_victim.respawn_seconds, 6.0)
	_kill(five_minutes)
	_match.watch_heroes(five_minutes)
	assert_eq(_match.kills(KILLER), 1)


func test_xp_de_abate_chega_mesmo_ao_matador_morto() -> void:
	var xp_before := _killer.xp
	var blow := HitEffect.new(LETHAL)
	_killer.receive_hit(START, HitLedger.source_key(-3, HitLedger.Slot.BASIC), blow)
	_killer._rollback_tick(TICK, START, true)
	_kill(START)
	_match.watch_heroes(START)
	_killer._rollback_tick(TICK, START + 1, true)
	assert_eq(_killer.xp, xp_before + 80)
