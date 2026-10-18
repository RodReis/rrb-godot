extends DruidTestBase
## Bot de Protetor da Selva (SPEC-074): Raizes ate 7 u para prender, Pocao Verde nos pes quando o HP
## cai abaixo de 50 % com perigo perto, Pantano no alvo ate 7 u so lutando. Limiares do
## bot_profile.tres.

const PROFILE: BotProfile = preload("res://shared/data/rules/bot_profile.tres")


func test_limiares_do_protetor_no_perfil() -> void:
	assert_eq([PROFILE.root_range, PROFILE.potion_hp_pct, PROFILE.swamp_range], [7.0, 0.5, 7.0])


func test_raizes_e_pantano_por_distancia_e_pocao_por_hp() -> void:
	assert_eq(BotRules.druid_skills(5.0, 1.0, PROFILE), Vector3i(1, 0, 1))
	assert_eq(BotRules.druid_skills(7.0, 1.0, PROFILE), Vector3i(1, 0, 1), "limite inclusivo")
	assert_eq(BotRules.druid_skills(7.5, 1.0, PROFILE), Vector3i(0, 0, 0), "longe demais")
	assert_eq(BotRules.druid_skills(5.0, 0.49, PROFILE), Vector3i(1, 1, 1), "HP abaixo de 50 %")
	assert_eq(BotRules.druid_skills(5.0, 0.5, PROFILE), Vector3i(1, 0, 1), "50 % ainda nao")


func test_mira_do_pantano_e_do_alvo_e_da_pocao_e_nos_pes() -> void:
	assert_almost_eq(BotRules.druid_aim_distance(5.0, true), 5.0, EPS)
	assert_almost_eq(BotRules.druid_aim_distance(5.0, false), 0.0, EPS)


func test_lutando_prende_e_lanca_o_pantano_no_alvo() -> void:
	var brain := _bot_brain()
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 5.0)
	await wait_physics_frames(2)
	brain._attack(START, golem, true)
	assert_true(brain.skill_q, "Raizes no alcance")
	assert_true(brain.skill_r, "Pantano pronto")
	assert_false(brain.skill_e)
	assert_almost_eq(brain.aim_distance, 5.0, EPS, "o Pantano cai no alvo")
	assert_eq(brain.target_id, golem.combat_id())
	assert_true(brain.movement.is_zero_approx(), "no alcance: para e golpeia")


func test_farmando_so_o_basico() -> void:
	var brain := _bot_brain()
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 5.0)
	await wait_physics_frames(2)
	brain._attack(START, golem, false)
	assert_false(brain.skill_q)
	assert_false(brain.skill_r)
	assert_eq(brain.target_id, golem.combat_id())


func test_pantano_em_recarga_nao_e_pedido() -> void:
	var brain := _bot_brain()
	_druid.r_cooldown = 300
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 5.0)
	await wait_physics_frames(2)
	brain._attack(START, golem, true)
	assert_false(brain.skill_r)
	assert_almost_eq(brain.aim_distance, 0.0, EPS)


func test_sem_linha_de_tiro_nao_atira_a_raiz() -> void:
	var brain := _bot_brain()
	_block_at(AHEAD * 2.5, Vector3(6, 4, 0.5), PhysicsLayers.WORLD)
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 5.0)
	await wait_physics_frames(2)
	brain._attack(START, golem, true)
	assert_false(brain.skill_q)


func test_pocao_quando_o_hp_cai_abaixo_de_50_por_cento_com_perigo() -> void:
	var brain := _bot_brain()
	_druid.hp = int(_druid.attributes.max_hp * 0.4)
	var view := BotView.new()
	view.hp_pct = 0.4
	view.in_danger = true
	brain._reset()
	brain._potion_when_hurt(view)
	assert_true(brain.skill_e)
	assert_almost_eq(brain.aim_distance, 0.0, EPS, "nos pes")


func test_pocao_nao_sem_perigo_nem_com_hp_alto_nem_com_o_pantano_na_vez() -> void:
	var brain := _bot_brain()
	var view := BotView.new()
	view.hp_pct = 0.4
	view.in_danger = false
	brain._reset()
	brain._potion_when_hurt(view)
	assert_false(brain.skill_e, "sem perigo")
	view.in_danger = true
	view.hp_pct = 0.9
	brain._potion_when_hurt(view)
	assert_false(brain.skill_e, "HP alto")
	view.hp_pct = 0.4
	brain.skill_r = true
	brain._potion_when_hurt(view)
	assert_false(brain.skill_e, "o Pantano usa a mira deste tick")


func test_pocao_em_recarga_nao_e_pedida() -> void:
	var brain := _bot_brain()
	_druid.e_cooldown = 300
	var view := BotView.new()
	view.hp_pct = 0.4
	view.in_danger = true
	brain._reset()
	brain._potion_when_hurt(view)
	assert_false(brain.skill_e)
