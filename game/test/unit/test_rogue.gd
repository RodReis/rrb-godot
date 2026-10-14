extends RogueTestBase
## rogue.tscn (GDB §4.5, F58; SPEC-058 §8 item 2): Virote para no 1o alvo e some aos 7 u; Rajada
## em Leque a 1,5 u acerta com os 3 virotes, a 6,5 u com 1; a Muralha bloqueia os 3. Servidor =
## processo do teste (peer offline).


func test_nivel_1_tem_os_atributos_base() -> void:
	var rogue := _spawn_rogue(1)
	assert_eq(rogue.hp, 400)
	assert_almost_eq(rogue.attributes.move_speed, 6.3 * (1.0 + 28.0 * 0.004), EPS)
	assert_eq(rogue.ranks, Vector3i(1, 0, 0))


func test_virote_acerta_o_primeiro_e_para() -> void:
	_spawn_rogue(1)
	var near := _spawn_monster(GOLEM, -1, AHEAD * 4.0)
	var far := _spawn_monster(GOLEM, -2, AHEAD * 6.0)
	_rogue.input.attack = true
	_run(START, 15)
	assert_eq(GOLEM_HP - near.hp, 54)
	assert_eq(far.hp, GOLEM_HP)
	assert_eq(_active_bolts(), 0)


func test_virote_some_aos_7_u() -> void:
	_spawn_rogue(1)
	var beyond := _spawn_monster(GOLEM, -1, AHEAD * 8.5)
	_rogue.input.attack = true
	_run(START, 15)
	assert_eq(beyond.hp, GOLEM_HP)
	assert_almost_eq((_rogue.get_node("Arrows/Arrow0") as Arrow).traveled, 7.0, EPS)


func test_rajada_dispara_tres_virotes_no_mesmo_tick() -> void:
	_spawn_rogue(1)
	_rogue.input.skill_q = true
	_run(START, 1)
	assert_eq(_active_bolts(), 3)
	var directions: Array[float] = []
	for node: Node in _rogue.get_node("Arrows").get_children():
		var arrow := node as Arrow
		if arrow.is_active():
			directions.append(
				snappedf(rad_to_deg(AHEAD.signed_angle_to(arrow.direction, Vector3.UP)), 0.01)
			)
	directions.sort()
	assert_eq(directions, [-12.0, 0.0, 12.0])


func test_rajada_a_1_5_u_acerta_com_os_tres() -> void:
	_spawn_rogue(1)
	var knight := _spawn_knight(AHEAD * 1.5)
	_rogue.input.skill_q = true
	_run(START, 10)
	var per_bolt := _q_damage()
	assert_eq(per_bolt, roundi(30.0 + 0.4 * 54.0))
	assert_eq(KNIGHT_HP - knight.hp, CombatRules.mitigated(per_bolt * 3, KNIGHT_DEF))
	assert_eq(_active_bolts(), 0)


func test_rajada_a_6_5_u_acerta_com_um() -> void:
	_spawn_rogue(1)
	var knight := _spawn_knight(AHEAD * 6.5)
	_rogue.input.skill_q = true
	_run(START, 15)
	assert_eq(KNIGHT_HP - knight.hp, CombatRules.mitigated(_q_damage(), KNIGHT_DEF))


func test_cada_virote_da_rajada_para_no_primeiro_alvo() -> void:
	_spawn_rogue(1)
	var front := _spawn_monster(GOLEM, -1, AHEAD * 3.0)
	var behind := _spawn_monster(GOLEM, -2, AHEAD * 6.0)
	_rogue.input.skill_q = true
	_run(START, 15)
	assert_eq(behind.hp, GOLEM_HP, "o do meio parou no golem da frente")
	assert_gt(GOLEM_HP - front.hp, 0)


func test_muralha_bloqueia_os_tres_virotes() -> void:
	_spawn_rogue(1)
	var knight := _spawn_knight(AHEAD * 1.5)
	knight.look_at(Vector3.ZERO, Vector3.UP)  # Muralha virada para a Ladina
	knight.shield_ticks = 90
	knight.shield_hp = 200
	_rogue.input.skill_q = true
	_run(START, 10)
	assert_eq(knight.hp, KNIGHT_HP)
	assert_eq(knight.shield_hp, 200, "bloqueados antes de chegar: nem o escudo absorve")
	assert_eq(_active_bolts(), 0)
