extends EngineerTestBase
## Torreta do Engenheiro (GDB §4.6, §7.3; SPEC-059 §8 item 3): 8 disparos em 6,0 s com alvo no
## alcance; so atira no que o Engenheiro ve (nao em heroi oculto na moita ou na fumaca, nem fora do
## raio de visao dele); a nova substitui a anterior; o disparo nao revela o Engenheiro. Servidor =
## processo do teste (peer offline).

var _deployed: Array[Vector3] = []


func before_each() -> void:
	super()
	_deployed = []


func _install(level: int = 2, at: Vector3 = Vector3.ZERO, aim_distance: float = 0.0) -> void:
	_spawn_engineer(level, at)
	_eng.deployed.connect(
		func(kind: Engineer.Deploy, center: Vector3, _tick: int) -> void:
			if kind == Engineer.Deploy.TURRET:
				_deployed.append(center)
	)
	_eng.input.skill_e = true
	_eng.input.aim_distance = aim_distance


func test_instala_no_ponto_mirado_ate_3_u() -> void:
	_install(2, Vector3.ZERO, 10.0)
	_run(START, 1)
	assert_almost_eq(_eng.turret_center, AHEAD * 3.0, Vector3.ONE * EPS)
	assert_eq(_eng.turret_ticks, TURRET_TICKS)
	assert_eq(_deployed.size(), 1)


func test_instala_no_ponto_mirado_aquem_do_limite() -> void:
	_install(2, Vector3.ZERO, 2.0)
	_run(START, 1)
	assert_almost_eq(_eng.turret_center, AHEAD * 2.0, Vector3.ONE * EPS)


func test_instala_para_no_obstaculo() -> void:
	_install(2, Vector3.ZERO, 10.0)
	_block_at(AHEAD * 2.0, Vector3(6, 4, 0.5), PhysicsLayers.WORLD)  # face a 1,75 u
	await wait_physics_frames(2)
	_run(START, 1)
	assert_almost_eq(_eng.turret_center.z, -(1.75 - Engineer.PLACE_MARGIN), 0.01)
	assert_almost_eq(_eng.turret_center.x, 0.0, EPS)


func test_dispara_8_vezes_em_6_s_com_alvo_no_alcance() -> void:
	_install()
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 4.0)
	_run(START, TURRET_TICKS + 20)
	assert_eq(_shots, 8)
	assert_eq(GOLEM_HP - golem.hp, 8 * _turret_damage())
	assert_eq(_turret_damage(), roundi(14.0 + 0.15 * _eng.attributes.attack))
	assert_eq(_eng.turret_ticks, 0, "a torreta some depois de 6 s")


func test_primeiro_disparo_no_tick_seguinte_e_depois_a_cada_0_75_s() -> void:
	_install()
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 4.0)
	_run(START, 1)
	assert_eq(golem.hp, GOLEM_HP, "instalar nao atira")
	_run(START + 1, 1)
	assert_eq(_shots, 1)
	_run(START + 2, 22)
	assert_eq(_shots, 1, "22 ticks depois ainda nao")
	_run(START + 24, 1)
	assert_eq(_shots, 2, "no 23o tick")


func test_acerta_heroi_pelo_ledger() -> void:
	_install()
	var knight := _spawn_knight(AHEAD * 4.0)
	_run(START, 40)
	assert_eq(_shots, 2)
	assert_eq(KNIGHT_HP - knight.hp, 2 * CombatRules.mitigated(_turret_damage(), KNIGHT_DEF))


func test_atira_no_mais_proximo_da_torreta() -> void:
	_install(2, Vector3.ZERO, 3.0)
	var near := _spawn_monster(GOLEM, -1, AHEAD * 5.0)  # a 2 u da torreta
	var far := _spawn_monster(GOLEM, -2, AHEAD * 8.0)  # a 5 u da torreta
	_run(START, 10)
	assert_eq(GOLEM_HP - near.hp, _turret_damage())
	assert_eq(far.hp, GOLEM_HP)


func test_nao_atira_alem_de_7_u_da_torreta() -> void:
	_install()
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 7.5)
	_run(START, TURRET_TICKS + 20)
	assert_eq(golem.hp, GOLEM_HP)
	assert_eq(_shots, 0)


