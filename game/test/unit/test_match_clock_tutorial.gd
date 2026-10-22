extends GutTest
## F85 (SPEC-085 §2, passo 6): o tutorial adianta o relogio ao fim da fase 1. Os eventos pulados
## (aviso e chegada do boss) nao disparam; o fim da fase 1 e as seguintes seguem nos tempos certos.

const RULES: String = "res://shared/data/rules/match_pacing.tres"
const RATE: int = 30
const START: int = 1000
const NOW: int = START + 40 * RATE

var _clock: MatchClock
var _fired: Dictionary = {}


func before_each() -> void:
	_fired = {}
	_clock = MatchClock.new()
	_clock.rules = load(RULES) as MatchRules
	add_child_autofree(_clock)
	for event: StringName in [
		&"boss_warning", &"boss_spawned", &"phase1_ended", &"transition_ended", &"collapsed"
	]:
		_fired[event] = []
		Signal(_clock, event).connect(
			func(tick: int) -> void: (_fired[event] as Array).append(tick)
		)
	_clock.start(START, RATE)
	_run(START, NOW)


func _run(from: int, to: int) -> void:
	for tick: int in range(from, to + 1):
		_clock.update(tick)


func test_salto_pula_o_boss_e_dispara_o_fim_da_fase_1() -> void:
	_clock.jump_to_phase1_end(NOW)
	_run(NOW, NOW + 10 * RATE)
	assert_eq(_fired[&"boss_warning"], [])
	assert_eq(_fired[&"boss_spawned"], [])
	assert_eq(_fired[&"phase1_ended"].size(), 1)
	assert_between(_fired[&"phase1_ended"][0], NOW, NOW + RATE)


func test_depois_do_salto_a_fase_2_chega_na_transicao_normal() -> void:
	_clock.jump_to_phase1_end(NOW)
	_run(NOW, NOW + 20 * RATE)
	var ended: int = _fired[&"phase1_ended"][0]
	assert_eq(
		_fired[&"transition_ended"], [ended + roundi(_clock.rules.transition_duration * RATE)]
	)


func test_relogio_marca_o_fim_da_fase_1_logo_depois_do_salto() -> void:
	_clock.jump_to_phase1_end(NOW)
	assert_almost_eq(_clock.elapsed(NOW), _clock.rules.phase1_duration, 1.0)


func test_colapso_continua_a_10_minutos_do_relogio_novo() -> void:
	_clock.jump_to_phase1_end(NOW)
	_run(NOW, NOW + 11 * 60 * RATE)
	assert_eq(_fired[&"collapsed"].size(), 1)
	var expected := (
		NOW + roundi((_clock.rules.max_match_duration - _clock.rules.phase1_duration) * RATE)
	)
	assert_between(_fired[&"collapsed"][0], expected - RATE, expected + RATE)


func test_salto_antes_de_comecar_e_ignorado() -> void:
	var idle := MatchClock.new()
	idle.rules = load(RULES) as MatchRules
	add_child_autofree(idle)
	idle.jump_to_phase1_end(NOW)
	assert_false(idle.is_started())


func test_relogio_parado_nao_dispara_nem_avanca() -> void:
	var held_at := NOW
	_clock.hold(held_at)
	var elapsed := _clock.elapsed(held_at)
	_run(held_at, held_at + 400 * RATE)  # passa de 5:00 de relogio real
	assert_eq(_fired[&"boss_warning"], [])
	assert_eq(_fired[&"phase1_ended"], [])
	assert_eq(_clock.elapsed(held_at + 400 * RATE), elapsed)


func test_soltar_retoma_do_ponto_em_que_parou() -> void:
	_clock.hold(NOW)
	var elapsed := _clock.elapsed(NOW)
	var later := NOW + 100 * RATE
	_clock.release(later)
	assert_almost_eq(_clock.elapsed(later), elapsed, 0.1)
	assert_almost_eq(_clock.elapsed(later + RATE), elapsed + 1.0, 0.1)


func test_salto_solta_o_relogio_parado() -> void:
	_clock.hold(NOW)
	var later := NOW + 100 * RATE
	_clock.jump_to_phase1_end(later)
	_run(later, later + 2 * RATE)
	assert_eq(_fired[&"phase1_ended"].size(), 1)
