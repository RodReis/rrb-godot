extends GutTest
## F98 (SPEC-098 §4): efeitos do Carrasco pela borda do estado (cone de espinhos no golpe dos
## Espinhos, clarao do recast, onda da Penitencia), pelo estado continuo (aro e brasas canalizando,
## contas da Dor, corpos e corrente dos projeteis), pelo impacto confirmado (estouro, raizes,
## grilhoes) e pelo evento do ImpactRelay (raio de luz das Correntes). Aqui o processo e o host
## (peer 1).

const CARRASCO: String = "res://scenes/heroes/carrasco.tscn"
const CARRASCO_VFX: PackedScene = preload("res://scenes/vfx/carrasco_vfx.tscn")
const FRAME: float = 1.0 / 60.0
const AIM: Vector3 = Vector3(0, 0, -1)
const EPS: float = 0.001

var _hero: Carrasco
var _pool: VfxPool
var _driver: CarrascoVfx


func _bind() -> void:
	_hero = (load(CARRASCO) as PackedScene).instantiate() as Carrasco
	_hero.name = "1"
	_hero.level = 6
	add_child_autofree(_hero)
	_hero.ranks = Vector3i(1, 1, 1)
	_pool = VfxPool.new()
	add_child_autofree(_pool)
	_driver = CARRASCO_VFX.instantiate() as CarrascoVfx
	add_child_autofree(_driver)
	_driver.bind(_hero, _pool)
	_frame()  # 1o valor visto nao e borda


func _frame() -> void:
	_driver._process(FRAME)


func _effects() -> int:
	return _pool.get_child_count()


func _last_effect() -> Node:
	return _pool.get_child(_effects() - 1)


func _visible_pips() -> int:
	var count := 0
	for pip: Node in _driver._pips.get_children():
		count += int((pip as Node3D).visible)
	return count if _driver._pips.visible else 0


func test_golpe_dos_espinhos_solta_o_cone_no_alcance() -> void:
	_bind()
	_hero.q_casts += 1
	_frame()
	assert_eq(_effects(), 1)
	var cone := _last_effect() as ThornsConeVfx
	assert_not_null(cone)
	assert_almost_eq(cone.scale.x, 3.0, EPS, "alcance de 3 u")
	_frame()
	assert_eq(_effects(), 1, "um cone por golpe")


func test_cone_tem_espinhos_dentro_dos_90_graus() -> void:
	_bind()
	_hero.q_casts += 1
	_frame()
	var cone := _last_effect() as ThornsConeVfx
	for spike: Node3D in cone._spikes:
		var flat := Vector2(spike.position.x, -spike.position.z)
		assert_lt(absf(flat.angle_to(Vector2(0, 1))), deg_to_rad(46.0), "dentro do cone")
		assert_lte(flat.length(), 1.0 + EPS, "ate o alcance")


func test_recast_e_explosao_soltam_um_efeito_cada() -> void:
	_bind()
	_hero.recasts += 1
	_frame()
	assert_eq(_effects(), 1, "clarao na mao")
	_hero.blasts += 1
	_frame()
	assert_eq(_effects(), 2)
	var blast := _last_effect() as Node3D
	assert_eq(blast.scene_file_path, "res://scenes/vfx/penance_blast.tscn")
	assert_almost_eq(blast.scale.x, 3.0, EPS, "raio da explosao")


func test_aro_e_brasas_so_canalizando() -> void:
	_bind()
	assert_false(_driver._aura.visible)
	_hero.penance_ticks = 30
	_frame()
	assert_true(_driver._aura.visible)
	assert_true(_driver._embers.emitting)
	_hero.penance_ticks = 0
	_frame()
	assert_false(_driver._aura.visible)
	assert_false(_driver._embers.emitting)


func test_uma_conta_por_ponto_de_dor() -> void:
	_bind()
	assert_eq(_visible_pips(), 0)
	for pain: int in [1, 4, 6, 2]:
		_hero.pain = pain
		_frame()
		assert_eq(_visible_pips(), pain)
	_hero.pain = 0
	_frame()
	assert_eq(_visible_pips(), 0)


func test_explosao_que_prendeu_vira_raizes_no_impacto() -> void:
	# A raiz vem do estado (blast_rooted): o ultimo pulso de Dor cai no tick da explosao.
	_bind()
	_hero.pain = 3
	_frame()
	_hero.pain = 0  # a explosao consome a Dor
	_hero.blast_rooted = true
	_hero.blasts += 1
	_frame()
	_driver.impact(HitLedger.Slot.E, Vector3(0, 0, -2))
	var roots := _last_effect() as RootsVfx
	assert_not_null(roots, "Dor 4: raiz")
	assert_almost_eq(roots.lifetime, 1.0 + RootsVfx.SHRINK_SECONDS, EPS)


func test_explosao_que_nao_prendeu_vira_estouro() -> void:
	_bind()
	_hero.pain = 3
	_frame()
	_hero.pain = 0
	_hero.blasts += 1
	_frame()
	_driver.impact(HitLedger.Slot.E, Vector3(0, 0, -2))
	assert_null(_last_effect() as RootsVfx)
	assert_eq((_last_effect() as Node3D).scene_file_path, "res://scenes/vfx/blood_burst.tscn")


