extends GutTest
## F58 (SPEC-058 §6): efeitos da Ladina pela borda do estado (clarao do disparo, maior na Rajada;
## rastro do virote; fantasmas da Emboscada), pelo impacto confirmado (corte, clarao roxo se
## oculta) e pela nuvem que chega do ImpactRelay. Aqui o processo e o host (peer 1).

const ROGUE: String = "res://scenes/heroes/rogue.tscn"
const ROGUE_VFX: PackedScene = preload("res://scenes/vfx/rogue_vfx.tscn")
const FRAME: float = 1.0 / 60.0

var _hero: Hero
var _pool: VfxPool
var _driver: HeroVfx


func _bind() -> void:
	_hero = (load(ROGUE) as PackedScene).instantiate() as Hero
	_hero.name = "1"
	_hero.level = 6
	add_child_autofree(_hero)
	_pool = VfxPool.new()
	add_child_autofree(_pool)
	_driver = ROGUE_VFX.instantiate() as HeroVfx
	add_child_autofree(_driver)
	_driver.bind(_hero, _pool)
	_frame()  # 1o valor visto nao e borda


func _frame() -> void:
	_driver._process(FRAME)


func _effects() -> int:
	return _pool.get_child_count()


func test_disparo_da_besta_solta_um_clarao_e_a_rajada_um_maior() -> void:
	_bind()
	_hero.basic_cooldown = 30
	_frame()
	assert_eq(_effects(), 1)
	var flash := _pool.get_child(0) as ScaledVfx
	assert_almost_eq(flash.scale.x, 1.0, 0.001)
	_hero.q_cooldown = 240
	_frame()
	assert_eq(_effects(), 2)
	assert_almost_eq((_pool.get_child(1) as ScaledVfx).scale.x, 1.8, 0.001)


func test_virote_em_voo_tem_rastro() -> void:
	_bind()
	var bolt := _hero.get_node("Arrows/Arrow2") as Arrow
	bolt.speed = 24.0
	bolt.launch(Arrow.Kind.FAN, Vector3.UP, Vector3.FORWARD, 7.0, 52)
	bolt._process(FRAME)
	_frame()
	var emitting := 0
	for node: Node in _driver.get_children():
		if node is TrailRibbon and (node as TrailRibbon).emitting:
			emitting += 1
	assert_eq(emitting, 1, "so o rastro do virote em voo")


func test_nuvem_no_raio_e_na_duracao_do_e() -> void:
	_bind()
	(_driver as RogueVfx).smoke(Vector3(2.0, 0.0, -3.0), NetworkTime.tick)
	assert_eq(_effects(), 1)
	var cloud := _pool.get_child(0) as SmokeCloudVfx
	assert_eq(cloud.global_position, Vector3(2.0, 0.0, -3.0))
	assert_almost_eq(cloud.lifetime, 3.0, 0.001)
	assert_almost_eq((cloud.get_node("Ring") as Node3D).scale.x, 3.0, 0.001)


func test_nuvem_que_chega_atrasada_mostra_so_o_que_falta() -> void:
	_bind()
	(_driver as RogueVfx).smoke(Vector3.ZERO, NetworkTime.tick - 30)
	assert_almost_eq((_pool.get_child(0) as SmokeCloudVfx).lifetime, 2.0, 0.001)
	(_driver as RogueVfx).smoke(Vector3.ZERO, NetworkTime.tick - 120)
	assert_eq(_effects(), 1, "ja acabou: nada")


func test_emboscada_solta_tres_fantasmas() -> void:
	_bind()
	var rogue := _hero as Rogue
	rogue.ambushing = true
	rogue.dash_ticks = 10
	for i: int in 20:
		_driver._process(0.03)
	assert_eq(_effects(), 3)


func test_golpe_oculto_tem_corte_e_clarao_roxo() -> void:
	_bind()
	_driver.impact(HitLedger.Slot.R, Vector3(1.0, 0.0, -2.0))
	assert_eq(_effects(), 1, "revelada: so o corte")
	(_hero as Rogue).ambush_hidden = true
	_driver.impact(HitLedger.Slot.R, Vector3(1.0, 0.0, -2.0))
	assert_eq(_effects(), 3, "oculta: corte + clarao roxo")
