extends GutTest
## Morte de heroi por fase (GDB §3.3): fase 1 = respawn 8 s, nao conta kill; a partir da
## TRANSITION vale a fase 2 (CONVENTION §3): 6 s, conta kill. XP do abate: test_xp_table.

const RULES: String = "res://shared/data/rules/match_pacing.tres"

var _rules: MatchRules


func before_all() -> void:
	_rules = load(RULES) as MatchRules


func test_fase_2_comeca_na_transicao_e_acaba_antes_do_fim() -> void:
	var s := MatchState.State
	assert_false(MatchState.is_phase2(s.LOBBY_WAIT))
	assert_false(MatchState.is_phase2(s.HERO_PICK))
	assert_false(MatchState.is_phase2(s.PHASE1))
	assert_true(MatchState.is_phase2(s.TRANSITION))
	assert_true(MatchState.is_phase2(s.PHASE2))
	assert_true(MatchState.is_phase2(s.SUDDEN_DEATH))
	assert_false(MatchState.is_phase2(s.ENDED))


func test_morte_na_fase_1_nao_conta_kill() -> void:
	assert_false(KillRules.counts_kill(MatchState.State.PHASE1))


func test_morte_na_fase_2_conta_kill() -> void:
	assert_true(KillRules.counts_kill(MatchState.State.TRANSITION))
	assert_true(KillRules.counts_kill(MatchState.State.PHASE2))


func test_respawn_8_s_na_fase_1_e_6_s_na_fase_2() -> void:
	assert_eq(KillRules.respawn_seconds(_rules, MatchState.State.PHASE1), 8.0)
	assert_eq(KillRules.respawn_seconds(_rules, MatchState.State.TRANSITION), 6.0)
