extends GutTest
## KillTracker (GDB §3.3, §7.2): kill so na fase 2 (I3), XP por kill e dano causado em herois,
## contado uma vez mesmo com o tick ressimulado; zona e monstro nao contam como dano de heroi.

const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const RULES: String = "res://shared/data/rules/match_pacing.tres"
const TICK: float = 1.0 / 30.0
const START: int = 1000
const P1: int = 11
const P2: int = 22
const BLOW: int = 100

var _rules: MatchRules
var _tracker: KillTracker


func before_each() -> void:
	_rules = load(RULES) as MatchRules
	_tracker = KillTracker.new()


func _spawn(peer: int, team: int) -> Hero:
	var hero := (load(KNIGHT) as PackedScene).instantiate() as Hero
	hero.name = str(peer)
	hero.team = team
	add_child_autofree(hero)
	return hero


func test_kill_na_fase_1_nao_conta() -> void:
	assert_false(_tracker.score(P1, MatchState.State.PHASE1))
	assert_eq(_tracker.kills(P1), 0)


func test_kill_na_fase_2_conta_a_partir_da_transicao() -> void:
	assert_true(_tracker.score(P1, MatchState.State.TRANSITION))
	assert_true(_tracker.score(P1, MatchState.State.PHASE2))
	assert_true(_tracker.score(P1, MatchState.State.SUDDEN_DEATH))
	assert_eq(_tracker.kills(P1), 3)
	assert_eq(_tracker.kills(P2), 0)


func test_morte_sem_heroi_matador_nao_conta() -> void:
	assert_false(_tracker.score(0, MatchState.State.PHASE2), "zona ou monstro")


func test_xp_por_kill() -> void:
	assert_eq(KillTracker.reward_xp(_rules, MatchState.State.PHASE1, 4), 80)
	assert_eq(KillTracker.reward_xp(_rules, MatchState.State.TRANSITION, 4), 230)
	assert_eq(KillTracker.reward_xp(_rules, MatchState.State.PHASE2, 10), 350)


func test_dano_em_heroi_conta_uma_vez_com_ressimulacao() -> void:
	var a := _spawn(P1, GateRules.TEAM_A)
	var b := _spawn(P2, GateRules.TEAM_B)
	var blow := HitEffect.new(BLOW, a.global_position)
	blow.attacker_id = P1
	b.receive_hit(START, HitLedger.source_key(P1, HitLedger.Slot.BASIC), blow)
	var hp_before := b.hp
	b._rollback_tick(TICK, START, true)
	var dealt := hp_before - b.hp
	assert_gt(dealt, 0)
	b.hp = hp_before  # o rollback restaura o estado e ressimula o mesmo tick
	b._rollback_tick(TICK, START, false)
	var heroes: Array[Hero] = [a, b]
	assert_eq(_tracker.damage_dealt(P1, heroes), dealt)
	assert_eq(_tracker.damage_dealt(P2, heroes), 0)


func test_zona_nao_conta_como_dano_de_heroi() -> void:
	var a := _spawn(P1, GateRules.TEAM_A)
	var zone := HitEffect.new()
	zone.true_damage = BLOW
	a.receive_hit(START, HitLedger.source_key(0, HitLedger.Slot.ZONE), zone)
	var hp_before := a.hp
	a._rollback_tick(TICK, START, true)
	assert_eq(a.hp, hp_before - BLOW, "zona ignora DEF")
	var heroes: Array[Hero] = [a]
	assert_eq(_tracker.damage_dealt(0, heroes), 0)


## F18: dano sofrido soma toda fonte (heroi, monstro, zona), uma vez por tick ressimulado.
func test_dano_sofrido_conta_toda_fonte_uma_vez_com_ressimulacao() -> void:
	var a := _spawn(P1, GateRules.TEAM_A)
	var b := _spawn(P2, GateRules.TEAM_B)
	var blow := HitEffect.new(BLOW, a.global_position)
	blow.attacker_id = P1
	b.receive_hit(START, HitLedger.source_key(P1, HitLedger.Slot.BASIC), blow)
	var monster := HitEffect.new(BLOW, a.global_position)  # monstro: attacker_id 0
	b.receive_hit(START, HitLedger.source_key(-3, HitLedger.Slot.BASIC), monster)
	var zone := HitEffect.new()
	zone.true_damage = BLOW
	b.receive_hit(START + 1, HitLedger.source_key(0, HitLedger.Slot.ZONE), zone)
	var hp_before := b.hp
	b._rollback_tick(TICK, START, true)
	b._rollback_tick(TICK, START + 1, true)
	var taken := hp_before - b.hp
	b.hp = hp_before  # o rollback restaura o estado e ressimula os mesmos ticks
	b._rollback_tick(TICK, START, false)
	b._rollback_tick(TICK, START + 1, false)
	assert_eq(b.damage_taken(), taken)
	assert_eq(a.damage_taken(), 0)
