extends FireWizardTestBase
## fire_wizard.tscn (GDB §4.4, F54; SPEC-054 §6 item 2): Bola de Fogo para no 1o alvo e na
## Muralha; Explosao de Chamas explode no 1o alvo, na Muralha, no muro ou no fim do alcance e fere
## em area quem esta no raio 2,0 u; bot. Anel e Meteoro em test_fire_wizard_areas.gd. Servidor =
## processo do teste (peer offline).


func test_nivel_1_tem_os_atributos_base() -> void:
	var wizard := _spawn_wizard(1)
	assert_eq(wizard.hp, 360)
	assert_almost_eq(wizard.attributes.move_speed, 6.0 * (1.0 + 15.0 * 0.004), EPS)
	assert_eq(wizard.ranks, Vector3i(1, 0, 0))


func test_bola_de_fogo_acerta_o_primeiro_e_para() -> void:
	_spawn_wizard(1)
	var near := _spawn_monster(SKELETON, -1, AHEAD * 4.0)
	var far := _spawn_monster(SKELETON, -2, AHEAD * 6.0)
	_wizard.input.attack = true
	_run(START, 20)
	assert_eq(near.hp, 160 - 45)
	assert_eq(far.hp, 160)
	assert_eq(_active_balls(), 0)


func test_bola_de_fogo_some_aos_8_u() -> void:
	_spawn_wizard(1)
	var beyond := _spawn_monster(SKELETON, -1, AHEAD * 9.5)
	_wizard.input.attack = true
	_run(START, 20)
	assert_eq(beyond.hp, 160)
	assert_almost_eq((_wizard.get_node("Arrows/Arrow0") as Arrow).traveled, 8.0, EPS)


func test_bola_de_fogo_no_heroi_passa_pela_def() -> void:
	_spawn_wizard(1)
	var knight := _spawn_knight(AHEAD * 5.0)
	_wizard.input.attack = true
	_run(START, 20)
	assert_eq(knight.hp, 600 - CombatRules.mitigated(45, 30.0))


func test_muralha_bloqueia_a_bola_de_fogo() -> void:
	_spawn_wizard(1)
	var knight := _spawn_knight(AHEAD * 5.0)
	knight.look_at(Vector3.ZERO, Vector3.UP)  # Muralha virada para o Bruxo
	knight.shield_ticks = 90
	knight.shield_hp = 200
	_wizard.input.attack = true
	_run(START, 20)
	assert_eq(knight.hp, 600)
	assert_eq(knight.shield_hp, 200, "bloqueada antes de chegar: nem o escudo absorve")
	assert_eq(_active_balls(), 0)


func test_explosao_no_primeiro_alvo_fere_quem_esta_no_raio_2_u() -> void:
	_spawn_wizard(1)
	# Bola (raio 0,4) toca o Golem (raio 0,7) a 5 - 1,1 = 3,9 u: a explosao nasce ali.
	var first := _spawn_monster(GOLEM, -1, AHEAD * 5.0)
	var beside := _spawn_monster(GOLEM, -2, AHEAD * 5.0 + SIDE * 1.5)
	var behind := _spawn_monster(GOLEM, -3, AHEAD * 7.0)
	var wide := _spawn_monster(GOLEM, -4, AHEAD * 3.9 - SIDE * 2.1)
	_wizard.input.skill_q = true
	_run(START, 20)
	var damage := _q_damage()
	assert_eq(damage, roundi(70.0 + 0.9 * 45.0))
	assert_eq(680 - first.hp, damage)
	assert_eq(680 - beside.hp, damage, "1,86 u da explosao")
	assert_eq(behind.hp, 680, "3,1 u: fora do raio")
	assert_eq(wide.hp, 680, "2,1 u: fora do raio")
	assert_eq(_active_balls(), 0)
	_run(START + 20, 30)
	assert_eq(680 - first.hp, damage, "uma vez por alvo")


func test_explosao_no_fim_do_alcance() -> void:
	_spawn_wizard(1)
	var past := _spawn_monster(GOLEM, -1, AHEAD * 10.5)
	_wizard.input.skill_q = true
	_run(START, 25)
	assert_eq(680 - past.hp, _q_damage(), "explode a 9 u e pega quem esta a 1,5 u")


func test_explosao_no_muro() -> void:
	_spawn_wizard(1)
	_block_at(AHEAD * 3.0, Vector3(4, 4, 0.5), PhysicsLayers.WORLD)
	var front := _spawn_monster(GOLEM, -1, AHEAD * 2.0 + SIDE * 1.5)
	var behind := _spawn_monster(GOLEM, -2, AHEAD * 5.0)
	await wait_physics_frames(2)
	_wizard.input.skill_q = true
	_run(START, 20)
	assert_eq(680 - front.hp, _q_damage(), "explode na face do muro (2,75 u)")
	assert_eq(behind.hp, 680)


func test_explosao_na_muralha() -> void:
	_spawn_wizard(1)
	var knight := _spawn_knight(AHEAD * 5.0)
	knight.look_at(Vector3.ZERO, Vector3.UP)
	knight.shield_ticks = 90
	knight.shield_hp = 200
	var behind := _spawn_monster(GOLEM, -1, AHEAD * 7.0)
	_wizard.input.skill_q = true
	_run(START, 20)
	assert_eq(knight.hp, 600, "a Muralha absorve a explosao que vem da frente")
	assert_eq(knight.shield_hp, 200 - CombatRules.mitigated(_q_damage(), 30.0))
	assert_eq(behind.hp, 680)
	assert_eq(_active_balls(), 0)


func test_bot_de_bruxo_lanca_q_e_meteoro_ate_9_u() -> void:
	var brain := _bot_brain()
	var monster := _spawn_monster(SKELETON, -1, AHEAD * 8.5)
	await wait_physics_frames(2)
	brain._attack(START, monster, true)
	assert_true(brain.skill_q)
	assert_true(brain.skill_r)
	assert_false(brain.skill_e)
	assert_false(brain.attack, "fora do alcance do basico: anda")
	assert_almost_eq(brain.aim_distance, 8.5, EPS, "Meteoro mira a posicao do alvo")


func test_bot_de_bruxo_usa_o_anel_com_inimigo_perto() -> void:
	var brain := _bot_brain()
	var monster := _spawn_monster(SKELETON, -1, AHEAD * 2.5)
	await wait_physics_frames(2)
	brain._attack(START, monster, true)
	assert_true(brain.skill_e)
	assert_true(brain.attack)


func test_bot_de_bruxo_farmando_nao_usa_habilidade() -> void:
	var brain := _bot_brain()
	var monster := _spawn_monster(SKELETON, -1, AHEAD * 2.5)
	await wait_physics_frames(2)
	brain._attack(START, monster, false)
	assert_false(brain.skill_q)
	assert_false(brain.skill_e)
	assert_false(brain.skill_r)
	assert_true(brain.attack)
