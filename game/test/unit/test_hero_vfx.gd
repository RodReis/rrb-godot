extends GutTest
## F41: os efeitos do heroi nascem uma vez por disparo, lidos da borda do estado. O rollback do
## cliente refaz o mesmo estado (valor restaurado igual) e nao pode duplicar o efeito; heroi
## escondido (mato, neblina) nao mostra nada. Aqui o processo e o host (peer 1).

const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const RANGER: String = "res://scenes/heroes/ranger.tscn"
const KNIGHT_VFX: PackedScene = preload("res://scenes/vfx/knight_vfx.tscn")
const RANGER_VFX: PackedScene = preload("res://scenes/vfx/ranger_vfx.tscn")
const BARBARIAN: String = "res://scenes/heroes/barbarian.tscn"
const BARBARIAN_VFX: PackedScene = preload("res://scenes/vfx/barbarian_vfx.tscn")
const WIZARD: String = "res://scenes/heroes/fire_wizard.tscn"
const WIZARD_VFX: PackedScene = preload("res://scenes/vfx/fire_wizard_vfx.tscn")
const ROGUE: String = "res://scenes/heroes/rogue.tscn"
const ROGUE_VFX: PackedScene = preload("res://scenes/vfx/rogue_vfx.tscn")
const FRAME: float = 1.0 / 60.0
const COOLDOWN: int = 1200

var _hero: Hero
var _pool: VfxPool
var _driver: HeroVfx


## [param peer] "1" e o jogador deste processo; outro peer comeca escondido (neblina).
func _bind(scene: String, driver_scene: PackedScene, peer: String = "1") -> void:
	_hero = (load(scene) as PackedScene).instantiate() as Hero
	_hero.name = peer
	_hero.level = 6
	add_child_autofree(_hero)
	_pool = VfxPool.new()
	add_child_autofree(_pool)
	_driver = driver_scene.instantiate() as HeroVfx
	add_child_autofree(_driver)
	_driver.bind(_hero, _pool)
	_frame()  # 1o valor visto nao e borda


func _frame() -> void:
	_driver._process(FRAME)


func _effects() -> int:
	return _pool.get_child_count()


func test_terremoto_nasce_uma_vez_mesmo_com_o_rollback_refazendo_o_estado() -> void:
	_bind(KNIGHT, KNIGHT_VFX)
	_hero.r_cooldown = COOLDOWN
	_frame()
	assert_eq(_effects(), 1)
	for value: int in [COOLDOWN - 1, COOLDOWN - 1, COOLDOWN - 2, COOLDOWN - 2, COOLDOWN - 3]:
		_hero.r_cooldown = value
		_frame()
	assert_eq(_effects(), 1, "estado restaurado igual nao e disparo novo")


func test_terremoto_usa_o_raio_do_gdb() -> void:
	_bind(KNIGHT, KNIGHT_VFX)
	_hero.r_cooldown = COOLDOWN
	_frame()
	var quake := _pool.get_child(0) as EarthquakeVfx
	var crack := quake.get_node("Crack") as Decal
	var radius := _hero.hero_data.skill_r.radius
	assert_eq(crack.size.x, radius * 2.0)
	assert_eq(quake.global_position, _hero.global_position)


func test_heroi_escondido_nao_mostra_o_disparo() -> void:
	_bind(KNIGHT, KNIGHT_VFX, "5")
	_hero.r_cooldown = COOLDOWN
	_frame()
	assert_eq(_effects(), 0)
	assert_false(_driver.visible)


func test_basico_liga_o_rastro_e_a_muralha_aparece_com_o_escudo() -> void:
	_bind(KNIGHT, KNIGHT_VFX)
	var trail := _driver.get_node("Trail") as TrailRibbon
	var shield := _driver.get_node("Shield") as MeshInstance3D
	_hero.basic_cooldown = 30
	_hero.shield_ticks = 90
	_frame()
	_frame()
	assert_true(trail.emitting, "rastro varre o arco")
	assert_true(shield.visible)


