extends GutTest
## MatchClock com tick falso a 30 Hz: aviso do boss 3:00, boss 3:30, fim da fase 1 5:00
## (GDB §5.1, §7.1; CONVENTION §4.1), cada evento uma vez, no tick certo.

const RULES: String = "res://shared/data/rules/match_pacing.tres"
const RATE: int = 30
const START: int = 1000

var _clock: MatchClock
var _fired: Dictionary = {}  # sinal -> [ticks]


func before_each() -> void:
	_fired = {}
	_clock = MatchClock.new()
	_clock.rules = load(RULES) as MatchRules
	add_child_autofree(_clock)
	for event: StringName in [&"boss_warning", &"boss_spawned", &"phase1_ended"]:
		_fired[event] = []
		_clock.connect(event, func(tick: int) -> void: (_fired[event] as Array).append(tick))


func _run(from: int, to: int) -> void:
	for tick: int in range(from, to + 1):
		_clock.update(tick)


func test_parado_nao_dispara_nada() -> void:
	assert_false(_clock.is_started())
	_run(START, START + 10000)
	for event: StringName in _fired:
		assert_eq(_fired[event], [], event)
	assert_eq(_clock.elapsed(START), 0.0)


func test_dispara_3_00_3_30_e_5_00_nos_ticks_certos() -> void:
	_clock.start(START, RATE)
	_run(START, START + 6 * 60 * RATE)
	assert_eq(_fired[&"boss_warning"], [START + 180 * RATE])
	assert_eq(_fired[&"boss_spawned"], [START + 210 * RATE])
	assert_eq(_fired[&"phase1_ended"], [START + 300 * RATE])


func test_um_tick_antes_nao_dispara() -> void:
	_clock.start(START, RATE)
	_run(START, START + 180 * RATE - 1)
	assert_eq(_fired[&"boss_warning"], [])


func test_tempo_decorrido_em_segundos() -> void:
	_clock.start(START, RATE)
	assert_almost_eq(_clock.elapsed(START + 95 * RATE), 95.0, 0.0001)


func test_comecar_adiantado_dispara_o_que_ja_passou_no_primeiro_tick() -> void:
	_clock.start(START, RATE, 200.0)
	_clock.update(START)
	assert_eq(_fired[&"boss_warning"], [START])
	assert_eq(_fired[&"boss_spawned"], [])
	_run(START + 1, START + 10 * RATE)
	assert_eq(_fired[&"boss_spawned"], [START + 10 * RATE])


func test_start_de_novo_e_ignorado() -> void:
	_clock.start(START, RATE)
	_clock.start(START + 500, RATE)
	assert_eq(_clock.start_tick, START)
