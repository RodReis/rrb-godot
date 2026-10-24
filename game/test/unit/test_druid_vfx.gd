extends GutTest
## F74 (SPEC-074 §VFX): efeitos do Protetor da Selva pela borda do estado (clarao de seiva no
## cajado, corpo e rastro do projetil por tipo), pelo impacto confirmado (respingo, raizes, bolha) e
## pelos eventos do ImpactRelay (Pocao Verde e Pantano). Aqui o processo e o host (peer 1).

const DRUID: String = "res://scenes/heroes/druid.tscn"
const DRUID_VFX: PackedScene = preload("res://scenes/vfx/druid_vfx.tscn")
const GOLEM: String = "res://scenes/monsters/golem_t3.tscn"
const BOSS: String = "res://scenes/monsters/skeleton_king_boss.tscn"
const FRAME: float = 1.0 / 60.0
const AIM: Vector3 = Vector3(0, 0, -1)

var _hero: Druid
var _pool: VfxPool
var _driver: DruidVfx


func _bind() -> void:
	_hero = (load(DRUID) as PackedScene).instantiate() as Druid
	_hero.name = "1"
	_hero.level = 6
	add_child_autofree(_hero)
	_pool = VfxPool.new()
	add_child_autofree(_pool)
	_driver = DRUID_VFX.instantiate() as DruidVfx
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


func test_basico_e_q_soltam_um_clarao_cada() -> void:
	_bind()
	_hero.basic_cooldown = 30
	_frame()
	assert_eq(_effects(), 1)
	_hero.q_cooldown = 300
	_frame()
	assert_eq(_effects(), 2)


func test_so_um_clarao_por_disparo() -> void:
	_bind()
	_hero.basic_cooldown = 30
	_frame()
	_hero.basic_cooldown = 29
	_frame()
	assert_eq(_effects(), 1)


func test_corpo_e_rastro_do_projetil_seguem_o_tipo() -> void:
	_bind()
	var arrow := _hero.get_node("Arrows/Arrow0") as Arrow
	arrow.launch(Arrow.Kind.BASIC, Vector3(0, 1, 0), AIM, 6.5, 40)
	arrow._process(FRAME)
	_frame()
	assert_true((arrow.get_node("Seed") as Node3D).visible)
	assert_false((arrow.get_node("Root") as Node3D).visible)
	assert_true(_driver._seed_trails[0].emitting)
	assert_false(_driver._root_trails[0].emitting)
	arrow.launch(Arrow.Kind.ROOT, Vector3(0, 1, 0), AIM, 7.0, 60)
	arrow._process(FRAME)
	_frame()
	assert_false((arrow.get_node("Seed") as Node3D).visible)
	assert_true((arrow.get_node("Root") as Node3D).visible)
	assert_false(_driver._seed_trails[0].emitting)
	assert_true(_driver._root_trails[0].emitting)


func test_impacto_da_seiva_solta_respingo() -> void:
	_bind()
	_driver.impact(HitLedger.Slot.BASIC, Vector3(0, 0, -3))
	assert_eq(_effects(), 1)


func test_impacto_da_raiz_solta_respingo_e_raizes_pelo_tempo_do_q() -> void:
	_bind()
	_driver.impact(HitLedger.Slot.Q, Vector3(0, 0, -3))
	assert_eq(_effects(), 2)
	var roots := _last_effect() as RootsVfx
	assert_not_null(roots)
	assert_almost_eq(roots.lifetime, 1.0 + RootsVfx.SHRINK_SECONDS, 0.001)
	assert_almost_eq(roots.global_position, Vector3(0, 0, -3), Vector3.ONE * 0.001)


func test_raizes_no_chefe_duram_so_um_floreio() -> void:
	_bind()
	var boss := (load(BOSS) as PackedScene).instantiate() as Monster
	boss.uid = -1
	boss.position = Vector3(0, 0, -3)
	add_child_autofree(boss)
	_driver.impact(HitLedger.Slot.Q, Vector3(0, 0, -3))
	var roots := _last_effect() as RootsVfx
	assert_almost_eq(roots.lifetime, DruidVfx.BOSS_ROOTS_SECONDS + RootsVfx.SHRINK_SECONDS, 0.001)


func test_raizes_em_monstro_comum_duram_o_tempo_do_q() -> void:
	_bind()
	var golem := (load(GOLEM) as PackedScene).instantiate() as Monster
	golem.uid = -2
	golem.position = Vector3(0, 0, -3)
	add_child_autofree(golem)
	_driver.impact(HitLedger.Slot.Q, Vector3(0, 0, -3))
	var roots := _last_effect() as RootsVfx
	assert_almost_eq(roots.lifetime, 1.0 + RootsVfx.SHRINK_SECONDS, 0.001)


