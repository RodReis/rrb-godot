extends GutTest
## F59 (SPEC-059 §6): efeitos do Engenheiro pela borda do estado (clarao e estilhacos do bacamarte,
## cabo da Garra), pelo impacto confirmado (faiscas) e pelos eventos do ImpactRelay (Torreta, tiros
## dela e caixa de Dinamite). Aqui o processo e o host (peer 1).

const ENGINEER: String = "res://scenes/heroes/engineer.tscn"
const ENGINEER_VFX: PackedScene = preload("res://scenes/vfx/engineer_vfx.tscn")
const FRAME: float = 1.0 / 60.0
const AIM: Vector3 = Vector3(0, 0, -1)

var _hero: Engineer
var _pool: VfxPool
var _driver: EngineerVfx


func _bind() -> void:
	_hero = (load(ENGINEER) as PackedScene).instantiate() as Engineer
	_hero.name = "1"
	_hero.level = 6
	add_child_autofree(_hero)
	_pool = VfxPool.new()
	add_child_autofree(_pool)
	_driver = ENGINEER_VFX.instantiate() as EngineerVfx
	add_child_autofree(_driver)
	_driver.bind(_hero, _pool)
	_frame()  # 1o valor visto nao e borda


func _frame() -> void:
	_driver._process(FRAME)


func _effects() -> int:
	return _pool.get_child_count()


func _last_effect() -> Node:
	return _pool.get_child(_effects() - 1)


func _now() -> int:
	return NetworkTime.tick


func test_bacamarte_solta_clarao_e_estilhacos_no_alcance_do_cone() -> void:
	_bind()
	_hero.basic_cooldown = 36
	_frame()
	assert_eq(_effects(), 1)
	var blast := _last_effect() as BlunderBlastVfx
	assert_not_null(blast)
	var shrapnel := blast.get_node("Shrapnel") as GPUParticles3D
	assert_eq(shrapnel.amount, 10, "10 estilhacos")
	var material := shrapnel.process_material as ParticleProcessMaterial
	assert_almost_eq(material.spread, 20.0, 0.001, "abertura de 40 graus")
	assert_almost_eq(
		material.initial_velocity_max * BlunderBlastVfx.SHRAPNEL_REACH_TIME, 4.5, 0.001
	)


func test_so_um_clarao_por_disparo() -> void:
	_bind()
	_hero.basic_cooldown = 36
	_frame()
	_hero.basic_cooldown = 35
	_frame()
	assert_eq(_effects(), 1)


func test_impacto_do_bacamarte_e_da_garra_solta_faiscas_e_o_da_dinamite_nao() -> void:
	_bind()
	_driver.impact(HitLedger.Slot.BASIC, Vector3(0, 0, -3))
	_driver.impact(HitLedger.Slot.Q, Vector3(0, 0, -3))
	assert_eq(_effects(), 2)
	_driver.impact(HitLedger.Slot.R, Vector3(0, 0, -3))
	assert_eq(_effects(), 2, "a explosao tem o proprio efeito")


func test_garra_em_voo_estica_o_cabo_ate_ela() -> void:
	_bind()
	var cable := _driver.get_node("Cable") as MeshInstance3D
	_frame()
	assert_false(cable.visible)
	var claw := _hero.get_node("Arrows/Arrow0") as Arrow
	claw.speed = 20.0
	claw.launch(Arrow.Kind.CLAW, Vector3(0, 1, 0), AIM, 7.0, 80)
	claw.traveled = 3.0
	claw.origin = Vector3(0, 1, -3)
	claw._process(FRAME)
	_frame()
	assert_true(cable.visible)
	assert_gt(cable.global_transform.basis.z.length(), 1.0, "esticado no comprimento")


