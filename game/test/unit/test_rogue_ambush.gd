extends RogueTestBase
## Emboscada (GDB §4.5; SPEC-058 §8 item 4): avanca ate 8 u a 24 u/s, para no 1o inimigo (golpe
## unico) ou no obstaculo (muro, rio); dano x1,3 se a Ladina estava oculta no tick do uso (moita ou
## fumaca, sem revelacao). Servidor = processo do teste.

## 8 u a 24 u/s = 0,33 s = 10 ticks.
const DASH_TICKS: int = 10


func _ambush() -> void:
	_rogue.input.skill_r = true
	_run(START, DASH_TICKS + 2)


func test_avanco_de_8_u_sem_alvo() -> void:
	_spawn_rogue(6)
	assert_eq(_rogue.ranks.z, 1, "R aprendido no nivel 6")
	await wait_physics_frames(2)
	_rogue.input.skill_r = true
	_run(START, 1)
	assert_eq(_rogue.dash_ticks, DASH_TICKS, "conta a partir do tick seguinte")
	_run(START + 1, DASH_TICKS + 1)
	assert_almost_eq(_rogue.global_position.z, -8.0, 0.1)
	assert_false(_rogue.ambushing)


func test_para_no_primeiro_inimigo_e_golpeia_uma_vez() -> void:
	_spawn_rogue(6)
	var knight := _spawn_knight(AHEAD * 5.0)
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 7.5)
	await wait_physics_frames(2)
	_ambush()
	var damage := roundi(_r_amount())
	assert_eq(KNIGHT_HP - knight.hp, CombatRules.mitigated(damage, KNIGHT_DEF))
	assert_eq(golem.hp, GOLEM_HP)
	var gap := _rogue.global_position.distance_to(knight.global_position)
	assert_between(gap, 0.7, 0.9, "parou colada no Cavaleiro")
	assert_gt(_rogue.stab_ticks, 0, "golpe marcado para a animacao")
	_run(START + DASH_TICKS + 2, 20)
	assert_eq(KNIGHT_HP - knight.hp, CombatRules.mitigated(damage, KNIGHT_DEF), "uma vez so")


func test_para_no_monstro() -> void:
	_spawn_rogue(6)
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 4.0)
	await wait_physics_frames(2)
	_ambush()
	assert_eq(GOLEM_HP - golem.hp, roundi(_r_amount()))


func test_para_no_muro() -> void:
	_spawn_rogue(6)
	_block_at(AHEAD * 3.0, Vector3(6, 4, 0.5), PhysicsLayers.WORLD)
	var knight := _spawn_knight(AHEAD * 6.0)
	await wait_physics_frames(2)
	_ambush()
	assert_gt(_rogue.global_position.z, -3.0, "nao atravessa o muro")
	assert_eq(knight.hp, KNIGHT_HP)
	assert_false(_rogue.ambushing)


func test_para_no_rio() -> void:
	_spawn_rogue(6)
	_block_at(AHEAD * 3.0, Vector3(6, 4, 0.5), PhysicsLayers.RIVER)
	var knight := _spawn_knight(AHEAD * 6.0)
	await wait_physics_frames(2)
	_ambush()
	assert_gt(_rogue.global_position.z, -3.0, "nao atravessa o rio")
	assert_eq(knight.hp, KNIGHT_HP)


func test_oculta_na_moita_multiplica_por_1_3() -> void:
	_grass_at(Vector3.ZERO, Vector3(4, 2.4, 4))
	_spawn_rogue(6)
	var knight := _spawn_knight(AHEAD * 5.0)
	await wait_physics_frames(2)
	_ambush()
	assert_true(_rogue.ambush_hidden)
	var damage := roundi(_r_amount() * 1.3)
	assert_eq(KNIGHT_HP - knight.hp, CombatRules.mitigated(damage, KNIGHT_DEF))


func test_oculta_na_fumaca_multiplica_por_1_3() -> void:
	_spawn_rogue(6)
	var knight := _spawn_knight(AHEAD * 5.5)
	await wait_physics_frames(2)
	_rogue.input.skill_e = true
	_run(START, 1)
	_rogue.input.skill_r = true
	_run(START + 1, DASH_TICKS + 2)
	assert_true(_rogue.ambush_hidden)
	var damage := roundi(_r_amount() * 1.3)
	assert_eq(KNIGHT_HP - knight.hp, CombatRules.mitigated(damage, KNIGHT_DEF))


func test_revelada_nao_multiplica() -> void:
	_grass_at(Vector3.ZERO, Vector3(4, 2.4, 4))
	_spawn_rogue(6)
	var knight := _spawn_knight(AHEAD * 5.0)
	await wait_physics_frames(2)
	_rogue.reveal_ticks = 45  # atacou ha pouco
	_ambush()
	assert_false(_rogue.ambush_hidden)
	assert_eq(KNIGHT_HP - knight.hp, CombatRules.mitigated(roundi(_r_amount()), KNIGHT_DEF))


func test_usar_a_emboscada_revela() -> void:
	_grass_at(Vector3.ZERO, Vector3(4, 2.4, 4))
	_spawn_rogue(6)
	await wait_physics_frames(2)
	_rogue.input.skill_r = true
	_run(START, 1)
	assert_eq(_rogue.reveal_ticks, 45)
