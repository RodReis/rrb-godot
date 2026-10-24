extends DruidTestBase
## Pocao Verde do Protetor da Selva (GDB §4.7, F74; SPEC-074 aceite): cura propria em 6 pulsos de
## 0,5 s, parando no obstaculo, sem passar do HP maximo. Servidor = processo do teste (peer
## offline).


func _cast_potion(level: int = 2, aim_distance: float = 0.0, at: Vector3 = Vector3.ZERO) -> void:
	_spawn_druid(level, at)
	_druid.input.skill_e = true
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
	assert_eq(
		_potion_total(),
		roundi(90.0 + 0.5 * _druid.attributes.attack),
		"base do rank 1 + 50% do ATK"
	)
	_run(START + 1, 1)
	assert_eq(
		_druid.hp, 100 + DruidRules.pulse_heal(_potion_total(), 0, 6), "1o pulso no tick seguinte"
	)
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
	assert_eq(_potion_total(), roundi(base + 0.5 * (40.0 + 3.8 * 4.0)))
