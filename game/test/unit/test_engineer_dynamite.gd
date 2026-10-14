extends EngineerTestBase
## Caixa de Dinamite (GDB §4.6; SPEC-059 §8 item 4): explode exatamente 1,5 s depois, acerta so quem
## esta no raio 4,5 u naquele tick e empurra 3,0 u para fora, parando no obstaculo. Servidor =
## processo do teste (peer offline).

var _crates: Array[Vector3] = []


func before_each() -> void:
	super()
	_crates = []


func _drop(aim_distance: float = 6.0) -> void:
	_spawn_engineer(6)
	assert_eq(_eng.ranks.z, 1, "R aprendido no nivel 6")
	_eng.deployed.connect(
		func(kind: Engineer.Deploy, center: Vector3, _tick: int) -> void:
			if kind == Engineer.Deploy.CRATE:
				_crates.append(center)
	)
	_eng.input.skill_r = true
	_eng.input.aim_distance = aim_distance


func test_caixa_no_ponto_mirado_ate_6_u() -> void:
	_drop(40.0)
	_run(START, 1)
	assert_almost_eq(_eng.crate_center, AHEAD * 6.0, Vector3.ONE * EPS)
	assert_eq(_eng.crate_ticks, FUSE_TICKS)
	assert_eq(_crates.size(), 1)


func test_explode_exatamente_1_5_s_depois() -> void:
	_drop()
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 6.0)
	_run(START, 1)
	_run(START + 1, FUSE_TICKS - 1)
	assert_eq(golem.hp, GOLEM_HP, "ainda no pavio")
	_run(START + FUSE_TICKS, 1)
	assert_eq(GOLEM_HP - golem.hp, _dynamite_damage())
	var r := _eng.hero_data.skill_r
	var a := _eng.attributes
	assert_eq(_dynamite_damage(), roundi(240.0 + 1.3 * a.intelligence + 0.6 * a.attack))
	assert_eq(r.duration, PackedFloat64Array([1.5]))
	assert_eq(_eng.crate_ticks, 0)
	_run(START + FUSE_TICKS + 1, 30)
	assert_eq(GOLEM_HP - golem.hp, _dynamite_damage(), "dano unico")


func test_acerta_so_quem_esta_no_raio_de_4_5_u() -> void:
	_drop()
	var inside := _spawn_monster(GOLEM, -1, AHEAD * 6.0 + SIDE * 4.4)
	var outside := _spawn_monster(GOLEM, -2, AHEAD * 6.0 + SIDE * 4.6)
	_run(START, FUSE_TICKS + 1)
	assert_eq(GOLEM_HP - inside.hp, _dynamite_damage())
	assert_eq(outside.hp, GOLEM_HP)


func test_acerta_quem_esta_na_area_naquele_tick() -> void:
	_drop()
	var leaves := _spawn_monster(GOLEM, -1, AHEAD * 6.0)
	var arrives := _spawn_monster(GOLEM, -2, AHEAD * 6.0 + SIDE * 8.0)
	_run(START, 15)
	leaves.global_position = AHEAD * 6.0 + SIDE * 8.0
	arrives.global_position = AHEAD * 6.0
	_run(START + 15, FUSE_TICKS)
	assert_eq(leaves.hp, GOLEM_HP)
	assert_lt(arrives.hp, GOLEM_HP)


func test_heroi_toma_dano_pelo_ledger_e_e_empurrado_3_u_para_fora() -> void:
	_drop()
	var knight := _spawn_knight(AHEAD * 6.0 + SIDE * 2.0)
	await wait_physics_frames(2)  # corpos do teste anterior saem do espaco fisico
	_run(START, FUSE_TICKS + 20)
	assert_eq(KNIGHT_HP - knight.hp, CombatRules.mitigated(_dynamite_damage(), KNIGHT_DEF))
	assert_almost_eq(knight.global_position, AHEAD * 6.0 + SIDE * 5.0, Vector3.ONE * 0.05)


func test_empurrao_para_no_muro() -> void:
	_drop()
	_block_at(AHEAD * 6.0 + SIDE * 3.5, Vector3(0.5, 4, 8), PhysicsLayers.WORLD)
	var knight := _spawn_knight(AHEAD * 6.0 + SIDE * 2.0)
	await wait_physics_frames(2)
	_run(START, FUSE_TICKS + 20)
	assert_lt(knight.global_position.x, 3.3, "nao atravessa o muro")
	assert_gt(knight.global_position.x, 2.0)


func test_nao_fere_nem_empurra_o_proprio_engenheiro() -> void:
	_drop(0.0)
	_run(START, FUSE_TICKS + 5)
	assert_eq(_eng.hp, _eng.attributes.max_hp)
	assert_almost_eq(_eng.global_position, Vector3.ZERO, Vector3.ONE * EPS)


func test_caixa_explode_mesmo_com_o_engenheiro_morto() -> void:
	_drop()
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 6.0)
	_run(START, 1)
	_eng.hp = 0
	_eng.respawn_ticks = 600
	_run(START + 1, FUSE_TICKS)
	assert_lt(golem.hp, GOLEM_HP)
