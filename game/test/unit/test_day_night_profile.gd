extends GutTest
## DayNightProfile (F49, SPEC-049 §2): dia (t=0) -> entardecer (0,5) -> noite (1), interpolacao
## suave entre as chaves e noite igual ao visual aceito no F40 (PI 2026-10-11).

const PROFILE: String = "res://shared/data/visual/day_night.tres"

var _profile: DayNightProfile
var _out: DayNightKey


func before_each() -> void:
	_profile = load(PROFILE) as DayNightProfile
	_out = DayNightKey.new()


func test_tem_dia_entardecer_e_noite_em_ordem() -> void:
	assert_eq(_profile.keys.size(), 3)
	assert_eq(_profile.keys[0].time, 0.0)
	assert_almost_eq(_profile.keys[1].time, 0.5, 0.0001)
	assert_eq(_profile.keys[2].time, 1.0)


func test_amostra_nas_chaves_devolve_a_propria_chave() -> void:
	for key: DayNightKey in _profile.keys:
		_profile.sample(key.time, _out)
		assert_almost_eq(_out.sun_energy, key.sun_energy, 0.0001, "energia em t=%s" % key.time)
		assert_almost_eq(_out.sun_pitch_deg, key.sun_pitch_deg, 0.0001)
		assert_almost_eq(_out.sky_day, key.sky_day, 0.0001)
		assert_true(_out.sun_color.is_equal_approx(key.sun_color), "cor do sol em t=%s" % key.time)


func test_dia_e_ceu_azul_e_noite_e_ceu_cosmico() -> void:
	assert_eq(_profile.keys[0].sky_day, 1.0)
	assert_eq(_profile.keys[2].sky_day, 0.0)


func test_sol_alto_de_dia_e_baixo_no_entardecer() -> void:
	var day_elevation := -_profile.keys[0].sun_pitch_deg
	var dusk_elevation := -_profile.keys[1].sun_pitch_deg
	assert_gt(day_elevation, 55.0, "sol alto")
	assert_lt(dusk_elevation, 20.0, "sol baixo")


func test_noite_e_o_visual_do_f40() -> void:
	var night := _profile.keys[2]
	assert_true(night.sun_color.is_equal_approx(Color(0.8, 0.85, 0.95)))
	assert_almost_eq(night.sun_energy, 1.05, 0.0001)
	assert_almost_eq(night.sun_pitch_deg, -38.0, 0.0001)
	assert_almost_eq(night.sun_yaw_deg, 38.0, 0.0001)
	assert_almost_eq(night.sun_shadow_blur, 3.0, 0.0001)
	assert_eq(night.ambient_color, Color(0.24, 0.27, 0.36))
	assert_almost_eq(night.ambient_energy, 0.72, 0.0001)
	assert_almost_eq(night.exposure, 0.92, 0.0001)
	assert_almost_eq(night.fog_density, 0.016, 0.0001)
	assert_eq(night.fog_albedo, Color(0.36, 0.41, 0.5))
	assert_almost_eq(night.emission_scale, 1.0, 0.0001)


func test_continuo_sem_salto_entre_amostras_vizinhas() -> void:
	var previous := DayNightKey.new()
	_profile.sample(0.0, previous)
	var steps := 600
	for i: int in range(1, steps + 1):
		_profile.sample(float(i) / steps, _out)
		assert_lt(absf(_out.sun_energy - previous.sun_energy), 0.05, "energia salta em %d" % i)
		assert_lt(absf(_out.sky_day - previous.sky_day), 0.05, "ceu salta em %d" % i)
		assert_lt(absf(_out.sun_pitch_deg - previous.sun_pitch_deg), 2.0, "sol salta em %d" % i)
		previous.sun_energy = _out.sun_energy
		previous.sky_day = _out.sky_day
		previous.sun_pitch_deg = _out.sun_pitch_deg


func test_fora_de_0_1_prende_nas_pontas() -> void:
	_profile.sample(-3.0, _out)
	assert_almost_eq(_out.sun_energy, _profile.keys[0].sun_energy, 0.0001)
	_profile.sample(7.0, _out)
	assert_almost_eq(_out.sun_energy, _profile.keys[2].sun_energy, 0.0001)


func test_sample_nao_aloca_chave_nova() -> void:
	var before := Performance.get_monitor(Performance.OBJECT_COUNT)
	for i: int in range(200):
		_profile.sample(float(i) / 200.0, _out)
	assert_lte(Performance.get_monitor(Performance.OBJECT_COUNT), before + 5)
