extends GutTest
## Sentido da luz do ciclo dia/noite no MatchController (F49): sorteado pela seed ao abrir a selecao
## de herois, --daynight vence a seed, e nao muda depois.

const RULES: String = "res://shared/data/rules/match_pacing.tres"
const RATE: int = 30
const START: int = 1000
const P1: int = 11
const P2: int = 22

var _match: MatchController


func before_each() -> void:
	var rules := load(RULES) as MatchRules
	var clock := MatchClock.new()
	clock.rules = rules
	add_child_autofree(clock)
	_match = MatchController.new()
	_match.rules = rules
	_match.clock = clock
	_match.available_heroes = [&"knight", &"ranger"]
	add_child_autofree(_match)
	_match.open(START, RATE)


func _to_pick() -> void:
	_match.join(P1, GateRules.TEAM_A, false, START)
	_match.join(P2, GateRules.TEAM_B, false, START)


func test_sentido_da_luz_sai_da_seed_e_chega_na_selecao() -> void:
	_match.match_seed = 1
	var expected := DayNightRules.starts_at_day(1)
	_to_pick()
	assert_eq(_match.day_to_night, expected)


func test_daynight_forcado_vence_a_seed() -> void:
	_match.match_seed = 1
	_match.forced_daynight = LaunchArgs.DAYNIGHT_NIGHT
	_to_pick()
	assert_false(_match.day_to_night)


func test_sentido_da_luz_nao_muda_depois_da_selecao() -> void:
	_match.forced_daynight = LaunchArgs.DAYNIGHT_DAY
	_to_pick()
	_match.forced_daynight = LaunchArgs.DAYNIGHT_NIGHT
	_match.submit_pick(P1, &"knight", START)
	_match.submit_pick(P2, &"ranger", START)
	assert_true(_match.day_to_night)
