extends RogueTestBase
## Bot de Ladina (SPEC-058 §7): basico ate 7 u; Rajada com o alvo a ate 4 u; Emboscada ate 8 u;
## Bomba de Fumaca para fugir com HP < 40 % e inimigo visto a ate 7 u. Limiares do bot_profile.tres.


func test_rajada_e_emboscada_com_o_alvo_perto() -> void:
	var brain := _bot_brain()
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 3.5)
	await wait_physics_frames(2)
	brain._attack(START, golem, true)
	assert_true(brain.skill_q)
	assert_true(brain.skill_r)
	assert_false(brain.skill_e, "a fumaca e so para fugir")
	assert_true(brain.attack)


func test_so_emboscada_entre_4_e_8_u() -> void:
	var brain := _bot_brain()
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 7.5)
	await wait_physics_frames(2)
	brain._attack(START, golem, true)
	assert_false(brain.skill_q)
	assert_true(brain.skill_r)
	assert_false(brain.attack, "fora do alcance do basico: anda")


func test_farmando_nao_usa_habilidade() -> void:
	var brain := _bot_brain()
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 3.0)
	await wait_physics_frames(2)
	brain._attack(START, golem, false)
	assert_false(brain.skill_q)
	assert_false(brain.skill_e)
	assert_false(brain.skill_r)
	assert_true(brain.attack)


func test_fumaca_de_fuga_com_hp_baixo_e_heroi_perto() -> void:
	var brain := _bot_brain()
	var knight := _spawn_knight(AHEAD * 5.0)
	knight.team = GateRules.TEAM_A
	await wait_physics_frames(2)
	_rogue.hp = roundi(_rogue.attributes.max_hp * 0.3)
	brain.think(START)
	assert_true(brain.skill_e)


func test_sem_fumaca_com_hp_alto() -> void:
	var brain := _bot_brain()
	var knight := _spawn_knight(AHEAD * 5.0)
	knight.team = GateRules.TEAM_A
	await wait_physics_frames(2)
	brain.think(START)
	assert_false(brain.skill_e)
