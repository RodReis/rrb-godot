extends GutTest


func test_a_partida_corre_da_fase_1_a_morte_subita() -> void:
	var s := MatchState.State
	for state: MatchState.State in [s.PHASE1, s.TRANSITION, s.PHASE2, s.SUDDEN_DEATH]:
		assert_true(MatchState.is_running(state), MatchState.State.keys()[state])


func test_antes_da_fase_1_e_depois_do_fim_nao_corre() -> void:
	var s := MatchState.State
	for state: MatchState.State in [s.LOBBY_WAIT, s.HERO_PICK, s.INTRO, s.ENDED]:
		assert_false(MatchState.is_running(state), MatchState.State.keys()[state])
