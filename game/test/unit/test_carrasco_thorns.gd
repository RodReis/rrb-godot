extends CarrascoTestBase
## Espinhos do Carrasco (GDB §4.11, F98; SPEC-098 §6 item 1): golpe em cone de 90° / 3 u com dano e
## lentidao de 30 % por 1,5 s em todos os atingidos; Q de novo em ate 3 s lanca o projetil (7 u),
## que para no 1o alvo, sem lentidao; a recarga so conta depois do recast ou do fim da janela.


func test_golpe_fere_e_deixa_lento_todos_do_cone() -> void:
	_spawn_carrasco()
	var a := _spawn_enemy(KNIGHT, AHEAD * 2.5, VICTIM)
	var b := _spawn_enemy(KNIGHT, Vector3(1.6, 0, -2.0), VICTIM + 1)
	_carrasco.input.skill_q = true
	_run(START, 2)
	var q := _carrasco.hero_data.skill_q
	assert_eq(_amount(q, 1), roundi(50 + 0.6 * CARRASCO_ATK))
	for knight: Hero in [a, b]:
		assert_eq(KNIGHT_HP - knight.hp, CombatRules.mitigated(_amount(q, 1), KNIGHT_DEF))
		assert_almost_eq(knight.slow_pct, 0.3, 0.001)
		assert_gt(knight.slow_ticks, 0)


func test_lentidao_dura_1_5_s() -> void:
	_spawn_carrasco()
	var knight := _spawn_enemy(KNIGHT, AHEAD * 2.0)
	_carrasco.input.skill_q = true
	# Tick do golpe + 45 ticks (1,5 s): no fim do 45o ainda falta 1 tick.
	_run(START, 46)
	assert_eq(knight.slow_ticks, 1)
	_run(START + 46, 1)
	assert_eq(knight.slow_ticks, 0)


func test_cone_nao_pega_atras_nem_longe() -> void:
	_spawn_carrasco()
	var behind := _spawn_enemy(KNIGHT, -AHEAD * 1.5, VICTIM)
	var far := _spawn_enemy(KNIGHT, AHEAD * 3.4, VICTIM + 1)
	_carrasco.input.skill_q = true
	_run(START, 2)
	assert_eq(behind.hp, KNIGHT_HP)
	assert_eq(far.hp, KNIGHT_HP)


func test_golpe_abre_a_janela_sem_contar_a_recarga() -> void:
	_spawn_carrasco()
	_carrasco.input.skill_q = true
	_run(START, 1)
	assert_true(_carrasco.can_recast())
	assert_eq(_carrasco.q_cooldown, 0, "a recarga so conta depois do recast")
	assert_eq(_carrasco.q_casts, 1)
	assert_gt(_carrasco.reveal_ticks, 0, "revela no mato no golpe")


func test_segurar_q_nao_lanca_o_recast() -> void:
	_spawn_carrasco()
	for i: int in 10:
		_carrasco.input.skill_q = true
		_run(START + i, 1)
	assert_eq(_carrasco.recasts, 0)
	assert_true(_carrasco.can_recast())


func test_recast_fere_o_primeiro_alvo_sem_lentidao_e_comeca_a_recarga() -> void:
	_spawn_carrasco()
	var near := _spawn_enemy(KNIGHT, AHEAD * 4.5, VICTIM)
	var far := _spawn_enemy(KNIGHT, AHEAD * 6.0, VICTIM + 1)
	_carrasco.input.skill_q = true
	_run(START, 1)
	_run(START + 1, 1)  # solta
	_carrasco.input.skill_q = true
	_run(START + 2, 1)  # toque de novo: recast
	assert_eq(_carrasco.recasts, 1)
	assert_false(_carrasco.can_recast())
	assert_gt(_carrasco.q_cooldown, 0)
	_run(START + 3, 20)
	var q := _carrasco.hero_data.skill_q
	var damage := roundi(30 + 0.4 * CARRASCO_ATK)
	assert_eq(KNIGHT_HP - near.hp, CombatRules.mitigated(damage, KNIGHT_DEF))
	assert_eq(near.slow_ticks, 0, "o recast nao deixa lento")
	assert_eq(far.hp, KNIGHT_HP, "para no 1o alvo")
	assert_almost_eq(q.distance, 7.0, EPS)


func test_recast_para_no_monstro() -> void:
	_spawn_carrasco()
	var golem := _spawn_monster(GOLEM, 900, AHEAD * 4.5)
	_carrasco.input.skill_q = true
	_run(START, 2)
	_carrasco.input.skill_q = true
	_run(START + 2, 20)
	assert_lt(golem.hp, GOLEM_HP)


func test_janela_acaba_em_3_s_e_a_recarga_comeca() -> void:
	_spawn_carrasco()
	_carrasco.input.skill_q = true
	_run(START, 1)
	_run(START + 1, 3 * RATE - 1)
	assert_true(_carrasco.can_recast(), "ainda no 3o segundo")
	assert_eq(_carrasco.q_cooldown, 0)
	_run(START + 3 * RATE, 1)
	assert_false(_carrasco.can_recast())
	assert_gt(_carrasco.q_cooldown, 0)
	_carrasco.input.skill_q = true
	_run(START + 3 * RATE + 1, 1)
	assert_eq(_carrasco.recasts, 0, "fora da janela, nada")
	assert_eq(_carrasco.q_casts, 1, "e sem golpe novo: em recarga")