func test_sem_alvo_o_disparo_nao_acontece_nem_acumula() -> void:
	_install()
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 7.5)
	_run(START, 60)
	golem.global_position = AHEAD * 4.0
	_run(START + 60, TURRET_TICKS)
	# Disparos nos ticks 0, 23, 46 (sem alvo) e 69, 92, 115, 138, 161 (com alvo).
	assert_eq(_shots, 5)
	assert_eq(GOLEM_HP - golem.hp, 5 * _turret_damage())


func test_nao_atira_em_heroi_oculto_na_moita() -> void:
	_grass_at(AHEAD * 4.0, Vector3(4, 4, 4))
	_install()
	var knight := _spawn_knight(AHEAD * 4.0)
	_run(START, TURRET_TICKS + 20)
	assert_eq(knight.hp, KNIGHT_HP)
	assert_eq(_shots, 0)


func test_atira_em_heroi_na_moita_se_o_engenheiro_esta_na_mesma() -> void:
	_grass_at(Vector3(0, 0, -2), Vector3(12, 4, 12))
	_install()
	var knight := _spawn_knight(AHEAD * 4.0)
	_run(START, 40)
	assert_lt(knight.hp, KNIGHT_HP, "mesma moita: se veem")


func test_nao_atira_em_heroi_oculto_na_fumaca() -> void:
	_install()
	var rogue := _spawn_rogue(AHEAD * 4.0)
	rogue.smoke_center = rogue.global_position
	rogue.smoke_ticks = TURRET_TICKS * 2
	_run(START, TURRET_TICKS + 20)
	assert_eq(rogue.hp, rogue.attributes.max_hp)
	assert_eq(_shots, 0)


func test_nao_atira_no_que_o_engenheiro_nao_ve_mesmo_perto_da_torreta() -> void:
	_install()
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 4.0)
	_run(START, 10)
	assert_eq(_shots, 1)
	_eng.global_position = Vector3(0, 0, 20)  # a 24 u do alvo: fora dos 12 u de visao
	_run(START + 10, TURRET_TICKS)
	assert_eq(_shots, 1, "a torreta nao da visao propria (ADR-0013)")
	assert_eq(GOLEM_HP - golem.hp, _turret_damage())


func test_nova_torreta_substitui_a_anterior() -> void:
	_install(2, Vector3.ZERO, 0.0)
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 4.0)
	_run(START, 40)
	var before := _shots
	assert_gt(before, 0)
	_eng.e_cooldown = 0
	_eng.input.skill_e = true
	_eng.input.aim_distance = 3.0
	_run(START + 40, 1)
	assert_almost_eq(_eng.turret_center, AHEAD * 3.0, Vector3.ONE * EPS)
	assert_eq(_eng.turret_ticks, TURRET_TICKS)
	assert_eq(_deployed.size(), 2)
	_run(START + 41, TURRET_TICKS + 20)
	assert_eq(_shots - before, 8, "so a nova atira: 8 disparos, nao 8 + o resto da anterior")
	assert_gt(GOLEM_HP - golem.hp, 0)


func test_disparo_da_torreta_nao_revela_o_engenheiro() -> void:
	_grass_at(Vector3.ZERO, Vector3(20, 4, 20))
	_install()
	_spawn_monster(GOLEM, -1, AHEAD * 4.0)
	_run(START, 1)
	assert_gt(_eng.reveal_ticks, 0, "instalar e usar skill: revela")
	_run(START + 1, 109)
	assert_eq(_eng.reveal_ticks, 0)
	var shots_before := _shots
	_run(START + 110, 16)
	assert_gt(_shots, shots_before, "a torreta atirou de novo")
	assert_eq(_eng.reveal_ticks, 0, "o disparo nao e acao do Engenheiro")


func test_engenheiro_morto_para_a_torreta() -> void:
	_install()
	_spawn_monster(GOLEM, -1, AHEAD * 4.0)
	_run(START, 10)
	assert_eq(_shots, 1)
	_eng.hp = 0
	_eng.respawn_ticks = 600
	_run(START + 10, TURRET_TICKS)
	assert_eq(_shots, 1, "quem morreu nao ve")