func test_raizes_brotam_de_zero_a_um_e_encolhem_no_fim() -> void:
	_bind()
	_driver.impact(HitLedger.Slot.Q, Vector3.ZERO)
	var roots := _last_effect() as RootsVfx
	var tendril := roots._tendrils[0]
	roots._process(0.0)
	assert_lt(tendril.scale.x, 0.1, "comeca perto de zero")
	roots._process(RootsVfx.GROW_SECONDS)
	assert_almost_eq(tendril.scale.x, RootsVfx.SIZE_JITTER[0], 0.01, "pleno")
	roots._process(1.0 - RootsVfx.GROW_SECONDS)
	roots._process(RootsVfx.SHRINK_SECONDS)
	assert_gt(tendril.scale.x, 0.0, "nunca singular")
	assert_true(tendril.scale.is_finite())


func test_impacto_do_pantano_solta_uma_bolha() -> void:
	_bind()
	_driver.impact(HitLedger.Slot.R, Vector3(0, 0, -3))
	assert_eq(_effects(), 1)
	_driver.impact(HitLedger.Slot.E, Vector3(0, 0, -3))
	assert_eq(_effects(), 1, "a pocao nao acerta ninguem")


func test_pocao_nasce_no_ponto_com_raio_e_tempo_que_faltam() -> void:
	_bind()
	var center := Vector3(2, 0, -3)
	_driver.zone(Druid.Zone.POTION, center, _now())
	assert_eq(_effects(), 1)
	var potion := _last_effect() as PotionZoneVfx
	assert_not_null(potion)
	assert_almost_eq(potion.global_position, center, Vector3.ONE * 0.001)
	assert_almost_eq(potion.lifetime, 3.0, 0.001)
	assert_almost_eq(potion.get_node("Ring").scale.x, 3.0, 0.001, "raio de 3 u")
	assert_true(potion.get_node("Flask").visible, "zona nova: a garrafa voa")


func test_pocao_que_chega_atrasada_mostra_so_o_que_falta_sem_arco() -> void:
	_bind()
	_driver.zone(Druid.Zone.POTION, Vector3.ZERO, _now() - 2 * NetworkTime.tickrate)
	var potion := _last_effect() as PotionZoneVfx
	assert_almost_eq(potion.lifetime, 1.0, 0.05)
	assert_false(potion.get_node("Flask").visible)


func test_pocao_ja_acabada_nao_aparece() -> void:
	_bind()
	_driver.zone(Druid.Zone.POTION, Vector3.ZERO, _now() - 4 * NetworkTime.tickrate)
	assert_eq(_effects(), 0)


func test_pantano_nasce_no_ponto_com_raio_de_5_u_por_6_s() -> void:
	_bind()
	var center := Vector3(0, 0, -5)
	_driver.zone(Druid.Zone.SWAMP, center, _now())
	var swamp := _last_effect() as SwampZoneVfx
	assert_not_null(swamp)
	assert_almost_eq(swamp.global_position, center, Vector3.ONE * 0.001)
	assert_almost_eq(swamp.lifetime, 6.0, 0.001)
	assert_almost_eq(swamp.get_node("Ring").scale.x, 5.0, 0.001, "raio de 5 u")


func test_pantano_atrasado_e_acabado() -> void:
	_bind()
	_driver.zone(Druid.Zone.SWAMP, Vector3.ZERO, _now() - 3 * NetworkTime.tickrate)
	assert_almost_eq((_last_effect() as SwampZoneVfx).lifetime, 3.0, 0.05)
	_driver.zone(Druid.Zone.SWAMP, Vector3.ZERO, _now() - 7 * NetworkTime.tickrate)
	assert_eq(_effects(), 1, "o de 7 s atras ja acabou")


func test_zonas_percorrem_a_vida_sem_erro_e_voltam_ao_pool() -> void:
	_bind()
	_driver.zone(Druid.Zone.POTION, Vector3.ZERO, _now())
	_driver.zone(Druid.Zone.SWAMP, Vector3(0, 0, -5), _now())
	for i: int in 400:  # ~6,7 s a 60 quadros
		for effect: Node in _pool.get_children():
			effect._process(FRAME)
	for effect: Node in _pool.get_children():
		assert_false((effect as Node3D).visible, "acabou")
