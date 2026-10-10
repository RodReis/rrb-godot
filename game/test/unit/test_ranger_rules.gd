extends GutTest
## Regras puras da Arqueira (GDB §4.2): perfuracao do Q, chuva do R, rolamento do E e flecha.

const EPS: float = 0.0001
const RANGER: HeroData = preload("res://shared/data/heroes/ranger.tres")
const TICKRATE: int = 30


func test_perfuracao_perde_15_por_cento_por_alvo_atravessado() -> void:
	var q := RANGER.skill_q
	assert_almost_eq(RangerRules.pierce_factor(0, q.pierce_decay, q.pierce_min), 1.0, EPS)
	assert_almost_eq(RangerRules.pierce_factor(1, q.pierce_decay, q.pierce_min), 0.85, EPS)
	assert_almost_eq(RangerRules.pierce_factor(2, q.pierce_decay, q.pierce_min), 0.70, EPS)
	assert_almost_eq(RangerRules.pierce_factor(3, q.pierce_decay, q.pierce_min), 0.55, EPS)


func test_perfuracao_para_no_piso_de_40_por_cento() -> void:
	var q := RANGER.skill_q
	assert_almost_eq(RangerRules.pierce_factor(4, q.pierce_decay, q.pierce_min), 0.40, EPS)
	assert_almost_eq(RangerRules.pierce_factor(9, q.pierce_decay, q.pierce_min), 0.40, EPS)


func test_chuva_tem_6_pulsos_a_cada_meio_segundo() -> void:
	var r := RANGER.skill_r
	var interval := SkillRules.seconds_to_ticks(r.pulse_interval, TICKRATE)
	var window := SkillRules.seconds_to_ticks(SkillData.at_rank(r.duration, 1), TICKRATE)
	var pulses: Array[int] = []
	for elapsed: int in window:
		if RangerRules.is_rain_pulse(elapsed, interval, r.pulse_count):
			pulses.append(elapsed)
	assert_eq(pulses, [0, 15, 30, 45, 60, 75])


func test_lentidao_da_chuva_cobre_ate_o_pulso_seguinte() -> void:
	var interval := SkillRules.seconds_to_ticks(RANGER.skill_r.pulse_interval, TICKRATE)
	# Aplicada no tick seguinte ao pulso e descontada no mesmo tick: sem buraco entre pulsos.
	assert_eq(RangerRules.rain_slow_ticks(interval), interval + 1)


func test_centro_da_chuva_no_cursor_ate_8_u() -> void:
	var r := RANGER.skill_r
	var origin := Vector3(1, 0, 1)
	var center := RangerRules.rain_center(origin, Vector3(1, 0, 0), 5.0, r.cast_range)
	assert_almost_eq(center, Vector3(6, 0, 1), Vector3.ONE * EPS)
	var far := RangerRules.rain_center(origin, Vector3(0, 0, -1), 30.0, r.cast_range)
	assert_almost_eq(far, Vector3(1, 0, -7), Vector3.ONE * EPS)


func test_centro_da_chuva_sem_mira_fica_no_heroi() -> void:
	var center := RangerRules.rain_center(Vector3(2, 0, 3), Vector3.ZERO, 5.0, 8.0)
	assert_eq(center, Vector3(2, 0, 3))


func test_rolamento_percorre_4_2_u_cravados() -> void:
	var e := RANGER.skill_e
	var ticks := SkillRules.seconds_to_ticks(SkillData.at_rank(e.duration, 1), TICKRATE)
	var speed := SkillRules.dash_speed(e.distance, ticks, TICKRATE)
	assert_almost_eq(speed * ticks / TICKRATE, 4.2, EPS)


func test_invulnerabilidade_do_rolamento_dura_9_ticks() -> void:
	assert_eq(SkillRules.seconds_to_ticks(RANGER.skill_e.invulnerability, TICKRATE), 9)


func test_recarga_do_rolamento_por_rank_com_cdr() -> void:
	var e := RANGER.skill_e
	# INT 15 = 7,5 % de CDR (GDB §2.2): 9,0 s -> 8,325 s -> 250 ticks; 5,8 s -> 5,365 s -> 161.
	assert_eq(SkillRules.cooldown_ticks(e, 1, 15.0, TICKRATE), 250)
	assert_eq(SkillRules.cooldown_ticks(e, 5, 15.0, TICKRATE), 161)


func test_recarga_do_basico_e_do_q_com_cdr() -> void:
	# INT 28,5 (nv 10) = 14,25 %: Q 7 s -> 6,0025 s -> 180 ticks.
	assert_eq(SkillRules.cooldown_ticks(RANGER.skill_q, 1, 28.5, TICKRATE), 180)
	# R rank 2: 38 s -> 32,585 s -> 978 ticks.
	assert_eq(SkillRules.cooldown_ticks(RANGER.skill_r, 2, 28.5, TICKRATE), 978)


func test_flecha_anda_ate_o_alcance_e_some() -> void:
	var basic := RANGER.basic_attack
	var traveled := 0.0
	var ticks := 0
	while traveled < basic.attack_range:
		traveled += RangerRules.flight_step(basic.speed, basic.attack_range, traveled, TICKRATE)
		ticks += 1
	assert_almost_eq(traveled, 9.0, EPS)
	assert_eq(ticks, 14)  # 9 u a 20 u/s = 0,45 s = 13,5 ticks: o ultimo passo e curto
