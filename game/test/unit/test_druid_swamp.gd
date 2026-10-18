extends DruidTestBase
## Pantano do Protetor da Selva (GDB §4.7, F74; SPEC-074 aceite): 6 pulsos de 1,0 s com dano e
## lentidao de 40 % em heroi e monstro, e a raiz que solta no fim dentro da zona. Servidor =
## processo do teste (peer offline).


func _cast_swamp(level: int = 6, aim_distance: float = 5.0) -> void:
	_spawn_druid(level)
	_druid.input.skill_r = true
	_druid.input.aim_distance = aim_distance


func test_pantano_cai_no_ponto_mirado_ate_7_u() -> void:
	_cast_swamp(6, 5.0)
	_run(START, 1)
	assert_almost_eq(_druid.swamp_center, AHEAD * 5.0, Vector3.ONE * EPS)
	assert_eq(_druid.swamp_ticks, SWAMP_TICKS)
	assert_eq(_zones[0][0], Druid.Zone.SWAMP)


func test_pantano_alem_do_alcance_cai_a_7_u() -> void:
	_cast_swamp(6, 40.0)
	_run(START, 1)
	assert_almost_eq(_druid.swamp_center, AHEAD * 7.0, Vector3.ONE * EPS)


func test_pantano_so_a_partir_do_nivel_6() -> void:
	_cast_swamp(5)
	_run(START, 1)
	assert_eq(_druid.swamp_ticks, 0)
	assert_true(_zones.is_empty())


func test_pantano_fere_e_deixa_lento_em_6_pulsos() -> void:
	_cast_swamp(6, 5.0)
	var knight := _spawn_knight(AHEAD * 5.0 + SIDE)
	_run(START, 1)
	assert_eq(_swamp_damage(), roundi(30.0 + 0.25 * _druid.attributes.intelligence))
	_run(START + 1, 2)
	assert_eq(KNIGHT_HP - knight.hp, CombatRules.mitigated(_swamp_damage(), KNIGHT_DEF), "1o pulso")
	assert_almost_eq(knight.slow_pct, 0.4, EPS)
	assert_eq(knight.slow_ticks, 30, "31 ticks de lentidao, um ja descontado")
	_run(START + 3, 190)
	assert_eq(_druid.swamp_ticks, 0)
	assert_eq(KNIGHT_HP - knight.hp, 6 * CombatRules.mitigated(_swamp_damage(), KNIGHT_DEF))
	assert_eq(knight.slow_ticks, 0, "a lentidao acaba depois do ultimo pulso")


func test_pantano_atinge_monstro_com_dano_e_lentidao() -> void:
	_cast_swamp(6, 5.0)
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 5.0)
	_run(START, 3)
	assert_gt(golem._slow_ticks, 0)
	assert_almost_eq(golem._slow_pct, 0.4, EPS)
	_run(START + 3, 190)
	assert_eq(GOLEM_HP - golem.hp, 6 * _swamp_damage())


func test_pantano_nao_atinge_quem_esta_fora_de_5_u() -> void:
	_cast_swamp(6, 5.0)
	var out := _spawn_knight(AHEAD * 5.0 + SIDE * 5.2)
	var inside := _spawn_knight(AHEAD * 5.0 + SIDE * 4.8, 9)
	_run(START, 40)
	assert_eq(out.hp, KNIGHT_HP)
	assert_eq(out.slow_ticks, 0)
	assert_lt(inside.hp, KNIGHT_HP)


func test_pantano_nao_fere_o_proprio_protetor() -> void:
	_cast_swamp(6, 0.0)
	_run(START, 200)
	assert_eq(_druid.hp, _druid.attributes.max_hp)
	assert_eq(_druid.slow_ticks, 0)


func test_recarga_do_pantano_60_s_no_rank_1() -> void:
	_cast_swamp(6, 5.0)
	_run(START, 1)
	var expected := SkillRules.cooldown_ticks(
		_druid.hero_data.skill_r, 1, _druid.attributes.intelligence, 30
	)
	assert_eq(_druid.r_cooldown, expected)
	assert_gt(expected, 1200, "60 s menos o CDR da INT 36")


func test_raiz_dentro_do_pantano_solta_no_fim_e_volta_a_lentidao_de_40() -> void:
	_cast_swamp(6, 5.0)
	var knight := _spawn_knight(AHEAD * 5.0 + SIDE)
	_run(START, 40)
	assert_almost_eq(knight.slow_pct, 0.4, EPS, "so o Pantano")
	_druid.input.skill_q = true
	_druid.input.aim = Vector3(1, 0, -5).normalized()
	var tick := START + 40
	var rooted := false
	for i: int in 120:
		_run(tick + i, 1)
		rooted = rooted or is_equal_approx(knight.slow_pct, 1.0)
	assert_true(rooted, "a raiz acertou")
	assert_gt(knight.slow_ticks, 0, "o pulso seguinte reaplicou a lentidao")
	assert_almost_eq(knight.slow_pct, 0.4, EPS, "depois da raiz, o Pantano volta a mandar")
