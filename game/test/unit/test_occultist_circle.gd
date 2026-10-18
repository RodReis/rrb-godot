extends OccultistTestBase
## Circulo Profano e R desligado do Ocultista (GDB §4.10, F77; SPEC-077 aceite): zona de 2,5 u no
## ponto mirado (ate 7 u) por 3 s, lentidao de 35 % e 6 pulsos de 0,5 s que somam o total; o R
## Servos do Vazio nao tem ponto alocavel ate o F78. Servidor = processo do teste.

const CIRCLE_TICKS: int = 90


func _cast_circle(level: int = 2, aim_distance: float = 5.0) -> void:
	_spawn_occultist(level)
	_occultist.input.skill_e = true
	_occultist.input.aim_distance = aim_distance


func test_circulo_cai_no_ponto_mirado_ate_7_u() -> void:
	_cast_circle(2, 5.0)
	_run(START, 1)
	assert_almost_eq(_occultist.circle_center, AHEAD * 5.0, Vector3.ONE * EPS)
	assert_eq(_occultist.circle_ticks, CIRCLE_TICKS)
	assert_eq(_zones[0][0], Occultist.Zone.CIRCLE)


func test_circulo_alem_do_alcance_cai_a_7_u() -> void:
	_cast_circle(2, 40.0)
	_run(START, 1)
	assert_almost_eq(_occultist.circle_center, AHEAD * 7.0, Vector3.ONE * EPS)


func test_circulo_so_a_partir_do_nivel_2() -> void:
	_cast_circle(1)
	_run(START, 1)
	assert_eq(_occultist.circle_ticks, 0)
	assert_true(_zones.is_empty())


func test_circulo_deixa_lento_e_fere_em_6_pulsos_que_somam_o_total() -> void:
	_cast_circle(2, 5.0)
	var knight := _spawn_knight(AHEAD * 5.0 + SIDE)
	_run(START, 3)
	assert_almost_eq(knight.slow_pct, 0.35, EPS)
	assert_gt(knight.slow_ticks, 0)
	var expected := 0
	for pulse: int in 6:
		expected += CombatRules.mitigated(
			OccultistRules.circle_pulse_damage(_e_total(), pulse, 6), KNIGHT_DEF
		)
	_run(START + 3, 120)
	assert_eq(_occultist.circle_ticks, 0)
	assert_eq(KNIGHT_HP - knight.hp, expected)
	assert_eq(knight.slow_ticks, 0, "a lentidao acaba depois do ultimo pulso")
	assert_eq(knight.curse_stacks, 0, "o Circulo nao marca")


func test_circulo_em_monstro_tira_o_total_exato() -> void:
	_cast_circle(2, 5.0)
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 5.0)
	_run(START, 130)
	assert_eq(GOLEM_HP - golem.hp, _e_total())
	assert_eq(_e_total(), roundi(60.0 + 0.6 * _occultist.attributes.attack))


func test_circulo_nao_atinge_quem_esta_fora_de_2_5_u() -> void:
	_cast_circle(2, 5.0)
	var out := _spawn_knight(AHEAD * 5.0 + SIDE * 2.7)
	var inside := _spawn_knight(AHEAD * 5.0 + SIDE * 2.3, 9)
	_run(START, 40)
	assert_eq(out.hp, KNIGHT_HP)
	assert_eq(out.slow_ticks, 0)
	assert_lt(inside.hp, KNIGHT_HP)


func test_circulo_nao_fere_o_proprio_ocultista() -> void:
	_cast_circle(2, 0.0)
	_run(START, 120)
	assert_eq(_occultist.hp, _occultist.attributes.max_hp)
	assert_eq(_occultist.slow_ticks, 0)


func test_recarga_do_circulo_13_s_no_rank_1() -> void:
	_cast_circle(2, 5.0)
	_run(START, 1)
	var expected := SkillRules.cooldown_ticks(
		_occultist.hero_data.skill_e, 1, _occultist.attributes.intelligence, 30
	)
	assert_eq(_occultist.e_cooldown, expected)
	assert_gt(expected, 300, "13 s menos o CDR da INT 35")


func test_r_sem_ponto_alocavel_e_nao_dispara() -> void:
	_spawn_occultist(10)
	assert_eq(_occultist.ranks.z, 0, "mesmo no nivel 10, sem rank de R")
	_occultist.input.skill_r = true
	_run(START, 5)
	assert_eq(_occultist.r_cooldown, 0, "nao usou")


func test_ponto_do_nivel_6_nao_vai_para_o_r() -> void:
	_spawn_occultist(5)
	_occultist.xp = XpTable.xp_for_level(_occultist.xp_curve, 6)
	_occultist.ranks = Vector3i(3, 2, 0)
	_occultist.input.learn = SkillRules.SLOT_R
	_run(START, 2)
	assert_eq(_occultist.ranks, Vector3i(3, 2, 0), "o R recusa o ponto")
	_occultist.input.learn = SkillRules.SLOT_Q
	_run(START + 2, 2)
	assert_eq(_occultist.ranks, Vector3i(4, 2, 0), "o ponto vai para o Q")
