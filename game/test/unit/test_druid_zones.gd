extends DruidTestBase
## Zonas do Protetor da Selva (GDB §4.7, F74; SPEC-074 aceite): Pocao Verde (cura propria em 6
## pulsos de 0,5 s, parando no obstaculo, sem passar do HP maximo) e Pantano (6 pulsos de 1,0 s com
## dano e lentidao de 40 % em heroi e monstro). Servidor = processo do teste (peer offline).


func _cast_potion(level: int = 2, aim_distance: float = 0.0, at: Vector3 = Vector3.ZERO) -> void:
	_spawn_druid(level, at)
	_druid.input.skill_e = true
	_druid.input.aim_distance = aim_distance


func _cast_swamp(level: int = 6, aim_distance: float = 5.0) -> void:
	_spawn_druid(level)
	_druid.input.skill_r = true
	_druid.input.aim_distance = aim_distance


func test_pocao_cai_no_ponto_mirado_ate_5_u() -> void:
	_cast_potion(2, 3.0)
	_run(START, 1)
	assert_almost_eq(_druid.potion_center, AHEAD * 3.0, Vector3.ONE * EPS)
	assert_eq(_druid.potion_ticks, POTION_TICKS)
	assert_eq(_zones.size(), 1)
	assert_eq(_zones[0][0], Druid.Zone.POTION)


func test_pocao_alem_do_alcance_cai_a_5_u() -> void:
	_cast_potion(2, 40.0)
	_run(START, 1)
	assert_almost_eq(_druid.potion_center, AHEAD * 5.0, Vector3.ONE * EPS)


func test_pocao_para_no_obstaculo() -> void:
	_cast_potion(2, 10.0)
	_block_at(AHEAD * 2.5, Vector3(6, 4, 0.5), PhysicsLayers.WORLD)  # face a 2,25 u
	await wait_physics_frames(2)
	_run(START, 1)
	assert_almost_eq(_druid.potion_center.z, -(2.25 - Druid.PLACE_MARGIN), 0.01)


func test_pocao_cura_o_protetor_em_6_pulsos_e_o_total_do_rank() -> void:
	_cast_potion()
	_run(START, 1)
	_druid.hp = 100
	assert_eq(_potion_total(), roundi(90.0 + 0.5 * _druid.attributes.attack), "base do rank 1 + 50% do ATK")
	_run(START + 1, 1)
	assert_eq(_druid.hp, 100 + DruidRules.pulse_heal(_potion_total(), 0, 6), "1o pulso no tick seguinte")
	_run(START + 2, 100)
	assert_eq(_druid.hp, 100 + _potion_total(), "6 pulsos somam a cura total")
	assert_eq(_druid.potion_ticks, 0)


func test_pocao_pulsa_a_cada_0_5_s() -> void:
	_cast_potion()
	_run(START, 1)
	_druid.hp = 100
	var seen := PackedInt32Array()
	var last := _druid.hp
	for tick: int in range(START + 1, START + 100):
		_run(tick, 1)
		if _druid.hp != last:
			seen.append(tick - START)
			last = _druid.hp
	assert_eq(seen, PackedInt32Array([1, 16, 31, 46, 61, 76]), "ticks dos 6 pulsos")


func test_pocao_nao_passa_do_hp_maximo() -> void:
	_cast_potion()
	_run(START, 1)
	_druid.hp = _druid.attributes.max_hp - 5
	_run(START + 1, 100)
	assert_eq(_druid.hp, _druid.attributes.max_hp)


func test_pocao_so_cura_quem_esta_na_zona() -> void:
	_cast_potion(2, 5.0)  # centro a 5 u, raio 3 u: o Protetor, em 0, esta fora
	_run(START, 1)
	_druid.hp = 100
	_run(START + 1, 100)
	assert_eq(_druid.hp, 100)


func test_pocao_na_borda_da_zona_ainda_cura() -> void:
	_cast_potion(2, 3.0)  # centro a 3 u, raio 3 u: o Protetor esta exatamente na borda
	_run(START, 1)
	_druid.hp = 100
	_run(START + 1, 100)
	assert_eq(_druid.hp, 100 + _potion_total())


func test_pocao_nao_cura_o_protetor_morto() -> void:
	_cast_potion()
	_run(START, 1)
	_druid.hp = 0
	_druid.respawn_ticks = 1000
	_run(START + 1, 100)
	assert_eq(_druid.hp, 0)


func test_pocao_nova_substitui_a_anterior() -> void:
	_cast_potion(2, 2.0)
	_run(START, 1)
	_druid.e_cooldown = 0
	_druid.input.skill_e = true
	_druid.input.aim_distance = 4.0
	_run(START + 10, 1)
	assert_almost_eq(_druid.potion_center, AHEAD * 4.0, Vector3.ONE * EPS)
	assert_eq(_druid.potion_ticks, POTION_TICKS)
	assert_eq(_zones.size(), 2)


func test_pocao_so_a_partir_do_nivel_2() -> void:
	_cast_potion(1)
	_run(START, 1)
	assert_eq(_druid.potion_ticks, 0)
	assert_true(_zones.is_empty())


func test_pocao_escala_com_o_atk_do_nivel() -> void:
	_cast_potion(5)
	_run(START, 1)
	var base := SkillData.at_rank(_druid.hero_data.skill_e.base_amount, _druid.ranks.y)
	assert_eq(_potion_total(), roundi(base + 0.5 * (44.0 + 3.8 * 4.0)))


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