func test_investida_solta_poeira_uma_vez_no_fim() -> void:
	_bind(KNIGHT, KNIGHT_VFX)
	var lines := _driver.get_node("SpeedLines") as GPUParticles3D
	_hero.dash_ticks = 10
	_frame()
	assert_true(lines.emitting, "linhas de velocidade durante o avanco")
	_hero.dash_ticks = 0
	_frame()
	_frame()
	assert_false(lines.emitting)
	assert_eq(_effects(), 1, "uma poeira no fim")


func test_impacto_confirmado_vira_faisca_no_alvo() -> void:
	_bind(KNIGHT, KNIGHT_VFX)
	var at := Vector3(3.0, 0.0, -2.0)
	_driver.impact(HitLedger.Slot.BASIC, at)
	assert_eq(_effects(), 1)
	assert_almost_eq((_pool.get_child(0) as Node3D).global_position.x, at.x, 0.001)


func test_rolamento_solta_poeira_e_fantasma_no_inicio_e_poeira_no_fim() -> void:
	_bind(RANGER, RANGER_VFX)
	_hero.dash_ticks = 10
	_frame()
	assert_eq(_effects(), 2, "poeira + fantasma")
	_hero.dash_ticks = 9
	_frame()
	_hero.dash_ticks = 10  # ressimulacao refaz o mesmo avanco
	_frame()
	assert_eq(_effects(), 2)
	_hero.dash_ticks = 0
	_frame()
	assert_eq(_effects(), 3, "2o tufo de poeira")


func test_pulso_por_alvo_atravessado_e_saraivada_na_area() -> void:
	_bind(RANGER, RANGER_VFX)
	_driver.impact(HitLedger.Slot.Q, Vector3.ZERO)
	_driver.impact(HitLedger.Slot.Q, Vector3(1.0, 0.0, 0.0))
	assert_eq(_effects(), 2, "um pulso por alvo")
	var volley := _driver.get_node("Volley") as GPUParticles3D
	_hero.rain_ticks = 90
	_hero.rain_center = Vector3(4.0, 0.0, 2.0)
	_frame()
	assert_true(volley.emitting)
	assert_almost_eq(volley.global_position.x, 4.0, 0.001)
	var rain := volley.process_material as ParticleProcessMaterial
	assert_eq(rain.emission_ring_radius, _hero.hero_data.skill_r.radius)


func test_flecha_em_voo_tem_rastro() -> void:
	_bind(RANGER, RANGER_VFX)
	var arrow := _hero.get_node("Arrows/Arrow0") as Arrow
	arrow.speed = 20.0
	arrow.launch(Arrow.Kind.PIERCE, Vector3.UP, Vector3.FORWARD, 9.0, 10)
	arrow._process(FRAME)
	_frame()
	var trail := _driver.get_node("ArrowTrail") as TrailRibbon
	assert_true(trail.emitting)
	assert_true((_driver.get_node("Spiral") as TrailRibbon).emitting, "espiral do Q")


func test_salto_tem_linhas_no_ar_e_rachadura_no_raio_do_salto_na_aterrissagem() -> void:
	_bind(BARBARIAN, BARBARIAN_VFX)
	var lines := _driver.get_node("SpeedLines") as GPUParticles3D
	_hero.dash_ticks = 14
	_frame()
	assert_true(lines.emitting)
	assert_eq(_effects(), 0, "no ar nada nasce")
	_hero.dash_ticks = 0
	_frame()
	assert_eq(_effects(), 1, "impacto na aterrissagem")
	var crack := (_pool.get_child(0) as EarthquakeVfx).get_node("Crack") as Decal
	assert_eq(crack.size.x, _hero.hero_data.skill_q.radius * 2.0)


