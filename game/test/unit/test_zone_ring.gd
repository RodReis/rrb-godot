extends GutTest
## Parede da zona (F16; visual final no F17): escondida antes dos 5:00, no raio de ZoneRules
## depois, surgindo aos poucos nos 5 s da transicao e escondida no colapso (raio 0).

const RULES: String = "res://shared/data/rules/match_pacing.tres"
const RATE: int = 30
const START: int = 1000

var _clock: MatchClock
var _ring: ZoneRing


func before_each() -> void:
	var rules := load(RULES) as MatchRules
	_clock = MatchClock.new()
	_clock.rules = rules
	add_child_autofree(_clock)
	_ring = ZoneRing.new()
	_ring.clock = _clock
	_ring.rules = rules
	add_child_autofree(_ring)


func test_escondida_antes_da_partida_e_da_fase_2() -> void:
	_ring.refresh(START)
	assert_false(_ring.is_shown())
	_clock.start(START, RATE)
	_ring.refresh(START + 299 * RATE)
	assert_false(_ring.is_shown())


func test_segue_o_raio_da_zona() -> void:
	_clock.start(START, RATE)
	_ring.refresh(START + 300 * RATE)
	assert_true(_ring.is_shown())
	assert_almost_eq(_ring.radius(), 35.0, 0.001)
	_ring.refresh(START + 390 * RATE)
	assert_almost_eq(_ring.radius(), 21.75, 0.001)


func test_some_no_colapso() -> void:
	_clock.start(START, RATE)
	_ring.refresh(START + 600 * RATE)
	assert_false(_ring.is_shown())


func test_surge_aos_poucos_na_transicao() -> void:
	_clock.start(START, RATE)
	_ring.refresh(START + roundi(302.5 * RATE))
	assert_almost_eq(_ring.appear(), 0.5, 0.001)
	_ring.refresh(START + 305 * RATE)
	assert_almost_eq(_ring.appear(), 1.0, 0.001)
