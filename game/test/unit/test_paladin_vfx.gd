extends GutTest
## F76 (SPEC-076 regra 4): efeitos do Paladino pela borda do estado (rastro da Maca, sigilo do Golpe
## Consagrado, coluna da Bencao), pelo estado que dura (aro da Retribuicao, aureola da Bencao) e
## pelo impacto confirmado (faiscas; clarao dourado no dano devolvido). Processo = host (peer 1).

const PALADIN: String = "res://scenes/heroes/paladin.tscn"
const PALADIN_VFX: PackedScene = preload("res://scenes/vfx/paladin_vfx.tscn")
const FRAME: float = 1.0 / 60.0

var _hero: Paladin
var _pool: VfxPool
var _driver: PaladinVfx


func _bind() -> void:
	_hero = (load(PALADIN) as PackedScene).instantiate() as Paladin
	_hero.name = "1"
	_hero.level = 6
	add_child_autofree(_hero)
	_pool = VfxPool.new()
	add_child_autofree(_pool)
	_driver = PALADIN_VFX.instantiate() as PaladinVfx
	add_child_autofree(_driver)
	_driver.bind(_hero, _pool)
	_frame()  # 1o valor visto nao e borda


func _frame(count: int = 1) -> void:
	for i: int in count:
		_driver._process(FRAME)


func _effects() -> int:
	return _pool.get_child_count()


func _last_effect() -> Node:
	return _pool.get_child(_effects() - 1)


func test_golpe_consagrado_poe_o_sigilo_a_frente() -> void:
	_bind()
	_hero.q_cooldown = 300
	_frame()
	assert_eq(_effects(), 1)
	var strike := _last_effect() as Node3D
	assert_eq(strike.name.begins_with("ConsecratedStrike"), true)
	var sigil := strike.get_node("Sigil") as Node3D
	assert_almost_eq(sigil.position.z, -1.25, 0.001, "centro da faixa de 2,5 u")


func test_bencao_solta_a_coluna_e_mostra_a_aureola_enquanto_dura() -> void:
	_bind()
	_hero.r_cooldown = 1800
	_hero.blessing_ticks = 45
	_frame()
	assert_eq(_effects(), 1, "coluna de luz no uso")
	assert_true(_driver._halo.visible)
	assert_true(_driver._bless_glow.emitting)
	_hero.blessing_ticks = 0
	_frame()
	assert_false(_driver._halo.visible)
	assert_false(_driver._bless_glow.emitting)


func test_aro_da_retribuicao_no_alcance_aparece_e_some() -> void:
	_bind()
	assert_almost_eq(_driver._ring.scale.x, 3.0, 0.001, "alcance da Retribuicao")
	_hero.retribution_ticks = 90
	_frame(20)
	assert_true(_driver._ring.visible)
	assert_true(_driver._ring_motes.emitting)
	_hero.retribution_ticks = 0
	_frame(20)
	assert_false(_driver._ring.visible)
	assert_false(_driver._ring_motes.emitting)


func test_basico_varre_o_rastro() -> void:
	_bind()
	_hero.basic_cooldown = 36
	_frame()
	assert_true(_driver._trail.emitting)
	assert_eq(_effects(), 0, "o basico nao usa o pool")


func test_impacto_do_dano_devolvido_e_dourado() -> void:
	_bind()
	_driver.impact(HitLedger.Slot.E, Vector3(2, 0, 0))
	assert_eq(_last_effect().name.begins_with("RetributionFlash"), true)
	_driver.impact(HitLedger.Slot.Q, Vector3(2, 0, 0))
	assert_eq(_effects(), 2)
	assert_eq(_last_effect().name.begins_with("Sparks"), true)


func test_heroi_escondido_nao_mostra_nada() -> void:
	_bind()
	_hero.hp = 0
	_hero.retribution_ticks = 90
	_hero.q_cooldown = 300
	_frame(20)
	assert_false(_driver.visible)
	assert_eq(_effects(), 0)
