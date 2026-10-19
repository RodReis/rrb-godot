# gdlint: ignore=max-public-methods
extends GutTest
## MatchController com relogio injetado (ticks falsos a 30 Hz, ARCHITECTURE-GAME §8):
## LOBBY_WAIT -> HERO_PICK -> INTRO -> PHASE1 -> TRANSITION (CONVENTION §3), timeout do lobby ->
## ENDED/abandoned, timeout do pick -> padrao do slot, espelho aceito, lock-in duplicado ou
## invalido recusado. INTRO (F69): minimo 5 s e ready dos dois, ou corte aos 8 s; o relogio da
## fase 1 so comeca no fim dela.

const RULES: String = "res://shared/data/rules/match_pacing.tres"
const RATE: int = 30
const START: int = 1000
const P1: int = 11
const P2: int = 22
const P3: int = 33
const INTRO_MIN: int = 5 * RATE
const INTRO_MAX: int = 8 * RATE
const BOTH: Array[StringName] = [&"knight", &"ranger"]
const KNIGHT_ONLY: Array[StringName] = [&"knight"]

var _match: MatchController
var _clock: MatchClock
var _phases: Array = []  # [from, to, tick]
var _picks: Array = []  # [peer, hero_id, tick]
var _ended: Array = []  # [winner, reason, tick]


func before_each() -> void:
	_phases = []
	_picks = []
	_ended = []
	var rules := load(RULES) as MatchRules
	_clock = MatchClock.new()
	_clock.rules = rules
	add_child_autofree(_clock)
	_match = MatchController.new()
	_match.rules = rules
	_match.clock = _clock
	_match.available_heroes = BOTH.duplicate()
	add_child_autofree(_match)
	_match.phase_changed.connect(
		func(from: int, to: int, tick: int) -> void: _phases.append([from, to, tick])
	)
	_match.hero_picked.connect(
		func(peer: int, hero_id: int, tick: int) -> void: _picks.append([peer, hero_id, tick])
	)
	_match.match_ended.connect(
		func(winner: int, reason: StringName, _stats: MatchStats, tick: int) -> void:
			_ended.append([winner, reason, tick])
	)
	_match.open(START, RATE)


func _run(from: int, to: int) -> void:
	for tick: int in range(from, to + 1):
		_clock.update(tick)
		_match.update(tick)


## Os dois jogadores entram no tick START; a selecao comeca ali.
func _to_pick() -> void:
	_match.join(P1, GateRules.TEAM_A, false, START)
	_match.join(P2, GateRules.TEAM_B, false, START)


## Os dois escolhem no tick START e acusam ready na hora: a INTRO dura o minimo e abre a fase 1.
func _to_phase1() -> void:
	_to_intro()
	_match.submit_ready(P1, START)
	_match.submit_ready(P2, START)
	_run(START, START + INTRO_MIN)


func _to_intro() -> void:
	_to_pick()
	_match.submit_pick(P1, &"knight", START)
	_match.submit_pick(P2, &"knight", START)


func _hero_of(peer: int) -> StringName:
	for seat: MatchController.Seat in _match.seats():
		if seat.peer == peer:
			return seat.hero
	return &"?"


func test_comeca_esperando_jogadores() -> void:
	assert_eq(_match.state, MatchState.State.LOBBY_WAIT)
	assert_false(_clock.is_started())


func test_dois_jogadores_abrem_a_selecao() -> void:
	_match.join(P1, GateRules.TEAM_A, false, START)
	assert_eq(_match.state, MatchState.State.LOBBY_WAIT)
	_match.join(P2, GateRules.TEAM_B, false, START + 5)
	assert_eq(_match.state, MatchState.State.HERO_PICK)
	var s := MatchState.State
	assert_eq(_phases, [[s.LOBBY_WAIT, s.HERO_PICK, START + 5]])


func test_terceiro_jogador_e_recusado() -> void:
	_to_pick()
	assert_false(_match.join(P3, GateRules.TEAM_A, false, START))
	assert_eq(_match.seats().size(), 2)