func test_impacto_do_q_e_do_r() -> void:
	_bind()
	_driver.impact(HitLedger.Slot.Q, Vector3(0, 0, -3))
	assert_eq(_effects(), 1)
	assert_almost_eq((_last_effect() as Node3D).global_position.y, CarrascoVfx.STRIKE_HEIGHT, EPS)
	_driver.impact(HitLedger.Slot.R, Vector3(0, 0, -3))
	var shackles := _last_effect() as ShacklesVfx
	assert_not_null(shackles)
	assert_almost_eq(shackles.lifetime, 1.25 + ShacklesVfx.SHRINK_SECONDS, EPS, "raiz do rank 1")


func test_corpos_dos_projeteis_seguem_o_tipo_e_a_corrente_o_grilhao() -> void:
	_bind()
	var arrow := _hero.get_node("Arrows/Arrow0") as Arrow
	arrow.launch(Arrow.Kind.THORNS, Vector3(0, 1, 0), AIM, 7.0, 40)
	arrow._process(FRAME)
	_frame()
	assert_true(_driver._thorn_bodies[0].visible)
	assert_false(_driver._shackle_bodies[0].visible)
	assert_true(_driver._thorn_trails[0].emitting)
	assert_eq(_driver._chain.multimesh.visible_instance_count, 0)
	arrow.launch(Arrow.Kind.CHAINS, Vector3(0, 1, 0), AIM, 6.0, 80)
	arrow.traveled = 3.0
	arrow.origin = Vector3(0, 1, -3)
	arrow._process(FRAME)
	_frame()
	assert_false(_driver._thorn_bodies[0].visible)
	assert_true(_driver._shackle_bodies[0].visible)
	assert_false(_driver._thorn_trails[0].emitting)
	assert_gt(_driver._chain.multimesh.visible_instance_count, 5, "elos do peito ao grilhao")
	arrow.stop()
	arrow._process(FRAME)
	_frame()
	assert_eq(_driver._chain.multimesh.visible_instance_count, 0)


func test_cada_projetil_do_pool_ganha_seus_corpos_e_rastro() -> void:
	_bind()
	var arrows := _hero.get_node("Arrows").get_child_count()
	assert_eq(_driver._thorn_trails.size(), arrows)
	assert_eq(_driver._shackle_bodies.size(), arrows)
	assert_ne(_driver._thorn_trails[0], _driver._thorn_trails[arrows - 1])


func test_luz_nasce_no_ponto_com_raio_e_tempo_da_raiz() -> void:
	_bind()
	var center := Vector3(2, 0, -5)
	_driver.zone(Carrasco.Zone.LIGHT, center, NetworkTime.tick)
	var pillar := _last_effect() as LightPillarVfx
	assert_not_null(pillar)
	assert_almost_eq(pillar.global_position, center, Vector3.ONE * EPS)
	assert_almost_eq(pillar.lifetime, 1.25, EPS)
	assert_almost_eq((pillar.get_node("Pillar") as Node3D).scale.x, 2.5, EPS, "raio de 2,5 u")


func test_luz_atrasada_mostra_o_que_falta_e_a_acabada_nao_aparece() -> void:
	_bind()
	_driver.zone(Carrasco.Zone.LIGHT, Vector3.ZERO, NetworkTime.tick - NetworkTime.tickrate / 2)
	assert_almost_eq((_last_effect() as LightPillarVfx).lifetime, 0.75, 0.05)
	_driver.zone(Carrasco.Zone.LIGHT, Vector3.ZERO, NetworkTime.tick - 2 * NetworkTime.tickrate)
	assert_eq(_effects(), 1, "a de 2 s atras ja acabou")


func test_luz_acaba_e_volta_ao_pool() -> void:
	_bind()
	_driver.zone(Carrasco.Zone.LIGHT, Vector3.ZERO, NetworkTime.tick)
	var pillar := _last_effect() as LightPillarVfx
	for i: int in 90:  # 1,5 s a 60 quadros
		pillar._process(FRAME)
	assert_false(pillar.visible)


func test_spawner_tem_o_efeito_do_carrasco() -> void:
	assert_true(VfxSpawner.DRIVERS.has(&"carrasco"))


func test_relay_anuncia_a_luz_das_correntes() -> void:
	var players := Node.new()
	add_child_autofree(players)
	var relay := ImpactRelay.new()
	relay.players = players
	add_child_autofree(relay)
	var hero := (load(CARRASCO) as PackedScene).instantiate() as Carrasco
	hero.name = "1"
	players.add_child(hero)
	var shown: Array = []
	relay.zone_shown.connect(
		func(caster: int, kind: int, center: Vector3, tick: int) -> void:
			shown.append([caster, kind, center, tick])
	)
	hero.zone_started.emit(Carrasco.Zone.LIGHT, Vector3(1, 0, -4), 500)
	hero.zone_started.emit(Carrasco.Zone.LIGHT, Vector3(1, 0, -4), 500)  # ressimulacao: uma vez
	assert_eq(shown, [[1, Carrasco.Zone.LIGHT, Vector3(1, 0, -4), 500]])