func test_cabo_encurta_depois_que_a_garra_para_e_some() -> void:
	_bind()
	var cable := _driver.get_node("Cable") as MeshInstance3D
	var claw := _hero.get_node("Arrows/Arrow0") as Arrow
	claw.speed = 20.0
	claw.launch(Arrow.Kind.CLAW, Vector3(0, 1, 0), AIM, 7.0, 80)
	claw.origin = Vector3(0, 1, -5)
	claw._process(FRAME)
	_frame()
	claw.stop()
	_frame()
	assert_true(cable.visible, "recolhendo")
	for i: int in 30:  # 0,5 s: mais que os 0,3 s do puxao
		_frame()
	assert_false(cable.visible)


func test_torreta_nasce_no_ponto_com_o_tempo_que_falta() -> void:
	_bind()
	var center := Vector3(2, 0, -3)
	_driver.deployed(Engineer.Deploy.TURRET, center, _now())
	assert_eq(_effects(), 1)
	var turret := _last_effect() as TurretVfx
	assert_not_null(turret)
	assert_almost_eq(turret.global_position, center, Vector3.ONE * 0.001)
	assert_almost_eq(turret.lifetime, 6.0 + TurretVfx.SHRINK_SECONDS, 0.001)
	assert_true(turret.is_up_for(1))


func test_torreta_que_chega_atrasada_mostra_so_o_que_falta() -> void:
	_bind()
	_driver.deployed(Engineer.Deploy.TURRET, Vector3.ZERO, _now() - 3 * NetworkTime.tickrate)
	var turret := _last_effect() as TurretVfx
	assert_almost_eq(turret.lifetime, 3.0 + TurretVfx.SHRINK_SECONDS, 0.05)


func test_torreta_que_ja_acabou_nao_aparece() -> void:
	_bind()
	_driver.deployed(Engineer.Deploy.TURRET, Vector3.ZERO, _now() - 8 * NetworkTime.tickrate)
	assert_eq(_effects(), 0)


func test_nova_torreta_encerra_a_anterior() -> void:
	_bind()
	_driver.deployed(Engineer.Deploy.TURRET, Vector3.ZERO, _now())
	var first := _last_effect() as TurretVfx
	_driver.deployed(Engineer.Deploy.TURRET, Vector3(3, 0, 0), _now())
	var second := _last_effect() as TurretVfx
	assert_ne(first, second)
	assert_false(first.is_up_for(1), "a anterior encolhe e some")
	assert_true(second.is_up_for(1))


func test_torreta_pop_encolhe_e_gira_a_cabeca_para_o_tiro() -> void:
	_bind()
	_driver.deployed(Engineer.Deploy.TURRET, Vector3.ZERO, _now())
	var turret := _last_effect() as TurretVfx
	var model := turret.get_node("Model") as Node3D
	turret._process(0.0)
	assert_lt(model.scale.x, 0.01, "nasce quase em 0 (nunca singular)")
	turret._process(TurretVfx.POP_SECONDS)
	assert_almost_eq(model.scale.x, 1.0, 0.001, "pop termina em 1")
	_driver.turret_shot(Vector3.ZERO, Vector3(4, 0, 0), 100)
	var gun := model.find_child("turret_gun", true, false) as Node3D
	# O cano do pack aponta para +Z: virado para +X, o yaw do no e 90 graus.
	assert_almost_eq(gun.global_rotation.y, deg_to_rad(90.0), 0.01)


func test_tiro_da_torreta_solta_tracante_do_cano_ao_alvo() -> void:
	_bind()
	_driver.deployed(Engineer.Deploy.TURRET, Vector3.ZERO, _now())
	var before := _effects()
	_driver.turret_shot(Vector3.ZERO, Vector3(0, 0, -5), 100)
	assert_eq(_effects(), before + 1)
	var tracer := _last_effect() as TurretTracerVfx
	assert_not_null(tracer)
	assert_almost_eq((tracer.get_node("Beam") as Node3D).scale.z, 5.0, 0.001)