func test_rodopio_gira_o_rastro_no_raio_do_e_enquanto_canaliza() -> void:
	_bind(BARBARIAN, BARBARIAN_VFX)
	var trail := _driver.get_node("Trail") as TrailRibbon
	var swing := _driver.get_node("Swing") as Node3D
	var tip := _driver.get_node("Swing/Tip") as Node3D
	(_hero as Barbarian).spin_ticks = 45
	_frame()
	var turned := swing.rotation.y
	_frame()
	assert_true(trail.emitting)
	assert_ne(swing.rotation.y, turned, "o rastro da volta")
	assert_almost_eq(tip.position.length(), _hero.hero_data.skill_e.radius, 0.001)
	(_hero as Barbarian).spin_ticks = 0
	for i: int in 30:
		_frame()
	assert_false(trail.emitting, "parou de girar")


func test_execucao_varre_o_arco_do_r_e_impacto_vira_faisca() -> void:
	_bind(BARBARIAN, BARBARIAN_VFX)
	var trail := _driver.get_node("Trail") as TrailRibbon
	var tip := _driver.get_node("Swing/Tip") as Node3D
	_hero.r_cooldown = COOLDOWN
	_frame()
	_frame()
	assert_true(trail.emitting)
	assert_almost_eq(tip.position.length(), _hero.hero_data.skill_r.attack_range, 0.001)
	_driver.impact(HitLedger.Slot.R, Vector3(1.0, 0.0, -2.0))
	assert_eq(_effects(), 1)


func test_bola_de_fogo_em_voo_tem_rastro() -> void:
	_bind(WIZARD, WIZARD_VFX)
	var ball := _hero.get_node("Arrows/Arrow0") as Arrow
	ball.speed = 16.0
	ball.launch(Arrow.Kind.BASIC, Vector3.UP, Vector3.FORWARD, 8.0, 45)
	ball._process(FRAME)
	_frame()
	assert_true((_driver.get_node("ArrowTrail") as TrailRibbon).emitting)
	assert_eq(_effects(), 0, "a bola em voo nao explode")


func test_explosao_de_chamas_nasce_onde_o_voo_acaba_no_raio_do_q() -> void:
	_bind(WIZARD, WIZARD_VFX)
	var ball := _hero.get_node("Arrows/Arrow1") as Arrow
	ball.launch(Arrow.Kind.EXPLODE, Vector3.UP, Vector3.FORWARD, 9.0, 110)
	_frame()
	ball.origin = Vector3(2.0, 1.0, -5.0)
	ball.stop()
	_frame()
	assert_eq(_effects(), 1)
	var burst := _pool.get_child(0) as FireBurstVfx
	assert_almost_eq(burst.global_position, Vector3(2.0, 1.0, -5.0), Vector3.ONE * 0.001)
	assert_almost_eq(burst.radius, _hero.hero_data.skill_q.radius, 0.001)
	_frame()
	assert_eq(_effects(), 1, "uma vez")


func test_bola_do_basico_que_para_nao_explode() -> void:
	_bind(WIZARD, WIZARD_VFX)
	var ball := _hero.get_node("Arrows/Arrow0") as Arrow
	ball.launch(Arrow.Kind.BASIC, Vector3.UP, Vector3.FORWARD, 8.0, 45)
	_frame()
	ball.stop()
	_frame()
	assert_eq(_effects(), 0)
	_driver.impact(HitLedger.Slot.BASIC, Vector3(1.0, 0.0, -3.0))
	assert_eq(_effects(), 1, "impacto confirmado da bola")


func test_anel_de_fogo_no_raio_do_e() -> void:
	_bind(WIZARD, WIZARD_VFX)
	_hero.e_cooldown = COOLDOWN
	_frame()
	assert_eq(_effects(), 1)
	var ring := _pool.get_child(0) as FireBurstVfx
	assert_almost_eq(ring.radius, _hero.hero_data.skill_e.radius, 0.001)
	assert_eq(ring.global_position, _hero.global_position)


