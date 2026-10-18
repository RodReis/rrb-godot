extends DruidTestBase
## druid.tscn (GDB §4.7, F74; SPEC-074 aceite): Seiva (projetil que para no 1o alvo, 6,5 u, bloqueado
## pela Muralha) e Raizes Vivas (enraiza heroi e monstro comum por 1,5 s, o chefe so toma o dano).
## Servidor = processo do teste (peer offline).


func test_nivel_1_tem_os_atributos_base() -> void:
	var druid := _spawn_druid(1)
	assert_eq(druid.hp, 470)
	assert_almost_eq(druid.attributes.move_speed, 6.0 * (1.0 + 16.0 * 0.004), EPS)
	assert_eq(druid.ranks, Vector3i(1, 0, 0))


func test_seiva_fere_o_primeiro_alvo_com_100_por_cento_do_atk() -> void:
	_spawn_druid(1)
	var front := _spawn_monster(GOLEM, -1, AHEAD * 3.0)
	var behind := _spawn_monster(GOLEM, -2, AHEAD * 5.0)
	_druid.input.attack = true
	_run(START, 30)
	assert_eq(_basic_damage(), 44)
	assert_eq(GOLEM_HP - front.hp, 44)
	assert_eq(behind.hp, GOLEM_HP, "a seiva para no 1o toque")


func test_seiva_no_heroi_passa_pelo_ledger() -> void:
	_spawn_druid(1)
	var knight := _spawn_knight(AHEAD * 4.0)
	_druid.input.attack = true
	_run(START, 30)
	assert_eq(KNIGHT_HP - knight.hp, CombatRules.mitigated(44, KNIGHT_DEF))
	assert_eq(knight.slow_ticks, 0, "a seiva nao deixa lento")


func test_seiva_alcanca_6_5_u_e_nao_mais() -> void:
	_spawn_druid(1)
	var near := _spawn_monster(GOLEM, -1, AHEAD * 6.0)
	var far := _spawn_monster(GOLEM, -2, Vector3(4, 0, -6.2))
	_druid.input.attack = true
	_run(START, 40)
	assert_lt(near.hp, GOLEM_HP)
	assert_eq(far.hp, GOLEM_HP)
	var out := _spawn_knight(AHEAD * 7.4, 9)
	_druid.basic_cooldown = 0
	_druid.input.attack = true
	_run(START + 40, 40)
	assert_eq(out.hp, KNIGHT_HP, "alem de 6,5 u + raios")


func test_seiva_cadencia_de_1_s() -> void:
	_spawn_druid(1)
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 3.0)
	for tick: int in range(START, START + 61):
		_druid.input.attack = true
		_run(tick, 1)
	# disparos nos ticks 0, 30 e 60 (recarga de 1,0 s)
	assert_eq(GOLEM_HP - golem.hp, 3 * 44)


func test_muralha_bloqueia_a_seiva() -> void:
	_spawn_druid(1)
	var knight := _spawn_knight(AHEAD * 4.0)
	knight.look_at(Vector3.ZERO, Vector3.UP)
	knight.shield_ticks = 90
	knight.shield_hp = 200
	_druid.input.attack = true
	_run(START, 20)
	assert_eq(knight.hp, KNIGHT_HP)
	assert_eq(knight.shield_hp, 200, "bloqueada antes de chegar")


func test_raizes_enraizam_o_heroi_por_1_5_s() -> void:
	_spawn_druid(1)
	var knight := _spawn_knight(AHEAD * 5.0)
	_druid.input.skill_q = true
	_run_until_slowed(knight, START)
	assert_eq(KNIGHT_HP - knight.hp, CombatRules.mitigated(_q_damage(), KNIGHT_DEF))
	assert_eq(_q_damage(), roundi(40.0 + 0.5 * 44.0))
	assert_almost_eq(knight.slow_pct, 1.0, EPS, "enraizado = lentidao de 100 %")
	assert_eq(knight.slow_ticks, ROOT_TICKS, "45 ticks = 1,5 s, contando o tick da aplicacao")


