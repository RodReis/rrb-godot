extends GutTest
## F41: os efeitos do heroi nascem uma vez por disparo, lidos da borda do estado. O rollback do
## cliente refaz o mesmo estado (valor restaurado igual) e nao pode duplicar o efeito; heroi
## escondido (mato, neblina) nao mostra nada. Aqui o processo e o host (peer 1).

const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const RANGER: String = "res://scenes/heroes/ranger.tscn"
const KNIGHT_VFX: PackedScene = preload("res://scenes/vfx/knight_vfx.tscn")
const RANGER_VFX: PackedScene = preload("res://scenes/vfx/ranger_vfx.tscn")
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
