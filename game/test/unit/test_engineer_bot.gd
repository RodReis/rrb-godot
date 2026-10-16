extends EngineerTestBase
## Bot de Engenheiro (SPEC-059 §7): basico com o alvo a ate 4,5 u; Garra entre 4,5 e 7 u; Torreta
## com inimigo (heroi ou monstro farmado) a ate 7 u, mirando entre ele e o alvo; Dinamite a ate 6 u,
## mirando a posicao atual. Limiares do bot_profile.tres.

const PROFILE: BotProfile = preload("res://shared/data/rules/bot_profile.tres")
const BASIC_RANGE: float = 4.5


func test_limiares_do_engenheiro_no_perfil() -> void:
	assert_eq([PROFILE.claw_range, PROFILE.turret_range, PROFILE.dynamite_range], [7.0, 7.0, 6.0])


func test_garra_so_alem_do_bacamarte_e_ate_7_u() -> void:
	assert_eq(_skills(3.0), Vector3i(0, 1, 1), "perto: sem Garra")
	assert_eq(_skills(4.5), Vector3i(0, 1, 1), "no limite do cone")
	assert_eq(_skills(5.0), Vector3i(1, 1, 1))
	assert_eq(_skills(6.5), Vector3i(1, 1, 0), "alem da Dinamite")
	assert_eq(_skills(7.5), Vector3i(0, 0, 0), "longe demais")


func test_mira_da_dinamite_e_do_alvo_e_da_torreta_e_meio_caminho() -> void:
	assert_almost_eq(BotRules.engineer_aim_distance(5.0, true), 5.0, EPS)
	assert_almost_eq(BotRules.engineer_aim_distance(5.0, false), 2.5, EPS)


func test_perto_usa_basico_torreta_e_dinamite() -> void:
	var brain := _bot_brain()
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 3.5)
	await wait_physics_frames(2)
	brain._attack(START, golem, true)
	assert_eq(brain.target_id, golem.combat_id())
	assert_true(brain.movement.is_zero_approx(), "no alcance: para e golpeia")
	assert_false(brain.skill_q, "dentro do cone: sem Garra")
	assert_true(brain.skill_r)
	assert_false(brain.skill_e, "a Dinamite tem a mira; a Torreta espera o proximo tick")
	assert_almost_eq(brain.aim_distance, 3.5, EPS)


func test_sem_dinamite_pronta_a_torreta_mira_no_meio() -> void:
	var brain := _bot_brain()
	_eng.r_cooldown = 300
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 3.5)
	await wait_physics_frames(2)
	brain._attack(START, golem, true)
	assert_true(brain.skill_e)
	assert_false(brain.skill_r)
	assert_almost_eq(brain.aim_distance, 1.75, EPS)


func test_entre_4_5_e_7_u_usa_a_garra_e_anda() -> void:
	var brain := _bot_brain()
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 6.0)
	await wait_physics_frames(2)
	brain._attack(START, golem, true)
	assert_true(brain.skill_q)
	assert_false(brain.movement.is_zero_approx(), "fora do alcance do basico: anda")


func test_farmando_so_a_torreta_e_o_basico() -> void:
	var brain := _bot_brain()
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 3.0)
	await wait_physics_frames(2)
	_eng.r_cooldown = 300
	brain._attack(START, golem, false)
	assert_false(brain.skill_q)
	assert_false(brain.skill_r, "a Dinamite fica para heroi e boss")
	assert_true(brain.skill_e, "a Torreta ajuda a farmar")
	assert_eq(brain.target_id, golem.combat_id())
	assert_true(brain.movement.is_zero_approx(), "no alcance: para e golpeia")


func _skills(distance: float) -> Vector3i:
	return BotRules.engineer_skills(distance, BASIC_RANGE, PROFILE)