func test_enraizado_nao_anda_por_1_5_s_e_depois_volta_a_andar() -> void:
	_spawn_druid(1)
	var knight := _spawn_knight(AHEAD * 5.0)
	await wait_physics_frames(2)
	_druid.input.skill_q = true
	var tick := _run_until_slowed(knight, START)
	var rooted_at := knight.global_position
	knight.input.movement = SIDE
	_run(tick, ROOT_TICKS - 1)
	assert_almost_eq(knight.global_position, rooted_at, Vector3.ONE * 0.01, "parado enquanto enraizado")
	_run(tick + ROOT_TICKS - 1, 15)
	assert_gt(knight.global_position.x, rooted_at.x + 0.5, "soltou: anda de novo")


func test_raizes_param_no_primeiro_heroi_ou_monstro() -> void:
	_spawn_druid(1)
	var front := _spawn_monster(GOLEM, -1, AHEAD * 3.0)
	var behind := _spawn_knight(AHEAD * 6.0)
	_druid.input.skill_q = true
	_run(START, 30)
	assert_gt(GOLEM_HP - front.hp, 0)
	assert_eq(behind.hp, KNIGHT_HP)
	assert_eq(behind.slow_ticks, 0)


func test_raizes_em_monstro_comum_enraizam() -> void:
	_spawn_druid(1)
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 5.0)
	_druid.input.skill_q = true
	_run(START, 20)
	assert_eq(GOLEM_HP - golem.hp, _q_damage())
	assert_gt(golem._slow_ticks, 0)
	assert_almost_eq(golem._slow_pct, 1.0, EPS)


func test_raizes_no_chefe_so_dao_dano() -> void:
	_spawn_druid(1)
	var boss := _spawn_monster(BOSS, -1, AHEAD * 5.0)
	var hp := boss.hp
	_druid.input.skill_q = true
	_run(START, 20)
	assert_eq(hp - boss.hp, _q_damage())
	assert_eq(boss._slow_ticks, 0, "o chefe nao fica enraizado")


func test_raizes_alem_de_7_u_nao_alcancam() -> void:
	_spawn_druid(1)
	var knight := _spawn_knight(AHEAD * 8.0)
	_druid.input.skill_q = true
	_run(START, 40)
	assert_eq(knight.hp, KNIGHT_HP)
	assert_eq(knight.slow_ticks, 0)


func test_muralha_bloqueia_as_raizes() -> void:
	_spawn_druid(1)
	var knight := _spawn_knight(AHEAD * 4.0)
	knight.look_at(Vector3.ZERO, Vector3.UP)
	knight.shield_ticks = 90
	knight.shield_hp = 200
	_druid.input.skill_q = true
	_run(START, 20)
	assert_eq(knight.hp, KNIGHT_HP)
	assert_eq(knight.slow_ticks, 0)


func test_recarga_do_q_no_rank_1_e_10_s_com_cdr() -> void:
	_spawn_druid(1)
	_druid.input.skill_q = true
	_run(START, 1)
	var expected := SkillRules.cooldown_ticks(
		_druid.hero_data.skill_q, 1, _druid.attributes.intelligence, 30
	)
	assert_eq(_druid.q_cooldown, expected)
	assert_gt(expected, 250, "perto de 10 s menos o CDR da INT 24")


func test_seiva_voa_a_20_u_s_e_a_raiz_a_18_u_s() -> void:
	_spawn_druid(1)
	assert_almost_eq(_druid._flight_speed(Arrow.Kind.BASIC), 20.0, EPS)
	assert_almost_eq(_druid._flight_speed(Arrow.Kind.ROOT), 18.0, EPS)
	assert_almost_eq(_druid._flight_radius(Arrow.Kind.BASIC), 0.35, EPS)
	assert_almost_eq(_druid._flight_radius(Arrow.Kind.ROOT), 0.4, EPS)
	for arrow: Arrow in _druid._arrows:
		assert_almost_eq(arrow.kind_speeds[Arrow.Kind.ROOT], 18.0, EPS)


## Roda ate o alvo ficar lento (o golpe da raiz aplicado) e devolve o proximo tick.
func _run_until_slowed(target: Hero, from: int) -> int:
	var tick := from
	while target.slow_ticks == 0 and tick < from + 60:
		_run(tick, 1)
		tick += 1
	return tick
