extends GutTest
## INTRO do MatchController (F69, CONVENTION §3, ADR-0015): entra ao concluir o pick, sai com 5 s
## no minimo e o ready dos dois (bot e desconectado contam como prontos) ou aos 8 s; o relogio da
## fase 1 so comeca no fim dela. Ticks falsos a 30 Hz, como no test_match_controller.

const RULES: String = "res://shared/data/rules/match_pacing.tres"
const RATE: int = 30
const START: int = 1000
const P1: int = 11
const P2: int = 22
const P3: int = 33
const INTRO_MIN: int = 5 * RATE
const INTRO_MAX: int = 8 * RATE

var _match: MatchController
var _clock: MatchClock
var _phases: Array = []  # [from, to, tick]


func before_each() -> void:
	_phases = []
	var rules := load(RULES) as MatchRules
	_clock = MatchClock.new()
	_clock.rules = rules
	add_child_autofree(_clock)
	_match = MatchController.new()
	_match.rules = rules
	_match.clock = _clock
	_match.available_heroes = [&"knight", &"ranger"]
	add_child_autofree(_match)
	_match.phase_changed.connect(
		func(from: int, to: int, tick: int) -> void: _phases.append([from, to, tick])
	)
	_match.open(START, RATE)


func _run(from: int, to: int) -> void:
	for tick: int in range(from, to + 1):
		_clock.update(tick)
		_match.update(tick)


func _to_pick() -> void:
	_match.join(P1, GateRules.TEAM_A, false, START)
	_match.join(P2, GateRules.TEAM_B, false, START)


func _to_intro() -> void:
	_to_pick()
	_match.submit_pick(P1, &"knight", START)
	_match.submit_pick(P2, &"knight", START)


func _to_phase1() -> void:
	_to_intro()
	_match.submit_ready(P1, START)
	_match.submit_ready(P2, START)
	_run(START, START + INTRO_MIN)


func test_intro_nao_sai_antes_de_5_s_mesmo_com_ready_dos_dois() -> void:
	_to_intro()
	assert_true(_match.submit_ready(P1, START + 10))
	assert_true(_match.submit_ready(P2, START + 20))
	_run(START, START + INTRO_MIN - 1)
	assert_eq(_match.state, MatchState.State.INTRO)
	assert_false(_clock.is_started())


func test_intro_sai_aos_5_s_com_ready_dos_dois_e_o_relogio_comeca_nesse_tick() -> void:
	_to_intro()
	_match.submit_ready(P1, START + 10)
	_match.submit_ready(P2, START + 20)
	_run(START, START + INTRO_MIN)
	assert_eq(_match.state, MatchState.State.PHASE1)
	assert_true(_clock.is_started())
	assert_eq(_clock.start_tick, START + INTRO_MIN)
	assert_eq(_clock.elapsed(START + INTRO_MIN), 0.0, "t_match comeca em 0:00")
	var s := MatchState.State
	assert_eq(_phases.back(), [s.INTRO, s.PHASE1, START + INTRO_MIN])


func test_ready_depois_dos_5_s_abre_a_fase_1_na_hora() -> void:
	_to_intro()
	_match.submit_ready(P1, START)
	_run(START, START + 6 * RATE)
	assert_eq(_match.state, MatchState.State.INTRO, "falta o ready do P2")
	assert_true(_match.submit_ready(P2, START + 6 * RATE + 1))
	assert_eq(_match.state, MatchState.State.PHASE1)
	assert_eq(_clock.start_tick, START + 6 * RATE + 1)


func test_ready_atrasado_corta_aos_8_s_e_a_fase_1_abre_uma_vez() -> void:
	_to_intro()
	_match.submit_ready(P1, START + 10)
	_run(START, START + INTRO_MAX - 1)
	assert_eq(_match.state, MatchState.State.INTRO)
	_run(START + INTRO_MAX, START + INTRO_MAX)
	assert_eq(_match.state, MatchState.State.PHASE1)
	assert_eq(_clock.start_tick, START + INTRO_MAX)
	_match.submit_ready(P2, START + INTRO_MAX + 5)
	var entries := _phases.filter(func(p: Array) -> bool: return p[1] == MatchState.State.PHASE1)
	assert_eq(entries.size(), 1, "uma entrada na fase 1, com o mesmo tick para todos")
	assert_eq(entries[0][2], START + INTRO_MAX)


func test_bot_acusa_ready_imediato() -> void:
	_match.join(P1, GateRules.TEAM_A, false, START)
	_match.join(P2, GateRules.TEAM_B, true, START)
	_match.submit_pick(P1, &"knight", START)
	_match.submit_pick(P2, &"knight", START)
	_match.submit_ready(P1, START + 1)
	_run(START, START + INTRO_MIN)
	assert_eq(_match.state, MatchState.State.PHASE1, "so o ready humano foi preciso")


func test_jogador_desconectado_nao_segura_a_intro() -> void:
	_to_intro()
	_match.leave(P2, START + 5)
	_match.submit_ready(P1, START + 6)
	_run(START, START + INTRO_MIN)
	assert_eq(_match.state, MatchState.State.PHASE1)


func test_queda_na_intro_nao_dispensa_os_5_s_minimos() -> void:
	_to_intro()
	_match.submit_ready(P1, START)
	_match.leave(P2, START + 10)
	assert_eq(_match.state, MatchState.State.INTRO)
	_run(START, START + INTRO_MIN)
	assert_eq(_match.state, MatchState.State.PHASE1)


func test_ready_recusado_fora_da_intro_ou_de_peer_de_fora() -> void:
	_to_pick()
	assert_false(_match.submit_ready(P1, START), "ainda na selecao")
	_match.submit_pick(P1, &"knight", START)
	_match.submit_pick(P2, &"knight", START)
	assert_false(_match.submit_ready(P3, START + 1), "peer sem vaga")
	_match.submit_ready(P1, START + 1)
	_match.submit_ready(P2, START + 1)
	_run(START, START + INTRO_MIN)
	assert_false(_match.submit_ready(P1, START + INTRO_MIN + 1), "ja na fase 1")


## CONVENTION §3: LOBBY_WAIT -> HERO_PICK -> INTRO -> PHASE1 -> TRANSITION ..., sem pular.
func test_tabela_de_transicoes_inclui_a_intro() -> void:
	_to_phase1()
	var s := MatchState.State
	var path: Array = _phases.map(func(p: Array) -> Array: return [p[0], p[1]])
	assert_eq(path, [[s.LOBBY_WAIT, s.HERO_PICK], [s.HERO_PICK, s.INTRO], [s.INTRO, s.PHASE1]])
	assert_eq(
		s.keys(),
		[
			"LOBBY_WAIT",
			"HERO_PICK",
			"INTRO",
			"PHASE1",
			"TRANSITION",
			"PHASE2",
			"SUDDEN_DEATH",
			"ENDED"
		]
	)