func test_sem_segundo_jogador_a_partida_e_abandonada_no_timeout() -> void:
	_match.join(P1, GateRules.TEAM_A, false, START)
	var timeout := START + 120 * RATE
	_run(START, timeout - 1)
	assert_eq(_match.state, MatchState.State.LOBBY_WAIT)
	_run(timeout, timeout)
	assert_eq(_match.state, MatchState.State.ENDED)
	assert_eq(_ended, [[MatchController.NO_WINNER, MatchController.REASON_ABANDONED, timeout]])
	_run(timeout + 1, timeout + 10 * RATE)
	assert_eq(_ended.size(), 1, "fim so uma vez")


func test_quem_sai_no_lobby_libera_a_vaga() -> void:
	_match.join(P1, GateRules.TEAM_A, false, START)
	_match.leave(P1, START + 1)
	assert_eq(_match.seats().size(), 0)
	assert_true(_match.join(P2, GateRules.TEAM_A, false, START + 2))
	assert_true(_match.join(P3, GateRules.TEAM_B, false, START + 3))
	assert_eq(_match.state, MatchState.State.HERO_PICK)


func test_lock_in_dos_dois_abre_a_intro_sem_relogio() -> void:
	_to_pick()
	assert_true(_match.submit_pick(P1, &"knight", START + 30))
	assert_eq(_match.state, MatchState.State.HERO_PICK)
	assert_true(_match.submit_pick(P2, &"ranger", START + 60))
	assert_eq(_match.state, MatchState.State.INTRO)
	assert_false(_clock.is_started(), "o relogio so corre depois da INTRO")
	assert_eq(_match.deadline_tick, START + 60 + INTRO_MAX)
	assert_eq(_picks.size(), 2)
	assert_eq(_picks[0], [P1, Ids.to_int(&"knight"), START + 30])
	var s := MatchState.State
	assert_eq(_phases.back(), [s.HERO_PICK, s.INTRO, START + 60])


func test_timeout_do_pick_da_o_heroi_padrao_do_slot() -> void:
	_to_pick()
	var deadline := START + 24 * RATE
	_run(START, deadline - 1)
	assert_eq(_match.state, MatchState.State.HERO_PICK)
	_run(deadline, deadline)
	assert_eq(_match.state, MatchState.State.INTRO)
	assert_eq(_hero_of(P1), &"knight")
	assert_eq(_hero_of(P2), &"ranger")


func test_timeout_com_a_arqueira_indisponivel_da_o_cavaleiro_ao_p2() -> void:
	_match.available_heroes = KNIGHT_ONLY.duplicate()
	_to_pick()
	_run(START, START + 24 * RATE)
	assert_eq(_hero_of(P2), &"knight")


func test_so_quem_nao_confirmou_recebe_o_padrao() -> void:
	_to_pick()
	_match.submit_pick(P2, &"knight", START + 1)
	_run(START, START + 24 * RATE)
	assert_eq(_hero_of(P1), &"knight")
	assert_eq(_hero_of(P2), &"knight")


func test_espelho_e_aceito() -> void:
	_to_pick()
	assert_true(_match.submit_pick(P1, &"knight", START))
	assert_true(_match.submit_pick(P2, &"knight", START))
	assert_eq(_match.state, MatchState.State.INTRO)


func test_lock_in_duplicado_e_recusado() -> void:
	_to_pick()
	assert_true(_match.submit_pick(P1, &"knight", START))
	assert_false(_match.submit_pick(P1, &"ranger", START + 1))
	assert_eq(_hero_of(P1), &"knight")
	assert_eq(_picks.size(), 1)


func test_lock_in_invalido_e_recusado() -> void:
	_match.available_heroes = KNIGHT_ONLY.duplicate()
	_to_pick()
	assert_false(_match.submit_pick(P1, &"ranger", START), "heroi indisponivel")
	assert_false(_match.submit_pick(P1, &"", START), "sem heroi")
	assert_false(_match.submit_pick(P1, &"golem_t3", START), "nao e heroi")
	assert_false(_match.submit_pick(P3, &"knight", START), "peer fora da partida")
	assert_eq(_picks, [])


func test_lock_in_fora_da_selecao_e_recusado() -> void:
	_match.join(P1, GateRules.TEAM_A, false, START)
	assert_false(_match.submit_pick(P1, &"knight", START), "ainda no lobby")
	_match.join(P2, GateRules.TEAM_B, false, START)
	_match.submit_pick(P1, &"knight", START)
	_match.submit_pick(P2, &"knight", START)
	assert_false(_match.submit_pick(P1, &"knight", START + 1), "ja na INTRO")


