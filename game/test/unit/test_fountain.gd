extends GutTest
## Fonte da base (PI 2026-10-10, #74): 1 % do HP max por segundo, so o time dono, raio 2,5 u, so
## com a fonte aberta (fase 1), vivo, e tomar dano pausa a cura por 3 s.

const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const FOUNTAIN: String = "res://scenes/world/fountain.tscn"
const TICK: float = 1.0 / 30.0
const RATE: int = 30
## Multiplo de 30: o pulso cai no fim de cada segundo a partir daqui.
const START: int = 900
const HERE: Vector3 = Vector3(-30, 0, 15)
const NEAR: Vector3 = Vector3(2, 0, 0)
const LOW_HP: int = 300

var _hero: Hero
var _fountain: Fountain


func before_each() -> void:
	_fountain = (load(FOUNTAIN) as PackedScene).instantiate() as Fountain
	_fountain.team = GateRules.TEAM_A
	_fountain.position = HERE
	add_child_autofree(_fountain)
	_hero = (load(KNIGHT) as PackedScene).instantiate() as Hero
	_hero.name = "1"
	_hero.team = GateRules.TEAM_A
	_hero.position = HERE + NEAR
	add_child_autofree(_hero)
	_hero.fountain_open = true
	_hero.hp = LOW_HP


func _run(from: int, to: int) -> void:
	for tick: int in range(from, to + 1):
		_hero._rollback_tick(TICK, tick, true)


func test_cura_um_por_cento_do_hp_max_por_segundo() -> void:
	_run(START + 1, START + RATE - 1)
	assert_eq(_hero.hp, LOW_HP, "so no fim do segundo")
	_run(START + RATE, START + 2 * RATE)
	assert_eq(_hero.hp, LOW_HP + 2 * 6)


func test_pulso_minimo_e_arredondado() -> void:
	assert_eq(FountainRules.heal_amount(600, 0.01), 6)
	assert_eq(FountainRules.heal_amount(810, 0.01), 8)
	assert_eq(FountainRules.heal_amount(10, 0.01), 1)


func test_condicoes_da_cura() -> void:
	assert_true(FountainRules.can_heal(true, true, 0, true))
	assert_false(FountainRules.can_heal(false, true, 0, true), "fechada")
	assert_false(FountainRules.can_heal(true, false, 0, true), "morto")
	assert_false(FountainRules.can_heal(true, true, 1, true), "dano recente")
	assert_false(FountainRules.can_heal(true, true, 0, false), "fora da area")


func test_fonte_do_outro_time_nao_cura() -> void:
	_fountain.team = GateRules.TEAM_B
	_run(START + 1, START + 2 * RATE)
	assert_eq(_hero.hp, LOW_HP)


func test_fora_do_raio_nao_cura() -> void:
	_hero.position = HERE + NEAR * 2
	_run(START + 1, START + 2 * RATE)
	assert_eq(_hero.hp, LOW_HP)


func test_fechada_fora_da_fase_1_nao_cura() -> void:
	_hero.fountain_open = false
	_run(START + 1, START + 2 * RATE)
	assert_eq(_hero.hp, LOW_HP)


func test_dano_pausa_a_cura_por_3_s() -> void:
	var blow := HitEffect.new(100)
	_hero.receive_hit(START + 1, HitLedger.source_key(-3, HitLedger.Slot.BASIC), blow)
	_run(START + 1, START + 1)
	var hurt := _hero.hp
	assert_lt(hurt, LOW_HP)
	_run(START + 2, START + 3 * RATE - 1)
	assert_eq(_hero.hp, hurt, "pulsos dos segundos 1 e 2 pulados")
	_run(START + 3 * RATE, START + 3 * RATE)
	assert_eq(_hero.hp, hurt + 6)


func test_nao_passa_do_hp_max() -> void:
	_hero.hp = _hero.attributes.max_hp - 2
	_run(START + 1, START + RATE)
	assert_eq(_hero.hp, _hero.attributes.max_hp)


func test_heroi_ve_a_fonte_aberta_so_na_fase_1() -> void:
	var rules := load("res://shared/data/rules/match_pacing.tres") as MatchRules
	var clock := MatchClock.new()
	clock.rules = rules
	add_child_autofree(clock)
	var match_controller := MatchController.new()
	match_controller.rules = rules
	match_controller.clock = clock
	match_controller.available_heroes = [&"knight"]
	add_child_autofree(match_controller)
	_hero.fountain_open = false
	match_controller.open(START, RATE)
	match_controller.join(1, GateRules.TEAM_A, false, START)
	match_controller.join(2, GateRules.TEAM_B, false, START)
	match_controller.update(START + 24 * RATE)
	assert_false(_hero.fountain_open, "INTRO")
	assert_true(_hero.input_locked, "INTRO")
	var phase1_tick := START + 24 * RATE + 8 * RATE  # corte da INTRO (F69)
	match_controller.update(phase1_tick)
	assert_true(_hero.fountain_open, "PHASE1")
	assert_false(_hero.input_locked, "PHASE1")
	clock.update(phase1_tick + 300 * RATE)
	assert_false(_hero.fountain_open, "TRANSITION")


## F64 (PI 2026-10-13) refeita no kit do F94 (ADR-0030: ate 1.600 triangulos por objeto): pedra
## PBR CC0 do kit e agua com o shader do F63; colisao igual (cilindro r 0,85 x h 1,2).
func test_modelo_com_pedra_realista_e_agua_do_f63() -> void:
	var scene := (load(FOUNTAIN) as PackedScene).instantiate()
	var mesh := scene.get_node("Model").find_children("*", "MeshInstance3D")[0] as MeshInstance3D
	var paths: Array[String] = []
	var tris := 0
	for surface: int in mesh.mesh.get_surface_count():
		paths.append(mesh.get_active_material(surface).resource_path.get_file())
		tris += (
			(mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
		)
	assert_has(paths, "kit_stone.tres")
	assert_has(paths, "fountain_water.tres")
	var water := mesh.get_active_material(paths.find("fountain_water.tres")) as ShaderMaterial
	assert_eq(water.shader.resource_path, "res://shared/shaders/arcane_river.gdshader")
	assert_between(tris, 50, 1600, "orcamento de objeto (ADR-0030)")
	var shape := scene.get_node("Body/Shape") as CollisionShape3D
	var cylinder := shape.shape as CylinderShape3D
	assert_almost_eq(cylinder.radius, 0.85, 0.001, "colisao igual")
	assert_almost_eq(cylinder.height, 1.2, 0.001, "colisao igual")
	scene.free()


## F64: agua caindo da taca para a bacia e respingo no impacto (particulas).
func test_agua_caindo_em_particulas() -> void:
	var scene := (load(FOUNTAIN) as PackedScene).instantiate()
	var names: Array[String] = []
	for node: Node in scene.get_node("Spray").get_children():
		assert_is(node, GPUParticles3D)
		names.append(String(node.name))
	assert_eq(names, ["Jet", "Overflow", "Splash"])
	scene.free()


## F64: servidor dedicado (headless) nao carrega as particulas; o modelo fica, como o resto da
## arena (malha estatica do lightmap, test_arena_lighting).
func test_headless_descarta_as_particulas() -> void:
	assert_eq(DisplayServer.get_name(), "headless", "GUT roda headless (tools/test.ps1)")
	assert_null(_fountain.get_node_or_null("Spray"))
	assert_not_null(_fountain.get_node_or_null("Model"))
	assert_not_null(_fountain.get_node_or_null("Body/Shape"))
