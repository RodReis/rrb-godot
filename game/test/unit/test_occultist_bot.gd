extends OccultistTestBase
## Bot de Ocultista (SPEC-077): o basico sai sozinho no alcance (marcas); Praga no alvo do Lutar ate
## 8 u; Circulo Profano com o alvo a ate 7 u e se aproximando; o R nunca. Limiares do
## bot_profile.tres.

const PROFILE: BotProfile = preload("res://shared/data/rules/bot_profile.tres")


func test_limiares_do_ocultista_no_perfil() -> void:
	assert_eq(
		[PROFILE.plague_range, PROFILE.circle_range, PROFILE.circle_approach_speed], [8.0, 7.0, 1.0]
	)


func test_praga_ate_8_u_e_circulo_so_se_aproximando_ate_7_u() -> void:
	assert_eq(BotRules.occultist_skills(5.0, 2.0, PROFILE), Vector3i(1, 1, 0))
	assert_eq(BotRules.occultist_skills(7.0, 2.0, PROFILE), Vector3i(1, 1, 0), "limite inclusivo")
	assert_eq(BotRules.occultist_skills(7.5, 2.0, PROFILE), Vector3i(1, 0, 0), "Circulo a 7 u")
	assert_eq(BotRules.occultist_skills(8.0, 2.0, PROFILE), Vector3i(1, 0, 0))
	assert_eq(BotRules.occultist_skills(8.5, 2.0, PROFILE), Vector3i(0, 0, 0), "longe demais")
	assert_eq(BotRules.occultist_skills(5.0, 0.0, PROFILE), Vector3i(1, 0, 0), "parado")
	assert_eq(BotRules.occultist_skills(5.0, -3.0, PROFILE), Vector3i(1, 0, 0), "fugindo")


func test_o_r_nunca_e_pedido() -> void:
	assert_eq(BotRules.occultist_skills(1.0, 9.0, PROFILE).z, 0)


func test_velocidade_de_aproximacao_e_a_projecao_no_eixo_do_bot() -> void:
	var to_target := Vector3(0, 0, -5)
	assert_almost_eq(BotRules.closing_speed(Vector3(0, 0, 3), to_target), 3.0, EPS, "vindo")
	assert_almost_eq(BotRules.closing_speed(Vector3(0, 0, -3), to_target), -3.0, EPS, "indo")
	assert_almost_eq(BotRules.closing_speed(Vector3(4, 0, 0), to_target), 0.0, EPS, "de lado")
	assert_almost_eq(BotRules.closing_speed(Vector3(0, 0, 3), Vector3.ZERO), 0.0, EPS, "colado")


func test_lutando_lanca_praga_e_circulo_no_alvo_que_se_aproxima() -> void:
	var brain := _bot_brain()
	var knight := _spawn_knight(AHEAD * 6.0)
	await wait_physics_frames(2)
	knight.velocity = -AHEAD * 3.0  # vindo na direcao do bot
	brain._attack(START, knight, true)
	assert_true(brain.skill_q, "Praga no alcance")
	assert_true(brain.skill_e, "Circulo: alvo a 6 u e se aproximando")
	assert_false(brain.skill_r)
	assert_almost_eq(brain.aim_distance, 6.0, EPS, "o Circulo cai no alvo")
	assert_eq(brain.target_id, knight.combat_id())


func test_alvo_parado_ou_fugindo_nao_leva_circulo() -> void:
	var brain := _bot_brain()
	var knight := _spawn_knight(AHEAD * 6.0)
	await wait_physics_frames(2)
	knight.velocity = Vector3.ZERO
	brain._attack(START, knight, true)
	assert_true(brain.skill_q)
	assert_false(brain.skill_e, "parado")
	knight.velocity = AHEAD * 3.0
	brain._attack(START, knight, true)
	assert_false(brain.skill_e, "fugindo")


func test_farmando_so_o_basico() -> void:
	var brain := _bot_brain()
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 5.0)
	await wait_physics_frames(2)
	golem.velocity = -AHEAD * 3.0
	brain._attack(START, golem, false)
	assert_false(brain.skill_q)
	assert_false(brain.skill_e)
	assert_eq(brain.target_id, golem.combat_id(), "o basico sai sozinho no alvo travado")


func test_sem_linha_de_tiro_nao_atira_a_praga() -> void:
	var brain := _bot_brain()
	var wall := StaticBody3D.new()
	wall.collision_layer = PhysicsLayers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(6, 4, 0.5)
	shape.shape = box
	wall.add_child(shape)
	wall.position = AHEAD * 2.5 + Vector3.UP
	add_child_autofree(wall)
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 5.0)
	await wait_physics_frames(2)
	brain._attack(START, golem, true)
	assert_false(brain.skill_q)


func test_gasta_o_ponto_do_nivel_6_em_q_ou_e_nunca_no_r() -> void:
	var brain := _bot_brain(5)
	_occultist.xp = XpTable.xp_for_level(_occultist.xp_curve, 6)
	_occultist._refresh_attributes()
	_occultist.ranks = Vector3i(3, 2, 0)
	brain._reset()
	brain._learn_points()
	assert_ne(brain.learn, SkillRules.SLOT_R)
	assert_true([SkillRules.SLOT_Q, SkillRules.SLOT_E].has(brain.learn))