func test_quem_cai_na_selecao_fica_com_o_padrao_e_desconectado() -> void:
	_to_pick()
	_match.leave(P2, START + 10)
	_run(START, START + 24 * RATE)
	assert_eq(_match.state, MatchState.State.INTRO)
	assert_eq(_hero_of(P2), &"ranger")
	for seat: MatchController.Seat in _match.seats():
		assert_eq(seat.connected, seat.peer != P2)


func test_queda_na_selecao_nao_faz_o_outro_esperar_o_prazo() -> void:
	_to_pick()
	_match.submit_pick(P1, &"knight", START + 10)
	_match.leave(P2, START + 20)
	assert_eq(_match.state, MatchState.State.INTRO)
	assert_eq(_hero_of(P2), &"ranger")
	assert_false(_clock.is_started())


func test_fase_1_vira_transicao_aos_5_00() -> void:
	_to_phase1()
	assert_eq(_clock.start_tick, START + INTRO_MIN, "5:00 conta a partir do fim da INTRO")
	var five_minutes := START + INTRO_MIN + 300 * RATE
	_run(START + INTRO_MIN + 1, five_minutes - 1)
	assert_eq(_match.state, MatchState.State.PHASE1)
	_run(five_minutes, five_minutes)
	assert_eq(_match.state, MatchState.State.TRANSITION)
	var s := MatchState.State
	assert_eq(_phases.back(), [s.PHASE1, s.TRANSITION, five_minutes])


func test_relogio_adiantado_de_dev_comeca_a_fase_1_ja_avancada() -> void:
	_match.start_seconds = 290.0
	_to_phase1()
	_run(START + INTRO_MIN + 1, START + INTRO_MIN + 10 * RATE)
	assert_eq(_match.state, MatchState.State.TRANSITION)


## F80 / ADR-0020: sair pelo menu com os dois conectados encerra na hora; quem sai perde.
func test_sair_pelo_menu_na_selecao_da_vitoria_ao_outro_e_fixa_o_heroi_de_quem_saiu() -> void:
	_to_pick()
	assert_true(_match.leave_by_menu(P1, START + 1))
	assert_eq(_ended, [[P2, VictoryRules.LEFT, START + 1]])
	assert_eq(_match.state, MatchState.State.ENDED)
	for seat: MatchController.Seat in _match.seats():
		assert_ne(seat.hero, &"", "quem saiu fica com heroi (o resultado precisa da linha dele)")


func test_sair_pelo_menu_na_intro() -> void:
	_to_intro()
	assert_eq(_match.state, MatchState.State.INTRO)
	assert_true(_match.leave_by_menu(P2, START + 2))
	assert_eq(_ended, [[P1, VictoryRules.LEFT, START + 2]])


func test_sair_pelo_menu_na_fase_1() -> void:
	_to_phase1()
	assert_eq(_match.state, MatchState.State.PHASE1)
	assert_true(_match.leave_by_menu(P1, START + INTRO_MIN + 3))
	assert_eq(_ended.size(), 1)
	assert_eq(_ended[0][0], P2)
	assert_eq(_ended[0][1], VictoryRules.LEFT)


func test_sair_no_lobby_nao_encerra() -> void:
	_match.join(P1, GateRules.TEAM_A, false, START)
	assert_false(_match.leave_by_menu(P1, START + 1))
	assert_eq(_ended, [])
	assert_eq(_match.state, MatchState.State.LOBBY_WAIT)


func test_sair_duas_vezes_nao_encerra_de_novo() -> void:
	_to_pick()
	assert_true(_match.leave_by_menu(P1, START + 1))
	assert_false(_match.leave_by_menu(P1, START + 2))
	assert_false(_match.leave_by_menu(P2, START + 2), "ja acabou: o outro nao 'sai' depois")
	assert_eq(_ended.size(), 1)


func test_peer_de_fora_nao_encerra_a_partida() -> void:
	_to_pick()
	assert_false(_match.leave_by_menu(P3, START + 1))
	assert_eq(_ended, [])


func test_com_o_adversario_desconectado_sair_so_desconecta() -> void:
	_to_pick()
	_match.leave(P2, START + 1)
	assert_false(_match.leave_by_menu(P1, START + 2))
	assert_eq(_ended, [])
