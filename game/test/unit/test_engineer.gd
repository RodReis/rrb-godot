extends EngineerTestBase
## engineer.tscn (GDB §4.6, F59; SPEC-059 §8 itens 1 e 2): Bacamarte acerta todos no cone 40 graus
## e 4,5 u e ninguem fora; Garra Mecanica puxa heroi ate 2,0 u e para no rio, monstro so toma dano
## e a Muralha bloqueia. Servidor = processo do teste (peer offline).


func test_nivel_1_tem_os_atributos_base() -> void:
	var eng := _spawn_engineer(1)
	assert_eq(eng.hp, 520)
	assert_almost_eq(eng.attributes.move_speed, 5.9 * (1.0 + 12.0 * 0.004), EPS)
	assert_eq(eng.ranks, Vector3i(1, 0, 0))


func test_bacamarte_acerta_todos_no_cone_e_ninguem_fora() -> void:
	_spawn_engineer(1)
	var near := _spawn_monster(GOLEM, -1, AHEAD * 2.0)
	var far := _spawn_monster(GOLEM, -2, AHEAD * 4.4)  # ainda dentro dos 4,5 u, na linha
	var edge := _spawn_monster(GOLEM, -3, Vector3(0.7, 0, -4.0))  # ~10 graus
	var wide := _spawn_monster(GOLEM, -4, Vector3(2.0, 0, -2.0))  # 45 graus: fora dos 20 de cada lado
	var beyond := _spawn_monster(GOLEM, -5, AHEAD * 4.6 + SIDE * 3.0)
	var behind := _spawn_monster(GOLEM, -6, -AHEAD * 2.0)
	_eng.input.attack = true
	_run(START, 3)
	var damage := roundi(_eng.attributes.attack)
	assert_eq(damage, 46)
	assert_eq(GOLEM_HP - near.hp, damage)
	assert_eq(GOLEM_HP - far.hp, damage, "acerta todos no cone, nao so o primeiro")
	assert_eq(GOLEM_HP - edge.hp, damage)
	assert_eq(wide.hp, GOLEM_HP, "fora do cone de 40 graus")
	assert_eq(beyond.hp, GOLEM_HP)
	assert_eq(behind.hp, GOLEM_HP)


func test_bacamarte_alem_de_4_5_u_nao_acerta() -> void:
	_spawn_engineer(1)
	var out := _spawn_monster(GOLEM, -1, AHEAD * 4.6)
	_eng.input.attack = true
	_run(START, 3)
	assert_eq(out.hp, GOLEM_HP)


func test_bacamarte_no_heroi_passa_pelo_ledger() -> void:
	_spawn_engineer(1)
	var knight := _spawn_knight(AHEAD * 3.0)
	_eng.input.attack = true
	_run(START, 3)
	assert_eq(KNIGHT_HP - knight.hp, CombatRules.mitigated(46, KNIGHT_DEF))


func test_garra_puxa_o_heroi_ate_2_u_do_engenheiro() -> void:
	_spawn_engineer(1)
	var knight := _spawn_knight(AHEAD * 6.0)
	await wait_physics_frames(2)  # corpos do teste anterior saem do espaco fisico
	_eng.input.skill_q = true
	_run(START, 30)
	assert_eq(KNIGHT_HP - knight.hp, CombatRules.mitigated(_q_damage(), KNIGHT_DEF))
	assert_eq(_q_damage(), roundi(50.0 + 0.7 * 46.0))
	assert_almost_eq(knight.global_position.z, -2.0, 0.05)
	assert_almost_eq(knight.global_position.x, 0.0, 0.05)


func test_garra_puxa_em_0_3_s() -> void:
	_spawn_engineer(1)
	var knight := _spawn_knight(AHEAD * 6.0)
	_eng.input.skill_q = true
	var first := 0
	for tick: int in range(START, START + 40):
		_run(tick, 1)
		if first == 0 and knight.knockback_ticks > 0:
			first = knight.knockback_ticks
	# O alvo aplica o golpe no tick seguinte: 9 ticks de deslize (0,3 s), um deles ja contado.
	assert_eq(first, PULL_TICKS - 1)
	assert_eq(knight.knockback_ticks, 0, "o puxao acabou")


func test_garra_para_no_rio() -> void:
	_spawn_engineer(1)
	_block_at(AHEAD * 3.5, Vector3(6, 4, 0.5), PhysicsLayers.RIVER)
	var knight := _spawn_knight(AHEAD * 6.0)
	await wait_physics_frames(2)
	_eng.input.skill_q = true
	_run(START, 30)
	assert_lt(knight.global_position.z, -3.7, "o puxao nao atravessa o rio")
	assert_gt(knight.global_position.z, -6.1)


func test_garra_em_monstro_so_da_dano() -> void:
	_spawn_engineer(1)
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 5.0)
	_eng.input.skill_q = true
	_run(START, 30)
	assert_eq(GOLEM_HP - golem.hp, _q_damage())
	assert_almost_eq(golem.global_position, AHEAD * 5.0, Vector3.ONE * EPS)


func test_garra_para_no_primeiro_inimigo() -> void:
	_spawn_engineer(1)
	var front := _spawn_monster(GOLEM, -1, AHEAD * 3.0)
	var behind := _spawn_knight(AHEAD * 6.0)
	_eng.input.skill_q = true
	_run(START, 30)
	assert_gt(GOLEM_HP - front.hp, 0)
	assert_eq(behind.hp, KNIGHT_HP)
	assert_almost_eq(behind.global_position.z, -6.0, EPS)


func test_garra_alem_de_7_u_nao_alcanca() -> void:
	_spawn_engineer(1)
	var knight := _spawn_knight(AHEAD * 8.0)
	_eng.input.skill_q = true
	_run(START, 30)
	assert_eq(knight.hp, KNIGHT_HP)


func test_muralha_bloqueia_a_garra() -> void:
	_spawn_engineer(1)
	var knight := _spawn_knight(AHEAD * 4.0)
	knight.look_at(Vector3.ZERO, Vector3.UP)  # Muralha virada para o Engenheiro
	knight.shield_ticks = 90
	knight.shield_hp = 200
	_eng.input.skill_q = true
	_run(START, 20)
	assert_eq(knight.hp, KNIGHT_HP)
	assert_eq(knight.shield_hp, 200, "bloqueada antes de chegar")
	assert_almost_eq(knight.global_position.z, -4.0, EPS, "sem puxao")


func test_alvo_invulneravel_e_puxado_sem_tomar_dano() -> void:
	_spawn_engineer(1)
	var knight := _spawn_knight(AHEAD * 6.0)
	knight.invuln_ticks = 120
	await wait_physics_frames(2)  # corpos do teste anterior saem do espaco fisico
	_eng.input.skill_q = true
	_run(START, 30)
	assert_eq(knight.hp, KNIGHT_HP, "mesma regra da Investida: invulneravel nao toma dano")
	assert_almost_eq(knight.global_position.z, -2.0, 0.05)
