extends GutTest
## F75 (SPEC-075 regra 5): efeitos do Berserker pela borda do estado — rastro do basico para o lado
## da mao, machado do Q girando com rastro, onda do Grito, explosao e aura do Ragnarok — e o brilho
## do Frenesi, que cresce com o f. Aqui o processo e o host (peer 1).

const BERSERKER: String = "res://scenes/heroes/berserker.tscn"
const BERSERKER_VFX: PackedScene = preload("res://scenes/vfx/berserker_vfx.tscn")
const FRAME: float = 1.0 / 60.0
const AIM: Vector3 = Vector3(0, 0, -1)
const EPS: float = 0.0001

var _hero: Berserker
var _pool: VfxPool
var _driver: BerserkerVfx


func _bind() -> void:
	_hero = (load(BERSERKER) as PackedScene).instantiate() as Berserker
	_hero.name = "1"
	_hero.level = 6
	add_child_autofree(_hero)
	_pool = VfxPool.new()
	add_child_autofree(_pool)
	_driver = BERSERKER_VFX.instantiate() as BerserkerVfx
	add_child_autofree(_driver)
	_driver.bind(_hero, _pool)
	_frame()  # 1o valor visto nao e borda


func _frame() -> void:
	_driver._process(FRAME)


func _effects() -> int:
	return _pool.get_child_count()


func test_frenesi_sem_brilho_com_hp_cheio() -> void:
	_bind()
	_frame()
	assert_false(_driver._embers.emitting)
	assert_false(_driver._frenzy_light.visible)


func test_brilho_do_frenesi_cresce_com_o_hp_perdido() -> void:
	_bind()
	_hero.hp = roundi(_hero.attributes.max_hp * 0.6)  # f = 0,5
	_frame()
	var half := _driver._frenzy_light.light_energy
	assert_true(_driver._embers.emitting)
	assert_almost_eq(_driver._embers.amount_ratio, 0.5, 0.01)
	_hero.hp = roundi(_hero.attributes.max_hp * 0.2)  # f = 1
	_frame()
	assert_gt(_driver._frenzy_light.light_energy, half)
	assert_almost_eq(_driver._embers.amount_ratio, 1.0, EPS)


func test_basico_varre_para_o_lado_da_mao() -> void:
	_bind()
	_hero.swing_left = false
	_hero.basic_cooldown = 20
	_frame()
	var right_start := _driver._swing_from
	_hero.basic_cooldown = 0
	_frame()
	_hero.swing_left = true
	_hero.basic_cooldown = 20
	_frame()
	assert_almost_eq(_driver._swing_from, -right_start, EPS, "a outra mao varre ao contrario")
	assert_true(_driver._trail.emitting)


func test_machado_gira_no_ar_com_rastro() -> void:
	_bind()
	var arrow := _hero.get_node("Arrows/Arrow0") as Arrow
	var axe := arrow.get_node("Axe") as Node3D
	arrow.launch(Arrow.Kind.AXE, Vector3(0, 1, 0), AIM, 7.0, 90)
	arrow._process(FRAME)
	var before := axe.rotation.x
	_frame()
	assert_ne(axe.rotation.x, before)
	assert_true(_driver._axe_trails[0].emitting)


func test_grito_solta_a_onda() -> void:
	_bind()
	_hero.e_cooldown = 300
	_frame()
	assert_eq(_effects(), 1)


func test_ragnarok_explode_e_acende_a_aura_enquanto_dura() -> void:
	_bind()
	_hero.r_cooldown = 1800
	_hero.cc_immune_ticks = 120
	_frame()
	assert_eq(_effects(), 1, "explosao no uso")
	assert_true(_driver._aura.emitting)
	assert_true(_driver._smoke.emitting, "fumaca junto do fogo")
	assert_almost_eq(_driver._frenzy_light.light_energy, _driver.rage_light_energy, EPS)
	_hero.cc_immune_ticks = 0
	_frame()
	assert_false(_driver._aura.emitting)