func test_caixa_voa_ate_o_ponto_e_explode_no_fim_do_pavio() -> void:
	_bind()
	var center := Vector3(0, 0, -6)
	_driver.deployed(Engineer.Deploy.CRATE, center, _now())
	assert_eq(_effects(), 1)
	var crate := _last_effect() as DynamiteCrateVfx
	assert_not_null(crate)
	var ring := crate.get_node("Ring") as MeshInstance3D
	crate._process(FRAME)
	assert_true(ring.visible)
	for i: int in 90:  # 1,5 s a 60 quadros
		crate._process(FRAME)
	assert_gt(_effects(), 1, "a explosao nasceu")
	assert_false(ring.visible, "o anel some na explosao")
	assert_false((crate.get_node("Crate") as Node3D).visible)


func test_caixa_atrasada_ou_vencida() -> void:
	_bind()
	_driver.deployed(Engineer.Deploy.CRATE, Vector3.ZERO, _now() - 3 * NetworkTime.tickrate)
	assert_eq(_effects(), 0, "o pavio de 1,5 s ja acabou")


func test_quem_ve_a_torreta_so_pelo_tiro_a_monta_com_o_tempo_que_falta() -> void:
	_bind()
	_driver.turret_shot(Vector3(1, 0, 1), Vector3(1, 0, -4), 90)
	var turret: TurretVfx = null
	for node: Node in _pool.get_children():
		if node is TurretVfx:
			turret = node
	assert_not_null(turret, "montada a partir do tiro")
	assert_almost_eq(turret.global_position, Vector3(1, 0, 1), Vector3.ONE * 0.001)
	assert_almost_eq(turret.lifetime, 3.0 + TurretVfx.SHRINK_SECONDS, 0.001)
	_driver.turret_shot(Vector3(1, 0, 1), Vector3(1, 0, -4), 67)
	var turrets := 0
	for node: Node in _pool.get_children():
		turrets += 1 if node is TurretVfx else 0
	assert_eq(turrets, 1, "o 2o tiro usa a mesma Torreta")


func test_torreta_acabando_sem_tempo_nao_e_montada_pelo_tiro() -> void:
	_bind()
	_driver.turret_shot(Vector3.ZERO, Vector3(0, 0, -4), 0)
	for node: Node in _pool.get_children():
		assert_false(node is TurretVfx)


func test_poeira_e_clarao_da_torreta_nao_tocam_no_spawn() -> void:
	_bind()
	_driver.deployed(Engineer.Deploy.TURRET, Vector3.ZERO, _now())
	var turret := _last_effect() as TurretVfx
	assert_false((turret.get_node("EndDust") as GPUParticles3D).emitting)
	assert_false((turret.get_node("Flash") as GPUParticles3D).emitting)
	assert_true((turret.get_node("InstallDust") as GPUParticles3D).emitting)


func test_torreta_reusada_do_pool_gira_a_cabeca_sem_nan() -> void:
	_bind()
	_driver.deployed(Engineer.Deploy.TURRET, Vector3.ZERO, _now())
	var first := _last_effect() as TurretVfx
	for i: int in 500:  # 6,25 s: a Torreta encolhe ate escala 0 e volta ao pool
		first._process(0.0125)
	assert_false(first.visible)
	var model := first.get_node("Model") as Node3D
	assert_lt(model.scale.x, 0.1, "fim da vida: quase 0")
	_driver.deployed(Engineer.Deploy.TURRET, Vector3(2, 0, 0), _now())
	assert_eq(_effects(), 1, "reusou a mesma instancia")
	_driver.turret_shot(Vector3(2, 0, 0), Vector3(2, 0, -4), 100)  # antes do 1o quadro dela
	var gun := model.find_child("turret_gun", true, false) as Node3D
	assert_true(gun.global_position.is_finite())
	assert_true(gun.global_transform.basis.x.is_finite())
	assert_true((first.get_node("Flash") as Node3D).global_position.is_finite())