func test_meteoro_cai_sobre_a_marcacao_e_explode_na_queda() -> void:
	_bind(WIZARD, WIZARD_VFX)
	var wizard := _hero as FireWizard
	var meteor := _driver.get_node("Meteor") as Node3D
	wizard.meteor_center = Vector3(3.0, 0.0, -6.0)
	wizard.meteor_ticks = 25
	_frame()
	assert_true(meteor.visible)
	var high := meteor.global_position.y
	assert_gt(high, 2.0, "ainda no alto")
	wizard.meteor_ticks = 5
	_frame()
	assert_lt(meteor.global_position.y, high, "desce")
	assert_eq(_effects(), 0)
	wizard.meteor_ticks = 0
	_frame()
	assert_false(meteor.visible)
	assert_eq(_effects(), 2, "explosao + cratera na queda")
	var burst := _pool.get_child(0) as FireBurstVfx
	assert_almost_eq(burst.global_position, wizard.meteor_center, Vector3.ONE * 0.001)
	assert_almost_eq(burst.radius, wizard.hero_data.skill_r.radius, 0.001)


# Ladina (F58, SPEC-058 §6).


func test_disparo_da_besta_solta_um_clarao_e_a_rajada_um_maior() -> void:
	_bind(ROGUE, ROGUE_VFX)
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
	_bind(ROGUE, ROGUE_VFX)
	var bolt := _hero.get_node("Arrows/Arrow2") as Arrow
	bolt.speed = 24.0
	bolt.launch(Arrow.Kind.FAN, Vector3.UP, Vector3.FORWARD, 7.0, 52)
	bolt._process(FRAME)
	_frame()
	assert_true((_driver.get_node("BoltTrail") as TrailRibbon).emitting or _any_trail_emitting())


func _any_trail_emitting() -> bool:
	for node: Node in _driver.get_children():
		if node is TrailRibbon and (node as TrailRibbon).emitting:
			return true
	return false


func test_nuvem_no_raio_e_na_duracao_do_e() -> void:
	_bind(ROGUE, ROGUE_VFX)
	(_driver as RogueVfx).smoke(Vector3(2.0, 0.0, -3.0), NetworkTime.tick)
	assert_eq(_effects(), 1)
	var cloud := _pool.get_child(0) as SmokeCloudVfx
	assert_eq(cloud.global_position, Vector3(2.0, 0.0, -3.0))
	assert_almost_eq(cloud.lifetime, 3.0, 0.001)
	assert_almost_eq((cloud.get_node("Ring") as Node3D).scale.x, 3.0, 0.001)


func test_nuvem_que_chega_atrasada_mostra_so_o_que_falta() -> void:
	_bind(ROGUE, ROGUE_VFX)
	(_driver as RogueVfx).smoke(Vector3.ZERO, NetworkTime.tick - 30)
	assert_almost_eq((_pool.get_child(0) as SmokeCloudVfx).lifetime, 2.0, 0.001)
	(_driver as RogueVfx).smoke(Vector3.ZERO, NetworkTime.tick - 120)
	assert_eq(_effects(), 1, "ja acabou: nada")


func test_emboscada_solta_tres_fantasmas() -> void:
	_bind(ROGUE, ROGUE_VFX)
	var rogue := _hero as Rogue
	rogue.ambushing = true
	rogue.dash_ticks = 10
	for i: int in 20:
		_driver._process(0.03)
	assert_eq(_effects(), 3)


func test_golpe_oculto_tem_corte_e_clarao_roxo() -> void:
	_bind(ROGUE, ROGUE_VFX)
	_driver.impact(HitLedger.Slot.R, Vector3(1.0, 0.0, -2.0))
	assert_eq(_effects(), 1, "revelada: so o corte")
	(_hero as Rogue).ambush_hidden = true
	_driver.impact(HitLedger.Slot.R, Vector3(1.0, 0.0, -2.0))
	assert_eq(_effects(), 3, "oculta: corte + clarao roxo")
