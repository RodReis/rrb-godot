extends GutTest
## DayNight (F49, SPEC-049 §5): a luz sai do relogio da partida e do sentido sorteado, igual nos
## dois clientes; selecao = inicio, partida parada congela, depois dos 10:00 fica na ponta.

const RULES: String = "res://shared/data/rules/match_pacing.tres"
const SKY_SHADER: String = "res://shared/shaders/abyss_sky.gdshader"
const SHARED_SKY: String = "res://shared/resources/materials/abyss_sky.tres"
const LAVA: String = "res://shared/resources/materials/volcanic_lava.tres"
const RATE: int = 30
const START: int = 1000
const EPS: float = 0.01

var _clock: MatchClock
var _match: MatchController
var _sun: DirectionalLight3D
var _world: WorldEnvironment
var _day_night: DayNight


func before_each() -> void:
	_clock = MatchClock.new()
	_clock.rules = load(RULES) as MatchRules
	add_child_autofree(_clock)
	_match = MatchController.new()
	add_child_autofree(_match)
	_sun = DirectionalLight3D.new()
	add_child_autofree(_sun)
	_world = WorldEnvironment.new()
	_world.environment = _make_environment()
	add_child_autofree(_world)
	_day_night = _make_day_night(_sun, _world)


func after_each() -> void:
	for file: String in DayNight.EMISSIVE_MATERIALS:
		var material := load(DayNight.MATERIALS_DIR + file) as ShaderMaterial
		material.set_shader_parameter(DayNight.EMISSION_PARAM, 1.0)


func _make_environment() -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var material := ShaderMaterial.new()
	material.shader = load(SKY_SHADER)
	sky.sky_material = material
	env.sky = sky
	return env


func _make_day_night(sun: DirectionalLight3D, world: WorldEnvironment) -> DayNight:
	var node := DayNight.new()
	add_child_autofree(node)
	node.bind(_clock, _match, sun, world)
	return node


func _sky(world: WorldEnvironment) -> ShaderMaterial:
	return world.environment.sky.sky_material as ShaderMaterial


func _sky_day(world: WorldEnvironment) -> float:
	return float(_sky(world).get_shader_parameter("day_amount"))


func _at(seconds: float) -> int:
	return START + int(seconds * RATE)


func test_selecao_mostra_o_inicio_do_dia_para_a_noite() -> void:
	_match.day_to_night = true
	_day_night.apply(START)
	assert_almost_eq(_sun.rotation_degrees.x, -62.0, EPS)
	assert_almost_eq(_sky_day(_world), 1.0, EPS)


func test_selecao_mostra_o_inicio_da_noite_para_o_dia() -> void:
	_match.day_to_night = false
	_day_night.apply(START)
	assert_almost_eq(_sun.rotation_degrees.x, -38.0, EPS)
	assert_almost_eq(_sky_day(_world), 0.0, EPS)


func test_dia_para_noite_aos_5_00_e_entardecer() -> void:
	_match.day_to_night = true
	_clock.start(START, RATE)
	_day_night.apply(_at(300.0))
	assert_almost_eq(_sun.rotation_degrees.x, -10.0, EPS)
	assert_almost_eq(_sun.light_energy, 1.4, EPS)


func test_noite_para_dia_aos_5_00_tambem_e_entardecer() -> void:
	_match.day_to_night = false
	_clock.start(START, RATE)
	_day_night.apply(_at(300.0))
	assert_almost_eq(_sun.rotation_degrees.x, -10.0, EPS)


func test_aos_10_00_dia_para_noite_termina_de_noite() -> void:
	_match.day_to_night = true
	_clock.start(START, RATE)
	_day_night.apply(_at(600.0))
	assert_almost_eq(_sun.rotation_degrees.x, -38.0, EPS)
	assert_almost_eq(_sun.light_energy, 1.05, EPS)
	assert_almost_eq(_world.environment.tonemap_exposure, 0.92, EPS)


func test_aos_10_00_noite_para_dia_termina_de_dia() -> void:
	_match.day_to_night = false
	_clock.start(START, RATE)
	_day_night.apply(_at(600.0))
	assert_almost_eq(_sun.rotation_degrees.x, -62.0, EPS)


