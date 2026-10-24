extends FireWizardTestBase
## fire_wizard.tscn (GDB §4.4, F54; SPEC-054 §6 item 2): Anel de Fogo fere e empurra 2,0 u para
## fora e para no muro e no rio; Meteoro cai exatamente 1,0 s depois da marcacao e acerta so quem
## esta no raio 3,5 u naquele tick. Servidor = processo do teste (peer offline).


func test_anel_fere_e_empurra_2_u_para_fora() -> void:
	_spawn_wizard(2)
	assert_eq(_wizard.ranks.y, 1, "E aprendido no nivel 2")
	var knight := _spawn_knight(SIDE * 2.0)
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 2.9)
	var outside := _spawn_monster(GOLEM, -2, -AHEAD * 3.2)
	await wait_physics_frames(2)  # corpos do teste anterior saem do espaco fisico
	_wizard.input.skill_e = true
	_run(START, 15)
	var damage := roundi(40.0 + 0.5 * _wizard.attributes.attack)
	assert_eq(KNIGHT_HP - knight.hp, CombatRules.mitigated(damage, 30.0))
	assert_eq(680 - golem.hp, damage)
	assert_eq(outside.hp, 680)
	assert_almost_eq(knight.global_position, SIDE * 4.0, Vector3.ONE * 0.05)
	assert_almost_eq(golem.global_position, AHEAD * 4.9, Vector3.ONE * 0.05)
	assert_almost_eq(outside.global_position, -AHEAD * 3.2, Vector3.ONE * EPS)


func test_anel_para_no_muro() -> void:
	_spawn_wizard(2)
	_block_at(SIDE * 3.0, Vector3(0.5, 4, 6), PhysicsLayers.WORLD)
	var knight := _spawn_knight(SIDE * 2.0)
	await wait_physics_frames(2)
	_wizard.input.skill_e = true
	_run(START, 15)
	assert_lt(knight.global_position.x, 2.75, "nao atravessa o muro")
	assert_gt(knight.global_position.x, 2.0)


func test_anel_para_no_rio() -> void:
	_spawn_wizard(2)
	_block_at(SIDE * 3.0, Vector3(0.5, 4, 6), PhysicsLayers.RIVER)
	var knight := _spawn_knight(SIDE * 2.0)
	await wait_physics_frames(2)
	_wizard.input.skill_e = true
	_run(START, 15)
	assert_lt(knight.global_position.x, 2.75, "o empurrao nao joga ninguem no rio")


func test_meteoro_cai_exatamente_1_s_depois_da_marcacao() -> void:
	_spawn_wizard(6)
	assert_eq(_wizard.ranks.z, 1, "R aprendido no nivel 6")
	var center := _spawn_monster(GOLEM, -1, AHEAD * 6.0)
	var edge := _spawn_monster(GOLEM, -2, AHEAD * 6.0 + SIDE * 3.4)
	var out := _spawn_monster(GOLEM, -3, AHEAD * 6.0 - SIDE * 3.7)
	_wizard.input.skill_r = true
	_wizard.input.aim_distance = 6.0
	_run(START, 1)
	assert_almost_eq(_wizard.meteor_center, AHEAD * 6.0, Vector3.ONE * EPS)
	assert_eq(_wizard.meteor_ticks, METEOR_TICKS)
	_run(START + 1, METEOR_TICKS - 1)
	assert_eq(center.hp, 680, "ainda no ar")
	_run(START + METEOR_TICKS, 1)
	var attrs := _wizard.attributes
	var damage := roundi(260.0 + 1.4 * attrs.intelligence + 0.6 * attrs.attack)
	assert_eq(680 - center.hp, damage)
	assert_eq(680 - edge.hp, damage, "3,4 u")
	assert_eq(out.hp, 680, "3,7 u")
	assert_eq(_wizard.meteor_ticks, 0)
	_run(START + METEOR_TICKS + 1, 30)
	assert_eq(680 - center.hp, damage, "dano unico")


func test_meteoro_acerta_quem_esta_na_area_na_queda() -> void:
	_spawn_wizard(6)
	var leaves := _spawn_monster(GOLEM, -1, AHEAD * 6.0)
	var arrives := _spawn_monster(GOLEM, -2, AHEAD * 6.0 + SIDE * 6.0)
	_wizard.input.skill_r = true
	_wizard.input.aim_distance = 6.0
	_run(START, 15)
	leaves.global_position = AHEAD * 6.0 + SIDE * 6.0
	arrives.global_position = AHEAD * 6.0
	_run(START + 15, METEOR_TICKS)
	assert_eq(leaves.hp, 680)
	assert_lt(arrives.hp, 680)


func test_meteoro_no_heroi_passa_pelo_ledger() -> void:
	_spawn_wizard(6)
	var knight := _spawn_knight(AHEAD * 6.0)
	_wizard.input.skill_r = true
	_wizard.input.aim_distance = 6.0
	_run(START, METEOR_TICKS + 2)
	var attrs := _wizard.attributes
	var damage := roundi(260.0 + 1.4 * attrs.intelligence + 0.6 * attrs.attack)
	assert_eq(KNIGHT_HP - knight.hp, CombatRules.mitigated(damage, 30.0))


func test_meteoro_alem_do_alcance_cai_a_9_u() -> void:
	_spawn_wizard(6)
	_wizard.input.skill_r = true
	_wizard.input.aim_distance = 40.0
	_run(START, 1)
	assert_almost_eq(_wizard.meteor_center, AHEAD * 9.0, Vector3.ONE * EPS)


func test_meteoro_segue_com_o_bruxo_morto() -> void:
	_spawn_wizard(6)
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 6.0)
	_wizard.input.skill_r = true
	_wizard.input.aim_distance = 6.0
	_run(START, 1)
	_wizard.hp = 0
	_wizard.respawn_ticks = 300
	_run(START + 1, METEOR_TICKS)
	assert_lt(golem.hp, 680)