func test_depois_dos_600s_fica_na_ponta() -> void:
	_match.day_to_night = true
	_clock.start(START, RATE)
	_day_night.apply(_at(600.0))
	var energy := _sun.light_energy
	_day_night.apply(_at(900.0))
	assert_almost_eq(_sun.light_energy, energy, 0.0001)


func test_dois_clientes_no_mesmo_tick_mostram_a_mesma_luz() -> void:
	_match.day_to_night = true
	_clock.start(START, RATE)
	var other_sun := DirectionalLight3D.new()
	add_child_autofree(other_sun)
	var other_world := WorldEnvironment.new()
	other_world.environment = _make_environment()
	add_child_autofree(other_world)
	var other := _make_day_night(other_sun, other_world)
	var tick := _at(217.0)
	_day_night.apply(tick)
	other.apply(tick)
	assert_eq(_sun.rotation_degrees, other_sun.rotation_degrees)
	assert_eq(_sun.light_energy, other_sun.light_energy)
	assert_eq(_world.environment.ambient_light_color, other_world.environment.ambient_light_color)
	assert_eq(_sky_day(_world), _sky_day(other_world))


func test_emissao_acompanha_a_curva() -> void:
	_match.day_to_night = true
	_clock.start(START, RATE)
	var lava := load(LAVA) as ShaderMaterial
	_day_night.apply(_at(0.0))
	assert_almost_eq(float(lava.get_shader_parameter(DayNight.EMISSION_PARAM)), 0.35, EPS)
	_day_night.apply(_at(600.0))
	assert_almost_eq(float(lava.get_shader_parameter(DayNight.EMISSION_PARAM)), 1.0, EPS)


func test_ceu_compartilhado_do_projeto_nao_e_alterado() -> void:
	var shared := load(SHARED_SKY) as ShaderMaterial
	var before: Variant = shared.get_shader_parameter("day_amount")
	_match.day_to_night = true
	_day_night.apply(START)
	assert_eq(shared.get_shader_parameter("day_amount"), before)


func test_sol_do_ceu_aponta_para_onde_o_sol_esta() -> void:
	_match.day_to_night = true
	_day_night.apply(START)
	var direction := _sky(_world).get_shader_parameter("sun_direction") as Vector3
	assert_almost_eq(direction, _sun.basis.z, Vector3.ONE * 0.0001)
	assert_gt(direction.y, 0.5, "sol alto de dia: o disco fica acima do horizonte")


func test_sentido_que_chega_depois_do_bind_troca_a_luz_e_a_sonda() -> void:
	var probe := ReflectionProbe.new()
	add_child_autofree(probe)
	var late := DayNight.new()
	add_child_autofree(late)
	late.bind(_clock, _match, _sun, _world, probe)  # bind com o padrao (dia -> noite)
	assert_almost_eq(_sun.rotation_degrees.x, -62.0, EPS)
	_match.day_to_night = false  # o RPC do sentido chega na selecao
	late.apply(START)
	assert_almost_eq(_sun.rotation_degrees.x, -38.0, EPS, "noite")
	assert_almost_eq(_sky_day(_world), 0.0, EPS)
	assert_eq(probe.update_mode, ReflectionProbe.UPDATE_ALWAYS, "sonda refeita")


func test_sonda_volta_para_once_depois_dos_quadros_de_refresh() -> void:
	var probe := ReflectionProbe.new()
	add_child_autofree(probe)
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	var node := DayNight.new()
	add_child_autofree(node)
	node.bind(_clock, _match, _sun, _world, probe)
	_clock.start(START, RATE)
	node.apply(_at(300.0))
	assert_eq(probe.update_mode, ReflectionProbe.UPDATE_ALWAYS)
	for i: int in range(DayNight.PROBE_REFRESH_FRAMES):
		node._process(0.0)
	assert_eq(probe.update_mode, ReflectionProbe.UPDATE_ONCE)


func test_ambiente_sem_ceu_de_shader_nao_derruba() -> void:
	var plain := WorldEnvironment.new()
	plain.environment = Environment.new()
	add_child_autofree(plain)
	var node := _make_day_night(_sun, plain)
	node.apply(START)
	assert_almost_eq(_sun.rotation_degrees.x, -62.0, EPS)
